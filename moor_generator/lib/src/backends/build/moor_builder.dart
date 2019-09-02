import 'package:build/build.dart';
import 'package:moor_generator/src/analyzer/session.dart';
import 'package:moor_generator/src/backends/build/build_backend.dart';
import 'package:moor_generator/src/backends/build/generators/dao_generator.dart';
import 'package:moor_generator/src/backends/build/generators/moor_generator.dart';
import 'package:source_gen/source_gen.dart';

part 'options.dart';

class MoorBuilder extends SharedPartBuilder {
  final BuildBackend backend = BuildBackend();
  final MoorOptions options;

  factory MoorBuilder(BuilderOptions options) {
    final parsedOptions = MoorOptions.fromBuilder(options.config);

    final generators = <Generator>[
      MoorGenerator(),
      DaoGenerator(),
    ];

    final builder = MoorBuilder._(generators, 'moor', parsedOptions);

    for (var generator in generators.cast<BaseGenerator>()) {
      generator.builder = builder;
    }

    return builder;
  }

  MoorBuilder._(List<Generator> generators, String name, this.options)
      : super(generators, name);

  Future<DartTask> createDartTask(BuildStep step) async {
    final backendTask = backend.createTask(step);
    return await backend.session
        .startDartTask(backendTask, uri: step.inputId.uri);
  }
}

abstract class BaseGenerator {
  MoorBuilder builder;
}
