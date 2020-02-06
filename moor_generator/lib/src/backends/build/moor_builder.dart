import 'package:build/build.dart';
import 'package:moor_generator/src/analyzer/options.dart';
import 'package:moor_generator/src/analyzer/runner/file_graph.dart';
import 'package:moor_generator/src/analyzer/runner/results.dart';
import 'package:moor_generator/src/analyzer/runner/task.dart';
import 'package:moor_generator/src/analyzer/session.dart';
import 'package:moor_generator/src/backends/build/build_backend.dart';
import 'package:moor_generator/src/backends/build/generators/dao_generator.dart';
import 'package:moor_generator/src/backends/build/generators/moor_generator.dart';
import 'package:moor_generator/writer.dart';
import 'package:source_gen/source_gen.dart';

mixin MoorBuilder on Builder {
  MoorOptions get options;

  Writer createWriter() => Writer(options);

  Future<ParsedDartFile> analyzeDartFile(BuildStep step) async {
    Task task;
    FoundFile input;
    try {
      final backend = BuildBackend();
      final backendTask = backend.createTask(step);
      final session = MoorSession(backend, options: options);

      input = session.registerFile(step.inputId.uri);
      task = session.startTask(backendTask);
      await task.runTask();
    } finally {
      task?.printErrors();
    }

    return input?.currentResult as ParsedDartFile;
  }
}

T _createBuilder<T extends MoorBuilder>(
  BuilderOptions options,
  T Function(List<Generator> generators, MoorOptions parsedOptions) creator,
) {
  final parsedOptions = MoorOptions.fromJson(options.config);

  final generators = <Generator>[
    MoorGenerator(),
    DaoGenerator(),
  ];

  final builder = creator(generators, parsedOptions);

  for (final generator in generators.cast<BaseGenerator>()) {
    generator.builder = builder;
  }

  return builder;
}

class MoorSharedPartBuilder extends SharedPartBuilder with MoorBuilder {
  @override
  final MoorOptions options;

  MoorSharedPartBuilder._(List<Generator> generators, String name, this.options)
      : super(generators, name);

  factory MoorSharedPartBuilder(BuilderOptions options) {
    return _createBuilder(options, (generators, parsedOptions) {
      return MoorSharedPartBuilder._(generators, 'moor', parsedOptions);
    });
  }
}

class MoorPartBuilder extends PartBuilder with MoorBuilder {
  @override
  final MoorOptions options;

  MoorPartBuilder._(List<Generator> generators, String extension, this.options)
      : super(generators, extension);

  factory MoorPartBuilder(BuilderOptions options) {
    return _createBuilder(options, (generators, parsedOptions) {
      return MoorPartBuilder._(generators, '.moor.dart', parsedOptions);
    });
  }
}

abstract class BaseGenerator {
  MoorBuilder builder;
}
