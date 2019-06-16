import 'package:sqlparser/src/ast/ast.dart';
import 'package:sqlparser/src/ast/expressions/simple.dart';

/// Checks whether [a] and [b] are equal. If they aren't, throws an exception.
void enforceEqual(AstNode a, AstNode b) {
  if (a.runtimeType != b.runtimeType) {
    throw ArgumentError('Not equal: First was $a, second $b');
  }
  _checkAdditional(a, b);

  final childrenA = a.childNodes.iterator;
  final childrenB = b.childNodes.iterator;

  // always move both iterators
  while (childrenA.moveNext() & childrenB.moveNext()) {
    enforceEqual(childrenA.current, childrenB.current);
  }

  if (childrenA.moveNext() || childrenB.moveNext()) {
    throw ArgumentError("$a and $b don't have an equal amount of children");
  }
}

void _checkAdditional<T extends AstNode>(T a, T b) {
  if (a is IsExpression) {
    return _checkIsExpr(a, b as IsExpression);
  } else if (a is UnaryExpression) {
    _checkUnaryExpression(a, b as UnaryExpression);
  } else if (a is BinaryExpression) {
    _checkBinaryExpression(a, b as BinaryExpression);
  }
}

void _checkIsExpr(IsExpression a, IsExpression b) {
  if (a.negated != b.negated) {
    throw ArgumentError('Negation status not the same');
  }
}

void _checkUnaryExpression(UnaryExpression a, UnaryExpression b) {
  if (a.operator.type != b.operator.type) throw ArgumentError('Different type');
}

void _checkBinaryExpression(BinaryExpression a, BinaryExpression b) {
  if (a.operator.type != b.operator.type) throw ArgumentError('Different type');
}
