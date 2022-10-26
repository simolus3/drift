import 'dart:io';
import 'dart:isolate';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
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
import 'package:drift_dev/src/analyzer/options.dart';
import 'package:logging/logging.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// A [DriftBackend] implementation used for testing.
///
/// This backend has limited support for Dart analysis: [sourceContents] forming
/// the package `a` are available for analysis. In addition, `drift` and
/// `drift_dev` imports can be analyzed as well.
class TestBackend extends DriftBackend {
  final Map<String, String> sourceContents;

  late final DriftAnalysisDriver driver;

  AnalysisContext? _dartContext;

  TestBackend(Map<String, String> sourceContents,
      {DriftOptions options = const DriftOptions.defaults()})
      : sourceContents = {
          for (final entry in sourceContents.entries)
            AssetId.parse(entry.key).uri.toString(): entry.value,
        } {
    driver = DriftAnalysisDriver(this, options);
  }

  factory TestBackend.inTest(Map<String, String> sourceContents,
      {DriftOptions options = const DriftOptions.defaults()}) {
    final backend = TestBackend(sourceContents, options: options);
    addTearDown(backend.dispose);

    return backend;
  }

  void expectNoErrors() {
    for (final file in driver.cache.knownFiles.values) {
      expect(file.allErrors, isEmpty, reason: 'Error in ${file.ownUri}');
    }
  }

  Future<void> _setupDartAnalyzer() async {
    final provider = OverlayResourceProvider(PhysicalResourceProvider.INSTANCE);

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
      final uri = Uri.parse(key);

      if (uri.scheme == 'package') {
        final package = uri.pathSegments.first;
        final path =
            p.url.joinAll(['/$package/lib', ...uri.pathSegments.skip(1)]);

        provider.setOverlay(path, content: value, modificationStamp: 1);
      }
    });

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
  Future<Never> resolveExpression(
      Uri context, String dartExpression, Iterable<String> imports) async {
    throw UnsupportedError('Not currently supported in tests');
  }

  @override
  Future<LibraryElement> readDart(Uri uri) async {
    await ensureHasDartAnalyzer();
    final result =
        await _dartContext!.currentSession.getLibraryByUri(uri.toString());

    return (result as LibraryElementResult).element;
  }

  @override
  Future<AstNode?> loadElementDeclaration(Element element) async {
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

  Future<FileState> analyze(String uriString) {
    return driver.fullyAnalyze(Uri.parse(uriString));
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
      for (final column in resultSet.columns) column.name: column.sqlType
    };
  }
}

TypeMatcher<DriftAnalysisError> isDriftError(dynamic message) {
  return isA<DriftAnalysisError>().having((e) => e.message, 'message', message);
}

extension DriftErrorMatchers on TypeMatcher<DriftAnalysisError> {
  TypeMatcher<DriftAnalysisError> withSpan(lexemeMatcher) {
    return having((e) => e.span?.text, 'span.text', lexemeMatcher);
  }
}
