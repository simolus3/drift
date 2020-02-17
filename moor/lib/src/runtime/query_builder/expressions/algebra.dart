part of '../query_builder.dart';

/// Defines the `-`, `*` and `/` operators on sql expressions that support it.
extension ArithmeticExpr<DT extends num> on Expression<DT> {
  /// Performs an addition (`this` + [other]) in sql.
  Expression<DT> operator +(Expression<DT> other) {
    return _BaseInfixOperator(this, '+', other,
        precedence: Precedence.plusMinus);
  }

  /// Performs a subtraction (`this` - [other]) in sql.
  Expression<DT> operator -(Expression<DT> other) {
    return _BaseInfixOperator(this, '-', other,
        precedence: Precedence.plusMinus);
  }

  /// Returns the negation of this value.
  Expression<DT> operator -() {
    return _UnaryMinus(this);
  }

  /// Performs a multiplication (`this` * [other]) in sql.
  Expression<DT> operator *(Expression<DT> other) {
    return _BaseInfixOperator(this, '*', other,
        precedence: Precedence.mulDivide);
  }

  /// Performs a division (`this` / [other]) in sql.
  Expression<DT> operator /(Expression<DT> other) {
    return _BaseInfixOperator(this, '/', other,
        precedence: Precedence.mulDivide);
  }
}
