import 'dart:math';

import 'package:moor_ffi/database.dart';
import 'package:test/test.dart';

void main() {
  Database db;

  setUp(() => db = Database.memory()..enableMathematicalFunctions());
  tearDown(() => db.close());

  group('pow', () {
    dynamic _resultOfPow(String a, String b) {
      final stmt = db.prepare('SELECT pow($a, $b) AS r;');
      final rows = stmt.select();
      stmt.close();

      return rows.single['r'];
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
