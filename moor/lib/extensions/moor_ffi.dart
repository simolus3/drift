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
Expression<num> sqlPow(Expression<num> base, Expression<num> exponent) {
  return FunctionCallExpression('pow', [base, exponent]);
}

/// Calculates the square root of [value] in sql.
///
/// This function is equivalent to [sqrt], except that it returns null instead
/// of `NaN` for negative values.
///
/// This function is only available when using `moor_ffi`.
Expression<num> sqlSqrt(Expression<num> value) {
  return FunctionCallExpression('sqrt', [value]);
}

/// Calculates the sine of [value] in sql.
///
/// This function is equivalent to [sin].
///
/// This function is only available when using `moor_ffi`.
Expression<num> sqlSin(Expression<num> value) {
  return FunctionCallExpression('sin', [value]);
}

/// Calculates the cosine of [value] in sql.
///
/// This function is equivalent to [sin].
///
/// This function is only available when using `moor_ffi`.
Expression<num> sqlCos(Expression<num> value) {
  return FunctionCallExpression('cos', [value]);
}

/// Calculates the tangent of [value] in sql.
///
/// This function is equivalent to [tan].
///
/// This function is only available when using `moor_ffi`.
Expression<num> sqlTan(Expression<num> value) {
  return FunctionCallExpression('tan', [value]);
}

/// Calculates the arc sine of [value] in sql.
///
/// This function is equivalent to [asin], except that it evaluates to null
/// instead of `NaN`.
///
/// This function is only available when using `moor_ffi`.
Expression<num> sqlAsin(Expression<num> value) {
  return FunctionCallExpression('asin', [value]);
}

/// Calculates the cosine of [value] in sql.
///
/// This function is equivalent to [acos], except that it evaluates to null
/// instead of `NaN`.
///
/// This function is only available when using `moor_ffi`.
Expression<num> sqlAcos(Expression<num> value) {
  return FunctionCallExpression('acos', [value]);
}

/// Calculates the tangent of [value] in sql.
///
/// This function is equivalent to [atan], except that it evaluates to null
/// instead of `NaN`.
///
/// This function is only available when using `moor_ffi`.
Expression<num> sqlAtan(Expression<num> value) {
  return FunctionCallExpression('atan', [value]);
}
