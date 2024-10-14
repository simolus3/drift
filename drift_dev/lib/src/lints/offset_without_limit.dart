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

final managerTypeChecker =
    TypeChecker.fromName('BaseTableManager', packageName: 'drift');

class OffsetWithoutLimit extends DartLintRule {
  OffsetWithoutLimit() : super(code: _code);

  static const _code = LintCode(
    name: 'offset_without_limit',
    problemMessage: 'Using offset without a limit will result in a ',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(CustomLintResolver resolver, ErrorReporter reporter,
      CustomLintContext context) async {
    context.registry.addMethodInvocation(
      (node) {
        if (node.argumentList.arguments.isEmpty) return;
        final func = _typeCheck<SimpleIdentifier>(node.function);

        if (func?.name == "get" || func?.name == "watch") {
          final target = _typeCheck<PrefixedIdentifier>(node.target);
          final managerGetter =
              _typeCheck<PropertyAccessorElement>(target?.staticElement);
          if (managerGetter != null) {
            if (managerTypeChecker.isSuperTypeOf(managerGetter.returnType)) {
              final namedArgs =
                  node.argumentList.arguments.whereType<NamedExpression>();
              if (namedArgs
                      .every((element) => element.name.label.name != "limit") &&
                  namedArgs
                      .any((element) => element.name.label.name == "offset")) {
                reporter.atNode(node, _code);
              }
            }
          }
        }
      },
    );
  }
}

T? _typeCheck<T>(i) {
  return i is T ? i : null;
}
