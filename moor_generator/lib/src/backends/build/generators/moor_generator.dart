import 'package:build/build.dart';
import 'package:moor_generator/src/backends/build/moor_builder.dart';
import 'package:moor_generator/writer.dart';
import 'package:source_gen/source_gen.dart';

const _ignoredLints = [
  'unnecessary_brace_in_string_interps',
  'unnecessary_this',
  // more style rules from the Flutter repo we're violating. Should we fix
  // those?
  /*
  'always_specify_types',
  'implicit_dynamic_parameter',
  'sort_constructors_first',
  'lines_longer_than_80_chars',*/
];

const _targetMajorVersion = 2;
const _targetMinorVersion = 6;

class MoorGenerator extends Generator implements BaseGenerator {
  @override
  MoorBuilder builder;

  @override
  Future<String> generate(LibraryReader library, BuildStep buildStep) async {
    final parsed = await builder.analyzeDartFile(buildStep);
    final writer = builder.createWriter();

    if (parsed.declaredDatabases.isNotEmpty) {
      final ignore = '// ignore_for_file: ${_ignoredLints.join(', ')}\n';
      writer.leaf().write(ignore);
    }

    for (final db in parsed.declaredDatabases) {
      DatabaseWriter(db, writer.child()).write();
    }

    if (parsed.declaredDatabases.isNotEmpty) {
      // Warn if the project uses an SDK version that is incompatible with what
      // moor generates.
      final major = library.element.languageVersionMajor;
      final minor = library.element.languageVersionMinor;

      const expected = '$_targetMajorVersion.$_targetMinorVersion';

      if (major < _targetMajorVersion ||
          (major == _targetMajorVersion && minor < _targetMinorVersion)) {
        log.warning('The language version of this file is Dart $major.$minor. '
            'Moor generates code for Dart $expected or later. Please consider '
            'raising the minimum SDK version in your pubspec.yaml to at least '
            '$expected.0.');
      }
    }

    return writer.writeGenerated();
  }
}
