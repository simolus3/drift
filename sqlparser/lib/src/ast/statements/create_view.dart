part of '../ast.dart';

/// A "CREATE VIEW" statement, see https://sqlite.org/lang_createview.html
class CreateViewStatement extends Statement implements CreatingStatement {
  final bool ifNotExists;

  final String viewName;
  IdentifierToken? viewNameToken;

  BaseSelectStatement query;

  final List<String>? columns;

  CreateViewStatement(
      {this.ifNotExists = false,
      required this.viewName,
      this.columns,
      required this.query});

  @override
  String get createdName => viewName;

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitCreateViewStatement(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    query = transformer.transformChild(query, this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [query];
}
