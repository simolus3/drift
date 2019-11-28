import 'dart:convert';

import 'package:moor/moor.dart';
import 'package:moor/extensions/json1.dart';
import 'package:moor_ffi/moor_ffi.dart';
import 'package:test/test.dart';

import '../data/tables/todos.dart';
import '../data/utils/expect_generated.dart';

void main() {
  test('json1 functions generate valid sql', () {
    final column = GeneratedTextColumn('col', 'tbl', false);

    column.jsonArrayLength().expectGenerates('json_array_length(col)');
    column
        .jsonArrayLength(r'$.c')
        .expectGenerates('json_array_length(col, ?)', [r'$.c']);

    column
        .jsonExtract(r'$.c')
        .expectGenerates('json_extract(col, ?)', [r'$.c']);
  });

  test('json1 integration test', () async {
    final db = TodoDb(VmDatabase.memory());
    const jsonObject = {
      'foo': 'bar',
      'array': [
        'one',
        'two',
        'three',
      ],
    };
    await db
        .into(db.pureDefaults)
        .insert(PureDefaultsCompanion(txt: Value(json.encode(jsonObject))));

    final arrayLengthExpr = db.pureDefaults.txt.jsonArrayLength(r'$.array');
    final query = db.select(db.pureDefaults).addColumns([arrayLengthExpr]);
    query.where(db.pureDefaults.txt
        .jsonExtract(r'$.foo')
        .equalsExp(Variable.withString('bar')));

    final resultRow = await query.getSingle();
    expect(resultRow.read(arrayLengthExpr), 3);
  });
}
