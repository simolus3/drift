import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/codegen/generator.dart';

Builder driftRiverpodBuilder(BuilderOptions options) {
  return SharedPartBuilder([DriftRiverpodGenerator()], 'drift_riverpod');
}
