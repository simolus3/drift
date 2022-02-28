part of '../ast.dart';

/// Base for `LIMIT` clauses. Without drift extensions, only [Limit] will be
/// parsed. With drift extensions, a [DartLimitPlaceholder] can be emitted as
/// well.
abstract class LimitBase implements AstNode {}

class Limit extends AstNode implements LimitBase {
  Expression count;
  Token? offsetSeparator; // can either be OFFSET or just a comma
  Expression? offset;

  Limit({required this.count, this.offsetSeparator, this.offset});

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitLimit(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    count = transformer.transformChild(count, this, arg);
    offset = transformer.transformNullableChild(offset, this, arg);
  }

  @override
  Iterable<AstNode> get childNodes {
    if (offsetSeparator?.type == TokenType.offset) {
      // Amount first, then offset
      return [count, offset!];
    }

    // If using a comma, the count is followed by an optional offset
    return [count, if (offset != null) offset!];
  }
}
