@Tags(['integration'])
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/extensions/json1.dart';
import 'package:test/test.dart';

import '../generated/todos.dart';
import '../test_utils/test_utils.dart';

void main() {
  test('json1 integration test', () async {
    final db = TodoDb(testInMemoryDatabase());
    const jsonObject = {
      'foo': 'bar',
      'array': [
        'one',
        'two',
        'three',
      ],
    };
    await db.into(db.pureDefaults).insert(PureDefaultsCompanion(
        txt: Value(MyCustomObject(json.encode(jsonObject)))));

    final arrayLengthExpr = db.pureDefaults.txt.jsonArrayLength(r'$.array');
    final query = db.select(db.pureDefaults).addColumns([arrayLengthExpr]);
    query.where(db.pureDefaults.txt
        .jsonExtract(r'$.foo')
        .equalsExp(Variable.withString('bar')));

    final resultRow = await query.getSingle();
    expect(resultRow.read(arrayLengthExpr), 3);
  }, tags: const ['integration']);
}
