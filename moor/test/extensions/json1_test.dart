import 'package:moor/moor.dart';
import 'package:moor/extensions/json1.dart';
import 'package:test/test.dart';

import '../data/utils/expect_generated.dart';

void main() {
  test('json1 functions generate valid sql', () {
    final column = GeneratedTextColumn('col', 'tbl', false);

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
