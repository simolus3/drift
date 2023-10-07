import 'dart:io';
import 'dart:isolate';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart' as dart;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:build/build.dart';
import 'package:drift/drift.dart';
import 'package:drift_dev/src/analysis/backend.dart';
import 'package:drift_dev/src/analysis/driver/driver.dart';
import 'package:drift_dev/src/analysis/driver/error.dart';
import 'package:drift_dev/src/analysis/driver/state.dart';
import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:drift_dev/src/analysis/options.dart';
import 'package:drift_dev/src/writer/import_manager.dart';
import 'package:logging/logging.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

/// A [DriftBackend] implementation used for testing.
///
/// This backend has limited support for Dart analysis: [sourceContents] forming
/// the package `a` are available for analysis. In addition, `drift` and
/// `drift_dev` imports can be analyzed as well.
class TestBackend extends DriftBackend {
  final Map<String, String> sourceContents;
  final Iterable<String> analyzerExperiments;

  late final DriftAnalysisDriver driver;

  AnalysisContext? _dartContext;
  OverlayResourceProvider? _resourceProvider;

  TestBackend(
    Map<String, String> sourceContents, {
    DriftOptions options = const DriftOptions.defaults(),
    this.analyzerExperiments = const Iterable.empty(),
  }) : sourceContents = {
          for (final entry in sourceContents.entries)
            AssetId.parse(entry.key).uri.toString(): entry.value,
        } {
    driver = DriftAnalysisDriver(this, options, isTesting: true);
  }

  factory TestBackend.inTest(
    Map<String, String> sourceContents, {
    DriftOptions options = const DriftOptions.defaults(),
    Iterable<String> analyzerExperiments = const Iterable.empty(),
  }) {
    final backend = TestBackend(sourceContents,
        options: options, analyzerExperiments: analyzerExperiments);
    addTearDown(backend.dispose);

    return backend;
  }

  static Future<FileState> analyzeSingle(String content,
      {String asset = 'a|lib/a.drift',
      DriftOptions options = const DriftOptions.defaults()}) {
    final assetId = AssetId.parse(asset);
    final backend = TestBackend.inTest({asset: content}, options: options);
    return backend.driver.fullyAnalyze(assetId.uri);
  }

  void expectNoErrors() {
    for (final file in driver.cache.knownFiles.values) {
      expect(file.allErrors, isEmpty, reason: 'Error in ${file.ownUri}');
    }
  }

  String _pathFor(Uri uri) {
    if (uri.scheme == 'package') {
      final package = uri.pathSegments.first;
      final path =
          p.url.joinAll(['/$package/lib', ...uri.pathSegments.skip(1)]);

      return path;
    }

    return uri.path;
  }

  Future<void> _setupDartAnalyzer() async {
    final provider = _resourceProvider =
        OverlayResourceProvider(PhysicalResourceProvider.INSTANCE);

    // Analyze example sources against the drift sources from the current
    // drift_dev test runner.
    final uri = await Isolate.packageConfig;
    final hostConfig =
        PackageConfig.parseBytes(await File.fromUri(uri!).readAsBytes(), uri);
    final testConfig = PackageConfig([
      ...hostConfig.packages,
      Package('a', Uri.directory('/a/'), packageUriRoot: Uri.parse('lib/')),
    ]);

    // Write package config used to analyze dummy sources
    final configBuffer = StringBuffer();
    PackageConfig.writeString(testConfig, configBuffer);
    provider.setOverlay('/a/.dart_tool/package_config.json',
        content: configBuffer.toString(), modificationStamp: 1);

    // Also put sources into the overlay:
    sourceContents.forEach((key, value) {
      final path = _pathFor(Uri.parse(key));
      provider.setOverlay(path, content: value, modificationStamp: 1);
    });

    if (analyzerExperiments.isNotEmpty) {
      final experiments = analyzerExperiments.join(', ');
      provider.setOverlay(
        '/a/analysis_options.yaml',
        content: 'analyzer: {enable-experiment: [$experiments]}',
        modificationStamp: 1,
      );
    }

    final collection = AnalysisContextCollection(
      includedPaths: ['/a'],
      resourceProvider: provider,
    );

    _dartContext = collection.contexts.single;
  }

  Future<void> ensureHasDartAnalyzer() async {
    if (_dartContext == null) {
      await _setupDartAnalyzer();
    }
  }

  @override
  Logger get log => Logger.root;

  @override
  Uri resolveUri(Uri base, String uriString) {
    return base.resolve(uriString);
  }

  @override
  Future<String> readAsString(Uri uri) async {
    return sourceContents[uri.toString()] ??
        (throw StateError('No source for $uri'));
  }

  @override
  Future<dart.Expression> resolveExpression(
      Uri context, String dartExpression, Iterable<String> imports) async {
    final fileContents = StringBuffer();
    for (final import in imports) {
      fileContents.writeln("import '$import';");
    }
    fileContents.writeln('var field = $dartExpression;');
    final path = '${_pathFor(context)}.exp.dart';

    await _setupDartAnalyzer();
    final resourceProvider = _resourceProvider!;
    final analysisContext = _dartContext!;

    resourceProvider.setOverlay(path,
        content: fileContents.toString(), modificationStamp: 1);

    try {
      final result =
          await analysisContext.currentSession.getResolvedLibrary(path);

      if (result is ResolvedLibraryResult) {
        final unit = result.units.single.unit;
        final field =
            unit.declarations.single as dart.TopLevelVariableDeclaration;

        return field.variables.variables.single.initializer!;
      } else {
        throw CannotReadExpressionException('Could not resolve temp file');
      }
    } finally {
      resourceProvider.removeOverlay(path);
    }
  }

  @override
  Future<Element?> resolveTopLevelElement(
      Uri context, String reference, Iterable<Uri> imports) async {
    final fileContents = StringBuffer();
    for (final import in imports) {
      fileContents.writeln("import '$import';");
    }

    final path = '${_pathFor(context)}.imports.dart';

    await _setupDartAnalyzer();

    final resourceProvider = _resourceProvider!;
    final analysisContext = _dartContext!;

    resourceProvider.setOverlay(path,
        content: fileContents.toString(), modificationStamp: 1);

    try {
      final result =
          await analysisContext.currentSession.getResolvedLibrary(path);

      if (result is ResolvedLibraryResult) {
        final lookup = result.element.scope.lookup(reference);
        return lookup.getter;
      }
    } finally {
      resourceProvider.removeOverlay(path);
    }

    return null;
  }

  @override
  Future<LibraryElement> readDart(Uri uri) async {
    await ensureHasDartAnalyzer();
    final result =
        await _dartContext!.currentSession.getLibraryByUri(uri.toString());

    return (result as LibraryElementResult).element;
  }

  @override
  Future<dart.AstNode?> loadElementDeclaration(Element element) async {
    final library = element.library;
    if (library == null) return null;

    final info = await library.session.getResolvedLibraryByElement(library);
    if (info is ResolvedLibraryResult) {
      return info.getElementDeclaration(element)?.node;
    } else {
      return null;
    }
  }

  Future<void> dispose() async {}

  Future<FileState> discoverLocalElements(String uriString) {
    return driver.findLocalElements(Uri.parse(uriString));
  }

  Future<FileState> analyze(String uriString) {
    return driver.fullyAnalyze(Uri.parse(uriString));
  }
}

class TestImportManager extends ImportManager {
  final Map<Uri, String> importAliases = {};

  @override
  String? prefixFor(Uri definitionUri, String elementName) {
    return importAliases.putIfAbsent(
        definitionUri, () => 'i${importAliases.length}');
  }
}

Matcher get hasNoErrors =>
    isA<FileState>().having((e) => e.allErrors, 'allErrors', isEmpty);

Matcher returnsColumns(Map<String, DriftSqlType> columns) {
  return _HasInferredColumnTypes(columns);
}

class _HasInferredColumnTypes extends CustomMatcher {
  _HasInferredColumnTypes(dynamic expected)
      : super('Select query with inferred columns', 'columns', expected);

  @override
  Object? featureValueOf(dynamic actual) {
    if (actual is! SqlSelectQuery) {
      return actual;
    }

    final resultSet = actual.resultSet;
    return {
      for (final column in resultSet.scalarColumns)
        column.name: column.sqlType.builtin
    };
  }
}

TypeMatcher<DriftAnalysisError> isDriftError(dynamic message) {
  return isA<DriftAnalysisError>().having((e) => e.message, 'message', message);
}

final _version = RegExp(r'\d\.\d+\.\d+');

String? requireDart(String minimalVersion) {
  final version =
      Version.parse(_version.firstMatch(Platform.version)!.group(0)!);
  final minimal = Version.parse(minimalVersion);

  if (version < minimal) {
    return 'This test requires SDK version $minimalVersion or later';
  } else {
    return null;
  }
}

extension DriftErrorMatchers on TypeMatcher<DriftAnalysisError> {
  TypeMatcher<DriftAnalysisError> withSpan(lexemeMatcher) {
    return having((e) => e.span?.text, 'span.text', lexemeMatcher);
  }
}
