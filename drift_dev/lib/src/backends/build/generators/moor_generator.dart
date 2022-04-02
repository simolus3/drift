import 'package:build/build.dart';
import 'package:drift_dev/src/backends/build/moor_builder.dart';
import 'package:drift_dev/writer.dart';
import 'package:source_gen/source_gen.dart';

const _targetMajorVersion = 2;
const _targetMinorVersion = 6;

class MoorGenerator extends Generator implements BaseGenerator {
  @override
  late MoorBuilder builder;

  @override
  Future<String> generate(LibraryReader library, BuildStep buildStep) async {
    final parsed = await builder.analyzeDartFile(buildStep);
    final writer =
        builder.createWriter(nnbd: library.element.isNonNullableByDefault);

    if (parsed.declaredDatabases.isNotEmpty) {
      const ignore = '// ignore_for_file: type=lint';
      writer.leaf().writeln(ignore);
    }

    for (final db in parsed.declaredDatabases) {
      DatabaseWriter(db, writer.child()).write();
    }

    if (parsed.declaredDatabases.isNotEmpty) {
      // Warn if the project uses an SDK version that is incompatible with what
      // moor generates.
      final version = library.element.languageVersion.effective;
      final major = version.major;
      final minor = version.minor;

      const expected = '$_targetMajorVersion.$_targetMinorVersion';

      if (major < _targetMajorVersion ||
          (major == _targetMajorVersion && minor < _targetMinorVersion)) {
        log.warning('The language version of this file is Dart $major.$minor. '
            'Drift generates code for Dart $expected or later. Please consider '
            'raising the minimum SDK version in your pubspec.yaml to at least '
            '$expected.0.');
      }
    }

    return writer.writeGenerated();
  }
}
