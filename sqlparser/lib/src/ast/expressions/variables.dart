part of '../ast.dart';

mixin Variable on Expression {
  int resolvedIndex;
}

/// A "?" or "?123" variable placeholder
class NumberedVariable extends Expression with Variable {
  final QuestionMarkVariableToken token;
  int get explicitIndex => token.explicitIndex;

  NumberedVariable(this.token) {
    resolvedIndex = explicitIndex;
  }

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitNumberedVariable(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {}

  @override
  Iterable<AstNode> get childNodes => const [];
}

class ColonNamedVariable extends Expression with Variable {
  final ColonVariableToken token;
  String get name => token.name;

  ColonNamedVariable(this.token);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitNamedVariable(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {}

  @override
  Iterable<AstNode> get childNodes => [];
}
