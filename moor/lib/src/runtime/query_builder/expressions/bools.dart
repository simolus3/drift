part of '../query_builder.dart';

/// Defines operations on boolean values.
extension BooleanExpressionOperators on Expression<bool, BoolType> {
  /// Negates this boolean expression. The returned expression is true if
  /// `this` is false, and vice versa.
  Expression<bool, BoolType> not() => _NotExpression(this);

  /// Returns an expression that is true iff both `this` and [other] are true.
  Expression<bool, BoolType> operator &(Expression<bool, BoolType> other) {
    return _BaseInfixOperator(this, 'AND', other, precedence: Precedence.and);
  }

  /// Returns an expression that is true if `this` or [other] are true.
  Expression<bool, BoolType> operator |(Expression<bool, BoolType> other) {
    return _BaseInfixOperator(this, 'OR', other, precedence: Precedence.or);
  }
}

class _NotExpression extends Expression<bool, BoolType> {
  final Expression<bool, BoolType> inner;

  _NotExpression(this.inner);

  @override
  Precedence get precedence => Precedence.unary;

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write('NOT ');
    writeInner(context, inner);
  }

  @override
  int get hashCode => inner.hashCode << 1;

  @override
  bool operator ==(dynamic other) {
    return other is _NotExpression && other.inner == inner;
  }
}
