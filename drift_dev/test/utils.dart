import 'dart:convert';
import 'dart:isolate';

import 'package:build/build.dart';
import 'package:build/experiments.dart';
import 'package:build_resolvers/build_resolvers.dart';
import 'package:build_test/build_test.dart';
import 'package:crypto/crypto.dart';
import 'package:drift_dev/integrations/build.dart';
import 'package:glob/glob.dart';
import 'package:logging/logging.dart';
import 'package:package_config/package_config.dart';
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

final _packageConfig = Future(() async {
  final uri = await Isolate.packageConfig;

  if (uri == null) {
    throw UnsupportedError(
        'Isolate running the build does not have a package config and no '
        'fallback has been provided');
  }

  return await loadPackageConfigUri(uri);
});

Future<DriftBuildResult> emulateDriftBuild({
  required Map<String, String> inputs,
  BuilderOptions options = const BuilderOptions({}),
  Logger? logger,
  bool modularBuild = false,
}) async {
  _resolvers.reset();
  logger ??= Logger.detached('emulateDriftBuild');

  final writer = InMemoryAssetWriter();
  final reader = MultiAssetReader([
    WrittenAssetReader(writer),
    InMemoryAssetReader(
      rootPackage: 'a',
      sourceAssets: {
        for (final entry in inputs.entries) makeAssetId(entry.key): entry.value,
      },
    ),
    await PackageAssetReader.currentIsolate(),
  ]);
  final readAssets = <(Type, String), Set<AssetId>>{};

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

        if (expectedOutputs(stage, inputId).isNotEmpty) {
          final readerForPhase = _TrackingAssetReader(reader);

          await runBuilder(
            stage,
            [inputId],
            readerForPhase,
            writer,
            _resolvers,
            logger: logger,
            packageConfig: await _packageConfig,
          );

          readAssets.putIfAbsent(
              (stage.runtimeType, input), () => {}).addAll(readerForPhase.read);
        }
      }
    } else if (stage is PostProcessBuilder) {
      final deleted = <AssetId>[];

      for (final assetId in writer.assets.keys) {
        final shouldBuild =
            stage.inputExtensions.any((e) => assetId.path.endsWith(e));
        if (shouldBuild) {
          await runPostProcessBuilder(
            stage,
            assetId,
            reader,
            writer,
            logger,
            addAsset: (_) {},
            deleteAsset: deleted.add,
          );
        }
      }
      deleted.forEach(writer.assets.remove);
    }
  }

  logger.clearListeners();
  return DriftBuildResult(writer, readAssets);
}

class DriftBuildResult {
  final InMemoryAssetWriter writer;

  /// Asset ids read for each (builder, input id) combination.
  final Map<(Type, String), Set<AssetId>> readAssetsByBuilder;

  DriftBuildResult(this.writer, this.readAssetsByBuilder);

  Iterable<AssetId> get dartOutputs {
    return writer.assets.keys.where((e) {
      return e.extension == '.dart';
    });
  }

  void checkDartOutputs(Map<String, Object> outputs) {
    checkOutputs(outputs, dartOutputs, writer);
  }
}

class _TrackingAssetReader implements AssetReader {
  final AssetReader _inner;

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
}
