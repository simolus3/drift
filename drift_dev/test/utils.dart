import 'package:build/build.dart';
import 'package:build_resolvers/build_resolvers.dart';
import 'package:build_test/build_test.dart';
import 'package:drift_dev/integrations/build.dart';

final _resolvers = AnalyzerResolvers();

Future<RecordingAssetWriter> emulateDriftBuild({
  required Map<String, String> inputs,
  BuilderOptions options = const BuilderOptions({}),
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
    driftBuilderNotShared(options),
  ];

  for (final stage in stages) {
    await runBuilder(
        stage, inputs.keys.map(makeAssetId), reader, writer, _resolvers);
  }

  return writer;
}

extension OnlyDartOutputs on RecordingAssetWriter {
  Iterable<AssetId> get dartOutputs {
    return assets.keys.where((e) => e.extension == '.dart');
  }
}
