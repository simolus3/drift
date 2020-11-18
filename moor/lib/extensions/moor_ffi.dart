/// High-level bindings to mathematical functions that are only available in
/// `moor_ffi`.
library moor_ffi_functions;

import 'dart:math';
import 'package:moor/moor.dart';

/// Raises [base] to the power of [exponent].
///
/// This function is equivalent to [pow], except that it evaluates to null
/// instead of `NaN`.
///
/// This function is only available when using `moor_ffi`.
Expression<num?> sqlPow(Expression<num?> base, Expression<num?> exponent) {
  return FunctionCallExpression('pow', [base, exponent]);
}

/// Calculates the square root of [value] in sql.
///
/// This function is equivalent to [sqrt], except that it returns null instead
/// of `NaN` for negative values.
///
/// This function is only available when using `moor_ffi`.
Expression<num?> sqlSqrt(Expression<num?> value) {
  return FunctionCallExpression('sqrt', [value]);
}

/// Calculates the sine of [value] in sql.
///
/// This function is equivalent to [sin].
///
/// This function is only available when using `moor_ffi`.
Expression<num?> sqlSin(Expression<num?> value) {
  return FunctionCallExpression('sin', [value]);
}

/// Calculates the cosine of [value] in sql.
///
/// This function is equivalent to [sin].
///
/// This function is only available when using `moor_ffi`.
Expression<num?> sqlCos(Expression<num?> value) {
  return FunctionCallExpression('cos', [value]);
}

/// Calculates the tangent of [value] in sql.
///
/// This function is equivalent to [tan].
///
/// This function is only available when using `moor_ffi`.
Expression<num?> sqlTan(Expression<num?> value) {
  return FunctionCallExpression('tan', [value]);
}

/// Calculates the arc sine of [value] in sql.
///
/// This function is equivalent to [asin], except that it evaluates to null
/// instead of `NaN`.
///
/// This function is only available when using `moor_ffi`.
Expression<num?> sqlAsin(Expression<num?> value) {
  return FunctionCallExpression('asin', [value]);
}

/// Calculates the cosine of [value] in sql.
///
/// This function is equivalent to [acos], except that it evaluates to null
/// instead of `NaN`.
///
/// This function is only available when using `moor_ffi`.
Expression<num?> sqlAcos(Expression<num?> value) {
  return FunctionCallExpression('acos', [value]);
}

/// Calculates the tangent of [value] in sql.
///
/// This function is equivalent to [atan], except that it evaluates to null
/// instead of `NaN`.
///
/// This function is only available when using `moor_ffi`.
Expression<num?> sqlAtan(Expression<num?> value) {
  return FunctionCallExpression('atan', [value]);
}

/// Adds functionality to string expressions that only work when using
/// `moor_ffi`.
extension MoorFfiSpecificStringExtensions on Expression<String?> {
  /// Version of `contains` that allows controlling case sensitivity better.
  ///
  /// The default `contains` method uses sqlite's `LIKE`, which is case-
  /// insensitive for the English alphabet only. [containsCase] is implemented
  /// in Dart with better support for casing.
  /// When [caseSensitive] is false (the default), this is equivalent to the
  /// Dart expression `this.contains(substring)`, where `this` is the string
  /// value this expression evaluates to.
  /// When [caseSensitive] is true, the equivalent Dart expression would be
  /// `this.toLowerCase().contains(substring.toLowerCase())`.
  ///
  /// Note that, while Dart has better support for an international alphabet,
  /// it can still yield unexpected results like the
  /// [Turkish İ Problem](https://haacked.com/archive/2012/07/05/turkish-i-problem-and-why-you-should-care.aspx/)
  ///
  /// Note that this is only available when using `moor_ffi` version 0.6.0 or
  /// greater.
  Expression<bool?> containsCase(String substring,
      {bool caseSensitive = false}) {
    return FunctionCallExpression('moor_contains', [
      this,
      Variable<String>(substring),
      if (caseSensitive) const Constant<int>(1) else const Constant<int>(0),
    ]);
  }
}
