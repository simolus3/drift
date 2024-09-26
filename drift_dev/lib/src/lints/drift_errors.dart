import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:drift_dev/src/analysis/backend.dart';
import 'package:drift_dev/src/analysis/options.dart';
import 'package:logging/logging.dart';

import '../analysis/driver/driver.dart';

final columnBuilderChecker =
    TypeChecker.fromName('DriftDatabase', packageName: 'drift');

class DriftBuildErrors extends DartLintRule {
  DriftBuildErrors() : super(code: _code);

  static const _code = LintCode(
    name: 'unawaited_futures_in_transaction',
    problemMessage:
        'All futures in a transaction should be awaited to ensure that all operations are completed before the transaction is closed.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(CustomLintResolver resolver, ErrorReporter reporter,
      CustomLintContext context) async {
    final unit = await resolver.getResolvedUnitResult();
    final backend = CustomLintBackend(unit.session);
    final driver = DriftAnalysisDriver(backend, const DriftOptions.defaults());

    final file = await driver.fullyAnalyze(unit.uri);
    print(
        'test? - ${unit.uri} - ${file.allErrors.length} - ${file.analysis.length}');
    for (final error in file.allErrors) {
      if (error.span case final span?) {
        reporter.reportErrorForSpan(_code, span);
      }
    }
  }
}

class CustomLintBackend extends DriftBackend {
  @override
  final Logger log = Logger('drift_dev.CustomLintBackend');
  final AnalysisSession session;

  CustomLintBackend(this.session);

  @override
  bool get canReadDart => true;

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

  @override
  Future<String> readAsString(Uri uri) async {
    final file = session.getFile(uri.path);

    if (file is FileResult) {
      return file.content;
    }

    throw FileSystemException('Not a file result: $file');
  }

  @override
  Future<LibraryElement> readDart(Uri uri) async {
    final result = await session.getLibraryByUri(uri.toString());
    if (result is LibraryElementResult) {
      return result.element;
    }

    throw NotALibraryException(uri);
  }

  @override
  Future<Expression> resolveExpression(
      Uri context, String dartExpression, Iterable<String> imports) {
    throw CannotReadExpressionException('Not supported at the moment');
  }

  @override
  Future<Element?> resolveTopLevelElement(
      Uri context, String reference, Iterable<Uri> imports) {
    throw UnimplementedError();
  }

  @override
  Uri resolveUri(Uri base, String uriString) => base.resolve(uriString);
}
