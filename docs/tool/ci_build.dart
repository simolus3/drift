//@dart=2.9
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
  final buildArgs = [
    'run',
    'build_runner',
    'build',
    '--release',
    if (isRelease) '--config=deploy',
  ];
  final build = await Process.start('dart', buildArgs,
      mode: ProcessStartMode.inheritStdio);
  await build.exitCode;

  print('Copying generated sources into deploy/');
  // Advanced build magic because --output creates weird files that we don't
  // want.
  final graph = await PackageGraph.forThisPackage();
  final env = IOEnvironment(graph);
  final assets =
      AssetGraph.deserialize(await (await _findAssetGraph()).readAsBytes());
  final reader = BuildCacheReader(env.reader, assets, graph.root.name);

  final output = Directory('deploy');
  if (output.existsSync()) {
    output.deleteSync(recursive: true);
  }
  output.createSync();

  final idsToRead = assets.allNodes
      .where((node) => !_shouldSkipNode(node, graph))
      .map((e) => e.id);

  for (final id in idsToRead) {
    final file = File(p.join('deploy', p.relative(id.path, from: 'web/')));
    file.parent.createSync(recursive: true);
    await file.writeAsBytes(await reader.readAsBytes(id));
  }
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
