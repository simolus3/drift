part of '../ast.dart';

class Limit extends AstNode {
  Expression count;
  Token offsetSeparator; // can either be OFFSET or just a comma
  Expression offset;

  Limit({this.count, this.offsetSeparator, this.offset});

  @override
  T accept<T>(AstVisitor<T> visitor) {
    return visitor.visitLimit(this);
  }

  @override
  Iterable<AstNode> get childNodes => [count, if (offset != null) offset];

  @override
  bool contentEquals(Limit other) {
    return other.offsetSeparator?.type == offsetSeparator?.type;
  }
}
