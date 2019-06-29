part of '../ast.dart';

class SelectStatement extends Statement with ResultSet {
  final bool distinct;
  final List<ResultColumn> columns;
  final List<Queryable> from;

  final Expression where;
  final GroupBy groupBy;

  final OrderBy orderBy;
  final Limit limit;

  /// The resolved list of columns returned by this select statements. Not
  /// available from the parse tree, will be set later by the analyzer.
  @override
  List<Column> resolvedColumns;

  SelectStatement(
      {this.distinct = false,
      this.columns,
      this.from,
      this.where,
      this.groupBy,
      this.orderBy,
      this.limit});

  @override
  T accept<T>(AstVisitor<T> visitor) {
    return visitor.visitSelectStatement(this);
  }

  @override
  Iterable<AstNode> get childNodes {
    return [
      if (where != null) where,
      ...columns,
      if (from != null) ...from,
      if (groupBy != null) groupBy,
      if (limit != null) limit,
      if (orderBy != null) orderBy,
    ];
  }

  @override
  bool contentEquals(SelectStatement other) {
    return other.distinct == distinct;
  }
}

abstract class ResultColumn extends AstNode {
  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitResultColumn(this);
}

/// A result column that either yields all columns or all columns from a table
/// by using "*" or "table.*".
class StarResultColumn extends ResultColumn {
  final String tableName;

  StarResultColumn(this.tableName);

  @override
  Iterable<AstNode> get childNodes => const [];

  @override
  bool contentEquals(StarResultColumn other) {
    return other.tableName == tableName;
  }
}

class ExpressionResultColumn extends ResultColumn
    implements Renamable, Referencable {
  final Expression expression;
  @override
  final String as;

  ExpressionResultColumn({@required this.expression, this.as});

  @override
  Iterable<AstNode> get childNodes => [expression];

  @override
  bool contentEquals(ExpressionResultColumn other) {
    return other.as == as;
  }
}

class GroupBy extends AstNode {
  /// The list of expressions that form the partition
  final List<Expression> by;
  final Expression having;

  GroupBy({@required this.by, this.having});

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitGroupBy(this);

  @override
  Iterable<AstNode> get childNodes => [...by, if (having != null) having];

  @override
  bool contentEquals(GroupBy other) {
    return true; // Defined via child nodes
  }
}
