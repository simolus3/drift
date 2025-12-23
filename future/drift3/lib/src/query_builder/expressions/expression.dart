import 'package:meta/meta.dart';

import '../statements/select.dart';
import 'boolean.dart';
import 'custom.dart';
import '../compiler.dart';
import '../dialect.dart';
import '../types.dart';
import 'case_when.dart';
import 'functions.dart';
import 'operators.dart';
import 'subquery.dart';
import 'tuple.dart';
import 'variables.dart';

/// Parameters that can be passed to SQL function calls.
///
/// This includes all [Expression]s, as well [StarFunctionParameter]s.
sealed class FunctionParameter implements SqlComponent {}

/// An SQL expression, which evaluates to a value when evaluated by a database
/// engine.
abstract base class Expression<T extends Object> implements FunctionParameter {
  /// Constant base constructor, allowing subclasses to be const.
  const Expression();

  /// A custom expression that can appear in a sql statement.
  ///
  /// The [text] will be written into the query without any modification.
  const factory Expression.customComponent(
    CustomComponent text, {
    Precedence precedence,
    SqlType<T>? customType,
  }) = CustomExpression<T>;

  /// A custom expression that can appear in a sql statement.
  ///
  /// The [sql] will be written into the query without any modification, and can
  /// be combined with [dialectSpecific] overrides.
  factory Expression.custom(
    String sql, {
    Map<KnownSqlDialect, String> dialectSpecific = const {},
    Precedence precedence = Precedence.unknown,
    SqlType<T>? customType,
  }) {
    return Expression.customComponent(
      CustomComponent(sql, dialectSpecifcSql: dialectSpecific),
      precedence: precedence,
      customType: customType,
    );
  }

  /// The precedence of this expression. This can be used to automatically put
  /// parentheses around expressions as needed.
  Precedence get precedence => Precedence.unknown;

  /// Resolves the [SqlType] implementation describing the type of this
  /// expression.
  PhysicalSqlType<T> resolveType(DriftDialect dialect) =>
      dialect.resolveType<T>();

  @override
  void compileWith(StatementCompiler compiler);

  /// Whether this expression is equal to the given expression.
  ///
  /// This generates an equals operator in SQL. To perform a comparison
  /// sensitive to `NULL` values, use [isExp] instead.
  Expression<bool> equalsExp(Expression<T> compare) =>
      BinaryExpression(this, BinaryOperator.equals, compare);

  /// Whether this column is equal to the given value, which must have a fitting
  /// type. The [compare] value will be written
  /// as a variable using prepared statements, so there is no risk of
  /// an SQL-injection.
  ///
  /// This method only supports comparing the value of the column to non-
  /// nullable values and translates to a direct `=` comparison in SQL.
  /// To compare this column to `null`, use [isValue].
  Expression<bool> equals(T compare) => equalsExp(variable(compare));

  /// Compares the value of this column to [compare] or `null`.
  ///
  /// When [compare] is null, this generates an `IS NULL` expression in SQL.
  /// For non-null values, an [equals] expression is generated.
  /// This means that, for this method, two null values are considered equal.
  /// This deviates from the usual notion in SQL that doesn't allow comparing
  /// `NULL` values with equals.
  Expression<bool> equalsNullable(T? compare) {
    if (compare == null) {
      return isNull();
    } else {
      return equals(compare);
    }
  }

  /// Casts this expression to an expression of [D].
  ///
  /// Calling [dartCast] will not affect the generated sql. In particular, it
  /// will __NOT__ generate a `CAST` expression in sql. To generate a `CAST`
  /// in sql, use [cast].
  ///
  /// This method is used internally by drift.
  Expression<T2> dartCast<T2 extends Object>({SqlType<T2>? customType}) {
    return _DartCastExpression<T, T2>(this, customType);
  }

  /// Generates a `CAST(expression AS TYPE)` expression.
  ///
  /// Note that this does not do a meaningful conversion for drift-only types
  /// like `bool` or `DateTime`. Both would simply generate a `CAST AS INT`
  /// expression.
  ///
  /// The optional [type] parameter can be used to specify the SQL type to cast
  /// to. This is mainly useful for [CustomSqlType]s. For types supported by
  /// drift, [DriftDialect.resolveType] will be used as a default.
  Expression<T2> cast<T2 extends Object>([SqlType<T2>? type]) {
    return CastExpression<T, T2>._(this, type);
  }

  /// Generates an `IS` expression in SQL, comparing this expression with the
  /// Dart [value].
  ///
  /// This is the SQL method most closely resembling the [Object.==] operator in
  /// Dart. When this expression and [value] are both non-null, this is the same
  /// as [equals]. Two `NULL` values are considered equal as well.
  Expression<bool> isValue(T value) {
    return isExp(variable(value));
  }

  /// Generates an `IS NOT` expression in SQL, comparing this expression with
  /// the Dart [value].
  ///
  /// This the inverse of [isValue].
  Expression<bool> isNotValue(T value) {
    return isNotExp(variable(value));
  }

  /// Expression that is true if the inner expression resolves to a null value.
  Expression<bool> isNull() => isExp(const Literal(null));

  /// Expression that is true if the inner expression resolves to a non-null
  /// value.
  Expression<bool> isNotNull() => isNotExp(const Literal(null));

  /// Generates an `IS` expression in SQL, comparing this expression with the
  /// [other] expression.
  ///
  /// This is the SQL method most closely resembling the [Object.==] operator in
  /// Dart. When this expression and [other] are both non-null, this is the same
  /// as [equalsExp]. Two `NULL` values are considered equal as well.
  Expression<bool> isExp(Expression<T> other) {
    return BinaryExpression(this, BinaryOperator.$is, other);
  }

  /// Generates an `IS NOT` expression in SQL, comparing this expression with
  /// the [other] expression.
  ///
  /// This the inverse of [isExp].
  Expression<bool> isNotExp(Expression<T> other) {
    return BinaryExpression(this, BinaryOperator.isNot, other);
  }

  /// An expression that is true if `this` resolves to any of the values in
  /// [values].
  Expression<bool> isIn(Iterable<T> values) {
    return isInExp([for (final value in values) variable(value)]);
  }

  /// An expression that is true if `this` does not resolve to any of the values
  /// in [values].
  Expression<bool> isNotIn(Iterable<T> values) {
    return isNotInExp([for (final value in values) variable(value)]);
  }

  /// An expression that evaluates to `true` if this expression resolves to a
  /// value that one of the [expressions] resolve to as well.
  ///
  /// For an "is in" comparison with values, use [isIn].
  Expression<bool> isInExp(List<Expression<T>> expressions) {
    if (expressions.isEmpty) {
      return Literal(false);
    }

    return BinaryExpression(
      this,
      BinaryOperator.$in,
      ExpressionTuple(expressions),
    );
  }

  /// An expression that evaluates to `true` if this expression does not resolve
  /// to any value that the [expressions] resolve to.
  ///
  /// For an "is not in" comparison with values, use [isNotIn].
  Expression<bool> isNotInExp(List<Expression<T>> expressions) {
    if (expressions.isEmpty) {
      return Literal(true);
    }

    return BinaryExpression(
      this,
      BinaryOperator.notIn,
      ExpressionTuple(expressions),
    );
  }

  /// An expression checking whether `this` is included in any row of the
  /// provided [select] statement.
  ///
  /// The [select] statement may only have one column.
  Expression<bool> isInQuery(BaseSelectStatement select) {
    return BinaryExpression(
      this,
      BinaryOperator.$in,
      SubqueryExpression(select),
    );
  }

  /// An expression checking whether `this` is _not_ included in any row of the
  /// provided [select] statement.
  ///
  /// The [select] statement may only have one column.
  Expression<bool> isNotInQuery(BaseSelectStatement select) {
    return BinaryExpression(
      this,
      BinaryOperator.notIn,
      SubqueryExpression(select),
    );
  }

  /// A `CASE WHEN` construct using the current expression as a base.
  ///
  /// The expression on which [caseMatch] is invoked will be used as a base and
  /// compared against the keys in [when]. If an equal key is found in the map,
  /// the expression returned evaluates to the respective value.
  /// If no matching keys are found in [when], the [orElse] expression is
  /// evaluated and returned. If no [orElse] expression is provided, `NULL` will
  /// be returned instead.
  ///
  /// For example, consider this expression mapping numerical weekdays to their
  /// name:
  ///
  /// ```dart
  /// final weekday = myTable.createdOnWeekDay;
  /// weekday.caseMatch<String>(
  ///   when: {
  ///     Constant(1): Constant('Monday'),
  ///     Constant(2): Constant('Tuesday'),
  ///     Constant(3): Constant('Wednesday'),
  ///     Constant(4): Constant('Thursday'),
  ///     Constant(5): Constant('Friday'),
  ///     Constant(6): Constant('Saturday'),
  ///     Constant(7): Constant('Sunday'),
  ///   },
  ///   orElse: Constant('(unknown)'),
  /// );
  /// ```
  Expression<R> caseMatch<R extends Object>({
    required Map<Expression<T>, Expression<R>> when,
    Expression<R>? orElse,
  }) {
    return CaseWhenExpression.withBase<T, R>(
      this,
      cases: [
        for (final MapEntry(:key, :value) in when.entries)
          (when: key, then: value),
      ],
      orElse: orElse,
    );
  }

  /// Evaluates to `this` if [predicate] is true, otherwise evaluates to
  /// [ifFalse].
  Expression<T> iif(Expression<bool> predicate, Expression<T> ifFalse) {
    return FunctionCallExpression('IIF', [predicate, this, ifFalse]);
  }

  /// Returns `null` if [matcher] is equal to this expression, `this` otherwise.
  Expression<T> nullIf(Expression<T> matcher) {
    return FunctionCallExpression('NULLIF', [this, matcher]);
  }

  /// Creates a variable that is guaranteed to have the same [SqlType] as
  /// `this`.
  @protected
  Variable<T> variable(T? value) {
    return Variable(value, resolveType);
  }

  /// Chains all [predicates] together into a single expression that will
  /// evaluate to `true` iff any of the [predicates] evaluates to `true`.
  ///
  /// The [ifEmpty] value will be used when no predicates have been passed to
  /// [or]. By default, `false` is returned.
  static Expression<bool> or(
    Iterable<Expression<bool>> predicates, {
    Expression<bool> ifEmpty = const Literal(false),
  }) {
    if (predicates.isEmpty) {
      return ifEmpty;
    }

    return predicates.reduce((value, element) => value | element);
  }

  /// Chains all [predicates] together into a single expression that will
  /// evaluate to `true` iff all of the [predicates] evaluates to `true`.
  ///
  /// The [ifEmpty] value will be used when no predicates have been passed to
  /// [or]. By default, `true` is returned.
  static Expression<bool> and(
    Iterable<Expression<bool>> predicates, {
    Expression<bool> ifEmpty = const Literal(true),
  }) {
    if (predicates.isEmpty) {
      return ifEmpty;
    }

    return predicates.reduce((value, element) => value & element);
  }
}

/// Evaluates to the first expression in [expressions] that's not null, or
/// null if all [expressions] evaluate to null.
Expression<T> coalesce<T extends Object>(List<Expression<T>> expressions) {
  assert(
    expressions.length >= 2,
    'expressions must be of length >= 2, got ${expressions.length}',
  );

  return FunctionCallExpression<T>('COALESCE', expressions);
}

/// Evaluates to the first expression that's not null, or null if both evaluate
/// to null. See [coalesce] if you need more than 2.
Expression<T> ifNull<T extends Object>(
  Expression<T> first,
  Expression<T> second,
) {
  return FunctionCallExpression<T>('IFNULL', [first, second]);
}

/// Used to order the precedence of sql expressions so that we can avoid
/// unnecessary parens when generating sql statements.
enum Precedence implements Comparable<Precedence> {
  /// Precedence is unknown, assume lowest. This can be used for a
  /// [CustomExpression] to always put parens around it.
  unknown._(-1),

  /// Precedence for the `OR` operator in sql
  or._(10),

  /// Precedence for the `AND` operator in sql
  and._(11),

  /// Precedence for the unary `NOT` operator in SQL.
  not._(12),

  /// Precedence for most of the comparisons operators in sql, including
  /// equality, is (not) checks, in, like, glob, match, regexp.
  comparisonEq._(13),

  /// Precedence for the <, <=, >, >= operators in sql
  comparison._(14),

  /// Precedence for bitwise operators in sql
  bitwise._(15),

  /// Precedence for the (binary) plus and minus operators in sql
  plusMinus._(16),

  /// Precedence for the *, / and % operators in sql
  mulDivide._(17),

  /// Precedence for the || operator in sql
  stringConcatenation._(18),

  /// Precedence for the `COLLATE` operator in sql
  collate._(19),

  /// Precedence for unary operators in sql
  unary._(20),

  /// Precedence for postfix operators (like collate) in sql
  postfix._(21),

  /// Highest precedence in sql, used for variables and literals.
  primary._(100);

  /// Higher means higher precedence.
  final int _value;

  const Precedence._(this._value);

  @override
  int compareTo(Precedence other) {
    return _value.compareTo(other._value);
  }

  /// Returns true if this [Precedence] is lower than [other].
  bool operator <(Precedence other) => compareTo(other) < 0;

  /// Returns true if this [Precedence] is lower or equal to [other].
  bool operator <=(Precedence other) => compareTo(other) <= 0;

  /// Returns true if this [Precedence] is higher than [other].
  bool operator >(Precedence other) => compareTo(other) > 0;

  /// Returns true if this [Precedence] is higher or equal to [other].
  bool operator >=(Precedence other) => compareTo(other) >= 0;
}

final class _DartCastExpression<D1 extends Object, D2 extends Object>
    extends Expression<D2> {
  final Expression<D1> inner;
  final SqlType<D2>? _resolvedType;

  const _DartCastExpression(this.inner, this._resolvedType);

  @override
  Precedence get precedence => inner.precedence;

  @override
  int get hashCode => inner.hashCode * 7;

  @override
  bool operator ==(Object other) {
    return other is _DartCastExpression && other.inner == inner;
  }

  @override
  PhysicalSqlType<D2> resolveType(DriftDialect dialect) {
    return _resolvedType?.resolveIn(dialect) ?? dialect.resolveType<D2>();
  }

  @override
  void compileWith(StatementCompiler compiler) {
    return inner.compileWith(compiler);
  }
}

/// A `CAST ([inner]) AS [type]` expression in SQL.
final class CastExpression<D1 extends Object, D2 extends Object>
    extends Expression<D2> {
  /// The expression for which the typecast should be performed.
  final Expression<D1> inner;

  /// The SQL type to which [inner] should be cast.
  final SqlType<D2>? _fixedType;

  @override
  Precedence get precedence => Precedence.primary;

  const CastExpression._(this.inner, this._fixedType);

  @override
  PhysicalSqlType<D2> resolveType(DriftDialect dialect) =>
      _fixedType?.resolveIn(dialect) ?? dialect.resolveType<D2>();

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addCastExpression(this);
  }
}

/// A `*` parameter passed to functions.
final class StarFunctionParameter implements FunctionParameter {
  /// @nodoc
  const StarFunctionParameter();

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addStarFunctionParameter(this);
  }
}
