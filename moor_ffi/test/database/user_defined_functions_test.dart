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
}
