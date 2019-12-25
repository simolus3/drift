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
  T accept<T>(AstVisitor<T> visitor) {
    return visitor.visitNumberedVariable(this);
  }

  @override
  Iterable<AstNode> get childNodes => const [];

  @override
  bool contentEquals(NumberedVariable other) {
    return other.explicitIndex == explicitIndex;
  }
}

class ColonNamedVariable extends Expression with Variable {
  final ColonVariableToken token;
  String get name => token.name;

  ColonNamedVariable(this.token);

  @override
  T accept<T>(AstVisitor<T> visitor) {
    return visitor.visitNamedVariable(this);
  }

  @override
  Iterable<AstNode> get childNodes => [];

  @override
  bool contentEquals(ColonNamedVariable other) {
    return other.name == name;
  }
}
