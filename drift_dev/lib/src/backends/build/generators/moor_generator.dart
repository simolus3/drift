import 'package:build/build.dart';
import 'package:drift_dev/src/backends/build/moor_builder.dart';
import 'package:drift_dev/writer.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:source_gen/source_gen.dart';

final _minLanguageVersion = Version(2, 12, 0);

class MoorGenerator extends Generator implements BaseGenerator {
  @override
  late MoorBuilder builder;

  @override
  Future<String> generate(LibraryReader library, BuildStep buildStep) async {
    final parsed = await builder.analyzeDartFile(buildStep);
    final writer = builder.createWriter();

    if (parsed.declaredDatabases.isNotEmpty) {
      const ignore = '// ignore_for_file: type=lint';
      writer.leaf().writeln(ignore);
    }

    for (final db in parsed.declaredDatabases) {
      DatabaseWriter(db, writer.child()).write();
    }

    if (parsed.declaredDatabases.isNotEmpty) {
      // Warn if the project uses an SDK version that is incompatible with what
      // drift generates.
      final version = library.element.languageVersion.effective;
      final major = version.major;
      final minor = version.minor;

      if (version < _minLanguageVersion) {
        log.warning(
          'The language version of this file is Dart $major.$minor. '
          'Drift generates code for Dart $_minLanguageVersion or later. Please '
          'consider raising the minimum SDK version in your pubspec.yaml to at '
          'least $_minLanguageVersion.',
        );
      }
    }

    return writer.writeGenerated();
  }
}
