import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:pub_semver/pub_semver.dart';

import '../../analysis/custom_result_class.dart';
import '../../analysis/driver/driver.dart';
import '../../analysis/driver/state.dart';
import '../../analysis/results/results.dart';
import '../../analysis/options.dart';
import '../../utils/string_escaper.dart';
import '../../writer/database_writer.dart';
import '../../writer/drift_accessor_writer.dart';
import '../../writer/function_stubs_writer.dart';
import '../../writer/import_manager.dart';
import '../../writer/modules.dart';
import '../../writer/tables/table_writer.dart';
import '../../writer/tables/view_writer.dart';
import '../../writer/writer.dart';
import 'backend.dart';
import 'exception.dart';

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
  monolithicSharedPart(true, true),

  /// Like [monolithicSharedPart], except that drift will generate a single
  /// part file on its own instead of generating a part file for `source_gen`
  /// to process later.
  monolithicPart(true, true),

  /// Generates a separate Dart library (no `part of` directive) for each input
  /// (.drift file or .dart file with databases / tables).
  modular(false, false);

  /// Whether this mode defines a "monolithic" build.
  ///
  /// In a monolithic build, drift will generate all code into a single file,
  /// even if tables and queries are defined across multiple `.drift` files.
  /// In modular (non-monolithic) builds, files are generated for each input
  /// defining drift elements instead.
  final bool isMonolithic;

  /// Whether this build mode generates a part file.
  final bool isPartFile;

  const DriftGenerationMode(this.isMonolithic, this.isPartFile);

  /// Whether the user-visible outputs for this builder will be written by the
  /// combining builder defined in the `source_gen` package.
  bool get appliesCombiningBuilderFromSourceGen =>
      this == DriftGenerationMode.monolithicSharedPart;

  /// Whether the analysis happens in the generating build step.
  ///
  /// For most generation modes, we run analysis work in a previous build step.
  /// For backwards compatibility and since the result of the analysis work
  /// should not be user-visible, the non-shared part builder runs its analysis
  /// work in the generation build step.
  bool get embeddedAnalyzer => this == DriftGenerationMode.monolithicPart;
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
      case DriftGenerationMode.modular:
        return {
          '.dart': ['.drift.dart'],
          '.drift': ['.drift.dart'],
        };
    }
  }

  @override
  Future<void> build(BuildStep buildStep) async {
    final run = _DriftBuildRun(options, generationMode, buildStep);
    await run.run();
  }
}

extension on Version {
  String get majorMinor => '$major.$minor';
}

class _DriftBuildRun {
  final DriftOptions options;
  final DriftGenerationMode mode;
  final BuildStep buildStep;

  final DriftAnalysisDriver driver;

  /// When emitting a direct part file, contains the `// @dart` language version
  /// comment from the main library. We need to apply it to the part file as
  /// well.
  Version? overriddenLanguageVersion;

  /// The Dart language version from the package. When it's too old and we're
  /// generating libraries, we need to apply a `// @dart` version comment to get
  /// a suitable version.
  Version? packageLanguageVersion;

  late Writer writer;

  Set<Uri> analyzedUris = {};
  bool _didPrintWarning = false;

  _DriftBuildRun(this.options, this.mode, this.buildStep)
      : driver = DriftAnalysisDriver(DriftBuildBackend(buildStep), options)
          ..cacheReader = BuildCacheReader(
            buildStep,
            // The discovery and analyzer builders will have emitted IR for
            // every relevant file in a previous build step that this builder
            // has a dependency on.
            findsResolvedElementsReliably: !mode.embeddedAnalyzer,
            findsLocalElementsReliably: !mode.embeddedAnalyzer,
          );

  Future<void> run() async {
    await _warnAboutDeprecatedOptions();
    if (!await _checkForElementsToBuild()) return;

    await _checkForLanguageVersions();

    final fileResult =
        await _analyze(buildStep.inputId.uri, isEntrypoint: true);

    // For the monolithic build modes, we only generate code for databases and
    // crawl the tables from there.
    if (mode.isMonolithic && !fileResult.containsDatabaseAccessor) {
      return;
    }

    _createWriter();
    if (mode.isMonolithic) {
      await _generateMonolithic(fileResult);
    } else {
      await _generateModular(fileResult);
    }
    await _emitCode();

    if (_didPrintWarning && options.fatalWarnings) {
      throw const FatalWarningException();
    }
  }

  Future<FileState> _analyze(Uri uri, {bool isEntrypoint = false}) async {
    final result = await driver.fullyAnalyze(uri);

    // If we're doing a monolithic build, we need to warn about errors in
    // imports too.
    final printErrors =
        isEntrypoint || (mode.isMonolithic && analyzedUris.add(result.ownUri));
    if (printErrors) {
      // Only printing errors from the fileAnalysis step here. The analyzer
      // builder will print errors from earlier analysis steps.
      for (final error in result.fileAnalysis?.analysisErrors ?? const []) {
        log.warning(error);
        _didPrintWarning = true;
      }
    }

    return result;
  }

  /// Once per build, prints a warning about deprecated build options if they
  /// are applied to this builder.
  Future<void> _warnAboutDeprecatedOptions() async {
    final flags = await buildStep.fetchResource(_flags);
    if (!flags.didWarnAboutDeprecatedOptions) {
      if (options.generateConnectConstructor) {
        log.warning(
          'You enabled the `generate_connect_constructor` build option. This '
          'option is no longer necessary in drift 2.5, as a '
          '`DatabaseConnection` can now be passed to the default constructor '
          'for generated databases. Consider removing this option.',
        );
      }

      if (mode.appliesCombiningBuilderFromSourceGen &&
          options.preamble != null) {
        log.warning(
          'The `preamble` builder option has no effect on `drift_dev`. Apply '
          'it to `source_gen:combining_builder` instead: '
          'https://pub.dev/packages/source_gen#preamble',
        );
      }

      flags.didWarnAboutDeprecatedOptions = true;
    }
  }

  /// Checks if the input file contains elements drift should generate code for.
  Future<bool> _checkForElementsToBuild() async {
    if (mode.embeddedAnalyzer) {
      // Check if there are any elements defined locally that would need code
      // to be generated for this file.
      final state = await driver.findLocalElements(buildStep.inputId.uri);
      return state.definedElements.isNotEmpty;
    } else {
      // An analysis step should have already run for this asset. If we can't
      // pick up results from that, there is no code for drift to generate.
      final fromCache =
          await driver.readStoredAnalysisResult(buildStep.inputId.uri);

      if (fromCache == null) {
        // Don't do anything! There are no analysis results for this file, so
        // there's nothing for drift to generate code for.
        return false;
      }
    }

    if (mode == DriftGenerationMode.modular &&
        buildStep.inputId.extension != '.dart') {
      // For modular drift file generation, we need to know about imports which
      // are only available when discovery ran.
      final state = driver.cache.stateForUri(buildStep.inputId.uri);
      await driver.discoverIfNecessary(state);
    }

    return true;
  }

  /// Prints a warning if the used Dart version is incompatible with drift's
  /// minimal version constraints.
  Future<void> _checkForLanguageVersions() async {
    if (mode.isPartFile) {
      final library = await buildStep.inputLibrary;
      overriddenLanguageVersion = library.languageVersion.override;

      final effectiveVersion = library.languageVersion.effective;
      if (effectiveVersion < _minimalDartLanguageVersion) {
        final effective = effectiveVersion.majorMinor;
        final minimum = _minimalDartLanguageVersion.majorMinor;

        log.warning(
          'The language version of this file is Dart $effective. '
          'Drift generates code for Dart $minimum or later. Please consider '
          'raising the minimum SDK version in your pubspec.yaml to at least '
          '$minimum, or add a `// @dart=$minimum` comment at the top of this '
          'file.',
        );
      }
    }
  }

  Future<void> _generateModular(FileState entrypointState) async {
    for (final element in entrypointState.analysis.values) {
      final result = element.result;

      if (result is DriftTable) {
        TableWriter(result, writer.child()).writeInto();
      } else if (result is DriftView) {
        ViewWriter(result, writer.child(), null).write();
      } else if (result is DriftTrigger) {
        writer.leaf()
          ..writeDriftRef('Trigger')
          ..write(' get ${result.dbGetterName} => ')
          ..write(DatabaseWriter.createTrigger(writer.child(), result))
          ..writeln(';');
      } else if (result is DriftIndex) {
        writer.leaf()
          ..writeDriftRef('Index')
          ..write(' get ${result.dbGetterName} => ')
          ..write(DatabaseWriter.createIndex(writer.child(), result))
          ..writeln(';');
      } else if (result is DriftDatabase) {
        final resolved =
            entrypointState.fileAnalysis!.resolvedDatabases[result.id]!;
        final input =
            DatabaseGenerationInput(result, resolved, const {}, driver);
        DatabaseWriter(input, writer.child()).write();

        // Also write stubs for known custom functions so that the user can
        // easily register them on the database.
        FunctionStubsWriter(driver, writer.leaf()).write();
      } else if (result is DatabaseAccessor) {
        final resolved =
            entrypointState.fileAnalysis!.resolvedDatabases[result.id]!;
        final input =
            AccessorGenerationInput(result, resolved, const {}, driver);
        AccessorWriter(input, writer.child()).write();
      } else if (result is DefinedSqlQuery) {
        switch (result.mode) {
          case QueryMode.regular:
            // Ignore, this query will be made available in a generated accessor
            // class.
            break;
          case QueryMode.atCreate:
            final resolved =
                entrypointState.fileAnalysis?.resolvedQueries[result.id];

            if (resolved != null) {
              writer.leaf()
                ..writeDriftRef('OnCreateQuery')
                ..write(' get ${result.dbGetterName} => ')
                ..write(DatabaseWriter.createOnCreate(
                    writer.child(), result, resolved))
                ..writeln(';');
            }

            break;
        }
      }
    }

    ModularAccessorWriter(writer.child(), entrypointState, driver).write();
  }

  Future<void> _generateMonolithic(FileState entrypointState) async {
    for (final element in entrypointState.analysis.values) {
      final result = element.result;

      if (result is BaseDriftAccessor) {
        final resolved =
            entrypointState.fileAnalysis!.resolvedDatabases[result.id]!;

        // In the monolithic build mode, we also need to analyze all reachable
        // imports - it is needed to fully resolve triggers and indices, and we
        // should also warn about issues in those files.
        final importRoots = {
          ...resolved.knownImports,
          for (final element in resolved.availableElements)
            if (driver.cache.knownFiles.containsKey(element.id.libraryUri))
              driver.cache.knownFiles[element.id.libraryUri]!,
        };
        for (final file in driver.cache.crawlMulti(importRoots)) {
          await _analyze(file.ownUri);
        }

        var importedQueries = <DefinedSqlQuery, SqlQuery>{};

        for (final query
            in resolved.availableElements.whereType<DefinedSqlQuery>()) {
          final resolvedFile = await _analyze(query.id.libraryUri);
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
          final input = DatabaseGenerationInput(
              result, resolved, importedQueries, driver);
          DatabaseWriter(input, writer.child()).write();
        } else if (result is DatabaseAccessor) {
          final input = AccessorGenerationInput(
              result, resolved, importedQueries, driver);
          AccessorWriter(input, writer.child()).write();
        }
      }
    }
  }

  void _createWriter() {
    if (mode.isMonolithic) {
      final generationOptions = GenerationOptions(
        imports: ImportManagerForPartFiles(),
      );
      writer = Writer(options, generationOptions: generationOptions);
    } else {
      final imports = LibraryImportManager(buildStep.allowedOutputs.single.uri);
      final generationOptions = GenerationOptions(
        imports: imports,
        isModular: true,
      );
      writer = Writer(options, generationOptions: generationOptions);
      imports.linkToWriter(writer);
    }
  }

  Future<void> _emitCode() {
    final output = StringBuffer();

    if (!mode.appliesCombiningBuilderFromSourceGen) {
      final preamble = options.preamble;
      if (preamble != null) {
        output.writeln(preamble);
      }
    }

    output.writeln('// ignore_for_file: type=lint');

    if (mode == DriftGenerationMode.monolithicPart) {
      final originalFile = buildStep.inputId.pathSegments.last;

      if (overriddenLanguageVersion != null) {
        // Part files need to have the same version as the main library.
        output.writeln('// @dart=${overriddenLanguageVersion!.majorMinor}');
      }

      output.writeln('part of ${asDartLiteral(originalFile)};');
    }
    output.write(writer.writeGenerated());

    var code = output.toString();
    try {
      code = DartFormatter().format(code);
    } on FormatterException {
      log.warning('Could not format generated source. The generated code is '
          'probably invalid, and this is most likely a bug in drift_dev.');
    }

    return buildStep.writeAsString(buildStep.allowedOutputs.single, code);
  }

  static final Version _minimalDartLanguageVersion = Version(2, 13, 0);
}
