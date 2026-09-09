import 'package:drift3_preview/drift.dart';
import 'package:drift3_preview/internal/versioned_schema.dart';
import 'package:drift_sqlite/extensions/fts5.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  final email = VersionedVirtualTable(
    entityName: 'email',
    columns: [
      (_) => TableColumn<String>(name: 'sender', sqlType: .text),
      (_) => TableColumn<String>(name: 'title', sqlType: .text),
      (_) => TableColumn<String>(name: 'body', sqlType: .text),
    ],
    moduleAndArgs: 'fts5(sender, title, body)',
  );
  final [sender, title, body] = email.columns.cast<TableColumn<String>>();

  test('generates a match expression', () {
    expect(
      email.match('hello world'),
      generates('"email" MATCH ?1', ['hello world']),
    );
  });

  test('matchExp supports arbitrary expressions', () {
    expect(
      email.matchExp(Expression.custom('query', precedence: .primary)),
      generates('"email" MATCH query'),
    );

    // inner expressions with a lower precedence are wrapped in parens
    expect(
      email.matchExp(Expression.custom('a OR b', precedence: .or)),
      generates('"email" MATCH (a OR b)'),
    );
  });

  test('generates a highlight expression', () {
    expect(
      email.highlight(title, before: '<b>', after: '</b>'),
      generates('highlight("email",?1,?2,?3)', [1, '<b>', '</b>']),
    );
    expect(
      email.highlight(sender, before: '[', after: ']'),
      generates('highlight("email",?1,?2,?3)', [0, '[', ']']),
    );
  });

  test('generates a snippet expression', () {
    expect(
      email.snippet(
        body,
        before: '<',
        after: '>',
        ellipsis: '…',
        tokenCount: 64,
      ),
      generates('snippet("email",?1,?2,?3,?4,?5)', [2, '<', '>', '…', 64]),
    );
  });

  test('generates a bm25 expression', () {
    expect(email.bm25(), generates('bm25("email")'));
    expect(
      email.bm25(weights: [1.0, 2.5]),
      generates('bm25("email",?1,?2)', [1.0, 2.5]),
    );
  });

  test('generates the rank column', () {
    expect(email.rank, generates('"rank"'));
  });

  test('match composes with other expressions', () {
    final matcher =
        email.match('drift') |
        Expression<bool>.custom('foo', precedence: .primary);
    expect(matcher, generates('"email" MATCH ?1 OR foo', ['drift']));

    final parenthesized = email.match('drift') & Expression<bool>.custom('foo');
    // unknown precedence of the inner expression requires parens
    expect(parenthesized, generates('"email" MATCH ?1 AND (foo)', ['drift']));
  });

  group('hidden table column', () {
    test('is not qualified in single table queries', () {
      expect(email.match('x'), generates('"email" MATCH ?1', ['x']));
      expect(email.rank, generates('"rank"'));
    });

    // test('is qualified with the alias in multi table queries', () {
    //   // Like the generated `createAlias`, aliases created here get fresh column
    //   // instances. Columns are matched by name, so the `title` column of the
    //   // original table resolves to the aliased `email` column with that name.
    //   final aliased = CustomVirtualTable(
    //     'email',
    //     db,
    //     'fts5(sender,title,body)',
    //     [
    //       GeneratedColumn<String>(
    //         'sender',
    //         'e',
    //         true,
    //         type: DriftSqlType.string,
    //       ),
    //       GeneratedColumn<String>(
    //         'title',
    //         'e',
    //         true,
    //         type: DriftSqlType.string,
    //       ),
    //       GeneratedColumn<String>('body', 'e', true, type: DriftSqlType.string),
    //     ],
    //     'e',
    //   );

    //   final ctx = stubContext()..hasMultipleTables = true;
    //   aliased.match('x').writeInto(ctx);
    //   expect(ctx.sql, '"e"."email" MATCH ?');
    //   expect(ctx.boundVariables, ['x']);

    //   final highlightContext = stubContext()..hasMultipleTables = true;
    //   aliased
    //       .highlight(title, before: '<', after: '>')
    //       .writeInto(highlightContext);
    //   expect(highlightContext.sql, 'highlight("e"."email", ?, ?, ?)');
    //   expect(highlightContext.boundVariables, [1, '<', '>']);

    //   final rankContext = stubContext()..hasMultipleTables = true;
    //   aliased.rank.writeInto(rankContext);
    //   expect(rankContext.sql, '"e"."rank"');
    // });
  });

  test('implements equality', () {
    expectEquals(email.match('x'), email.match('x'));
    expectNotEquals(email.match('x'), email.match('y'));
    // `matchExp` with the same query is expected to be equal to `match`
    expectEquals(email.match('x'), email.matchExp(Variable.withString('x')));

    expectEquals(
      email.highlight(title, before: '<', after: '>'),
      email.highlight(title, before: '<', after: '>'),
    );
    expectNotEquals(
      email.highlight(title, before: '<', after: '>'),
      email.snippet(
        title,
        before: '<',
        after: '>',
        ellipsis: '…',
        tokenCount: 64,
      ),
    );

    expectEquals(email.bm25(), email.bm25());
    // note that [FunctionCallExpression.hashCode] only considers the function
    // name, so two unequal function calls may have the same hash code.
    expect(email.bm25(), isNot(equals(email.bm25(weights: [2.0]))));

    expectEquals(email.rank, email.rank);
  });
}
