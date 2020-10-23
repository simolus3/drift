import 'package:moor_generator/src/services/schema/find_differences.dart';
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
          contains('Different types: TEXT and INTEGER'),
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
          contains('Not equal: `PRIMARY KEY NOT NULL` and ``'),
        );
      });
    });

    test('of different type', () {
      final result = compare(
        Input('a', 'CREATE TABLE a (id INTEGER);'),
        Input('a', 'CREATE INDEX a ON b (c, d);'),
      );

      expect(result, hasChanges);
      expect(
        result.describe(),
        contains('Expected a table, but got a index.'),
      );
    });
  });
}

CompareResult compare(Input a, Input b) {
  return FindSchemaDifferences([a], [b], false).compare();
}

Matcher hasChanges = _matchChanges(false);
Matcher hasNoChanges = _matchChanges(true);

Matcher _matchChanges(bool expectNoChanges) {
  return isA<CompareResult>()
      .having((e) => e.noChanges, 'noChanges', expectNoChanges);
}
