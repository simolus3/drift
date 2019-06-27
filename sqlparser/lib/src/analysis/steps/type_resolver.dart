part of '../analysis.dart';

const _comparisons = [
  TokenType.less,
  TokenType.lessEqual,
  TokenType.more,
  TokenType.moreEqual,
  TokenType.equal,
  TokenType.doubleEqual,
  TokenType.exclamationEqual,
  TokenType.lessMore,
];

class TypeResolvingVisitor extends RecursiveVisitor<void> {
  final AnalysisContext context;
  TypeResolver get types => context.types;

  TypeResolvingVisitor(this.context);

  @override
  void visitSelectStatement(SelectStatement e) {
    if (e.where != null) {
      context.types.suggestBool(e.where);
    }

    visitChildren(e);
  }

  @override
  void visitResultColumn(ResultColumn e) {
    visitChildren(e);
  }

  @override
  void visitFunction(FunctionExpression e) {
    // todo handle function calls
    visitChildren(e);
  }

  @override
  void visitLimit(Limit e) {
    if (e.count != null) {
      types.suggestType(e.count, const SqlType.int());
    }
    if (e.offset != null) {
      types.suggestType(e.offset, const SqlType.int());
    }

    visitChildren(e);
  }

  @override
  void visitBinaryExpression(BinaryExpression e) {
    final operator = e.operator.type;
    if (operator == TokenType.doublePipe) {
      // string concatenation: Will return a string, makes most sense with a
      // string.
      types
        ..forceType(e, const SqlType.text())
        ..suggestType(e.left, const SqlType.text())
        ..suggestType(e.right, const SqlType.text());
    } else if (operator == TokenType.and || operator == TokenType.or) {
      types
        ..suggestBool(e.left)
        ..suggestBool(e.right)
        ..forceType(e, const SqlType.int())
        ..addTypeHint(e, const IsBoolean());
    } else if (_comparisons.contains(operator)) {
      types
        ..suggestBool(e)
        ..suggestSame(e.left, e.right);
    } else {
      // arithmetic operator
      types
        ..forceType(e, const AnyNumericType())
        ..suggestType(e.right, const AnyNumericType())
        ..suggestType(e.left, const AnyNumericType());
    }

    visitChildren(e);
  }

  @override
  void visitUnaryExpression(UnaryExpression e) {
    final operator = e.operator.type;
    if (operator == TokenType.plus) {
      // unary type does nothing, just returns the value
      types.suggestSame(e, e.inner);
    } else if (operator == TokenType.minus) {
      types
        ..forceType(e, const AnyNumericType())
        ..suggestType(e.inner, const AnyNumericType());
    }

    visitChildren(e);
  }

  @override
  void visitLiteral(Literal e) {
    if (e is NullLiteral) {
      types.forceType(e, const SqlType.nullType());
    } else if (e is NumericLiteral) {
      if (e.number.toInt() == e.number) {
        types.forceType(e, const SqlType.int());
      } else {
        types.forceType(e, const SqlType.real());
      }

      if (e is BooleanLiteral) {
        types.addTypeHint(e, const IsBoolean());
      }
    }

    visitChildren(e);
  }
}
