import 'package:collection/collection.dart';
import 'package:drift_core/src/builder/context.dart';
import 'package:meta/meta.dart';

import 'expression.dart';

@internal
class BinaryExpression<T> extends Expression<T> {
  final Expression<Object?> _left, _right;
  final String _operator;

  BinaryExpression(
    this._left,
    this._operator,
    this._right, {
    Precedence precedence = Precedence.unknown,
  }) : super(precedence: precedence);

  @override
  void writeInto(GenerationContext context) {
    writeInner(context, _left);
    context.buffer.write(' $_operator ');
    writeInner(context, _right);
  }
}

/// A sql expression that calls a function.
///
/// This class is mainly used by drift internally. If you find yourself using
/// this class, consider [creating an issue](https://github.com/simolus3/drift/issues/new)
/// to request native support in drift.
class FunctionCallExpression<R> extends Expression<R> {
  static const _equality = ListEquality();

  /// The name of the function to call
  final String functionName;

  /// The arguments passed to the function, as expressions.
  final List<Expression> arguments;

  @override
  Precedence get precedence => Precedence.primary;

  /// Constructs a function call expression in sql from the [functionName] and
  /// the target [arguments].
  FunctionCallExpression(this.functionName, this.arguments);

  @override
  void writeInto(GenerationContext context) {
    context.buffer
      ..write(functionName)
      ..write('(');
    context.join(arguments, ',');
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
