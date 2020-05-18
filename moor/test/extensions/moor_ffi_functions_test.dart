@TestOn('vm')
import 'package:moor/extensions/moor_ffi.dart';
import 'package:moor/src/runtime/query_builder/query_builder.dart';
import 'package:moor_ffi/moor_ffi.dart';
import 'package:test/test.dart';

import '../data/tables/todos.dart';
import '../data/utils/expect_generated.dart';

void main() {
  final a = GeneratedRealColumn('a', null, false);
  final b = GeneratedRealColumn('b', null, false);

  test('pow', () {
    expect(sqlPow(a, b), generates('pow(a, b)'));
  });

  test('sqrt', () => expect(sqlSqrt(a), generates('sqrt(a)')));
  test('sin', () => expect(sqlSin(a), generates('sin(a)')));
  test('cos', () => expect(sqlCos(a), generates('cos(a)')));
  test('tan', () => expect(sqlTan(a), generates('tan(a)')));
  test('asin', () => expect(sqlAsin(a), generates('asin(a)')));
  test('acos', () => expect(sqlAcos(a), generates('acos(a)')));
  test('atan', () => expect(sqlAtan(a), generates('atan(a)')));

  test('containsCase', () {
    final c = GeneratedTextColumn('a', null, false);

    expect(c.containsCase('foo'), generates('moor_contains(a, ?, 0)', ['foo']));
    expect(
      c.containsCase('foo', caseSensitive: true),
      generates('moor_contains(a, ?, 1)', ['foo']),
    );
  });

  test('containsCase integration test', () async {
    final db = TodoDb(VmDatabase.memory());
    // insert exactly one row so that we can evaluate expressions from Dart
    await db.into(db.pureDefaults).insert(PureDefaultsCompanion.insert());

    Future<bool> evaluate(Expression<bool> expr) async {
      final result = await (db.selectOnly(db.pureDefaults)..addColumns([expr]))
          .getSingle();

      return result.read(expr);
    }

    expect(
      evaluate(const Variable('Häuser').containsCase('Ä')),
      completion(isTrue),
    );

    expect(
      evaluate(const Variable('Dart is cool')
          .containsCase('dart', caseSensitive: false)),
      completion(isTrue),
    );
  });
}
