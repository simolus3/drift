import 'package:analyzer/dart/analysis/results.dart';
import 'package:meta/meta.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:moor_generator/src/analyzer/errors.dart';
import 'package:moor_generator/src/analyzer/session.dart';
import 'package:moor_generator/src/model/specified_column.dart';

part 'column_parser.dart';

class MoorDartParser {
  final DartTask task;

  MoorDartParser(this.task);

  @visibleForTesting
  Expression returnExpressionOfMethod(MethodDeclaration method) {
    final body = method.body;

    if (!(body is ExpressionFunctionBody)) {
      task.reportError(ErrorInDartCode(
        affectedElement: method.declaredElement,
        severity: Severity.criticalError,
        message:
            'This method must have an expression body (user => instead of {return ...})',
      ));
      return null;
    }

    return (method.body as ExpressionFunctionBody).expression;
  }

  Future<ElementDeclarationResult> loadElementDeclaration(
      Element element) async {
    final resolvedLibrary = await element.library.session
        .getResolvedLibraryByElement(element.library);

    return resolvedLibrary.getElementDeclaration(element);
  }
}
