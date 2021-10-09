part of '../query_builder.dart';

const _equality = ListEquality();

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
/// It's important that all subclasses properly implement [hashCode] and
/// [==].
abstract class Expression<D> implements FunctionParameter {
  /// Constant constructor so that subclasses can be constant.
  const Expression();

  /// The precedence of this expression. This can be used to automatically put
  /// parentheses around expressions as needed.
  Precedence get precedence => Precedence.unknown;

  /// Whether this expression is a literal. Some use-sites need to put
  /// parentheses around non-literals.
  bool get isLiteral => false;

  /// Whether this expression is equal to the given expression.
  Expression<bool> equalsExp(Expression<D> compare) =>
      _Comparison.equal(this, compare);

  /// Whether this column is equal to the given value, which must have a fitting
  /// type. The [compare] value will be written
  /// as a variable using prepared statements, so there is no risk of
  /// an SQL-injection.
  Expression<bool> equals(D compare) =>
      _Comparison.equal(this, Variable<D>(compare));

  /// Casts this expression to an expression of [D].
  ///
  /// Calling [dartCast] will not affect the generated sql. In particular, it
  /// will __NOT__ generate a `CAST` expression in sql. To generate a `CAST`
  /// in sql, use [cast].
  ///
  /// This method is used internally by drift.
  Expression<D2> dartCast<D2>() {
    return _DartCastExpression<D, D2>(this);
  }

  /// Generates a `CAST(expression AS TYPE)` expression.
  ///
  /// Note that this does not do a meaningful conversion for drift-only types
  /// like `bool` or `DateTime`. Both would simply generate a `CAST AS INT`
  /// expression.
  Expression<D2> cast<D2>() => _CastInSqlExpression<D, D2>(this);

  /// An expression that is true if `this` resolves to any of the values in
  /// [values].
  Expression<bool?> isIn(Iterable<D> values) {
    return _InExpression(this, values.toList(), false);
  }

  /// An expression that is true if `this` does not resolve to any of the values
  /// in [values].
  Expression<bool?> isNotIn(Iterable<D> values) {
    return _InExpression(this, values.toList(), true);
  }

  /// An expression checking whether `this` is included in any row of the
  /// provided [select] statement.
  ///
  /// The [select] statement may only have one column.
  Expression<bool?> isInQuery(BaseSelectStatement select) {
    _checkSubquery(select);
    return _InSelectExpression(select, this, false);
  }

  /// An expression checking whether `this` is _not_ included in any row of the
  /// provided [select] statement.
  ///
  /// The [select] statement may only have one column.
  Expression<bool?> isNotInQuery(BaseSelectStatement select) {
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
  Expression<T?> caseMatch<T>({
    required Map<Expression<D>, Expression<T?>> when,
    Expression<T?>? orElse,
  }) {
    if (when.isEmpty) {
      throw ArgumentError.value(when, 'when', 'Must not be empty');
    }

    return CaseWhenExpression<T>(this, when.entries.toList(), orElse);
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

  /// Finds the runtime implementation of [D] in the provided [types].
  SqlType<D> findType(SqlTypeSystem types) {
    return types.forDartType<D>();
  }
}

/// Used to order the precedence of sql expressions so that we can avoid
/// unnecessary parens when generating sql statements.
class Precedence implements Comparable<Precedence> {
  /// Higher means higher precedence.
  final int _value;

  const Precedence._(this._value);

  @override
  int compareTo(Precedence other) {
    return _value.compareTo(other._value);
  }

  @override
  int get hashCode => _value;

  @override
  bool operator ==(Object other) {
    // runtimeType comparison isn't necessary, the private constructor prevents
    // subclasses
    return other is Precedence && other._value == _value;
  }

  /// Returns true if this [Precedence] is lower than [other].
  bool operator <(Precedence other) => compareTo(other) < 0;

  /// Returns true if this [Precedence] is lower or equal to [other].
  bool operator <=(Precedence other) => compareTo(other) <= 0;

  /// Returns true if this [Precedence] is higher than [other].
  bool operator >(Precedence other) => compareTo(other) > 0;

  /// Returns true if this [Precedence] is higher or equal to [other].
  bool operator >=(Precedence other) => compareTo(other) >= 0;

  /// Precedence is unknown, assume lowest. This can be used for a
  /// [CustomExpression] to always put parens around it.
  static const Precedence unknown = Precedence._(-1);

  /// Precedence for the `OR` operator in sql
  static const Precedence or = Precedence._(10);

  /// Precedence for the `AND` operator in sql
  static const Precedence and = Precedence._(11);

  /// Precedence for most of the comparisons operators in sql, including
  /// equality, is (not) checks, in, like, glob, match, regexp.
  static const Precedence comparisonEq = Precedence._(12);

  /// Precedence for the <, <=, >, >= operators in sql
  static const Precedence comparison = Precedence._(13);

  /// Precedence for bitwise operators in sql
  static const Precedence bitwise = Precedence._(14);

  /// Precedence for the (binary) plus and minus operators in sql
  static const Precedence plusMinus = Precedence._(15);

  /// Precedence for the *, / and % operators in sql
  static const Precedence mulDivide = Precedence._(16);

  /// Precedence for the || operator in sql
  static const Precedence stringConcatenation = Precedence._(17);

  /// Precedence for unary operators in sql
  static const Precedence unary = Precedence._(20);

  /// Precedence for postfix operators (like collate) in sql
  static const Precedence postfix = Precedence._(21);

  /// Highest precedence in sql, used for variables and literals.
  static const Precedence primary = Precedence._(100);
}

/// An expression that looks like "$a operator $b", where $a and $b itself
/// are expressions and the operator is any string.
abstract class _InfixOperator<D> extends Expression<D> {
  /// The left-hand side of this expression
  Expression get left;

  /// The right-hand side of this expresion
  Expression get right;

  /// The sql operator to write
  String get operator;

  @override
  void writeInto(GenerationContext context) {
    writeInner(context, left);
    context.writeWhitespace();
    context.buffer.write(operator);
    context.writeWhitespace();
    writeInner(context, right);
  }

  @override
  int get hashCode => Object.hash(left, right, operator);

  @override
  bool operator ==(Object other) {
    return other is _InfixOperator &&
        other.left == left &&
        other.right == right &&
        other.operator == operator;
  }
}

class _BaseInfixOperator<D> extends _InfixOperator<D> {
  @override
  final Expression left;

  @override
  final String operator;

  @override
  final Expression right;

  @override
  final Precedence precedence;

  _BaseInfixOperator(this.left, this.operator, this.right,
      {this.precedence = Precedence.unknown});
}

/// Defines the possible comparison operators that can appear in a
/// [_Comparison].
enum _ComparisonOperator {
  /// '<' in sql
  less,

  /// '<=' in sql
  lessOrEqual,

  /// '=' in sql
  equal,

  /// '>=' in sql
  moreOrEqual,

  /// '>' in sql
  more
}

/// An expression that compares two child expressions.
class _Comparison extends _InfixOperator<bool> {
  static const Map<_ComparisonOperator, String> _operatorNames = {
    _ComparisonOperator.less: '<',
    _ComparisonOperator.lessOrEqual: '<=',
    _ComparisonOperator.equal: '=',
    _ComparisonOperator.moreOrEqual: '>=',
    _ComparisonOperator.more: '>'
  };

  @override
  final Expression left;
  @override
  final Expression right;

  /// The operator to use for this comparison
  final _ComparisonOperator op;

  @override
  String get operator => _operatorNames[op]!;

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
}

class _UnaryMinus<DT> extends Expression<DT> {
  final Expression<DT> inner;

  _UnaryMinus(this.inner);

  @override
  Precedence get precedence => Precedence.unary;

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write('-');
    inner.writeInto(context);
  }

  @override
  int get hashCode => inner.hashCode * 5;

  @override
  bool operator ==(Object other) {
    return other is _UnaryMinus && other.inner == inner;
  }
}

class _DartCastExpression<D1, D2> extends Expression<D2> {
  final Expression<D1> inner;

  _DartCastExpression(this.inner);

  @override
  Precedence get precedence => inner.precedence;

  @override
  bool get isLiteral => inner.isLiteral;

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

class _CastInSqlExpression<D1, D2> extends Expression<D2> {
  final Expression<D1> inner;

  @override
  final Precedence precedence = Precedence.primary;

  _CastInSqlExpression(this.inner);

  @override
  void writeInto(GenerationContext context) {
    final type = context.typeSystem.forDartType<D2>();

    context.buffer.write('CAST(');
    inner.writeInto(context);
    context.buffer.write(' AS ${type.sqlName})');
  }
}

/// A sql expression that calls a function.
///
/// This class is mainly used by drift internally. If you find yourself using
/// this class, consider [creating an issue](https://github.com/simolus3/moor/issues/new)
/// to request native support in drift.
class FunctionCallExpression<R> extends Expression<R> {
  /// The name of the function to call
  final String functionName;

  /// The arguments passed to the function, as expressions.
  final List<Expression> arguments;

  @override
  final Precedence precedence = Precedence.primary;

  /// Constructs a function call expression in sql from the [functionName] and
  /// the target [arguments].
  FunctionCallExpression(this.functionName, this.arguments);

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
  final columns = statement._returnedColumnCount;
  if (columns != 1) {
    throw ArgumentError.value(statement, 'statement',
        'Must return exactly one column (actually returns $columns)');
  }
}

/// Creates a subquery expression from the given [statement].
///
/// The statement, which can be created via [DatabaseConnectionUser.select] in
/// a database class, must return exactly one row with exactly one column.
Expression<R> subqueryExpression<R>(BaseSelectStatement statement) {
  _checkSubquery(statement);
  return _SubqueryExpression<R>(statement);
}

class _SubqueryExpression<R> extends Expression<R> {
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
