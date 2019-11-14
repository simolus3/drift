import 'package:moor_ffi/database.dart';
import 'package:test/test.dart';

void main() {
  test('select statements return expected value', () {
    final opened = Database.memory();

    final prepared = opened.prepare('SELECT ?');

    final result1 = prepared.select([1]);
    expect(result1.columnNames, ['?']);
    expect(result1.single.columnAt(0), 1);

    final result2 = prepared.select([2]);
    expect(result2.columnNames, ['?']);
    expect(result2.single.columnAt(0), 2);

    opened.close();
  });
}
