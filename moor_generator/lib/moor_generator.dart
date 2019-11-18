import 'package:build/build.dart';
import 'package:moor_generator/src/backends/build/moor_builder.dart';
import 'package:moor_generator/src/backends/build/preprocess_builder.dart';

Builder preparingBuilder(BuilderOptions options) => PreprocessBuilder();

Builder moorBuilder(BuilderOptions options) => MoorBuilder(options);

PostProcessBuilder moorCleanup(BuilderOptions options) {
  return const FileDeletingBuilder(['.temp.dart']);
}
