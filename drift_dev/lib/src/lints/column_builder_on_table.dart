// import 'package:analyzer/dart/ast/ast.dart';
// import 'package:analyzer/dart/element/nullability_suffix.dart';
// import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class ColumnBuilderOnTable extends DartLintRule {
  ColumnBuilderOnTable() : super(code: _code);

  static const _code = LintCode(
    name: 'column_builder_on_table',
    problemMessage:
        'This column declaration is missing an extra set of parentheses at the end'
        ' of the column builder. This is likely a mistake.'
        ' Add a pair of parentheses to the end of the column builder.',
    errorSeverity: ErrorSeverity.ERROR,
  );
  @override
  void run(CustomLintResolver resolver, ErrorReporter reporter,
      CustomLintContext context) {
    print("Hi");
    context.registry.addVariableDeclaration(
      (node) {
        reporter.atNode(node, _code);
      },
    );
  }
}
