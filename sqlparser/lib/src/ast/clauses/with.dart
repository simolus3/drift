part of '../ast.dart';

class WithClause extends AstNode {
  Token? withToken;

  final bool recursive;
  Token? recursiveToken;

  final List<CommonTableExpression> ctes;

  WithClause({required this.recursive, required this.ctes});

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitWithClause(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    transformer.transformChildren(ctes, this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => ctes;
}

class CommonTableExpression extends AstNode with ResultSet {
  final String cteTableName;

  /// If this common table expression has explicit column names, e.g. with
  /// `cnt(x) AS (...)`, contains the column names (`['x']`, in that case).
  /// Otherwise null.
  final List<String>? columnNames;
  BaseSelectStatement as;

  Token? asToken;
  IdentifierToken? tableNameToken;

  List<CommonTableExpressionColumn>? _cachedColumns;

  CommonTableExpression(
      {required this.cteTableName, this.columnNames, required this.as});

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitCommonTableExpression(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    as = transformer.transformChild(as, this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [as];

  @override
  List<Column>? get resolvedColumns {
    final columnsOfSelect = as.resolvedColumns;

    // we don't override column names, so just return the columns declared by
    // the select statement
    if (columnNames == null) return columnsOfSelect;

    final cached = _cachedColumns ??=
        columnNames!.map((name) => CommonTableExpressionColumn(name)).toList();

    if (columnsOfSelect != null) {
      // bind the CommonTableExpressionColumn to the real underlying column
      // returned by the select statement

      for (var i = 0; i < cached.length; i++) {
        if (i < columnsOfSelect.length) {
          final selectColumn = columnsOfSelect[i];
          cached[i].innerColumn = selectColumn;
        }
      }
    }

    return _cachedColumns;
  }

  @override
  bool get visibleToChildren => true;
}
