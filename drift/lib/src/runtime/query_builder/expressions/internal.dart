@internal
import 'package:meta/meta.dart';

import '../query_builder.dart';

/// An expression that looks like "$a operator $b", where $a and $b itself
/// are expressions and the operator is any string.
abstract class InfixOperator<D extends Object> extends Expression<D> {
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
    return other is InfixOperator &&
        other.left == left &&
        other.right == right &&
        other.operator == operator;
  }
}

/// A basic binary expression with an infix operator.
class BaseInfixOperator<D extends Object> extends InfixOperator<D> {
  @override
  final Expression left;

  @override
  final String operator;

  @override
  final Expression right;

  @override
  final Precedence precedence;

  /// Create an infix operator with the child expressions, the operator and the
  /// assumed precedence.
  BaseInfixOperator(this.left, this.operator, this.right,
      {this.precedence = Precedence.unknown});
}
