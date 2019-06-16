import 'package:sqlparser/src/ast/expressions/literals.dart';
import 'package:sqlparser/src/ast/expressions/simple.dart';

abstract class AstNode {
  Iterable<AstNode> get childNodes;
  T accept<T>(AstVisitor<T> visitor);
}

abstract class AstVisitor<T> {
  T visitBinaryExpression(BinaryExpression e);
  T visitUnaryExpression(UnaryExpression e);
  T visitIsExpression(IsExpression e);
  T visitLiteral(Literal e);
}
