part of '../ast.dart';

class WithClause extends AstNode {
  Token withToken;

  final bool recursive;
  Token recursiveToken;

  final List<CommonTableExpression> ctes;

  WithClause({@required this.recursive, @required this.ctes});

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitWithClause(this);

  @override
  Iterable<AstNode> get childNodes => ctes;

  @override
  bool contentEquals(WithClause other) => other.recursive == recursive;
}

class CommonTableExpression extends AstNode with ResultSet, VisibleToChildren {
  final String cteTableName;

  /// If this common table expression has explicit column names, e.g. with
  /// `cnt(x) AS (...)`, contains the column names (`['x']`, in that case).
  /// Otherwise null.
  final List<String> columnNames;
  final BaseSelectStatement as;

  Token asToken;
  IdentifierToken tableNameToken;

  List<CommonTableExpressionColumn> _cachedColumns;

  CommonTableExpression(
      {@required this.cteTableName, this.columnNames, @required this.as});

  @override
  T accept<T>(AstVisitor<T> visitor) {
    return visitor.visitCommonTableExpression(this);
  }

  @override
  Iterable<AstNode> get childNodes => [as];

  @override
  bool contentEquals(CommonTableExpression other) {
    return other.cteTableName == cteTableName;
  }

  @override
  List<Column> get resolvedColumns {
    final columnsOfSelect = as.resolvedColumns;

    // we don't override column names, so just return the columns declared by
    // the select statement
    if (columnNames == null) return columnsOfSelect;

    _cachedColumns ??= columnNames
        .map((name) => CommonTableExpressionColumn(name, null))
        .toList();

    if (columnsOfSelect != null) {
      // bind the CommonTableExpressionColumn to the real underlying column
      // returned by the select statement

      for (var i = 0; i < _cachedColumns.length; i++) {
        if (i < columnsOfSelect.length) {
          final selectColumn = columnsOfSelect[i];
          _cachedColumns[i].innerColumn = selectColumn;
        }
      }
    }

    return _cachedColumns;
  }
}
