import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:drift_dev/src/utils/entity_reference_sorter.dart';
import 'package:test/test.dart';

void main() {
  DriftTable table(String name) {
    final uri = Uri.parse('drift:hidden');

    return DriftTable(
      DriftElementId(uri, name),
      DriftDeclaration(uri, -1, name),
      columns: const [],
      baseDartName: name,
      nameOfRowClass: name,
      references: [], // needs to be mutable
    );
  }

  test('throws cyclic exception when two tables reference each other', () {
    final first = table('a');
    final second = table('b');
    first.references.add(second);
    second.references.add(first);

    expect(() => [first, second].sortTopologically(),
        throwsA(isCircularReferenceException([first, second])));
  });

  test('throws cyclic exception on a circular reference with three tables', () {
    final a = table('a');
    final b = table('b');
    final c = table('c');
    final d = table('d');

    a.references.add(b);
    b.references.add(c);
    c.references.add(d);
    d.references.add(b);

    expect(() => [a, b, c, d].sortTopologically(),
        throwsA(isCircularReferenceException([b, c, d])));
  });

  test('sortOr returns original order and reports message for erro', () {
    final a = table('a');
    final b = table('b');
    final c = table('c');
    final d = table('d');

    a.references.add(b);
    b.references.add(c);
    c.references.add(d);
    d.references.add(b);

    expect(
      [a, b, c, d].sortTopologicallyOrElse(expectAsync1((message) {
        expect(message, contains('Invalid cycle from b->c->d->b'));
      })),
      [a, b, c, d],
    );
  });

  test('sorts tables topologically when no cycles exist', () {
    final a = table('a');
    final b = table('b');
    final c = table('c');
    final d = table('d');

    a.references.add(b);
    b.references.add(c);

    expect([a, b, c, d].sortTopologically(), [c, b, a, d]);
  });

  test('does not allow self-references', () {
    final a = table('a');
    final b = table('b');

    a.references
      ..add(a)
      ..add(b);

    expect(() => [a, b].sortTopologically(), throwsA(isA<AssertionError>()));
  });
}

TypeMatcher<CircularReferenceException> isCircularReferenceException(
    List<DriftElement> path) {
  return isA<CircularReferenceException>()
      .having((e) => e.affected, 'affected', path);
}
