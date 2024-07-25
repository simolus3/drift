import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'dart:convert';
import 'dart:io';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:build_runner_core/src/asset/build_cache.dart';
import 'package:build_runner_core/src/asset_graph/graph.dart';
import 'package:build_runner_core/src/asset_graph/node.dart';
import 'package:path/path.dart' as p;

class DocsCommand extends Command<int> {
  DocsCommand({
    required Logger logger,
    required this.serve,
  }) : _logger = logger {
    argParser.addFlag('only-mkdocs',
        help: "If set, only builds the MkDocs documentation.",
        defaultsTo: false);
  }
  final bool serve;

  @override
  String get description =>
      serve ? 'Serve the documentation' : 'Build the documentation';

  @override
  String get name => serve ? "serve" : 'build';

  final Logger _logger;

  @override
  Future<int> run() async {
    final onlyMkDocs = argResults!['only-mkdocs'] as bool;
    if (!onlyMkDocs) {
      _logger.info("Building the DartDocs and Running Build Runner");
      final output = Directory('build');
      if (output.existsSync()) {
        output.deleteSync(recursive: true);
      }
      output.createSync();

      await Future.wait([
        _runBuildAndCopyFiles(output),
        _createApiDocumentation(output),
      ]);
    } else {
      _logger.info("Skipping DartDocs and Build Runner");
    }
    _logger.info("Building the MkDocs Documentation");
    await Future.wait([
      _buildDockerfileAndBuildMkDocs(serve),
    ]);

    return ExitCode.success.code;
  }
}

/// Create the snippets for the documentation & compile the `/web` directory to javascript
Future<void> _runBuildAndCopyFiles(Directory output) async {
  final buildArgs = [
    'run',
    'build_runner',
    'build',
    '--release',
    '--delete-conflicting-outputs'
  ];
  final build = await Process.start('dart', buildArgs);
  await _waitForProcess(build, 'build');

  print('Copying generated sources into build/');
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
    final file = File(p.join('build', p.relative(id.path, from: 'web/')));
    file.parent.createSync(recursive: true);
    await file.writeAsBytes(await reader.readAsBytes(id));
  }
}

/// Build the dartdoc documentation for the API and copy it into the build
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

/// Build the MkDocs documentation
Future<void> _buildDockerfileAndBuildMkDocs(bool serve) async {
  final buildArgs = [
    'build',
    '-t',
    'mkdocs:latest',
    p.join(Directory.current.path, "mkdocs")
  ];
  final build = await Process.start('docker', buildArgs);
  await _waitForProcess(build, 'docker build');

  final userIdProcess = await Process.start('id', ['-u']);
  final userId = (await utf8.decodeStream(userIdProcess.stdout)).trim();
  final groupIdProcess = await Process.start('id', ['-g']);
  final groupId = (await utf8.decodeStream(groupIdProcess.stdout)).trim();
  final List<String> mkdocsArgs;
  if (serve) {
    mkdocsArgs = [
      'run',
      '--rm',
      '-p',
      '9000:9000',
      '-v',
      '${Directory.current.path}:/docs',
      '--user',
      '$userId:$groupId',
      'mkdocs:latest',
      'serve',
      '-f',
      '/docs/mkdocs/mkdocs.yml',
      "-a",
      '0.0.0.0:9000'
    ];
  } else {
    mkdocsArgs = [
      'run',
      '--rm',
      '-v',
      '${Directory.current.path}:/docs',
      '--user',
      '$userId:$groupId',
      'mkdocs:latest',
      'build',
      '-f',
      '/docs/mkdocs/mkdocs.yml',
      "-d",
      '/docs/dist'
    ];
  }
  final mkdocs = await Process.start(
    'docker',
    mkdocsArgs,
    includeParentEnvironment: true,
    runInShell: true,
  );
  await _waitForProcess(mkdocs, 'mkdocs build');
}

// Utility function to wait for a process to finish and forward its output to
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
