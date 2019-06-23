part of '../ast.dart';

class SelectStatement extends AstNode {
  final bool distinct;
  final Expression where;
  final List<ResultColumn> columns;
  final List<Queryable> from;
  final OrderBy orderBy;
  final Limit limit;

  SelectStatement(
      {this.distinct,
      this.where,
      this.columns,
      this.from,
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
      if (limit != null) limit,
      if (orderBy != null) orderBy,
    ];
  }

  @override
  bool contentEquals(SelectStatement other) {
    return true;
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

class ExpressionResultColumn extends ResultColumn implements Renamable {
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
