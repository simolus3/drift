import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

final tableChecker = TypeChecker.fromName('Table', packageName: 'drift');
final databaseConnectionUserChecker =
    TypeChecker.fromName('DatabaseConnectionUser', packageName: 'drift');
final columnBuilderChecker =
    TypeChecker.fromName('ColumnBuilder', packageName: 'drift');

bool inTransactionBlock(AstNode node) {
  return node.thisOrAncestorMatching(
        (method) {
          if (method is! MethodInvocation) return false;

          final methodElement = method.methodName.staticElement;
          if (methodElement is! MethodElement ||
              methodElement.name != 'transaction') return false;

          final enclosingElement = methodElement.enclosingElement;
          if (enclosingElement is! ClassElement ||
              !databaseConnectionUserChecker.isExactly(enclosingElement)) {
            return false;
          }
          return true;
        },
      ) !=
      null;
}

class UnawaitedFuturesInTransaction extends DartLintRule {
  UnawaitedFuturesInTransaction() : super(code: _code);

  static const _code = LintCode(
    name: 'unawaited_futures_in_transaction',
    problemMessage:
        'All futures in a transaction should be awaited to ensure that all operations are completed before the transaction is closed.',
    errorSeverity: ErrorSeverity.ERROR,
  );
  @override
  void run(CustomLintResolver resolver, ErrorReporter reporter,
      CustomLintContext context) {
    context.registry.addVariableDeclarationStatement((node) {
      if (inTransactionBlock(node)) {
        for (var variable in node.variables.variables) {
          final type = variable.declaredElement?.type;
          if (type == null || !type.isDartAsyncFuture) continue;
          reporter.atNode(variable, _code);
        }
      }
    });
    context.registry.addExpressionStatement((statement) {
      if (inTransactionBlock(statement)) {
        final expression = statement.expression;
        print(statement);
        print(expression);
        print(expression.runtimeType);

        if (expression is! MethodInvocation) return;
        final element = expression.methodName.staticElement;
        if (element is! MethodElement) return;
        if (element.returnType.isDartAsyncFuture) {
          reporter.atNode(expression, _code);
        }
      }
    });
  }
}
