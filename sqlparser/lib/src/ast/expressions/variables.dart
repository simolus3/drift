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
  final String name;

  @override
  int? resolvedIndex;

  ColonNamedVariable._(this.name);

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

/// A variable that is created when a nested query requires data from the
/// main query. In most cases this can be treated like a colon named
/// variable, this this extends [ColonNamedVariable].
class NestedQueryVariable extends ColonNamedVariable {
  static String _nameFrom(String? entityName, String? columnName) {
    final buf = StringBuffer();

    if (entityName != null) {
      buf.write('${entityName}_');
    }
    buf.write(columnName);

    return buf.toString();
  }

  final String? entityName;
  final String columnName;

  NestedQueryVariable({
    required this.entityName,
    required this.columnName,
  }) : super._(_nameFrom(entityName, columnName));

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitNestedQueryVariable(this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => const [];

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {}
}
