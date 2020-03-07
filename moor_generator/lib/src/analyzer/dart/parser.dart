import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:meta/meta.dart';
import 'package:moor/sqlite_keywords.dart';
import 'package:moor_generator/moor_generator.dart';
import 'package:moor_generator/src/analyzer/errors.dart';
import 'package:moor_generator/src/analyzer/runner/steps.dart';
import 'package:moor_generator/src/model/declarations/declaration.dart';
import 'package:moor_generator/src/model/used_type_converter.dart';
import 'package:moor_generator/src/utils/names.dart';
import 'package:moor_generator/src/utils/type_utils.dart';
import 'package:recase/recase.dart';
import 'package:source_gen/source_gen.dart';

part 'column_parser.dart';
part 'table_parser.dart';
part 'use_dao_parser.dart';
part 'use_moor_parser.dart';

class MoorDartParser {
  final ParseDartStep step;

  ColumnParser _columnParser;
  TableParser _tableParser;

  MoorDartParser(this.step) {
    _columnParser = ColumnParser(this);
    _tableParser = TableParser(this);
  }

  Future<MoorTable> parseTable(ClassElement classElement) {
    return _tableParser.parseTable(classElement);
  }

  Future<MoorColumn> parseColumn(
      MethodDeclaration declaration, Element element) {
    return Future.value(_columnParser.parse(declaration, element));
  }

  @visibleForTesting
  Expression returnExpressionOfMethod(MethodDeclaration method) {
    final body = method.body;

    if (body is! ExpressionFunctionBody) {
      step.reportError(ErrorInDartCode(
        affectedElement: method.declaredElement,
        severity: Severity.criticalError,
        message: 'This method must have an expression body '
            '(use => instead of {return ...})',
      ));
      return null;
    }

    return (method.body as ExpressionFunctionBody).expression;
  }

  Future<ElementDeclarationResult> loadElementDeclaration(Element element) {
    return step.task.backend.loadElementDeclaration(element);
  }

  String readStringLiteral(Expression expression, void Function() onError) {
    if (expression is! StringLiteral) {
      onError();
    } else {
      final value = (expression as StringLiteral).stringValue;
      if (value == null) {
        onError();
      } else {
        return value;
      }
    }

    return null;
  }

  int readIntLiteral(Expression expression, void Function() onError) {
    if (expression is! IntegerLiteral) {
      onError();
      // ignore: avoid_returning_null
      return null;
    } else {
      return (expression as IntegerLiteral).value;
    }
  }

  Expression findNamedArgument(ArgumentList args, String argName) {
    final argument = args.arguments.singleWhere(
        (e) => e is NamedExpression && e.name.label.name == argName,
        orElse: () => null) as NamedExpression;

    return argument?.expression;
  }
}
