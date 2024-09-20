// import 'package:analyzer/dart/ast/ast.dart';
// import 'package:analyzer/dart/element/nullability_suffix.dart';
// import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

final tableChecker = TypeChecker.fromName('Table', packageName: 'drift');
final columnBuilderChecker =
    TypeChecker.fromName('ColumnBuilder', packageName: 'drift');

class ColumnBuilderOnTable extends DartLintRule {
  ColumnBuilderOnTable() : super(code: _code);

  static const _code = LintCode(
    name: 'column_builder_on_table',
    problemMessage:
        'This column declaration is missing a set of parentheses at the end'
        ' of the column builder. This is likely a mistake.'
        ' Add a pair of parentheses to the end of the column builder.',
    errorSeverity: ErrorSeverity.ERROR,
  );
  @override
  void run(CustomLintResolver resolver, ErrorReporter reporter,
      CustomLintContext context) {
    context.registry.addVariableDeclaration(
      (node) {
        // Extract the element from the node
        final element = node.declaredElement;

        // Extract the type of the declared element
        final type = element?.type;

        if (type == null || element is! FieldElement) {
          return;
        }
        // Check if the field element is a field of a class that extends Table and has a type of ColumnBuilder
        if (tableChecker.isSuperOf(element.enclosingElement) &&
            columnBuilderChecker.isExactlyType(type)) {
          reporter.atNode(node, _code);
        }
      },
    );
  }
}
