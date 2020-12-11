part of '../ast.dart';

abstract class Variable extends Expression {
  int? resolvedIndex;
}

/// A "?" or "?123" variable placeholder
class NumberedVariable extends Expression implements Variable {
  final QuestionMarkVariableToken token;
  int? get explicitIndex => token.explicitIndex;

  @override
  int? resolvedIndex;

  NumberedVariable(this.token) {
    resolvedIndex = token.explicitIndex;
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

class ColonNamedVariable extends Expression implements Variable {
  final ColonVariableToken token;
  String get name => token.name;

  @override
  int? resolvedIndex;

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
