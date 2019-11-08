part of '../query_builder.dart';

/// Defines the `+` operator on sql expressions that support it.
extension MonoidExpr<DT, ST extends Monoid<DT>> on Expression<DT, ST> {
  /// Performs an addition (`this` + [other]) in sql.
  Expression<DT, ST> operator +(Expression<DT, ST> other) {
    assert(other is! Expression<String, StringType>,
        'Used Monoid extension but should have resolved to String extension');

    return _BaseInfixOperator(this, '+', other,
        precedence: Precedence.plusMinus);
  }
}

/// Defines the `+` operator as a concatenation for string expressions.
extension StringMonoidExpr on Expression<String, StringType> {
  /// Performs a string concatenation in sql by appending [other] to `this`.
  Expression<String, StringType> operator +(
      Expression<String, StringType> other) {
    return _BaseInfixOperator(this, '||', other,
        precedence: Precedence.stringConcatenation);
  }
}

/// Defines the `-`, `*` and `/` operators on sql expressions that support it.
extension ArithmeticExpr<DT, ST extends FullArithmetic<DT>>
    on Expression<DT, ST> {
  /// Performs a subtraction (`this` - [other]) in sql.
  Expression<DT, ST> operator -(Expression<DT, ST> other) {
    return _BaseInfixOperator(this, '-', other,
        precedence: Precedence.plusMinus);
  }

  /// Returns the negation of this value.
  Expression<DT, ST> operator -() {
    return _UnaryMinus(this);
  }

  /// Performs a multiplication (`this` * [other]) in sql.
  Expression<DT, ST> operator *(Expression<DT, ST> other) {
    return _BaseInfixOperator(this, '*', other,
        precedence: Precedence.mulDivide);
  }

  /// Performs a division (`this` / [other]) in sql.
  Expression<DT, ST> operator /(Expression<DT, ST> other) {
    return _BaseInfixOperator(this, '/', other,
        precedence: Precedence.mulDivide);
  }
}
