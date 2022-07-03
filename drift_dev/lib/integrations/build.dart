import 'package:build/build.dart';
import 'package:drift_dev/src/backends/build/drift_builder.dart';
import 'package:drift_dev/src/backends/build/preprocess_builder.dart';

Builder driftBuilder(BuilderOptions options) =>
    DriftSharedPartBuilder(options, isForNewDriftPackage: true);

Builder driftBuilderNotShared(BuilderOptions options) =>
    DriftPartBuilder(options, isForNewDriftPackage: true);

Builder preparingBuilder(BuilderOptions options) =>
    PreprocessBuilder(isForNewDriftPackage: true);

PostProcessBuilder driftCleanup(BuilderOptions options) {
  return const FileDeletingBuilder(['.temp.dart']);
}
