import 'package:drift_dev/api/migrations_common.dart';
import 'package:drift_dev/src/services/schema/find_differences.dart';
import 'package:test/test.dart';

void main() {
  group('compares individual', () {
    group('tables', () {
      test('with rowid mismatch', () {
        final result = compare(
          Input('a', 'CREATE TABLE a (id INTEGER) WITHOUT ROWID;'),
          Input('a', 'CREATE TABLE a (id INTEGER);'),
        );

        expect(result, hasChanges);
        expect(
          result.describe(),
          contains('Expected the table to have a WITHOUT ROWID clause'),
        );
      });

      test('with too few columns', () {
        final result = compare(
          Input('a', 'CREATE TABLE a (id INTEGER, b TEXT);'),
          Input('a', 'CREATE TABLE a (id INTEGER);'),
        );

        expect(result, hasChanges);
        expect(
          result.describe(),
          contains('The actual schema does not contain'),
        );
      });

      test('with too many columns', () {
        final result = compare(
          Input('a', 'CREATE TABLE a (id INTEGER);'),
          Input('a', 'CREATE TABLE a (id INTEGER, b TEXT);'),
        );

        expect(result, hasChanges);
        expect(
          result.describe(),
          contains('Contains the following unexpected entries: b'),
        );
      });

      test('that are equal', () {
        final result = compare(
          Input('a', 'CREATE TABLE a (b TEXT, id INTEGER PRIMARY KEY);'),
          Input('a', 'CREATE TABLE a (id INTEGER PRIMARY KEY, b TEXT);'),
        );

        expect(result, hasNoChanges);
      });

      test('with different lexemes for the same column type', () {
        final result = compare(
          Input('a', 'CREATE TABLE a (id TEXT);'),
          Input('a', 'CREATE TABLE a (id VARCHAR(42));'),
        );

        expect(result, hasNoChanges);
      });

      test('with mismatching column types', () {
        final result = compare(
          Input('a', 'CREATE TABLE a (id TEXT);'),
          Input('a', 'CREATE TABLE a (id INTEGER);'),
        );

        expect(result, hasChanges);
        expect(
          result.describe(),
          contains('Different types: Expected TEXT, got INTEGER'),
        );
      });

      test('with different column constraints', () {
        final result = compare(
          Input('a', 'CREATE TABLE a (id INTEGER PRIMARY KEY NOT NULL);'),
          Input('a', 'CREATE TABLE a (id INTEGER);'),
        );

        expect(result, hasChanges);
        expect(
          result.describe(),
          contains(
            'Not equal: `PRIMARY KEY NOT NULL` (expected) and `` (actual)',
          ),
        );
      });

      test('with a boolean default written as an integer', () {
        // Booleans are stored as integers in SQLite, so a `DEFAULT TRUE`
        // written by an older drift version and a `DEFAULT (1)` emitted by a
        // newer one describe the same column.
        // https://github.com/simolus3/drift/issues/3738
        final result = compare(
          Input('a', 'CREATE TABLE a (b INTEGER NOT NULL DEFAULT TRUE);'),
          Input('a', 'CREATE TABLE a (b INTEGER NOT NULL DEFAULT (1));'),
        );

        expect(result, hasNoChanges);
      });

      test('with a boolean default and a check (as reported in #3738)', () {
        final result = compare(
          Input(
            'a',
            'CREATE TABLE a (is_first_login INTEGER NOT NULL DEFAULT TRUE '
                'CHECK (is_first_login IN (0, 1)));',
          ),
          Input(
            'a',
            'CREATE TABLE a (is_first_login INTEGER NOT NULL DEFAULT (1) '
                'CHECK ("is_first_login" IN (0, 1)));',
          ),
        );

        expect(result, hasNoChanges);
      });

      test('with a genuinely different default', () {
        final result = compare(
          Input('a', 'CREATE TABLE a (b INTEGER NOT NULL DEFAULT TRUE);'),
          Input('a', 'CREATE TABLE a (b INTEGER NOT NULL DEFAULT (0));'),
        );

        expect(result, hasChanges);
      });

      test('with a boolean default under a different constraint name', () {
        // The default values are equivalent, but a named constraint differs,
        // so this is a real schema difference and must still be reported.
        final result = compare(
          Input(
            'a',
            'CREATE TABLE a (b INTEGER NOT NULL CONSTRAINT x DEFAULT TRUE);',
          ),
          Input(
            'a',
            'CREATE TABLE a (b INTEGER NOT NULL CONSTRAINT y DEFAULT (1));',
          ),
        );

        expect(result, hasChanges);
      });

      test('ignored column constraints diff', () {
        final result = compare(
          Input('a', 'CREATE TABLE a (id INTEGER PRIMARY KEY NOT NULL);'),
          Input('a', 'CREATE TABLE a (id INTEGER);'),
          options: const ValidationOptions(validateColumnConstraints: false),
        );

        expect(result, hasNoChanges);
      });
    });

    test('of different type', () {
      final result = compare(
        Input('a', 'CREATE TABLE a (id INTEGER);'),
        Input('a', 'CREATE INDEX a ON b (c, d);'),
      );

      expect(result, hasChanges);
      expect(result.describe(), contains('Expected a table, but got a index.'));
    });
  });
}

CompareResult compare(
  Input a,
  Input b, {
  ValidationOptions options = const ValidationOptions(),
}) {
  return FindSchemaDifferences([a], [b], options).compare();
}

Matcher hasChanges = _matchChanges(false);
Matcher hasNoChanges = _matchChanges(true);

Matcher _matchChanges(bool expectNoChanges) {
  return isA<CompareResult>().having(
    (e) => e.noChanges,
    'noChanges',
    expectNoChanges,
  );
}
