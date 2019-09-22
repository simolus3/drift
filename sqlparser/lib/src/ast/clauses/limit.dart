part of '../ast.dart';

/// Base for limit statements. Without moor extensions, only [Limit] will be
/// parsed. With moor extensions, a [DartLimitPlaceholder] can be emitted as
/// well.
abstract class LimitBase implements AstNode {}

class Limit extends AstNode implements LimitBase {
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
