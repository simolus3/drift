import 'package:meta/meta.dart';

import '../builder/builder.dart';
import 'expression.dart';

/// A `CASE WHEN` expression in SQL.
///
/// This class supports when expressions with or without a base expression.
@internal
class CaseWhenExpression<T> extends Expression<T> {
  /// The optional base expression. If it's set, the keys in [whenThen] will be
  /// compared to this expression.
  final Expression? base;

  /// The when entries for this expression. This expression will evaluate to the
  /// value of the entry with a matching key.
  final List<MapEntry<Expression, Expression>> whenThen;

  /// The expression to use if no entry in [whenThen] matched.
  final Expression<T>? orElse;

  /// Creates a `CASE WHEN` expression from the independent components.
  CaseWhenExpression(this.base, this.whenThen, this.orElse);

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write('CASE ');
    base?.writeInto(context);

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
