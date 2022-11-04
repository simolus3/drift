import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';

import '../../analysis/custom_result_class.dart';
import '../../analysis/driver/driver.dart';
import '../../analysis/driver/error.dart';
import '../../analysis/driver/state.dart';
import '../../analysis/results/results.dart';
import '../../analyzer/options.dart';
import '../../writer/database_writer.dart';
import '../../writer/drift_accessor_writer.dart';
import '../../writer/import_manager.dart';
import '../../writer/writer.dart';
import 'backend.dart';

class _BuilderFlags {
  bool didWarnAboutDeprecatedOptions = false;
}

final _flags = Resource(() => _BuilderFlags());

enum DriftGenerationMode {
  /// Generate a shart part file which `source_gen:combining_builder` will then
  /// pick up to generate a part for the input file.
  ///
  /// Drift will generate a single part file for the main database file and each
  /// DAO-defining file.
  monolithicSharedPart,

  /// Like [monolithicSharedPart], except that drift will generate a single
  /// part file on its own instead of generating a part file for `source_gen`
  /// to process later.
  monolithicPart;

  bool get isMonolithic => true;
}

class DriftBuilder extends Builder {
  final DriftOptions options;
  final DriftGenerationMode generationMode;

  DriftBuilder._(this.options, this.generationMode);

  factory DriftBuilder(
      DriftGenerationMode generationMode, BuilderOptions options) {
    final parsedOptions = DriftOptions.fromJson(options.config);
    return DriftBuilder._(parsedOptions, generationMode);
  }

  @override
  Map<String, List<String>> get buildExtensions {
    switch (generationMode) {
      case DriftGenerationMode.monolithicSharedPart:
        return {
          '.dart': ['.drift.g.part']
        };
      case DriftGenerationMode.monolithicPart:
        return {
          '.dart': ['.drift.dart']
        };
    }
  }

  @override
  Future<void> build(BuildStep buildStep) async {
    final flags = await buildStep.fetchResource(_flags);
    if (!flags.didWarnAboutDeprecatedOptions &&
        options.enabledDeprecatedOption) {
      print('You have the eagerly_load_dart_ast option enabled. The option is '
          'no longer necessary and will be removed in a future drift version. '
          'Consider removing the option from your build.yaml.');
      flags.didWarnAboutDeprecatedOptions = true;
    }

    final driver = DriftAnalysisDriver(DriftBuildBackend(buildStep), options)
      ..cacheReader = BuildCacheReader(buildStep);

    final fromCache =
        await driver.readStoredAnalysisResult(buildStep.inputId.uri);

    if (fromCache == null) {
      // Don't do anything! There are no analysis results for this file, so
      // there's nothing for drift to generate code for.
      return;
    }

    Set<Uri> analyzedUris = {};
    Future<FileState> analyze(Uri uri) async {
      final fileResult = await driver.fullyAnalyze(uri);
      if (analyzedUris.add(fileResult.ownUri)) {
        for (final error
            in fileResult.fileAnalysis?.analysisErrors ?? const []) {
          log.warning(error);
        }
      }

      return fileResult;
    }

    final fileResult = await analyze(buildStep.inputId.uri);

    final generationOptions = GenerationOptions(
      imports: ImportManagerForPartFiles(),
    );
    final writer = Writer(options, generationOptions: generationOptions);

    for (final element in fileResult.analysis.values) {
      final result = element.result;

      if (result is BaseDriftAccessor) {
        final resolved = fileResult.fileAnalysis!.resolvedDatabases[result.id]!;
        var importedQueries = <DefinedSqlQuery, SqlQuery>{};

        for (final query
            in resolved.availableElements.whereType<DefinedSqlQuery>()) {
          final resolvedFile = await analyze(query.id.libraryUri);
          final resolvedQuery =
              resolvedFile.fileAnalysis?.resolvedQueries[query.id];

          if (resolvedQuery != null) {
            importedQueries[query] = resolvedQuery;
          }
        }

        // Apply custom result classes
        final mappedQueries = transformCustomResultClasses(
          resolved.definedQueries.values.followedBy(importedQueries.values),
          (message) => log.warning('For accessor ${result.id.name}: $message'),
        );
        importedQueries =
            importedQueries.map((k, v) => MapEntry(k, mappedQueries[v] ?? v));
        resolved.definedQueries = resolved.definedQueries
            .map((k, v) => MapEntry(k, mappedQueries[v] ?? v));

        if (result is DriftDatabase) {
          final input =
              DatabaseGenerationInput(result, resolved, importedQueries);
          DatabaseWriter(input, writer.child()).write();
        } else if (result is DatabaseAccessor) {
          final input =
              AccessorGenerationInput(result, resolved, importedQueries);
          AccessorWriter(input, writer.child()).write();
        }
      } else {
        writer.leaf().writeln('// ${element.ownId}');
      }
    }

    var generated = writer.writeGenerated();

    try {
      generated = DartFormatter().format(generated);
    } on FormatterException {
      log.warning('Could not format generated source. The generated code is '
          'probably invalid, and this is most likely a bug in drift_dev.');
    }

    await buildStep.writeAsString(buildStep.allowedOutputs.single, generated);
  }
}
