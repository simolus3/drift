import 'dart:convert';
import 'dart:io';

import 'package:build_runner_core/build_runner_core.dart';
import 'package:build_runner_core/src/asset/build_cache.dart';
import 'package:build_runner_core/src/asset_graph/graph.dart';
import 'package:build_runner_core/src/asset_graph/node.dart';
import 'package:path/path.dart' as p;

Future<void> main() async {
  final isReleaseEnv = Platform.environment['IS_RELEASE'];
  print('Is release build: $isReleaseEnv');
  final isRelease = isReleaseEnv == 'true';

  final output = Directory('deploy');
  if (output.existsSync()) {
    output.deleteSync(recursive: true);
  }
  output.createSync();

  await Future.wait([
    _runBuildAndCopyFiles(output, isRelease),
    _createApiDocumentation(output),
  ]);
}

Future<void> _waitForProcess(Process p, String name) async {
  Future<void> forward(Stream<List<int>> source, IOSink out) {
    return source
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .forEach((line) => out.writeln('$name: $line'));
  }

  await Future.wait([
    forward(p.stdout, stdout),
    forward(p.stderr, stderr),
  ]);
  await stdout.flush();
  await stderr.flush();
}

Future<void> _runBuildAndCopyFiles(Directory output, bool isRelease) async {
  final siteEnv = isRelease ? 'prod' : 'preview';

  final buildArgs = [
    'run',
    'build_runner',
    'build',
    '--release',
    '--define=built_site=environment=$siteEnv',
    '--delete-conflicting-outputs'
  ];
  final build = await Process.start('dart', buildArgs);
  await _waitForProcess(build, 'build');

  print('Copying generated sources into deploy/');
  // Advanced build magic because --output creates weird files that we don't
  // want.
  final graph = await PackageGraph.forThisPackage();
  final env = IOEnvironment(graph);
  final assets =
      AssetGraph.deserialize(await (await _findAssetGraph()).readAsBytes());
  final reader = BuildCacheReader(env.reader, assets, graph.root.name);

  final idsToRead = assets.allNodes
      .where((node) => !_shouldSkipNode(node, graph))
      .map((e) => e.id);

  for (final id in idsToRead) {
    final file = File(p.join('deploy', p.relative(id.path, from: 'web/')));
    file.parent.createSync(recursive: true);
    await file.writeAsBytes(await reader.readAsBytes(id));
  }
}

Future<void> _createApiDocumentation(Directory output) async {
  print('Globally activating dartdoc');
  await Process.run('dart', ['pub', 'global', 'activate', 'dartdoc']);

  final gitRevResult =
      await Process.run('git', ['rev-parse', 'HEAD'], stdoutEncoding: utf8);
  final rev = (gitRevResult.stdout as String).replaceAll('\n', '');

  // Dartdoc supports %r% for the revision, %f% for the file name and %l% for
  // the line number.
  const source = 'https://github.com/simolus3/drift/blob/%r%/%f%/#L%l%';
  // todo: Use `dart doc` after https://github.com/dart-lang/sdk/issues/46100#issuecomment-1033899215
  // gets clarified.
  final dartDoc = await Process.start(
    'dart',
    [
      'pub',
      'global',
      'run',
      'dartdoc',
      '--rel-canonical-prefix=https://pub.dev/documentation/drift/latest',
      '--link-to-source-revision=$rev',
      '--link-to-source-root=..',
      '--link-to-source-uri-template=$source',
    ],
    // This should run in the `drift` directory to properly recognize packages.
    workingDirectory: '../drift',
  );
  await _waitForProcess(dartDoc, 'dartdoc');

  final docOutput = Directory('../drift/doc/api');
  final targetForDocs = p.join(output.path, 'api');

  await for (final file in docOutput.list(recursive: true)) {
    if (file is! File) continue;

    final target =
        p.join(targetForDocs, p.relative(file.path, from: docOutput.path));
    File(target).parent.createSync(recursive: true);
    await file.copy(target);
  }
  await docOutput.parent.delete(recursive: true);
}

Future<File> _findAssetGraph() {
  final dir = Directory('.dart_tool/build');
  return dir.list().firstWhere((e) {
    final base = p.basename(e.path);
    return base != 'entrypoint' && base != 'generated';
  }).then((dir) => File(p.join(dir.path, 'asset_graph.json')));
}

bool _shouldSkipNode(AssetNode node, PackageGraph packageGraph) {
  if (!node.isReadable) return true;
  if (node.isDeleted) return true;

  if (!node.id.path.startsWith('web/') ||
      node.id.package != packageGraph.root.name) {
    return true;
  }

  if (node is InternalAssetNode) return true;
  if (node is GeneratedAssetNode) {
    if (!node.wasOutput ||
        node.isFailure ||
        node.state == NodeState.definitelyNeedsUpdate) {
      return true;
    }
  }
  return false;
}
