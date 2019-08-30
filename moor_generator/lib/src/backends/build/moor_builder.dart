import 'package:build/build.dart';
import 'package:moor_generator/src/dao_generator.dart';
import 'package:moor_generator/src/moor_generator.dart';
import 'package:moor_generator/src/state/options.dart';
import 'package:source_gen/source_gen.dart';

class MoorBuilder extends SharedPartBuilder {
  factory MoorBuilder(BuilderOptions options) {
    final parsedOptions = MoorOptions.fromBuilder(options.config);

    final generators = [
      MoorGenerator(parsedOptions),
      DaoGenerator(parsedOptions),
    ];

    return MoorBuilder._(generators, 'moor');
  }

  MoorBuilder._(List<Generator> generators, String name)
      : super(generators, name);
}
