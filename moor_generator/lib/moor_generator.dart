import 'package:build/build.dart';
import 'package:moor_generator/src/backends/build/moor_builder.dart';

Builder moorBuilder(BuilderOptions options) => MoorBuilder(options);
