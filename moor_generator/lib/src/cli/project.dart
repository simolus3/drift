import 'dart:io';

import 'package:build_config/build_config.dart';
import 'package:moor_generator/src/analyzer/options.dart';
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
      : moorOptions = _readOptions(buildConfig);

  Stream<File> get sourceFiles {
    const topLevelDirs = {'lib', 'test', 'bin', 'example'};

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

  static MoorOptions _readOptions(BuildConfig config) {
    final options = config.buildTargets.values
        .map((t) => t.builders['moor_generator:moor_generator']?.options)
        .where((t) => t != null)
        .map((json) => MoorOptions.fromJson(json));

    final iterator = options.iterator;
    return iterator.moveNext() ? iterator.current : const MoorOptions();
  }

  static Future<MoorProject> readFromDir(Directory directory) async {
    final config = await BuildConfig.fromPackageDir(directory.path);

    return MoorProject(config, directory);
  }
}
