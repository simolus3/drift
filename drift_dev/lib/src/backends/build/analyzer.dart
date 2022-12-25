import 'dart:convert';

import 'package:build/build.dart';

import '../../analysis/driver/driver.dart';
import '../../analysis/serializer.dart';
import '../../analysis/options.dart';
import '../../writer/import_manager.dart';
import '../../writer/writer.dart';
import 'backend.dart';

class DriftAnalyzer extends Builder {
  final DriftOptions options;

  DriftAnalyzer(BuilderOptions options)
      : options = DriftOptions.fromJson(options.config);

  @override
  Map<String, List<String>> get buildExtensions => const {
        '.drift': [
          '.drift.drift_module.json',
          '.types.temp.dart',
        ],
        '.dart': [
          '.dart.drift_module.json',
          '.types.temp.dart',
        ],
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    final backend = DriftBuildBackend(buildStep);
    final driver = DriftAnalysisDriver(backend, options);

    final results = await driver.resolveElements(buildStep.inputId.uri);

    for (final parseError in results.errorsDuringDiscovery) {
      log.warning(parseError.toString());
    }

    if (results.analysis.isNotEmpty) {
      for (final result in results.analysis.values) {
        for (final error in result.errorsDuringAnalysis) {
          log.warning(error.toString());
        }
      }

      final serialized = ElementSerializer.serialize(
          results.analysis.values.map((e) => e.result).whereType());
      final asJson =
          JsonUtf8Encoder(' ' * 2).convert(serialized.serializedElements);

      final jsonOutput = buildStep.inputId.addExtension('.drift_module.json');
      final typesOutput = buildStep.inputId.changeExtension('.types.temp.dart');

      await buildStep.writeAsBytes(jsonOutput, asJson);

      if (serialized.dartTypes.isNotEmpty) {
        final imports = LibraryInputManager();
        final writer = Writer(
          options,
          generationOptions: GenerationOptions(imports: imports),
        );
        imports.linkToWriter(writer);

        for (var i = 0; i < serialized.dartTypes.length; i++) {
          writer.leaf()
            ..write('typedef T$i = ')
            ..writeDart(serialized.dartTypes[i])
            ..writeln(';');
        }

        await buildStep.writeAsString(typesOutput, writer.writeGenerated());
      }
    }
  }
}
