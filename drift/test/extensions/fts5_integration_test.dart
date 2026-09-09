@Tags(['integration'])
library;

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/extensions/fts5.dart';
import 'package:sqlite3/common.dart' show SqliteException;
import 'package:test/test.dart';

import '../generated/custom_tables.dart';
import '../test_utils/test_utils.dart';

// Emails used by the tests in this library.
//
// The emails are chosen so that the term `drift` only appears in the first
// email and the term `hello` appears multiple times in the third and once in
// the second email.
final _driftEmail = EmailCompanion.insert(
  sender: 'a@example.org',
  title: 'drift release',
  body: 'the drift library drift is out',
);
final _helloEmail = EmailCompanion.insert(
  sender: 'b@example.org',
  title: 'hello world',
  body: 'greetings everyone',
);
final _manyHelloEmail = EmailCompanion.insert(
  sender: 'c@example.org',
  title: 'hello again',
  body: 'hello world hello',
);

void main() {
  late CustomTablesDb db;

  setUp(() {
    db = CustomTablesDb(testInMemoryDatabase());
  });

  tearDown(() => db.close());

  Future<void> insertEmails() async {
    await db.into(db.email).insert(_driftEmail);
    await db.into(db.email).insert(_helloEmail);
    await db.into(db.email).insert(_manyHelloEmail);
  }

  test('fts5 integration test', () async {
    await db
        .into(db.email)
        .insert(
          EmailCompanion.insert(
            sender: 'foo@example.org',
            title: 'Hello world',
            body: 'Test email',
          ),
        );

    await db
        .into(db.email)
        .insert(
          EmailCompanion.insert(
            sender: 'another@example.org',
            title: 'Good morning',
            body: 'hello',
          ),
        );

    final results = await db.searchEmails(term: 'hello').get();

    expect(results, hasLength(2));
  });

  test('match filters rows by an fts5 query', () async {
    await insertEmails();

    final query = db.select(db.email)..where((tbl) => tbl.match('drift'));
    final matches = await query.get();

    expect(matches.map((email) => email.sender), ['a@example.org']);

    // queries can also be supplied as expressions
    final expressionQuery = db.select(db.email)
      ..where((tbl) => tbl.matchExp(Variable.withString('hello')));
    final expressionMatches = await expressionQuery.get();

    expect(expressionMatches.map((email) => email.sender).toSet(), {
      'b@example.org',
      'c@example.org',
    });
  });

  test('match and rank sort by relevance', () async {
    await insertEmails();

    final query = db.select(db.email)
      ..where((tbl) => tbl.match('hello'))
      ..orderBy([(u) => OrderingTerm(expression: u.rank)]);
    final matches = await query.get();

    // the email containing `hello` three times is a better match than the one
    // containing it once, and better matches have a smaller rank.
    expect(matches.map((email) => email.sender), [
      'c@example.org',
      'b@example.org',
    ]);
  });

  test('bm25 and rank can be read as doubles', () async {
    await insertEmails();

    final score = db.email.bm25();
    final rank = db.email.rank;
    final query = db.selectOnly(db.email)
      ..addColumns([score, rank])
      ..where(db.email.match('hello'));
    final rows = await query.get();

    expect(rows, hasLength(2));
    expect(rows.map((row) => row.read(score)), everyElement(isA<double>()));
    expect(rows.map((row) => row.read(rank)), everyElement(isA<double>()));
  });

  test('highlight wraps matches in the configured markers', () async {
    await insertEmails();

    final titleHighlight = db.email.highlight(
      db.email.title,
      before: '<b>',
      after: '</b>',
    );
    final query = db.selectOnly(db.email)
      ..addColumns([db.email.title, titleHighlight])
      ..where(db.email.match('hello'));
    final rows = await query.get();

    final highlights = {
      for (final row in rows)
        row.read(db.email.title)!: row.read(titleHighlight)!,
    };

    expect(highlights, {
      'hello world': '<b>hello</b> world',
      'hello again': '<b>hello</b> again',
    });
  });

  test('snippet excerpts the text around a match', () async {
    await insertEmails();

    final bodySnippet = db.email.snippet(
      db.email.body,
      before: '<',
      after: '>',
      ellipsis: '…',
      tokenCount: 10,
    );
    final query = db.selectOnly(db.email)
      ..addColumns([bodySnippet])
      ..where(db.email.match('hello'));
    final rows = await query.get();

    final snippets = rows.map((row) => row.read(bodySnippet)!).toSet();

    // columns without a match are returned as they are.
    expect(snippets, {'<hello> world <hello>', 'greetings everyone'});
  });

  test('match works on aliased tables in joins', () async {
    await insertEmails();
    await db.into(db.config).insert(ConfigCompanion.insert(configKey: 'other'));

    final aliased = db.alias(db.email, 'e');
    final query =
        db.select(db.config).join([
          innerJoin(aliased, aliased.rowId.isNotNull()),
        ])..where(
          // constrain the config table so that only the row inserted below
          // is joined. The `key` row is added by the `@create` query in the
          // drift file this database is generated from.
          db.config.configKey.equals('other') & aliased.match('hello'),
        );
    final rows = await query.get();

    expect(rows, hasLength(2));
    expect(rows.map((row) => row.readTable(aliased).sender).toSet(), {
      'b@example.org',
      'c@example.org',
    });
  });

  test('highlight works on aliased tables', () async {
    await insertEmails();
    await db.into(db.config).insert(ConfigCompanion.insert(configKey: 'other'));

    final aliased = db.alias(db.email, 'e');
    // The aliased table creates fresh column instances, so columns are matched
    // by name: columns of the original table work just as well as the aliased
    // ones.
    for (final column in [db.email.title, aliased.title]) {
      final highlight = aliased.highlight(column, before: '<b>', after: '</b>');
      final query = (db.selectOnly(db.config)..addColumns([highlight])).join([
        innerJoin(aliased, aliased.rowId.isNotNull()),
      ])..where(db.config.configKey.equals('other') & aliased.match('hello'));
      final rows = await query.get();

      expect(rows.map((row) => row.read(highlight)).toSet(), {
        '<b>hello</b> again',
        '<b>hello</b> world',
      });
    }
  });

  test('queries without matches return no rows', () async {
    await insertEmails();

    final query = db.select(db.email)
      ..where((tbl) => tbl.match('nothingmatchesthis'));

    expect(await query.get(), isEmpty);
  });

  test('match works in update and delete statements', () async {
    await insertEmails();

    await (db.update(db.email)..where((tbl) => tbl.match('drift'))).write(
      const EmailCompanion(body: Value('gone')),
    );
    final updated = await (db.select(
      db.email,
    )..where((tbl) => tbl.match('gone'))).get();
    expect(updated.single.sender, 'a@example.org');
    expect(updated.single.body, 'gone');

    await (db.delete(db.email)..where((tbl) => tbl.match('gone'))).go();
    final remaining = await db.select(db.email).get();
    expect(remaining.map((email) => email.sender).toSet(), {
      'b@example.org',
      'c@example.org',
    });
  });

  test('streams using match update when the table changes', () async {
    await insertEmails();

    final expectation = expectLater(
      (db.select(db.email)..where((tbl) => tbl.match('drift'))).watch(),
      emitsInOrder([hasLength(1), hasLength(2)]),
    );

    await db
        .into(db.email)
        .insert(
          EmailCompanion.insert(
            sender: 'd@example.org',
            title: 'drift 2.0',
            body: 'more drift',
          ),
        );

    await expectation;
  });

  test('match works with multiple fts5 tables in one query', () async {
    await insertEmails();
    await db.customStatement('CREATE VIRTUAL TABLE docs USING fts5(content)');
    await db.customStatement("INSERT INTO docs VALUES ('drift documentation')");

    // a drift-side representation of the table created above.
    final docs = CustomVirtualTable('docs', db, 'fts5(content)', [
      GeneratedColumn<String>(
        'content',
        'docs',
        true,
        type: DriftSqlType.string,
      ),
    ]);

    final query = db.select(docs).join([
      innerJoin(db.email, db.email.rowId.isNotNull()),
    ])..where(docs.match('drift') & db.email.match('greetings'));
    final rows = await query.get();

    // one row in docs and the one email matching `greetings`.
    expect(rows, hasLength(1));
    expect(rows.single.readTable(db.email).sender, 'b@example.org');
  });

  test('highlight and snippet reject unknown columns', () {
    // A column that isn't part of the fts5 table at all is rejected.
    final unknown = GeneratedColumn<String>(
      'other_col',
      'other',
      true,
      type: DriftSqlType.string,
    );

    expect(
      () => db.email.highlight(unknown, before: '<', after: '>'),
      throwsArgumentError,
    );
    expect(
      () => db.email.snippet(
        unknown,
        before: '<',
        after: '>',
        ellipsis: '…',
        tokenCount: 10,
      ),
      throwsArgumentError,
    );
  });

  test('malformed fts5 query strings fail at runtime', () async {
    await insertEmails();

    // fts5 query strings are parsed by sqlite when the statement runs, so a
    // malformed query (here: an unterminated phrase) fails with an error.
    final query = db.select(db.email)..where((tbl) => tbl.match('hello"'));

    await expectLater(query.get(), throwsA(isA<SqliteException>()));
  });

  test('all auxiliaries work together in one query', () async {
    await insertEmails();

    // Same combination previously checked statically with the sql analyzer:
    // match in the WHERE clause with highlight, snippet, bm25 and rank
    // projected together, ordered by rank.
    final titleHighlight = db.email.highlight(
      db.email.title,
      before: '<b>',
      after: '</b>',
    );
    final bodySnippet = db.email.snippet(
      db.email.body,
      before: '<',
      after: '>',
      ellipsis: '…',
      tokenCount: 64,
    );
    final score = db.email.bm25(weights: [1.0, 2.0, 3.0]);
    final rank = db.email.rank;

    final query = db.selectOnly(db.email)
      ..addColumns([db.email.title, titleHighlight, bodySnippet, score, rank])
      ..where(db.email.match('hello'))
      ..orderBy([OrderingTerm(expression: rank)]);
    final rows = await query.get();

    // Only the two emails containing `hello` match, best match first.
    expect(rows.map((row) => row.read(db.email.title)), [
      'hello again',
      'hello world',
    ]);
    expect(rows.map((row) => row.read(titleHighlight)), [
      '<b>hello</b> again',
      '<b>hello</b> world',
    ]);
    expect(
      rows.map((row) => row.read(bodySnippet)),
      everyElement(isA<String>()),
    );
    expect(rows.map((row) => row.read(score)), everyElement(isA<double>()));
    expect(rows.map((row) => row.read(rank)), everyElement(isA<double>()));
  });
}
