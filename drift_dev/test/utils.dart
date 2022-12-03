import 'package:build/build.dart';
import 'package:build_resolvers/build_resolvers.dart';
import 'package:build_test/build_test.dart';
import 'package:drift_dev/integrations/build.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

final _resolvers = AnalyzerResolvers();

BuilderOptions builderOptionsFromYaml(String yaml) {
  final map = loadYaml(yaml);
  return BuilderOptions((map as YamlMap).cast());
}

Future<RecordingAssetWriter> emulateDriftBuild({
  required Map<String, String> inputs,
  BuilderOptions options = const BuilderOptions({}),
  Logger? logger,
  bool modularBuild = false,
}) async {
  _resolvers.reset();

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
    analyzer(options),
    modularBuild ? modular(options) : driftBuilderNotShared(options),
  ];

  for (final stage in stages) {
    await runBuilder(
      stage,
      inputs.keys.map(makeAssetId),
      reader,
      writer,
      _resolvers,
      logger: logger,
    );
  }

  logger?.clearListeners();
  return writer;
}

extension OnlyDartOutputs on RecordingAssetWriter {
  Iterable<AssetId> get dartOutputs {
    return assets.keys.where((e) {
      final fullExtension = p.url.extension(e.path, 2);

      return e.extension == '.dart' && fullExtension != '.temp.dart';
    });
  }
}
