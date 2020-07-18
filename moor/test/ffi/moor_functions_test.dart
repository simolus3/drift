@TestOn('vm')
import 'dart:math';

import 'package:moor/src/ffi/moor_ffi_functions.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  Database db;

  setUp(() => db = sqlite3.openInMemory()..useMoorVersions());
  tearDown(() => db.dispose());

  dynamic selectSingle(String expression) {
    final stmt = db.prepare('SELECT $expression AS r;');
    final rows = stmt.select();
    stmt.dispose();

    return rows.single['r'];
  }

  group('pow', () {
    dynamic _resultOfPow(String a, String b) {
      return selectSingle('pow($a, $b)');
    }

    test('returns null when any argument is null', () {
      expect(_resultOfPow('null', 'null'), isNull);
      expect(_resultOfPow('3', 'null'), isNull);
      expect(_resultOfPow('null', '3'), isNull);
    });

    test('returns correct results', () {
      expect(_resultOfPow('10', '0'), 1);
      expect(_resultOfPow('0', '10'), 0);
      expect(_resultOfPow('0', '0'), 1);
      expect(_resultOfPow('2', '5'), 32);
      expect(_resultOfPow('3.5', '2'), 12.25);
      expect(_resultOfPow('10', '-1'), 0.1);
    });
  });

  for (final scenario in _testCases) {
    final function = scenario.sqlFunction;

    test(function, () {
      final stmt = db.prepare('SELECT $function(?) AS r');

      for (final input in scenario.inputs) {
        final sqlResult = stmt.select([input]).single['r'];
        final dartResult = scenario.dartEquivalent(input);

        // NaN in sqlite is null, account for that
        if (dartResult.isNaN) {
          expect(
            sqlResult,
            null,
            reason: '$function($input) = $dartResult',
          );
        } else {
          expect(
            sqlResult,
            equals(dartResult),
            reason: '$function($input) = $dartResult',
          );
        }
      }

      final resultWithNull = stmt.select([null]);
      expect(resultWithNull.single['r'], isNull);
    });
  }

  group('regexp', () {
    test('cannot be called with more or fewer than 2 parameters', () {
      expect(() => db.execute("SELECT regexp('foo')"),
          throwsA(isA<SqliteException>()));

      expect(() => db.execute("SELECT regexp('foo', 'bar', 'baz')"),
          throwsA(isA<SqliteException>()));
    });

    test('results in error when not passing a string', () {
      final complainsAboutTypes = throwsA(isA<SqliteException>().having(
        (e) => e.message,
        'message',
        contains('Expected two strings as parameters to regexp'),
      ));

      expect(() => db.execute("SELECT 'foo' REGEXP 3"), complainsAboutTypes);
      expect(() => db.execute("SELECT 3 REGEXP 'foo'"), complainsAboutTypes);
    });

    test('fails on invalid regex', () {
      expect(
        () => db.execute("SELECT 'foo' REGEXP '('"),
        throwsA(isA<SqliteException>()
            .having((e) => e.message, 'message', contains('Invalid regex'))),
      );
    });

    test('returns true on a match', () {
      final stmt = db.prepare("SELECT 'foo' REGEXP 'fo+' AS r");
      final result = stmt.select();
      expect(result.single['r'], 1);
    });

    test("returns false when the regex doesn't match", () {
      final stmt = db.prepare("SELECT 'bar' REGEXP 'fo+' AS r");
      final result = stmt.select();
      expect(result.single['r'], 0);
    });

    test('supports flags', () {
      final stmt =
          db.prepare(r"SELECT regexp_moor_ffi('^bar', 'foo\nbar', 8) AS r;");
      final result = stmt.select();
      expect(result.single['r'], 0);
    });

    test('returns null when either argument is null', () {
      final stmt = db.prepare('SELECT ? REGEXP ?');

      expect(stmt.select(['foo', null]).single.columnAt(0), isNull);
      expect(stmt.select([null, 'foo']).single.columnAt(0), isNull);

      stmt.dispose();
    });
  });

  group('moor_contains', () {
    test('checks for type errors', () {
      expect(() => db.execute('SELECT moor_contains(12, 1);'),
          throwsA(isA<SqliteException>()));
    });

    test('case insensitive without parameter', () {
      expect(selectSingle("moor_contains('foo', 'O')"), 1);
    });

    test('case insensitive with parameter', () {
      expect(selectSingle("moor_contains('foo', 'O', 0)"), 1);
    });

    test('case sensitive', () {
      expect(selectSingle("moor_contains('Hello', 'hell', 1)"), 0);
      expect(selectSingle("moor_contains('hi', 'i', 1)"), 1);
    });
  });
}

// utils to verify the sql functions behave exactly like the ones from the VM

class _UnaryFunctionTestCase {
  final String sqlFunction;
  final num Function(num) dartEquivalent;
  final List<num> inputs;

  const _UnaryFunctionTestCase(
      this.sqlFunction, this.dartEquivalent, this.inputs);
}

const _unaryInputs = [
  pi,
  0,
  pi / 2,
  e,
  123,
];

const _testCases = <_UnaryFunctionTestCase>[
  _UnaryFunctionTestCase('sin', sin, _unaryInputs),
  _UnaryFunctionTestCase('cos', cos, _unaryInputs),
  _UnaryFunctionTestCase('tan', tan, _unaryInputs),
  _UnaryFunctionTestCase('sqrt', sqrt, _unaryInputs),
  _UnaryFunctionTestCase('asin', asin, _unaryInputs),
  _UnaryFunctionTestCase('acos', acos, _unaryInputs),
  _UnaryFunctionTestCase('atan', atan, _unaryInputs),
];
