import 'package:build/build.dart';
import 'package:drift_dev/src/analyzer/options.dart';
import 'package:drift_dev/src/analyzer/runner/file_graph.dart';
import 'package:drift_dev/src/analyzer/runner/results.dart';
import 'package:drift_dev/src/analyzer/runner/task.dart';
import 'package:drift_dev/src/analyzer/session.dart';
import 'package:drift_dev/src/backends/build/build_backend.dart';
import 'package:drift_dev/src/backends/build/generators/dao_generator.dart';
import 'package:drift_dev/src/backends/build/generators/moor_generator.dart';
import 'package:drift_dev/writer.dart';
import 'package:source_gen/source_gen.dart';

class _BuilderFlags {
  bool didWarnAboutDeprecatedOptions = false;
}

final _flags = Resource(() => _BuilderFlags());

mixin MoorBuilder on Builder {
  MoorOptions get options;
  bool get isForNewDriftPackage;

  Writer createWriter({bool nnbd = false}) {
    return Writer(options,
        generationOptions: GenerationOptions(
            nnbd: nnbd, writeForMoorPackage: !isForNewDriftPackage));
  }

  Future<ParsedDartFile> analyzeDartFile(BuildStep step) async {
    Task? task;
    FoundFile input;
    try {
      final backend = BuildBackend(options);
      final backendTask = backend.createTask(step);
      final session = MoorSession(backend, options: options);

      input = session.registerFile(step.inputId.uri);
      task = session.startTask(backendTask);
      await task.runTask();
    } finally {
      task?.printErrors();
    }

    return input.currentResult as ParsedDartFile;
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

  @override
  final bool isForNewDriftPackage;

  MoorSharedPartBuilder._(List<Generator> generators, String name, this.options,
      this.isForNewDriftPackage)
      : super(generators, name);

  factory MoorSharedPartBuilder(BuilderOptions options,
      {bool isForNewDriftPackage = false}) {
    return _createBuilder(options, (generators, parsedOptions) {
      return MoorSharedPartBuilder._(
          generators, 'moor', parsedOptions, isForNewDriftPackage);
    });
  }

  @override
  Future build(BuildStep buildStep) async {
    final flags = await buildStep.fetchResource(_flags);
    if (!flags.didWarnAboutDeprecatedOptions &&
        options.enabledDeprecatedOption) {
      print('You have the eagerly_load_dart_ast option enabled. The option is '
          'no longer necessary and will be removed in a future moor version. '
          'Consider removing the option from your build.yaml.');
      flags.didWarnAboutDeprecatedOptions = true;
    }

    return super.build(buildStep);
  }
}

class MoorPartBuilder extends PartBuilder with MoorBuilder {
  @override
  final MoorOptions options;

  @override
  final bool isForNewDriftPackage;

  MoorPartBuilder._(List<Generator> generators, String extension, this.options,
      this.isForNewDriftPackage)
      : super(generators, extension);

  factory MoorPartBuilder(BuilderOptions options,
      {bool isForNewDriftPackage = false}) {
    return _createBuilder(options, (generators, parsedOptions) {
      return MoorPartBuilder._(
          generators, '.moor.dart', parsedOptions, isForNewDriftPackage);
    });
  }
}

abstract class BaseGenerator {
  late MoorBuilder builder;
}
