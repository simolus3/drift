import 'package:build/build.dart';
import 'package:moor_generator/src/backends/build/moor_builder.dart';

export 'src/model/model.dart';

Builder moorBuilder(BuilderOptions options) => MoorBuilder(options);
