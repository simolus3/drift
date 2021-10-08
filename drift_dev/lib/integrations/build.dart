import 'package:build/build.dart';
import 'package:drift_dev/src/backends/build/moor_builder.dart';
import 'package:drift_dev/src/backends/build/preprocess_builder.dart';

Builder moorBuilder(BuilderOptions options) => MoorSharedPartBuilder(options);

Builder moorBuilderNotShared(BuilderOptions options) =>
    MoorPartBuilder(options);

Builder preparingBuilder(BuilderOptions options) => PreprocessBuilder();

PostProcessBuilder moorCleanup(BuilderOptions options) {
  return const FileDeletingBuilder(['.temp.dart']);
}
