import 'package:drift/drift.dart';
import 'package:drift/extensions/json1.dart';
import 'package:test/test.dart';

import '../test_utils/test_utils.dart';

void main() {
  test('json1 functions generate valid sql', () {
    const column = CustomExpression<String>('col');

    expect(column.jsonArrayLength(), generates('json_array_length(col)'));
    expect(
      column.jsonArrayLength(r'$.c'),
      generates('json_array_length(col, ?)', [r'$.c']),
    );

    expect(
      column.jsonExtract(r'$.c'),
      generates('json_extract(col, ?)', [r'$.c']),
    );
  });
}
