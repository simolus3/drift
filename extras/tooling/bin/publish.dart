import 'package:file/file.dart';
import 'package:simons_pub_uploader/upload.dart';

const packageNames = [
  'moor',
  'moor_flutter',
  'moor_generator',
  'sqlparser',
];

/// Publishes moor, moor_flutter, moor_generator and sqlparser to my pub
/// server, simonbinder.eu.
Future<void> main() async {
  final packages = [
    for (final pkg in packageNames)
      Package(
        pkg,
        trasformer: _transformPubspec,
        listPackageFiles:
            _findFiles(pkg, includeBuildConfig: pkg == 'moor_generator'),
      ),
  ];

  await uploadPackages(packages);
}

Map<String, dynamic> _transformPubspec(Map<String, dynamic> original) {
  const copyFields = ['name', 'version', 'environment'];
  final originalDependencies = original['dependencies'] as Map;

  return {
    for (final keyToCopy in copyFields)
      if (original.containsKey(keyToCopy)) keyToCopy: original[keyToCopy],
    // Transform dependencies: Rewrite dependencies to a moor a package so that
    // they point to the custom pub server.
    'dependencies': {
      for (final dependencyName in originalDependencies.keys)
        if (packageNames.contains(dependencyName))
          dependencyName: {
            'hosted': {
              'url': 'https://simonbinder.eu',
              'name': dependencyName,
            },
            'version': originalDependencies[dependencyName]
          }
        else
          dependencyName: originalDependencies[dependencyName],
    },
  };
}

Stream<FileSystemEntity> Function(FileSystem) _findFiles(String packageName,
    {bool includeBuildConfig = false}) {
  return (FileSystem fs) async* {
    final pkg = fs.directory(packageName);

    yield* pkg.childDirectory('lib').list(recursive: true);
    if (includeBuildConfig) {
      yield pkg.childFile('build.yaml');
    }
  };
}
