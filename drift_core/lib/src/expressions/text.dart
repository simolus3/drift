import 'common.dart';
import 'expression.dart';

/// SQL operators and functions working on text values.
extension TextOperators on Expression<String> {
  /// A `LIKE` expression in SQL, checking whether `this` matches the [pattern].
  ///
  /// The pattern may be a string with `%` to match many amount of characters
  /// and `_` matching exactly one character.
  ///
  /// To construct a dynamic `LIKE` expression with any SQL expression being a
  /// pattern, use [likeExpr].
  Expression<bool> like(String pattern) {
    return likeExpr(sqlVar(pattern));
  }

  /// A `LIKE` expression in SQL, checking whether `this` matches the [pattern].
  ///
  /// The pattern may be a string with `%` to match many amount of characters
  /// and `_` matching exactly one character.
  ///
  /// To construct a `LIKE` expression with a string on the right-hand side, use
  /// [like].
  Expression<bool> likeExpr(Expression<String> pattern) {
    return BinaryExpression(this, 'LIKE', pattern,
        precedence: Precedence.comparisonEq);
  }

  /// A `UPPER` call in SQL, returning the all-uppercase variant of this string.
  Expression<String> get upper => FunctionCallExpression('UPPER', [this]);

  /// A `LOWER` call in SQL, returning the all-lowercase variant of this string.
  Expression<String> get lower => FunctionCallExpression('LOWER', [this]);
}
