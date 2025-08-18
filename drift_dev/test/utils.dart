import 'dart:convert';
import 'dart:isolate';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:build/build.dart';
import 'package:build/experiments.dart';
import 'package:build/src/state/asset_finder.dart';
import 'package:build/src/state/asset_path_provider.dart';
import 'package:build/src/state/filesystem.dart';
import 'package:build/src/state/filesystem_cache.dart';
import 'package:build/src/state/generated_asset_hider.dart';
import 'package:build/src/state/reader_writer.dart';
import 'package:build_resolvers/build_resolvers.dart';
import 'package:build_test/build_test.dart';
import 'package:build_test/src/in_memory_reader_writer.dart';
import 'package:build/src/state/reader_state.dart';
import 'package:crypto/crypto.dart';
import 'package:drift_dev/integrations/build.dart';
import 'package:glob/glob.dart';
import 'package:logging/logging.dart';
import 'package:package_config/package_config.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

final _resolvers =
    withEnabledExperiments(() => AnalyzerResolvers.sharedInstance, ['records']);

BuilderOptions builderOptionsFromYaml(String yaml) {
  final map = loadYaml(yaml);
  return BuilderOptions((map as YamlMap).cast());
}

Logger loggerThat(dynamic expectedLogs) {
  final logger = Logger.detached('drift_dev_test');

  expect(logger.onRecord, expectedLogs);
  return logger;
}

TypeMatcher<LogRecord> record(dynamic message) {
  return isA<LogRecord>().having((e) => e.message, 'message', message);
}

final _packageConfig = Future(() async {
  final uri = await Isolate.packageConfig;

  if (uri == null) {
    throw UnsupportedError(
        'Isolate running the build does not have a package config and no '
        'fallback has been provided');
  }

  return await loadPackageConfigUri(uri);
});

Future<TestReaderWriter> driftTestEnvironment(
    {String rootPackage = 'a'}) async {
  final rw = TestReaderWriter(rootPackage: rootPackage);
  final reader = await PackageAssetReader.currentIsolate();
  for (final package in [
    'async',
    'convert',
    'collection',
    'drift',
    'meta',
    'stream_channel',
    'sqlite3',
    'path',
    'stack_trace',
    'typed_data',
  ]) {
    await for (final asset
        in reader.findAssets(Glob('lib/**'), package: package)) {
      rw.testing.writeBytes(asset, await reader.readAsBytes(asset));
    }
  }

  return rw;
}

Future<DriftBuildResult> emulateDriftBuild({
  required Map<String, String> inputs,
  BuilderOptions options = const BuilderOptions({}),
  Logger? logger,
  bool modularBuild = false,
}) async {
  _resolvers.reset();
  logger ??= Logger.detached('emulateDriftBuild');

  final readAssets = <(Type, String), Set<AssetId>>{};
  final deletedAssets = <AssetId>[];
  final env = await driftTestEnvironment();
  inputs.forEach((id, contents) {
    env.testing.writeString(makeAssetId(id), contents);
  });

  final stages = [
    preparingBuilder(options),
    discover(options),
    analyzer(options),
    modularBuild ? modular(options) : driftBuilderNotShared(options),
    driftCleanup(options),
  ];

  for (final stage in stages) {
    if (stage is Builder) {
      // We might want to consider running these concurrently, but tests are
      // easier to debug when running builders in a serial order.
      for (final input in inputs.keys) {
        final inputId = makeAssetId(input);

        // Assets from other packages are visible, but we're not running
        // builders on them.
        if (inputId.package != 'a') continue;

        if (expectedOutputs(stage, inputId).isNotEmpty) {
          final readerForPhase = _TrackingAssetReader(env);

          await runBuilder(
            stage,
            [inputId],
            readerForPhase,
            env,
            _resolvers,
            logger: logger,
            packageConfig: await _packageConfig,
          );

          readAssets.putIfAbsent(
              (stage.runtimeType, input), () => {}).addAll(readerForPhase.read);
        }
      }
    } else if (stage is PostProcessBuilder) {
      for (final assetId in env.testing.assetsWritten) {
        final shouldBuild =
            stage.inputExtensions.any((e) => assetId.path.endsWith(e));
        if (shouldBuild) {
          await runPostProcessBuilder(
            stage,
            assetId,
            env,
            env,
            logger,
            addAsset: (_) {},
            deleteAsset: (id) {
              env.delete(id);
              deletedAssets.add(id);
            },
          );
        }
      }
    }
  }

  logger.clearListeners();
  return DriftBuildResult(env, readAssets, deletedAssets);
}

class DriftBuildResult {
  final TestReaderWriter writer;
  final List<AssetId> deleted;

  /// Asset ids read for each (builder, input id) combination.
  final Map<(Type, String), Set<AssetId>> readAssetsByBuilder;

  DriftBuildResult(this.writer, this.readAssetsByBuilder, this.deleted);

  Iterable<AssetId> get dartOutputs {
    return writer.testing.assetsWritten.where((e) {
      return e.extension == '.dart' && !deleted.contains(e);
    });
  }

  void checkDartOutputs(Map<String, Object> outputs) {
    checkOutputs(outputs, dartOutputs, writer);
  }
}

class _TrackingAssetReader implements AssetReader, AssetReaderState {
  final TestReaderWriter _inner;

  final Set<AssetId> read = {};

  _TrackingAssetReader(this._inner);

  void _trackRead(AssetId id) {
    read.add(id);
  }

  @override
  Future<bool> canRead(AssetId id) {
    _trackRead(id);
    return _inner.canRead(id);
  }

  @override
  Future<Digest> digest(AssetId id) {
    _trackRead(id);
    return _inner.digest(id);
  }

  @override
  Stream<AssetId> findAssets(Glob glob) {
    return _inner.findAssets(glob).map((id) {
      _trackRead(id);
      return id;
    });
  }

  @override
  Future<List<int>> readAsBytes(AssetId id) {
    _trackRead(id);
    return _inner.readAsBytes(id);
  }

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding = utf8}) {
    _trackRead(id);
    return _inner.readAsString(id, encoding: encoding);
  }

  @override
  AssetFinder get assetFinder => _inner.assetFinder;

  @override
  AssetPathProvider get assetPathProvider => _inner.assetPathProvider;

  @override
  FilesystemCache get cache => _inner.cache;

  @override
  AssetReaderWriter copyWith(
      {FilesystemCache? cache, GeneratedAssetHider? generatedAssetHider}) {
    throw UnimplementedError();
  }

  @override
  Filesystem get filesystem => _inner.filesystem;

  @override
  GeneratedAssetHider get generatedAssetHider => _inner.generatedAssetHider;
}

extension ReaderWriterUtils on TestReaderWriter {
  String readGenerated(String assetId) {
    var id = AssetId.parse(assetId);
    if (!testing.exists(id)) {
      id = AssetId(
        (this as InMemoryAssetReaderWriter).rootPackage,
        '.dart_tool/build/generated/${id.package}/${id.path}',
      );

      // If neither succeeded then the asset was output but written somewhere
      // unexpected.
      if (!testing.exists(id)) {
        throw StateError(
          'Internal error: "$assetId" was recorded as output, but the file '
          'could not be found. All assets: ${testing.assets}',
        );
      }
    }

    return testing.readString(id);
  }
}

class IsValidDartFile extends CustomMatcher {
  IsValidDartFile(dynamic valueOrMatcher)
      : super(
          'A syntactically-valid Dart source file',
          'parsed unit',
          valueOrMatcher,
        );

  @override
  Object? featureValueOf(actual) {
    final resourceProvider = MemoryResourceProvider();
    if (actual is List<int>) {
      resourceProvider.newFileWithBytes('/foo.dart', actual);
    } else if (actual is String) {
      resourceProvider.newFile('/foo.dart', actual);
    } else {
      throw 'Not a String or a List<int>';
    }

    return parseFile(
      path: '/foo.dart',
      featureSet: FeatureSet.fromEnableFlags2(
        sdkLanguageVersion: Version(3, 0, 0),
        flags: const [],
      ),
      resourceProvider: resourceProvider,
      throwIfDiagnostics: true,
    ).unit;
  }
}
