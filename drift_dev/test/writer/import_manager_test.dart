import 'package:build/build.dart';
import 'package:drift_dev/src/analysis/options.dart';
import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:drift_dev/src/writer/import_manager.dart';
import 'package:drift_dev/src/writer/writer.dart';
import 'package:test/test.dart';

void main() {
  group('LibraryInputManager', () {
    final sourceUri = AssetId('a', 'example/main.dart').uri;

    late LibraryInputManager imports;
    late Writer writer;

    setUp(() {
      imports = LibraryInputManager(sourceUri);
      final generationOptions =
          GenerationOptions(imports: imports, isModular: true);
      writer = Writer(const DriftOptions.defaults(),
          generationOptions: generationOptions);
      imports.linkToWriter(writer);
    });

    test('does not generate prefix for dart:core', () {
      expect(imports.prefixFor(Uri.parse('dart:core'), 'String'), isNull);
    });

    test('writes imports', () {
      expect(imports.prefixFor(AnnotatedDartCode.dartAsync, 'Future'), 'i0');
      expect(imports.prefixFor(AnnotatedDartCode.drift, 'GeneratedDatabase'),
          'i1');
      expect(imports.prefixFor(AnnotatedDartCode.dartAsync, 'Stream'), 'i0');

      expect(writer.writeGenerated(), '''
import 'dart:async' as i0;
import 'package:drift/drift.dart' as i1;
''');
    });

    test('can write imports for files outside of lib', () {
      final uri = AssetId('a', 'example/imported.dart').uri;
      expect(imports.prefixFor(uri, 'Test'), 'i0');

      expect(
          writer.writeGenerated(), contains("import 'imported.dart' as i0;"));
    });
  });
}
