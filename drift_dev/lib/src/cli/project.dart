import 'dart:io';

import 'package:build_config/build_config.dart';
import 'package:drift_dev/src/analysis/options.dart';
import 'package:drift_dev/src/utils/options_reader.dart';
import 'package:path/path.dart' as p;
import 'package:stream_transform/stream_transform.dart';

/// A project using moor. This is typically a dart project with a dependency on
/// moor and moor_generator.
class DriftProject {
  /// The build configuration for this project.
  final BuildConfig buildConfig;
  final DriftOptions options;

  final Directory directory;

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

  static Future<DriftProject> readFromDir(Directory directory) async {
    final config = await BuildConfig.fromPackageDir(directory.path);

    return DriftProject(config, directory);
  }
}
