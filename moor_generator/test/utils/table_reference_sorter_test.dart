import 'package:moor_generator/src/model/specified_table.dart';
import 'package:moor_generator/src/utils/table_reference_sorter.dart';
import 'package:test/test.dart';

void main() {
  test('throws cyclic exception when two tables reference each other', () {
    final first = SpecifiedTable(sqlName: 'a');
    final second = SpecifiedTable(sqlName: 'b');
    first.references.add(second);
    second.references.add(first);

    final exception = _expectFails([first, second]);

    expect(exception.affected, [first, second]);
  });

  test('throws cyclic exception on a circular reference with three tables', () {
    final a = SpecifiedTable(sqlName: 'a');
    final b = SpecifiedTable(sqlName: 'b');
    final c = SpecifiedTable(sqlName: 'c');
    final d = SpecifiedTable(sqlName: 'd');

    a.references.add(b);
    b.references.add(c);
    c.references.add(d);
    d.references.add(b);

    final exception = _expectFails([a, b, c, d]);

    expect(exception.affected, [b, c, d]);
  });

  test('sorts tables topologically when no cycles exist', () {
    final a = SpecifiedTable(sqlName: 'a');
    final b = SpecifiedTable(sqlName: 'b');
    final c = SpecifiedTable(sqlName: 'c');
    final d = SpecifiedTable(sqlName: 'd');

    a.references.add(b);
    b.references.add(c);

    final sorted = sortTablesTopologically([a, b, c, d]);
    expect(sorted, [c, b, a, d]);
  });
}

CircularReferenceException _expectFails(Iterable<SpecifiedTable> table) {
  try {
    sortTablesTopologically(table);
    fail('Expected sortTablesTopologically to throw here');
  } on CircularReferenceException catch (e) {
    return e;
  }
}
