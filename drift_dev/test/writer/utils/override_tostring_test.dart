import 'package:drift_dev/src/analysis/options.dart';
import 'package:drift_dev/src/writer/import_manager.dart';
import 'package:drift_dev/src/writer/utils/override_toString.dart';
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

  test('overrides toString on class with dollar sign in name', () {
    overrideToString(r'$Foo', ['a', 'b'], writer.leaf().buffer);

    expect(
        writer.writeGenerated(),
        '@override\n'
        'String toString() {'
        r"return (StringBuffer('\$Foo(')..write('a: $a, ')..write('b: $b')..write(')')).toString();"
        '}\n');
  });
}
