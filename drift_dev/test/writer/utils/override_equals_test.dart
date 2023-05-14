import 'package:drift_dev/src/analysis/options.dart';
import 'package:drift_dev/src/writer/import_manager.dart';
import 'package:drift_dev/src/writer/utils/hash_and_equals.dart';
import 'package:drift_dev/src/writer/writer.dart';
import 'package:test/test.dart';

void main() {
  late Writer writer;

  setUp(() {
    final imports = LibraryImportManager(Uri.parse('drift:test'));
    final generationOptions =
        GenerationOptions(imports: imports, isModular: true);
    writer = Writer(const DriftOptions.defaults(),
        generationOptions: generationOptions);
    imports.linkToWriter(writer);
  });

  test('overrides equals on class without fields', () {
    overrideEquals([], 'Foo', writer.leaf());

    expect(
        writer.writeGenerated(),
        '@override\nbool operator ==(Object other) => '
        'identical(this, other) || (other is Foo);\n');
  });

  test('overrides equals on class with fields', () {
    overrideEquals([
      EqualityField('a'),
      EqualityField('b', isList: true),
      EqualityField('c'),
    ], 'Foo', writer.leaf());

    expect(
      writer.writeGenerated(),
      contains(
        '@override\nbool operator ==(Object other) => '
        'identical(this, other) || (other is Foo && '
        r'other.a == this.a && i0.$driftBlobEquality.equals(other.b, this.b) && '
        'other.c == this.c);\n',
      ),
    );
  });
}
