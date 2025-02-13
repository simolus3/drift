/// A library providing a factory for the [Builder] `drift_riverpod` uses to
/// generate code.
library;

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/codegen/generator.dart';

/// Returns a builder generating code for `drift_riverpod` through the build
/// system.
Builder driftRiverpodBuilder(BuilderOptions options) {
  return SharedPartBuilder([DriftRiverpodGenerator()], 'drift_riverpod');
}
