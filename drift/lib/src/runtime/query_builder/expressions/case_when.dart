import 'package:meta/meta.dart';

import '../query_builder.dart';

/// `CASE WHEN` expression **without** base expression in sqlite.
///
/// This expression evaluates to the first value in [CaseWhenExpression.when]
/// for which its key evaluates to `true`.
///
/// See [BaseCaseWhenExpression] for more info.
class CaseWhenExpression<R extends Object> extends BaseCaseWhenExpression<R> {
  /// Creates a `CASE WHEN` expression from the independent components.
  ///
  /// If [when] is empty - throws [ArgumentError]
  CaseWhenExpression({
    required Map<Expression<bool>, Expression<R>> when,
    Expression<R>? orElse,
  }) : super._(null, when.entries.toList(), orElse);
}

/// `CASE WHEN` expression **with** base expression in sqlite.
///
/// For internal use. Must be used via [Expression.caseMatch]
///
/// See [BaseCaseWhenExpression] for more info.
@internal
class CaseWhenExpressionWithBase<T extends Object, R extends Object>
    extends BaseCaseWhenExpression<R> {
  /// Creates a `CASE WHEN` expression from the independent components.
  ///
  /// If [when] is empty - throws [ArgumentError]
  CaseWhenExpressionWithBase(
    Expression<T> base, {
    required Map<Expression<T>, Expression<R>> when,
    Expression<R>? orElse,
  }) : super._(base, when.entries.toList(), orElse);
}

/// `CASE WHEN` expression in sqlite.
///
/// This expression evaluates to the first value in [BaseCaseWhenExpression.whenThen]
/// for which its key evaluates to `true`.
///
/// Supports `CASE WHEN` expression with base expression and without base expression.
///
/// For internal use. Must be used via [CaseWhenExpression] and [CaseWhenExpressionWithBase]
///
/// https://www.sqlite.org/lang_expr.html#the_case_expression
@internal
abstract class BaseCaseWhenExpression<T extends Object> extends Expression<T> {
  /// The optional base expression.
  ///
  /// If it is set, the keys in [whenThen] will be compared to this expression.
  final Expression? base;

  /// The when-then entries for this expression.
  ///
  /// This expression will evaluate to the value of the entry with a matching key.
  final List<MapEntry<Expression, Expression<T>>> whenThen;

  /// The expression to use if no entry in [whenThen] matched.
  final Expression<T>? orElse;

  /// Creates a `CASE WHEN` expression from the independent components.
  ///
  /// If [whenThen] list is empty - throws [ArgumentError]
  BaseCaseWhenExpression._(this.base, this.whenThen, this.orElse) {
    if (whenThen.isEmpty) {
      throw ArgumentError.value(whenThen, 'whenThen', 'Must not be empty');
    }
  }

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write('CASE');

    if (base != null) {
      context.buffer.write(' ');
      base!.writeInto(context);
    }

    for (final entry in whenThen) {
      context.buffer.write(' WHEN ');
      entry.key.writeInto(context);
      context.buffer.write(' THEN ');
      entry.value.writeInto(context);
    }

    final orElse = this.orElse;
    if (orElse != null) {
      context.buffer.write(' ELSE ');
      orElse.writeInto(context);
    }

    context.buffer.write(' END');
  }
}
