import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:drift_dev/src/utils/entity_reference_sorter.dart';
import 'package:test/test.dart';

void main() {
  DriftTable table(String name) {
    final uri = Uri.parse('drift:hidden');

    return DriftTable(
      DriftElementReference(DriftElementId(uri, name)),
      DriftDeclaration(uri, -1, name),
      columns: const [],
      baseDartName: name,
      nameOfRowClass: name,
      references: [], // needs to be mutable
    );
  }

  test('can handle cyclic reference', () {
    final first = table('a');
    final second = table('b');
    first.references.add(second);
    second.references.add(first);

    expect([first, second].sortByReferences(), hasLength(2));
  });

  test('can handle reference to cycle', () {
    final a = table('a');
    final b = table('b');
    final c = table('c');
    final d = table('d');

    a.references.add(b);
    b.references.add(c);
    c.references.add(d);
    d.references.add(b);

    final [...cycle, last] = [a, b, c, d].sortByReferences();
    expect(last, a);
    expect(cycle.toSet(), {b, c, d});
  });

  test('sorts tables topologically when no cycles exist', () {
    final a = table('a');
    final b = table('b');
    final c = table('c');
    final d = table('d');

    a.references.add(b);
    b.references.add(c);

    expect([a, b, c, d].sortByReferences(), [c, b, a, d]);
  });

  test('allows self-references', () {
    final a = table('a');
    final b = table('b');

    a.references
      ..add(a)
      ..add(b);

    expect([a, b].sortByReferences(), [b, a]);
  });
}

TypeMatcher<CircularReferenceException> isCircularReferenceException(
  List<DriftElement> path,
) {
  return isA<CircularReferenceException>().having(
    (e) => e.affected,
    'affected',
    path,
  );
}
