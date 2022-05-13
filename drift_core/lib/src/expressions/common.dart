import 'package:collection/collection.dart';
import 'package:drift_core/src/builder/context.dart';
import 'package:meta/meta.dart';

import 'expression.dart';

const _equality = ListEquality();

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
  int get hashCode => Object.hash(functionName, _equality.hash(arguments));

  @override
  bool operator ==(Object other) {
    return other is FunctionCallExpression &&
        other.functionName == functionName &&
        _equality.equals(other.arguments, arguments);
  }
}

@internal
class InExpression<T> extends Expression<bool> {
  final Expression _expression;
  final List<T> _values;

  InExpression(this._expression, this._values)
      : super(precedence: Precedence.comparisonEq);

  @override
  void writeInto(GenerationContext context) {
    writeInner(context, _expression);

    context.buffer.write(' IN (');
    context.join(_values.map(sqlVar), ',');
    context.buffer.write(')');
  }

  @override
  int get hashCode => Object.hash(_expression, _equality.hash(_values));

  @override
  bool operator ==(Object other) {
    return other is InExpression &&
        other._expression == _expression &&
        _equality.equals(other._values, _values);
  }
}
