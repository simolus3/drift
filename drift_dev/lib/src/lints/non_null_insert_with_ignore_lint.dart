import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

final managerTypeChecker =
    TypeChecker.fromName('BaseTableManager', packageName: 'drift');
final insertStatementChecker =
    TypeChecker.fromName('InsertStatement', packageName: 'drift');
final insertOrIgnoreChecker =
    TypeChecker.fromName('InsertMode', packageName: 'drift');

class NonNullInsertWithIgnore extends DartLintRule {
  NonNullInsertWithIgnore() : super(code: _code);

  static const _code = LintCode(
    name: 'non_null_insert_with_ignore',
    problemMessage:
        '`insertReturning` and `createReturning` will throw an exception if a row isn\'t actually inserted. Use `createReturningOrNull` or `insertReturningOrNull` if you want to ignore conflicts.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(CustomLintResolver resolver, ErrorReporter reporter,
      CustomLintContext context) async {
    context.registry.addMethodInvocation(
      (node) {
        if (node.argumentList.arguments.isEmpty) return;
        switch (node.function) {
          case SimpleIdentifier func:
            if (func.name == "insertReturning" ||
                func.name == "createReturning") {
              switch (func.parent) {
                case MethodInvocation func:
                  final targetType = func.realTarget?.staticType;
                  if (targetType != null) {
                    if (managerTypeChecker.isSuperTypeOf(targetType) ||
                        insertStatementChecker.isExactlyType(targetType)) {
                      final namedArgs = func.argumentList.arguments
                          .whereType<NamedExpression>();
                      for (final arg in namedArgs) {
                        if (arg.name.label.name == "mode") {
                          switch (arg.expression) {
                            case PrefixedIdentifier mode:
                              if (mode.identifier.name == "insertOrIgnore") {
                                print("Found insertOrIgnore");
                                reporter.atNode(node, _code);
                              }
                          }
                        }
                      }
                    }
                  }
              }
            }
        }
      },
    );
  }
}
