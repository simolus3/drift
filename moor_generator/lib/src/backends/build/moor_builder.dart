import 'package:build/build.dart';
import 'package:moor_generator/src/analyzer/runner/results.dart';
import 'package:moor_generator/src/backends/build/build_backend.dart';
import 'package:moor_generator/src/backends/build/generators/dao_generator.dart';
import 'package:moor_generator/src/backends/build/generators/moor_generator.dart';
import 'package:moor_generator/src/writer/writer.dart';
import 'package:source_gen/source_gen.dart';

part 'options.dart';

final backendResource = Resource(() => BuildBackend());

class MoorBuilder extends SharedPartBuilder {
  final MoorOptions options;

  MoorBuilder._(List<Generator> generators, String name, this.options)
      : super(generators, name);

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

  Writer createWriter() => Writer(options);

  Future<ParsedDartFile> analyzeDartFile(BuildStep step) async {
    final backend = await step.fetchResource(backendResource);
    final backendTask = backend.createTask(step);
    final session = backend.session;

    final input = session.registerFile(step.inputId.uri);
    final task = session.startTask(backendTask);
    await task.runTask();

    task.printErrors();

    await backendTask.finish(input);

    return input.currentResult as ParsedDartFile;
  }
}

abstract class BaseGenerator {
  MoorBuilder builder;
}
