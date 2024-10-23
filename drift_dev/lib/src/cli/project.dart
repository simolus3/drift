import 'dart:io';

import 'package:build_config/build_config.dart';
import 'package:dart_style/dart_style.dart';
import 'package:drift_dev/src/analysis/options.dart';
import 'package:drift_dev/src/utils/dartfmt.dart';
import 'package:drift_dev/src/utils/options_reader.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:stream_transform/stream_transform.dart';

/// A project using drift. This is typically a dart project with a dependency on
/// drift and drift_dev.
class DriftProject {
  /// The build configuration for this project.
  final BuildConfig buildConfig;
  final DriftOptions options;

  final Directory directory;
  Version? _languageVersion;

  DriftProject(this.buildConfig, this.directory)
      : options = readOptionsFromConfig(buildConfig);

  Stream<File> get sourceFiles {
    const topLevelDirs = {'lib', 'test', 'bin', 'example', 'web'};

    return directory.list().asyncExpand((entity) {
      // report all top-level files and all (recursive) content in topLevelDirs
      if (entity is File) {
        return Stream.value(entity);
      } else if (entity is Directory) {
        if (topLevelDirs.contains(p.basename(entity.path))) {
          return entity.list(recursive: true);
        }
      }
      return const Stream.empty();
    }).whereType();
  }

  Future<Version> inferLanguageVersion() async {
    if (_languageVersion != null) {
      return _languageVersion!;
    }

    final config = await findPackageConfig(directory);
    if (config == null) {
      return _languageVersion = DartFormatter.latestLanguageVersion;
    }

    final package = config.packageOf(Uri.file(p.join(directory.path, 'lib')));
    return _languageVersion = package?.languageVersion?.asPubSemver ??
        DartFormatter.latestLanguageVersion;
  }

  Future<String> formatSource(String source) async {
    final version = await inferLanguageVersion();
    return formatDartCode(source, version);
  }

  static Future<DriftProject> readFromDir(Directory directory) async {
    final config = await BuildConfig.fromPackageDir(directory.path);

    return DriftProject(config, directory);
  }
}
