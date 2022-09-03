import 'package:build/build.dart';
import 'package:drift_dev/src/backends/build/analyzer.dart';
import 'package:drift_dev/src/backends/build/drift_builder.dart';
import 'package:drift_dev/src/backends/build/preprocess_builder.dart';

Builder preparingBuilder(BuilderOptions options) => PreprocessBuilder();

Builder analyzer(BuilderOptions options) => DriftAnalyzer(options);

Builder driftBuilder(BuilderOptions options) => DriftSharedPartBuilder(options);

Builder driftBuilderNotShared(BuilderOptions options) =>
    DriftPartBuilder(options);

PostProcessBuilder driftCleanup(BuilderOptions options) {
  return const FileDeletingBuilder(['.temp.dart']);
}
