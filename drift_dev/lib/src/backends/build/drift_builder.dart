import 'package:build/build.dart';
import 'package:drift_dev/src/analyzer/options.dart';
import 'package:drift_dev/src/analyzer/runner/file_graph.dart';
import 'package:drift_dev/src/analyzer/runner/results.dart';
import 'package:drift_dev/src/analyzer/runner/task.dart';
import 'package:drift_dev/src/analyzer/session.dart';
import 'package:drift_dev/src/backends/build/build_backend.dart';
import 'package:drift_dev/src/backends/build/generators/dao_generator.dart';
import 'package:drift_dev/src/backends/build/generators/database_generator.dart';
import 'package:drift_dev/writer.dart';
import 'package:source_gen/source_gen.dart';

class _BuilderFlags {
  bool didWarnAboutDeprecatedOptions = false;
}

final _flags = Resource(() => _BuilderFlags());

mixin DriftBuilder on Builder {
  DriftOptions get options;

  Writer createWriter() {
    return Writer(options);
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

T _createBuilder<T extends DriftBuilder>(
  BuilderOptions options,
  T Function(List<Generator> generators, DriftOptions parsedOptions) creator,
) {
  final parsedOptions = DriftOptions.fromJson(options.config);

  final generators = <Generator>[
    DriftDatabaseGenerator(),
    DaoGenerator(),
  ];

  final builder = creator(generators, parsedOptions);

  for (final generator in generators.cast<BaseGenerator>()) {
    generator.builder = builder;
  }

  return builder;
}

class DriftSharedPartBuilder extends SharedPartBuilder with DriftBuilder {
  @override
  final DriftOptions options;

  DriftSharedPartBuilder._(
      List<Generator> generators, String name, this.options)
      : super(generators, name);

  factory DriftSharedPartBuilder(BuilderOptions options) {
    return _createBuilder(options, (generators, parsedOptions) {
      return DriftSharedPartBuilder._(generators, 'drift', parsedOptions);
    });
  }

  @override
  Future build(BuildStep buildStep) async {
    final flags = await buildStep.fetchResource(_flags);
    if (!flags.didWarnAboutDeprecatedOptions &&
        options.enabledDeprecatedOption) {
      print('You have the eagerly_load_dart_ast option enabled. The option is '
          'no longer necessary and will be removed in a future drift version. '
          'Consider removing the option from your build.yaml.');
      flags.didWarnAboutDeprecatedOptions = true;
    }

    return super.build(buildStep);
  }
}

class DriftPartBuilder extends PartBuilder with DriftBuilder {
  @override
  final DriftOptions options;

  DriftPartBuilder._(List<Generator> generators, String extension, this.options)
      : super(generators, extension);

  factory DriftPartBuilder(BuilderOptions options) {
    return _createBuilder(options, (generators, parsedOptions) {
      return DriftPartBuilder._(generators, '.drift.dart', parsedOptions);
    });
  }
}

abstract class BaseGenerator {
  late DriftBuilder builder;
}
