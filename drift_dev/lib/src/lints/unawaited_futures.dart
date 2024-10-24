import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

final tableChecker = TypeChecker.fromName('Table', packageName: 'drift');
final databaseConnectionUserChecker =
    TypeChecker.fromName('DatabaseConnectionUser', packageName: 'drift');
final columnBuilderChecker =
    TypeChecker.fromName('ColumnBuilder', packageName: 'drift');
final migrationStrategyChecker =
    TypeChecker.fromName('MigrationStrategy', packageName: 'drift');

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

    context.registry.addExpressionStatement((node) {
      node.accept(
          _Visitor(this, reporter, _code, additionalCheck: inTransactionBlock));
    });
    context.registry.addCascadeExpression((node) {
      node.accept(
          _Visitor(this, reporter, _code, additionalCheck: inTransactionBlock));
    });
    context.registry.addInterpolationExpression((node) {
      node.accept(
          _Visitor(this, reporter, _code, additionalCheck: inTransactionBlock));
    });
  }
}

class UnawaitedFuturesInMigration extends DartLintRule {
  UnawaitedFuturesInMigration() : super(code: _code);

  static const _code = LintCode(
    name: 'unawaited_futures_in_migration',
    problemMessage:
        'All futures in a migrations should be awaited to ensure that all operations are completed before the other opperations are performed.',
    errorSeverity: ErrorSeverity.ERROR,
  );
  @override
  void run(CustomLintResolver resolver, ErrorReporter reporter,
      CustomLintContext context) {
    bool inMigrationBlock(AstNode node) {
      return node.thisOrAncestorMatching((node) =>
              (node is InstanceCreationExpression &&
                  node.staticType != null &&
                  migrationStrategyChecker.isExactlyType(node.staticType!))) !=
          null;
    }

    context.registry.addExpressionStatement((node) {
      node.accept(
          _Visitor(this, reporter, _code, additionalCheck: inMigrationBlock));
    });
    context.registry.addCascadeExpression((node) {
      node.accept(
          _Visitor(this, reporter, _code, additionalCheck: inMigrationBlock));
    });
    context.registry.addInterpolationExpression((node) {
      node.accept(
          _Visitor(this, reporter, _code, additionalCheck: inMigrationBlock));
    });
  }
}

// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Source: https://github.com/dart-lang/sdk/blob/main/pkg/linter/lib/src/rules/unawaited_futures.dart
/// A visitor which will report any future that is not awaited.
/// If an [additionalCheck] is provided, it will be used to check if the future should be reported
class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final ErrorReporter reporter;
  final LintCode code;
  final bool Function(AstNode node) additionalCheck;

  _Visitor(this.rule, this.reporter, this.code,
      {required this.additionalCheck});

  @override
  void visitCascadeExpression(CascadeExpression node) {
    var sections = node.cascadeSections;
    for (var i = 0; i < sections.length; i++) {
      _visit(sections[i]);
    }
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    var expr = node.expression;
    if (expr is AssignmentExpression) return;

    var type = expr.staticType;
    if (type == null) {
      return;
    }
    if (type.implementsInterface('Future', 'dart.async')) {
      // Ignore a couple of special known cases.
      if (_isFutureDelayedInstanceCreationWithComputation(expr) ||
          _isMapPutIfAbsentInvocation(expr)) {
        return;
      }

      if (_isEnclosedInAsyncFunctionBody(node) && additionalCheck(node)) {
        // Future expression statement that isn't awaited in an async function:
        // while this is legal, it's a very frequent sign of an error.

        reporter.atNode(node, code);
      }
    }
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    _visit(node.expression);
  }

  bool _isEnclosedInAsyncFunctionBody(AstNode node) {
    var enclosingFunctionBody = node.thisOrAncestorOfType<FunctionBody>();
    return enclosingFunctionBody?.isAsynchronous ?? false;
  }

  /// Detects `Future.delayed(duration, [computation])` creations with a
  /// computation.
  bool _isFutureDelayedInstanceCreationWithComputation(Expression expr) =>
      expr is InstanceCreationExpression &&
      (expr.staticType?.isDartAsyncFuture ?? false) &&
      expr.constructorName.name?.name == 'delayed' &&
      expr.argumentList.arguments.length == 2;

  bool _isMapClass(Element? e) =>
      e is ClassElement && e.name == 'Map' && e.library.name == 'dart.core';

  /// Detects Map.putIfAbsent invocations.
  bool _isMapPutIfAbsentInvocation(Expression expr) =>
      expr is MethodInvocation &&
      expr.methodName.name == 'putIfAbsent' &&
      _isMapClass(expr.methodName.staticElement?.enclosingElement);

  void _visit(Expression expr) {
    if ((expr.staticType?.isDartAsyncFuture ?? false) &&
        _isEnclosedInAsyncFunctionBody(expr) &&
        expr is! AssignmentExpression &&
        additionalCheck(expr)) {
      reporter.atNode(expr, code);
    }
  }
}

extension DartTypeExtension on DartType? {
  bool implementsInterface(String interface, String library) {
    var self = this;
    if (self is! InterfaceType) {
      return false;
    }
    bool predicate(InterfaceType i) => i.isSameAs(interface, library);
    var element = self.element;
    return predicate(self) ||
        !element.isSynthetic && element.allSupertypes.any(predicate);
  }

  /// Returns whether `this` is the same element as [interface], declared in
  /// [library].
  bool isSameAs(String? interface, String? library) {
    var self = this;
    return self is InterfaceType &&
        self.element.name == interface &&
        self.element.library.name == library;
  }
}
