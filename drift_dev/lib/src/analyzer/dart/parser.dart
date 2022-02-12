import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:drift_dev/moor_generator.dart';
import 'package:drift_dev/src/analyzer/data_class.dart';
import 'package:drift_dev/src/analyzer/errors.dart';
import 'package:drift_dev/src/analyzer/runner/steps.dart';
import 'package:drift_dev/src/utils/exception.dart';
import 'package:drift_dev/src/utils/type_utils.dart';
import 'package:meta/meta.dart';
import 'package:recase/recase.dart';
import 'package:source_gen/source_gen.dart';
import 'package:sqlparser/sqlparser.dart' show ReferenceAction;

import '../custom_row_class.dart';

part 'column_parser.dart';
part 'table_parser.dart';
part 'use_dao_parser.dart';
part 'use_moor_parser.dart';
part 'view_parser.dart';

class MoorDartParser {
  final ParseDartStep step;

  late ColumnParser _columnParser;
  late TableParser _tableParser;
  late ViewParser _viewParser;

  MoorDartParser(this.step) {
    _columnParser = ColumnParser(this);
    _tableParser = TableParser(this);
    _viewParser = ViewParser(this);
  }

  Future<MoorTable?> parseTable(ClassElement classElement) {
    return _tableParser.parseTable(classElement);
  }

  Future<MoorView?> parseView(
      ClassElement classElement, List<MoorTable> tables) {
    return _viewParser.parseView(classElement, tables);
  }

  /// Attempts to parse the column created from the Dart getter.
  ///
  /// When the column is invalid, an error will be logged and `null` is
  /// returned.
  Future<MoorColumn?> parseColumn(
      MethodDeclaration declaration, Element element) {
    return Future.value(_columnParser.parse(declaration, element));
  }

  @visibleForTesting
  Expression? returnExpressionOfMethod(MethodDeclaration method) {
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

  Future<AstNode?> loadElementDeclaration(Element element) {
    return step.task.backend.loadElementDeclaration(element);
  }

  String? readStringLiteral(Expression expression, void Function() onError) {
    if (expression is! StringLiteral) {
      onError();
    } else {
      final value = expression.stringValue;
      if (value == null) {
        onError();
      } else {
        return value;
      }
    }

    return null;
  }

  int? readIntLiteral(Expression expression, void Function() onError) {
    if (expression is! IntegerLiteral) {
      onError();
      // ignore: avoid_returning_null
      return null;
    } else {
      return expression.value;
    }
  }

  Expression? findNamedArgument(ArgumentList args, String argName) {
    final argument = args.arguments.singleWhereOrNull(
      (e) => e is NamedExpression && e.name.label.name == argName,
    ) as NamedExpression?;

    return argument?.expression;
  }
}
