import 'dart:ffi';

import 'package:moor/moor.dart';
import 'package:moor_ffi/database.dart';
import 'package:test/test.dart';

final _params = <dynamic>[];

void _testFunImpl(Pointer<FunctionContext> ctx, int argCount,
    Pointer<Pointer<SqliteValue>> args) {
  _params.clear();
  for (var i = 0; i < argCount; i++) {
    _params.add(args[i].value);
  }

  ctx.resultNull();
}

void _testNullImpl(Pointer<FunctionContext> ctx, int argCount,
    Pointer<Pointer<SqliteValue>> args) {
  ctx.resultNull();
}

void _testIntImpl(Pointer<FunctionContext> ctx, int argCount,
    Pointer<Pointer<SqliteValue>> args) {
  ctx.resultInt(420);
}

void _testDoubleImpl(Pointer<FunctionContext> ctx, int argCount,
    Pointer<Pointer<SqliteValue>> args) {
  ctx.resultDouble(133.7);
}

void main() {
  test('can read arguments of user defined functions', () {
    final db = Database.memory();
    db.createFunction('test_fun', 6, Pointer.fromFunction(_testFunImpl));

    db.execute(
        r'''SELECT test_fun(1, 2.5, 'hello world', X'ff00ff', X'', NULL)''');
    db.close();

    expect(_params, [
      1,
      2.5,
      'hello world',
      Uint8List.fromList([255, 0, 255]),
      Uint8List(0),
      null,
    ]);
  });

  group('can return', () {
    Database db;

    setUp(() => db = Database.memory());
    tearDown(() => db.close());

    test('null', () {
      db.createFunction('test_null', 0, Pointer.fromFunction(_testNullImpl));
      final stmt = db.prepare('SELECT test_null() AS result');

      expect(stmt.select(), [
        {'result': null}
      ]);
    });

    test('integers', () {
      db.createFunction('test_int', 0, Pointer.fromFunction(_testIntImpl));
      final stmt = db.prepare('SELECT test_int() AS result');

      expect(stmt.select(), [
        {'result': 420}
      ]);
    });

    test('doubles', () {
      db.createFunction(
          'test_double', 0, Pointer.fromFunction(_testDoubleImpl));
      final stmt = db.prepare('SELECT test_double() AS result');

      expect(stmt.select(), [
        {'result': 133.7}
      ]);
    });
  });

  test('throws when using a long function name', () {
    final db = Database.memory();

    expect(
        () => db.createFunction('foo' * 100, 10, nullptr), throwsArgumentError);

    db.close();
  });

  test('throws when using an invalid argument count', () {
    final db = Database.memory();

    expect(() => db.createFunction('foo', -2, nullptr), throwsArgumentError);
    expect(() => db.createFunction('foo', 128, nullptr), throwsArgumentError);

    db.close();
  });
}
