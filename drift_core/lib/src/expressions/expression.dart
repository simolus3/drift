import 'package:meta/meta.dart';

import '../builder/context.dart';

import '../types.dart';
import 'case_when.dart';
import 'common.dart';

abstract class Expression<T> extends SqlComponent {
  final Precedence precedence;

  const Expression({this.precedence = Precedence.unknown});

  /// Whether this expression is a literal. Some use-sites need to put
  /// parentheses around non-literals.
  bool get isLiteral => false;

  Expression<bool> eq(Expression<bool> compareTo) {
    return BinaryExpression(this, '=', compareTo);
  }

  Expression<T2> dartCast<T2>() => _DartCastExpression<T, T2>(this);

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
  Expression<T2> caseMatch<T2>({
    required Map<Expression<T>, Expression<T2>> when,
    Expression<T2>? orElse,
  }) {
    if (when.isEmpty) {
      throw ArgumentError.value(when, 'when', 'Must not be empty');
    }

    return CaseWhenExpression<T2>(this, when.entries.toList(), orElse);
  }

  Expression<T2> cast<T2>(SqlType<T2> type) => _CastInSqlExpression(this, type);

  /// Writes this expression into the [GenerationContext], assuming that there's
  /// an outer expression with [precedence]. If the [Expression.precedence] of
  /// `this` expression is lower, it will be wrappped in parentheses.
  ///
  /// See also:
  ///  - [SqlComponent.writeInto], which doesn't take any precedence relation
  ///    into account.
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
  final SqlType<D2> type;

  _CastInSqlExpression(this.inner, this.type)
      : super(precedence: Precedence.primary);

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write('CAST(');
    inner.writeInto(context);
    context.buffer.write(' AS ${type.name})');
  }
}
