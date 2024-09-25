import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:drift_dev/src/analysis/backend.dart';
import 'package:drift_dev/src/backends/build/backend.dart';
import 'package:logging/src/logger.dart';

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

    /// @Simon
  }
}

class CustomLintBackend extends DriftBackend {
  @override
  // TODO: implement canReadDart
  bool get canReadDart => throw UnimplementedError();

  @override
  Future<AstNode?> loadElementDeclaration(Element element) {
    // TODO: implement loadElementDeclaration
    throw UnimplementedError();
  }

  @override
  // TODO: implement log
  Logger get log => throw UnimplementedError();

  @override
  Future<String> readAsString(Uri uri) {
    // TODO: implement readAsString
    throw UnimplementedError();
  }

  @override
  Future<LibraryElement> readDart(Uri uri) {
    // TODO: implement readDart
    throw UnimplementedError();
  }

  @override
  Future<Expression> resolveExpression(
      Uri context, String dartExpression, Iterable<String> imports) {
    // TODO: implement resolveExpression
    throw UnimplementedError();
  }

  @override
  Future<Element?> resolveTopLevelElement(
      Uri context, String reference, Iterable<Uri> imports) {
    // TODO: implement resolveTopLevelElement
    throw UnimplementedError();
  }

  @override
  Uri resolveUri(Uri base, String uriString) {
    // TODO: implement resolveUri
    throw UnimplementedError();
  }
}
