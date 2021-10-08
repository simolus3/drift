//@dart=2.9
import 'dart:io';

import 'package:build_config/build_config.dart';
import 'package:drift_dev/src/analyzer/options.dart';
import 'package:drift_dev/src/utils/options_reader.dart';
import 'package:path/path.dart' as p;
import 'package:stream_transform/stream_transform.dart';

/// A project using moor. This is typically a dart project with a dependency on
/// moor and moor_generator.
class MoorProject {
  /// The build configuration for this project.
  final BuildConfig buildConfig;
  final MoorOptions moorOptions;

  final Directory directory;

  MoorProject(this.buildConfig, this.directory)
      : moorOptions = readOptionsFromConfig(buildConfig);

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

  static Future<MoorProject> readFromDir(Directory directory) async {
    final config = await BuildConfig.fromPackageDir(directory.path);

    return MoorProject(config, directory);
  }
}
