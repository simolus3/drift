// import 'package:analyzer/dart/ast/ast.dart';
// import 'package:analyzer/dart/element/nullability_suffix.dart';
// import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:custom_lint_core/src/node_lint_visitor.dart';
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
      // If this variable declaration is not inside a transaction block, return
      if (inTransactionBlock(node)) {
        for (var variable in node.variables.variables) {
          final type = variable.declaredElement?.type;
          if (type == null || !type.isDartAsyncFuture) continue;
          reporter.atNode(variable, _code);
        }
      }
    });
    context.registry.addExpressionStatement((statement) {
      // If this variable declaration is not inside a transaction block, return
      if (inTransactionBlock(statement)) {
        final expression = statement.expression;
        if (expression is! MethodInvocation) return;
        final element = expression.methodName.staticElement;
        if (element is! MethodElement) return;
        if (element.returnType.isDartAsyncFuture) {
          reporter.atNode(expression, _code);
        }
      }
    });
    // context.registry.addInstanceCreationExpression((statement) {
    //   if (inTransactionBlock(statement)) {
    //     if (statement
    //             .constructorName.staticElement?.returnType.isDartAsyncFuture ??
    //         false) {
    //       reporter.atNode(statement, _code);
    //     }
    //   }
    // If this variable declaration is not inside a transaction block, return
    // if (inTransactionBlock(statement)) {
    //   final expression = statement.expression;
    //   if (expression is! MethodInvocation) return;
    //   final element = expression.methodName.staticElement;
    //   if (element is! MethodElement) return;
    //   if (element.returnType.isDartAsyncFuture) {
    //     reporter.atNode(expression, _code);
    //   }
    // }
    // });
    // context.registry.addArgumentList(
    //   (node) {
    //     final method = node.parent;
    //     if (method is! MethodInvocation) return;

    //     final methodElement = method.methodName.staticElement;
    //     if (methodElement is! MethodElement) return;

    //     // Verify that the method is a transaction method
    //     if (methodElement.name != 'transaction') return;

    //     // Verify that the method is called on a DatabaseConnectionUser
    //     final enclosingElement = methodElement.enclosingElement;
    //     if (enclosingElement is! ClassElement) return;

    //     // Get the 1st argument of the transaction method
    //     final classback = node.arguments.firstOrNull;
    //     if (classback is! FunctionExpression) return;

    //     // Get the body of the function
    //     final body = classback.body;
    //     if (body is! BlockFunctionBody) return;
    //     for (var statement in body.block.statements) {
    //       if (statement is ExpressionStatement) {
    //         final expression = statement.expression;
    //         if (expression is! MethodInvocation) continue;
    //         // If the return type of the method is a Future, then the method should have been awaited
    //         final element = expression.methodName.staticElement;
    //         if (element is! MethodElement) continue;
    //         if (element.returnType.isDartAsyncFuture) {
    //           reporter.atNode(expression, _code);
    //         }
    //       } else if (statement is VariableDeclarationStatement) {
    //         for (var variable in statement.variables.variables) {
    //           final type = variable.declaredElement?.type;
    //           if (type == null || !type.isDartAsyncFuture) continue;
    //           reporter.atNode(variable, _code);
    //         }
    //       }
    //     }
    //   },
    // );
  }
}
