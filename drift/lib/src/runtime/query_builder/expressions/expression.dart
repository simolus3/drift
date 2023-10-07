part of '../query_builder.dart';

const _equality = ListEquality<Object?>();

/// Base class for everything that can be used as a function parameter in sql.
///
/// Most prominently, this includes [Expression]s.
///
/// Used internally by drift.
abstract class FunctionParameter implements Component {}

/// Any sql expression that evaluates to some generic value. This does not
/// include queries (which might evaluate to multiple values) but individual
/// columns, functions and operators.
///
/// To obtain the result of an [Expression], add it as a result column to a
/// [JoinedSelectStatement], e.g. through [DatabaseConnectionUser.selectOnly]:
///
/// ```dart
///  Expression<int> countUsers = users.id.count();
///
///  // Add the expression to a select statement to evaluate it.
///  final query = selectOnly(users)..addColumns([countUsers]);
///  final row = await query.getSingle();
///
///  // Use .read() on a row to read expressions.
///  final amountOfUsers = query.read(counUsers);
/// ```
///
/// It's important that all subclasses properly implement [hashCode] and
/// [==].
abstract class Expression<D extends Object> implements FunctionParameter {
  /// Constant constructor so that subclasses can be constant.
  const Expression();

  /// The precedence of this expression. This can be used to automatically put
  /// parentheses around expressions as needed.
  Precedence get precedence => Precedence.unknown;

  /// Whether this expression is a literal. Some use-sites need to put
  /// parentheses around non-literals.
  bool get isLiteral => false;

  /// Whether this expression is equal to the given expression.
  ///
  /// This generates an equals operator in SQL. To perform a comparison
  /// sensitive to `NULL` values, use [isExp] instead.
  Expression<bool> equalsExp(Expression<D> compare) =>
      _Comparison.equal(this, compare);

  /// Whether this column is equal to the given value, which must have a fitting
  /// type. The [compare] value will be written
  /// as a variable using prepared statements, so there is no risk of
  /// an SQL-injection.
  ///
  /// This method only supports comparing the value of the column to non-
  /// nullable values and translates to a direct `=` comparison in SQL.
  /// To compare this column to `null`, use [isValue].
  Expression<bool> equals(D compare) =>
      _Comparison.equal(this, Variable<D>(compare));

  /// Compares the value of this column to [compare] or `null`.
  ///
  /// When [compare] is null, this generates an `IS NULL` expression in SQL.
  /// For non-null values, an [equals] expression is generated.
  /// This means that, for this method, two null values are considered equal.
  /// This deviates from the usual notion in SQL that doesn't allow comparing
  /// `NULL` values with equals.
  Expression<bool> equalsNullable(D? compare) {
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
  Expression<D2> dartCast<D2 extends Object>() {
    return _DartCastExpression<D, D2>(this);
  }

  /// Generates a `CAST(expression AS TYPE)` expression.
  ///
  /// Note that this does not do a meaningful conversion for drift-only types
  /// like `bool` or `DateTime`. Both would simply generate a `CAST AS INT`
  /// expression.
  ///
  /// The optional [type] parameter can be used to specify the SQL type to cast
  /// to. This is mainly useful for [CustomSqlType]s. For types supported by
  /// drift, [DriftSqlType.forType] will be used as a default.
  Expression<D2> cast<D2 extends Object>([BaseSqlType<D2>? type]) {
    return _CastInSqlExpression<D, D2>(
        this, type ?? DriftSqlType.forType<D2>());
  }

  /// Generates an `IS` expression in SQL, comparing this expression with the
  /// Dart [value].
  ///
  /// This is the SQL method most closely resembling the [Object.==] operator in
  /// Dart. When this expression and [value] are both non-null, this is the same
  /// as [equals]. Two `NULL` values are considered equal as well.
  Expression<bool> isValue(D value) {
    return isExp(Variable<D>(value));
  }

  /// Generates an `IS NOT` expression in SQL, comparing this expression with
  /// the Dart [value].
  ///
  /// This the inverse of [isValue].
  Expression<bool> isNotValue(D value) {
    return isNotExp(Variable<D>(value));
  }

  /// Expression that is true if the inner expression resolves to a null value.
  Expression<bool> isNull() => isExp(const Constant(null));

  /// Expression that is true if the inner expression resolves to a non-null
  /// value.
  Expression<bool> isNotNull() => isNotExp(const Constant(null));

  /// Generates an `IS` expression in SQL, comparing this expression with the
  /// [other] expression.
  ///
  /// This is the SQL method most closely resembling the [Object.==] operator in
  /// Dart. When this expression and [other] are both non-null, this is the same
  /// as [equalsExp]. Two `NULL` values are considered equal as well.
  Expression<bool> isExp(Expression<D> other) {
    return BaseInfixOperator(this, 'IS', other,
        precedence: Precedence.comparisonEq);
  }

  /// Generates an `IS NOT` expression in SQL, comparing this expression with
  /// the [other] expression.
  ///
  /// This the inverse of [isExp].
  Expression<bool> isNotExp(Expression<D> other) {
    return BaseInfixOperator(this, 'IS NOT', other,
        precedence: Precedence.comparisonEq);
  }

  /// An expression that is true if `this` resolves to any of the values in
  /// [values].
  Expression<bool> isIn(Iterable<D> values) {
    return isInExp([for (final value in values) Variable<D>(value)]);
  }

  /// An expression that is true if `this` does not resolve to any of the values
  /// in [values].
  Expression<bool> isNotIn(Iterable<D> values) {
    return isNotInExp([for (final value in values) Variable<D>(value)]);
  }

  /// An expression that evaluates to `true` if this expression resolves to a
  /// value that one of the [expressions] resolve to as well.
  ///
  /// For an "is in" comparison with values, use [isIn].
  Expression<bool> isInExp(List<Expression<D>> expressions) {
    if (expressions.isEmpty) {
      return Constant(false);
    }

    return _InExpression(this, expressions, false);
  }

  /// An expression that evaluates to `true` if this expression does not resolve
  /// to any value that the [expressions] resolve to.
  ///
  /// For an "is not in" comparison with values, use [isNotIn].
  Expression<bool> isNotInExp(List<Expression<D>> expressions) {
    if (expressions.isEmpty) {
      return Constant(true);
    }

    return _InExpression(this, expressions, true);
  }

  /// An expression checking whether `this` is included in any row of the
  /// provided [select] statement.
  ///
  /// The [select] statement may only have one column.
  Expression<bool> isInQuery(BaseSelectStatement select) {
    _checkSubquery(select);
    return _InSelectExpression(select, this, false);
  }

  /// An expression checking whether `this` is _not_ included in any row of the
  /// provided [select] statement.
  ///
  /// The [select] statement may only have one column.
  Expression<bool> isNotInQuery(BaseSelectStatement select) {
    _checkSubquery(select);
    return _InSelectExpression(select, this, true);
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
  Expression<T> caseMatch<T extends Object>({
    required Map<Expression<D>, Expression<T>> when,
    Expression<T>? orElse,
  }) {
    return CaseWhenExpressionWithBase<D, T>(
      this,
      cases: when.entries.map((e) => CaseWhen(e.key, then: e.value)),
      orElse: orElse,
    );
  }

  /// Evaluates to `this` if [predicate] is true, otherwise evaluates to [ifFalse].
  Expression<T> iif<T extends Object>(
      Expression<bool> predicate, Expression<T> ifFalse) {
    return FunctionCallExpression<T>('IIF', [predicate, this, ifFalse]);
  }

  /// Returns `null` if [matcher] is equal to this expression, `this` otherwise.
  Expression<D> nullIf(Expression<D> matcher) {
    return FunctionCallExpression('NULLIF', [this, matcher]);
  }

  /// Writes this expression into the [GenerationContext], assuming that there's
  /// an outer expression with [precedence]. If the [Expression.precedence] of
  /// `this` expression is lower, it will be wrap}ped in
  ///
  /// See also:
  ///  - [Component.writeInto], which doesn't take any precedence relation into
  ///  account.
  void writeAroundPrecedence(GenerationContext context, Precedence precedence) {
    if (this.precedence < precedence) {
      context.buffer.write('(');
      writeInto(context);
      context.buffer.write(')');
    } else {
      writeInto(context);
    }
  }

  /// If this [Expression] wraps an [inner] expression, this utility method can
  /// be used inside [writeInto] to write that inner expression while wrapping
  /// it in parentheses if necessary.
  @protected
  void writeInner(GenerationContext ctx, Expression inner) {
    assert(precedence != Precedence.unknown,
        "Expressions with unknown precedence shouldn't have inner expressions");
    inner.writeAroundPrecedence(ctx, precedence);
  }

  /// The [BaseSqlType] backing this expression.
  ///
  /// This is a recognized [DriftSqlType] for all expressions for which a custom
  /// type has not explicitly been set.
  BaseSqlType<D> get driftSqlType => DriftSqlType.forType();

  /// Chains all [predicates] together into a single expression that will
  /// evaluate to `true` iff any of the [predicates] evaluates to `true`.
  ///
  /// The [ifEmpty] value will be used when no predicates have been passed to
  /// [or]. By default, `false` is returned.
  static Expression<bool> or(
    Iterable<Expression<bool>> predicates, {
    Expression<bool> ifEmpty = const Constant(false),
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
    Expression<bool> ifEmpty = const Constant(true),
  }) {
    if (predicates.isEmpty) {
      return ifEmpty;
    }

    return predicates.reduce((value, element) => value & element);
  }
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

  /// Precedence for most of the comparisons operators in sql, including
  /// equality, is (not) checks, in, like, glob, match, regexp.
  comparisonEq._(12),

  /// Precedence for the <, <=, >, >= operators in sql
  comparison._(13),

  /// Precedence for bitwise operators in sql
  bitwise._(14),

  /// Precedence for the (binary) plus and minus operators in sql
  plusMinus._(15),

  /// Precedence for the *, / and % operators in sql
  mulDivide._(16),

  /// Precedence for the || operator in sql
  stringConcatenation._(17),

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

/// Defines the possible comparison operators that can appear in a
/// [_Comparison].
enum _ComparisonOperator {
  /// '<' in sql
  less('<'),

  /// '<=' in sql
  lessOrEqual('<='),

  /// '=' in sql
  equal('='),

  /// '>=' in sql
  moreOrEqual('>='),

  /// '>' in sql
  more('>');

  final String operator;

  const _ComparisonOperator(this.operator);
}

/// An expression that compares two child expressions.
class _Comparison extends InfixOperator<bool> {
  @override
  final Expression left;
  @override
  final Expression right;

  /// The operator to use for this comparison
  final _ComparisonOperator op;

  @override
  String get operator => op.operator;

  @override
  Precedence get precedence {
    if (op == _ComparisonOperator.equal) {
      return Precedence.comparisonEq;
    } else {
      return Precedence.comparison;
    }
  }

  /// Constructs a comparison from the [left] and [right] expressions to compare
  /// and the [ComparisonOperator] [op].
  _Comparison(this.left, this.op, this.right);

  /// Like [Comparison(left, op, right)], but uses [_ComparisonOperator.equal].
  _Comparison.equal(this.left, this.right) : op = _ComparisonOperator.equal;

  @override
  void writeInto(GenerationContext context) {
    // Most values can be compared directly, but date time values need to be
    // brought into a comparable format if they're stored as text (since we
    // don't want to compare datetimes lexicographically).
    final left = this.left;
    final right = this.right;

    if (left is Expression<DateTime> &&
        right is Expression<DateTime> &&
        context.typeMapping.storeDateTimesAsText) {
      // Compare julianday values instead of texts
      writeInner(context, left.julianday);
      context.writeWhitespace();
      context.buffer.write(operator);
      context.writeWhitespace();
      writeInner(context, right.julianday);
    } else {
      super.writeInto(context);
    }
  }
}

class _UnaryMinus<DT extends Object> extends Expression<DT> {
  final Expression<DT> inner;

  _UnaryMinus(this.inner);

  @override
  Precedence get precedence => Precedence.unary;

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write('-');
    writeInner(context, inner);
  }

  @override
  int get hashCode => inner.hashCode * 5;

  @override
  bool operator ==(Object other) {
    return other is _UnaryMinus && other.inner == inner;
  }
}

class _DartCastExpression<D1 extends Object, D2 extends Object>
    extends Expression<D2> {
  final Expression<D1> inner;

  const _DartCastExpression(this.inner);

  @override
  Precedence get precedence => inner.precedence;

  @override
  bool get isLiteral => inner.isLiteral;

  @override
  void writeAroundPrecedence(GenerationContext context, Precedence precedence) {
    // This helps avoid parentheses if the inner expression has a precedence
    // that is computed dynamically.
    return inner.writeAroundPrecedence(context, precedence);
  }

  @override
  void writeInto(GenerationContext context) {
    return inner.writeInto(context);
  }

  @override
  int get hashCode => inner.hashCode * 7;

  @override
  bool operator ==(Object other) {
    return other is _DartCastExpression && other.inner == inner;
  }
}

class _CastInSqlExpression<D1 extends Object, D2 extends Object>
    extends Expression<D2> {
  final Expression<D1> inner;
  final BaseSqlType<D2> targetType;

  @override
  Precedence get precedence => Precedence.primary;

  @override
  BaseSqlType<D2> get driftSqlType => targetType;

  const _CastInSqlExpression(this.inner, this.targetType);

  @override
  void writeInto(GenerationContext context) {
    // ignore: unrelated_type_equality_checks
    if (targetType == DriftSqlType.any) {
      inner.writeInto(context); // No need to cast
    }

    final String typeName;

    if (context.dialect == SqlDialect.mariadb) {
      // MariaDB has a weird cast syntax that uses different type names than the
      // ones used in a create table statement.

      // ignore: unnecessary_cast
      typeName = switch (targetType) {
        DriftSqlType.int ||
        DriftSqlType.bigInt ||
        DriftSqlType.bool =>
          'INTEGER',
        DriftSqlType.string => 'CHAR',
        DriftSqlType.double => 'DOUBLE',
        DriftSqlType.blob => 'BINARY',
        DriftSqlType.dateTime => 'DATETIME',
        DriftSqlType.any => '',
        CustomSqlType() => targetType.sqlTypeName(context),
      };
    } else {
      typeName = targetType.sqlTypeName(context);
    }

    context.buffer.write('CAST(');
    inner.writeInto(context);
    context.buffer.write(' AS $typeName)');
  }
}

/// A sql expression that calls a function.
///
/// This class is mainly used by drift internally. If you find yourself using
/// this class, consider [creating an issue](https://github.com/simolus3/drift/issues/new)
/// to request native support in drift.
class FunctionCallExpression<R extends Object> extends Expression<R> {
  /// The name of the function to call
  final String functionName;

  /// The arguments passed to the function, as expressions.
  final List<Expression> arguments;

  @override
  Precedence get precedence => Precedence.primary;

  /// Constructs a function call expression in sql from the [functionName] and
  /// the target [arguments].
  const FunctionCallExpression(this.functionName, this.arguments);

  @override
  void writeInto(GenerationContext context) {
    context.buffer
      ..write(functionName)
      ..write('(');
    _writeCommaSeparated(context, arguments);
    context.buffer.write(')');
  }

  @override
  int get hashCode => Object.hash(functionName, _equality);

  @override
  bool operator ==(Object other) {
    return other is FunctionCallExpression &&
        other.functionName == functionName &&
        _equality.equals(other.arguments, arguments);
  }
}

void _checkSubquery(BaseSelectStatement statement) {
  final columns = statement._expandedColumns.length;
  if (columns != 1) {
    throw ArgumentError.value(statement, 'statement',
        'Must return exactly one column (actually returns $columns)');
  }
}

/// Creates a subquery expression from the given [statement].
///
/// The statement, which can be created via [DatabaseConnectionUser.select] in
/// a database class, must return exactly one row with exactly one column.
Expression<R> subqueryExpression<R extends Object>(
    BaseSelectStatement statement) {
  _checkSubquery(statement);
  return _SubqueryExpression<R>(statement);
}

class _SubqueryExpression<R extends Object> extends Expression<R> {
  final BaseSelectStatement statement;

  _SubqueryExpression(this.statement);

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write('(');
    statement.writeInto(context);
    context.buffer.write(')');
  }

  @override
  int get hashCode => statement.hashCode;

  @override
  bool operator ==(Object? other) {
    return other is _SubqueryExpression && other.statement == statement;
  }
}
