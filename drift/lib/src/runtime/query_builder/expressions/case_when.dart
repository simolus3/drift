import '../query_builder.dart';

/// A `CASE WHEN` expression (without base expression) in sqlite.
class CaseWhenExpression<R extends Object> extends _CaseWhenExpression<R> {
  /// Creates a `CASE WHEN` expression from the independent components.
  CaseWhenExpression({
    required Map<Expression, Expression<R>> when,
    Expression<R>? orElse,
  }) : super._(null, when.entries.toList(), orElse);
}

/// A `CASE WHEN` expression (with base expression) in sqlite.
class CaseWhenExpressionWithBase<T extends Object, R extends Object>
    extends _CaseWhenExpression<R> {
  /// Creates a `CASE WHEN` expression from the independent components.
  CaseWhenExpressionWithBase(
    Expression<T> base, {
    required Map<Expression<T>, Expression<R>> when,
    Expression<R>? orElse,
  }) : super._(base, when.entries.toList(), orElse);
}

/// A `CASE WHEN` expression in sqlite.
///
/// This class supports when expressions with or without a base expression.

abstract class _CaseWhenExpression<T extends Object> extends Expression<T> {
  /// The optional base expression. If it's set, the keys in [whenThen] will be
  /// compared to this expression.
  final Expression? base;

  /// The when entries for this expression. This expression will evaluate to the
  /// value of the entry with a matching key.
  final List<MapEntry<Expression, Expression<T>>> whenThen;

  /// The expression to use if no entry in [whenThen] matched.
  final Expression<T>? orElse;

  /// Creates a `CASE WHEN` expression from the independent components.
  _CaseWhenExpression._(this.base, this.whenThen, this.orElse) {
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
