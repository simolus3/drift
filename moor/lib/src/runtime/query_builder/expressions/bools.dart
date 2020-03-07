part of '../query_builder.dart';

/// Defines operations on boolean values.
extension BooleanExpressionOperators on Expression<bool> {
  /// Negates this boolean expression. The returned expression is true if
  /// `this` is false, and vice versa.
  Expression<bool> not() => _NotExpression(this);

  /// Returns an expression that is true iff both `this` and [other] are true.
  Expression<bool> operator &(Expression<bool> other) {
    return _BaseInfixOperator(this, 'AND', other, precedence: Precedence.and);
  }

  /// Returns an expression that is true if `this` or [other] are true.
  Expression<bool> operator |(Expression<bool> other) {
    return _BaseInfixOperator(this, 'OR', other, precedence: Precedence.or);
  }
}

class _NotExpression extends Expression<bool> {
  final Expression<bool> inner;

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
