import 'package:sqlparser/src/reader/tokenizer/token.dart';

part 'clauses/limit.dart';

part 'expressions/expressions.dart';
part 'expressions/literals.dart';
part 'expressions/simple.dart';

part 'statements/select.dart';

abstract class AstNode {
  Iterable<AstNode> get childNodes;
  T accept<T>(AstVisitor<T> visitor);
}

abstract class AstVisitor<T> {
  T visitSelectStatement(SelectStatement e);

  T visitLimit(Limit e);

  T visitBinaryExpression(BinaryExpression e);
  T visitUnaryExpression(UnaryExpression e);
  T visitIsExpression(IsExpression e);
  T visitLiteral(Literal e);
}
