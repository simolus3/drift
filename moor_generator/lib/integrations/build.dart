// ignore_for_file: implementation_imports
import 'package:build/build.dart';
import 'package:drift_dev/src/backends/build/drift_builder.dart';
import 'package:drift_dev/src/backends/build/preprocess_builder.dart';

Builder moorBuilder(BuilderOptions options) =>
    DriftSharedPartBuilder(options, isForNewDriftPackage: false);

Builder moorBuilderNotShared(BuilderOptions options) =>
    DriftPartBuilder(options, isForNewDriftPackage: false);

Builder preparingBuilder(BuilderOptions options) => PreprocessBuilder();

PostProcessBuilder moorCleanup(BuilderOptions options) {
  return const FileDeletingBuilder(['.temp.dart']);
}
