import 'dart:convert';

import 'package:build/build.dart';

import '../../analysis/driver/driver.dart';
import '../../analysis/serializer.dart';
import '../../analysis/options.dart';
import 'backend.dart';

class DriftAnalyzer extends Builder {
  final DriftOptions options;

  DriftAnalyzer(BuilderOptions options)
      : options = DriftOptions.fromJson(options.config);

  @override
  Map<String, List<String>> get buildExtensions => const {
        '.drift': ['.drift.drift_module.json'],
        '.dart': ['.dart.drift_module.json']
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

      final serializer = ElementSerializer();
      final asJson = serializer.serializeElements(
          results.analysis.values.map((e) => e.result).whereType());
      final serialized = JsonUtf8Encoder(' ' * 2).convert(asJson);

      await buildStep.writeAsBytes(buildStep.allowedOutputs.single, serialized);
    }
  }
}
