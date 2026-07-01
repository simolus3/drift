import 'package:drift_sqlite/schema_verifier.dart';
import 'package:drift_sqlite/src/schema_verifier/find_differences.dart';
import 'package:test/test.dart';

void main() {
  group('compares individual', () {
    group('tables', () {
      test('with rowid mismatch', () {
        final result = compare(
          SyntacticSchemaElement(
            name: 'a',
            create: 'CREATE TABLE a (id INTEGER) WITHOUT ROWID;',
          ),
          SyntacticSchemaElement(
            name: 'a',
            create: 'CREATE TABLE a (id INTEGER);',
          ),
        );

        expect(result, hasChanges);
        expect(
          result.describe(),
          contains('Expected the table to have a WITHOUT ROWID clause'),
        );
      });

      test('with too few columns', () {
        final result = compare(
          SyntacticSchemaElement(
            name: 'a',
            create: 'CREATE TABLE a (id INTEGER, b TEXT);',
          ),
          SyntacticSchemaElement(
            name: 'a',
            create: 'CREATE TABLE a (id INTEGER);',
          ),
        );

        expect(result, hasChanges);
        expect(
          result.describe(),
          contains('The actual schema does not contain'),
        );
      });

      test('with too many columns', () {
        final result = compare(
          SyntacticSchemaElement(
            name: 'a',
            create: 'CREATE TABLE a (id INTEGER);',
          ),
          SyntacticSchemaElement(
            name: 'a',
            create: 'CREATE TABLE a (id INTEGER, b TEXT);',
          ),
        );

        expect(result, hasChanges);
        expect(
          result.describe(),
          contains('Contains the following unexpected entries: b'),
        );
      });

      test('that are equal', () {
        final result = compare(
          SyntacticSchemaElement(
            name: 'a',
            create: 'CREATE TABLE a (b TEXT, id INTEGER PRIMARY KEY);',
          ),
          SyntacticSchemaElement(
            name: 'a',
            create: 'CREATE TABLE a (id INTEGER PRIMARY KEY, b TEXT);',
          ),
        );

        expect(result, hasNoChanges);
      });

      test('with different lexemes for the same column type', () {
        final result = compare(
          SyntacticSchemaElement(
            name: 'a',
            create: 'CREATE TABLE a (id TEXT);',
          ),
          SyntacticSchemaElement(
            name: 'a',
            create: 'CREATE TABLE a (id VARCHAR(42));',
          ),
        );

        expect(result, hasNoChanges);
      });

      test('with mismatching column types', () {
        final result = compare(
          SyntacticSchemaElement(
            name: 'a',
            create: 'CREATE TABLE a (id TEXT);',
          ),
          SyntacticSchemaElement(
            name: 'a',
            create: 'CREATE TABLE a (id INTEGER);',
          ),
        );

        expect(result, hasChanges);
        expect(
          result.describe(),
          contains('Different types: Expected TEXT, got INTEGER'),
        );
      });

      test('with different column constraints', () {
        final result = compare(
          SyntacticSchemaElement(
            name: 'a',
            create: 'CREATE TABLE a (id INTEGER PRIMARY KEY NOT NULL);',
          ),
          SyntacticSchemaElement(
            name: 'a',
            create: 'CREATE TABLE a (id INTEGER);',
          ),
        );

        expect(result, hasChanges);
        expect(
          result.describe(),
          contains(
            'Not equal: `PRIMARY KEY NOT NULL` (expected) and `` (actual)',
          ),
        );
      });

      test('ignored column constraints diff', () {
        final result = compare(
          SyntacticSchemaElement(
            name: 'a',
            create: 'CREATE TABLE a (id INTEGER PRIMARY KEY NOT NULL);',
          ),
          SyntacticSchemaElement(
            name: 'a',
            create: 'CREATE TABLE a (id INTEGER);',
          ),
          options: const ValidationOptions(validateColumnConstraints: false),
        );

        expect(result, hasNoChanges);
      });
    });

    test('of different type', () {
      final result = compare(
        SyntacticSchemaElement(
          name: 'a',
          create: 'CREATE TABLE a (id INTEGER);',
        ),
        SyntacticSchemaElement(
          name: 'a',
          create: 'CREATE INDEX a ON b (c, d);',
        ),
      );

      expect(result, hasChanges);
      expect(result.describe(), contains('Expected a table, but got a index.'));
    });
  });
}

CompareResult compare(
  SyntacticSchemaElement expected,
  SyntacticSchemaElement actual, {
  ValidationOptions options = const ValidationOptions(),
}) {
  return SyntacticSchema([
    actual,
  ]).compareTo(expected: SyntacticSchema([expected]), options: options);
}

Matcher hasChanges = _matchChanges(false);
Matcher hasNoChanges = _matchChanges(true);

Matcher _matchChanges(bool expectNoChanges) {
  return isA<CompareResult>().having(
    (e) => e.areEqual,
    'noChanges',
    expectNoChanges,
  );
}
