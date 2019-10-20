part of '../ast.dart';

abstract class BaseSelectStatement extends Statement
    with CrudStatement, ResultSet {
  /// The resolved list of columns returned by this select statements. Not
  /// available from the parse tree, will be set later by the analyzer.
  @override
  List<Column> resolvedColumns;
}

class SelectStatement extends BaseSelectStatement implements HasWhereClause {
  final bool distinct;
  final List<ResultColumn> columns;
  final List<Queryable> from;

  @override
  final Expression where;
  final GroupBy groupBy;
  final List<NamedWindowDeclaration> windowDeclarations;

  final OrderByBase orderBy;
  final LimitBase limit;

  SelectStatement(
      {this.distinct = false,
      this.columns,
      this.from,
      this.where,
      this.groupBy,
      this.windowDeclarations = const [],
      this.orderBy,
      this.limit});

  @override
  T accept<T>(AstVisitor<T> visitor) {
    return visitor.visitSelectStatement(this);
  }

  @override
  Iterable<AstNode> get childNodes {
    return [
      ...columns,
      if (from != null) ...from,
      if (where != null) where,
      if (groupBy != null) groupBy,
      for (var windowDecl in windowDeclarations) windowDecl.definition,
      if (limit != null) limit,
      if (orderBy != null) orderBy,
    ];
  }

  @override
  bool contentEquals(SelectStatement other) {
    return other.distinct == distinct;
  }
}

class CompoundSelectStatement extends BaseSelectStatement {
  final SelectStatement base;
  final List<CompoundSelectPart> additional;

  // the grammar under https://www.sqlite.org/syntax/compound-select-stmt.html
  // defines an order by and limit clause on this node, but we parse them as
  // part of the last compound select statement in [additional]

  CompoundSelectStatement({
    @required this.base,
    this.additional = const [],
  });

  @override
  Iterable<AstNode> get childNodes {
    return [base, ...additional];
  }

  @override
  T accept<T>(AstVisitor<T> visitor) {
    return visitor.visitCompoundSelectStatement(this);
  }

  @override
  bool contentEquals(CompoundSelectStatement other) {
    // this class doesn't contain anything but child nodes
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

  StarResultColumn([this.tableName]);

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

enum CompoundSelectMode {
  union,
  unionAll,
  intersect,
  except,
}

class CompoundSelectPart extends AstNode {
  final CompoundSelectMode mode;
  final SelectStatement select;

  /// The first token of this statement, so either union, intersect or except.
  Token firstModeToken;

  /// The "ALL" token, if this is a "UNION ALL" part
  Token allToken;

  CompoundSelectPart({@required this.mode, @required this.select});

  @override
  Iterable<AstNode> get childNodes => [select];

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitCompoundSelectPart(this);

  @override
  bool contentEquals(CompoundSelectPart other) => mode == other.mode;
}
