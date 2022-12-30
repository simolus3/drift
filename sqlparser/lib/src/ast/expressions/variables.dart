part of '../ast.dart';

abstract class Variable extends Expression {
  int? resolvedIndex;
}

/// A "?" or "?123" variable placeholder
class NumberedVariable extends Expression implements Variable {
  QuestionMarkVariableToken? token;

  int? explicitIndex;

  @override
  int? resolvedIndex;

  NumberedVariable(this.explicitIndex) : resolvedIndex = explicitIndex;

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
  final String name;

  @override
  int? resolvedIndex;

  ColonNamedVariable.synthetic(this.name);

  ColonNamedVariable(ColonVariableToken token) : name = token.name;

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitNamedVariable(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {}

  @override
  Iterable<AstNode> get childNodes => [];
}
