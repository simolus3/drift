//@dart=2.9
import 'package:moor_generator/moor_generator.dart';
import 'package:moor_generator/src/utils/entity_reference_sorter.dart';
import 'package:test/test.dart';

void main() {
  test('throws cyclic exception when two tables reference each other', () {
    final first = MoorTable(sqlName: 'a');
    final second = MoorTable(sqlName: 'b');
    first.references.add(second);
    second.references.add(first);

    final exception = _expectFails([first, second]);

    expect(exception.affected, [first, second]);
  });

  test('throws cyclic exception on a circular reference with three tables', () {
    final a = MoorTable(sqlName: 'a');
    final b = MoorTable(sqlName: 'b');
    final c = MoorTable(sqlName: 'c');
    final d = MoorTable(sqlName: 'd');

    a.references.add(b);
    b.references.add(c);
    c.references.add(d);
    d.references.add(b);

    final exception = _expectFails([a, b, c, d]);

    expect(exception.affected, [b, c, d]);
  });

  test('sorts tables topologically when no cycles exist', () {
    final a = MoorTable(sqlName: 'a');
    final b = MoorTable(sqlName: 'b');
    final c = MoorTable(sqlName: 'c');
    final d = MoorTable(sqlName: 'd');

    a.references.add(b);
    b.references.add(c);

    final sorted = sortEntitiesTopologically([a, b, c, d]);
    expect(sorted, [c, b, a, d]);
  });

  test('accepts self-references', () {
    // https://github.com/simolus3/moor/issues/586
    final a = MoorTable(sqlName: 'a');
    final b = MoorTable(sqlName: 'b');

    a.references..add(a)..add(b);

    final sorted = sortEntitiesTopologically([a, b]);
    expect(sorted, [b, a]);
  });
}

CircularReferenceException _expectFails(Iterable<MoorTable> table) {
  try {
    sortEntitiesTopologically(table);
    fail('Expected sortTablesTopologically to throw here');
  } on CircularReferenceException catch (e) {
    return e;
  }
}
