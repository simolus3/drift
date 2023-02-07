import 'package:charcode/ascii.dart';
import 'package:drift_dev/src/analysis/options.dart';
import 'package:drift_dev/src/writer/import_manager.dart';
import 'package:drift_dev/src/writer/utils/hash_and_equals.dart';
import 'package:drift_dev/src/writer/writer.dart';
import 'package:test/test.dart';

void main() {
  late Writer writer;

  setUp(() {
    final imports = LibraryInputManager(Uri.parse('drift:test'));
    final generationOptions =
        GenerationOptions(imports: imports, isModular: true);
    writer = Writer(const DriftOptions.defaults(),
        generationOptions: generationOptions);
    imports.linkToWriter(writer);
  });

  test('hash code for no fields', () {
    writeHashCode([], writer.leaf());
    expect(writer.writeGenerated(), r'identityHashCode(this)');
  });

  test('hash code for a single field - not a list', () {
    writeHashCode([EqualityField('a')], writer.leaf());
    expect(writer.writeGenerated(), r'a.hashCode');
  });

  test('hash code for a single field - list', () {
    writeHashCode([EqualityField('a', isList: true)], writer.leaf());
    expect(writer.writeGenerated(), contains(r'i0.$driftBlobEquality.hash(a)'));
  });

  test('hash code for multiple fields', () {
    writeHashCode([
      EqualityField('a'),
      EqualityField('b', isList: true),
      EqualityField('c'),
    ], writer.leaf());
    expect(writer.writeGenerated(),
        contains(r'Object.hash(a, i0.$driftBlobEquality.hash(b), c)'));
  });

  test('hash code for lots of fields', () {
    writeHashCode(
        List.generate(
            26, (index) => EqualityField(String.fromCharCode($a + index))),
        writer.leaf());
    expect(
      writer.writeGenerated(),
      r'Object.hashAll([a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, '
      's, t, u, v, w, x, y, z])',
    );
  });
}
