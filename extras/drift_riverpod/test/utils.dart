import 'dart:isolate';

import 'package:build/build.dart';
import 'package:build_resolvers/build_resolvers.dart';
import 'package:build_test/build_test.dart';
import 'package:drift_dev/integrations/build.dart';
import 'package:drift_riverpod/codegen.dart';
import 'package:logging/logging.dart';
import 'package:package_config/package_config.dart';
import 'package:source_gen/builder.dart';
import 'package:test/test.dart';

final _packageConfig = Future(() async {
  final uri = await Isolate.packageConfig;

  if (uri == null) {
    throw UnsupportedError(
        'Isolate running the build does not have a package config and no '
        'fallback has been provided');
  }

  return await loadPackageConfigUri(uri);
});

Logger loggerThat(dynamic expectedLogs) {
  final logger = Logger.detached('drift_dev_test');

  expect(logger.onRecord, expectedLogs);
  return logger;
}

Future<BuildResult> emulateDriftBuild({
  required Map<String, String> inputs,
  BuilderOptions options = const BuilderOptions({}),
  Logger? logger,
}) async {
  final resolvers = AnalyzerResolvers.sharedInstance..reset();
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

  final stages = [
    preparingBuilder(options),
    discover(options),
    analyzer(options),
    driftBuilder(options),
    driftRiverpodBuilder(options),
    combiningBuilder(),
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
          await runBuilder(
            stage,
            [inputId],
            reader,
            writer,
            resolvers,
            logger: logger,
            packageConfig: await _packageConfig,
          );
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
  return BuildResult(writer);
}

extension type BuildResult(InMemoryAssetWriter writer)
    implements InMemoryAssetWriter {
  Iterable<AssetId> get dartOutputs {
    return writer.assets.keys.where((e) {
      return e.extension == '.dart';
    });
  }

  Iterable<AssetId> get driftRiverpodOutputs {
    return writer.assets.keys.where((e) {
      return e.path.endsWith('.drift_riverpod.g.part');
    });
  }

  void checkDartOutputs(Map<String, Object> outputs) {
    checkOutputs(outputs, dartOutputs, writer);
  }
}
