import 'package:build/build.dart';
import 'package:drift_dev/src/backends/build/analyzer.dart';
import 'package:drift_dev/src/backends/build/drift_builder.dart';
import 'package:drift_dev/src/backends/build/preprocess_builder.dart';

Builder preparingBuilder(BuilderOptions options) => PreprocessBuilder();

Builder analyzer(BuilderOptions options) => DriftAnalyzer(options);

Builder driftBuilder(BuilderOptions options) =>
    DriftBuilder(DriftGenerationMode.monolithicSharedPart, options);

Builder driftBuilderNotShared(BuilderOptions options) =>
    DriftBuilder(DriftGenerationMode.monolithicPart, options);

Builder modular(BuilderOptions options) =>
    DriftBuilder(DriftGenerationMode.modular, options);

PostProcessBuilder driftCleanup(BuilderOptions options) {
  return const FileDeletingBuilder(['.temp.dart']);
}
