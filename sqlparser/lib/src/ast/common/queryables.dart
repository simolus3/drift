part of '../ast.dart';

/// Marker interface for something that can appear after a "FROM" in a select
/// statement.
sealed class Queryable extends AstNode {}

/// https://www.sqlite.org/syntax/table-or-subquery.html
/// Marker interface
sealed class TableOrSubquery extends Queryable {
  /// The result set that this node made available, if any
  ResultSetAvailableInStatement? availableResultSet;
}

/// A table. The first path in https://www.sqlite.org/syntax/table-or-subquery.html
///
/// This is both referencable (if we have SELECT * FROM table t), other parts
/// of the select statement can access "t") and a reference owner (the table).
///
/// Note that this doesn't necessarily resolve to a result set. It could also
/// resolve to a common table expression or anything else defining a result
/// set.
class TableReference extends TableOrSubquery
    with ReferenceOwner
    implements Renamable, ResolvesToResultSet, InExpressionTarget {
  final String? schemaName;
  IdentifierToken? schemaNameToken;
  final String tableName;
  IdentifierToken? tableNameToken;

  @override
  AliasClause? as;

  TableReference(this.tableName, {this.as, this.schemaName});

  @override
  Iterable<AstNode> get childNodes => [?as];

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitTableReference(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    as = transformer.transformNullableChild(as, this, arg);
  }

  @override
  ResultSet? get resultSet {
    return resolved as ResultSet?;
  }

  @override
  bool get visibleToChildren => true;
}

/// A nested select statement that appears after a FROM clause. This is
/// different from nested select expressions, which can only return one value.
class SelectStatementAsSource extends TableOrSubquery implements Renamable {
  @override
  AliasClause? as;
  BaseSelectStatement statement;

  SelectStatementAsSource({required this.statement, this.as});

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitSelectStatementAsSource(this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [statement, ?as];

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    statement = transformer.transformChild(statement, this, arg);
    as = transformer.transformNullableChild(as, this, arg);
  }
}

/// https://www.sqlite.org/syntax/join-clause.html
class JoinClause extends Queryable {
  Queryable primary;
  List<Join> joins;

  JoinClause({required this.primary, required this.joins});

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitJoinClause(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    primary = transformer.transformChild(primary, this, arg);
    joins = transformer.transformChildren(joins, this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [primary, ...joins];
}

enum JoinOperatorKind {
  none, // just JOIN, no other keywords
  comma,
  left,
  right,
  full,
  inner,
  cross;

  bool get supportsOuterKeyword {
    switch (this) {
      case JoinOperatorKind.left:
      case JoinOperatorKind.right:
      case JoinOperatorKind.full:
        return true;
      default:
        return false;
    }
  }
}

class JoinOperator extends AstNode {
  final bool natural;
  final bool outer;
  final JoinOperatorKind operator;

  JoinOperator(this.operator, {this.natural = false, this.outer = false});

  JoinOperator.comma()
    : natural = false,
      outer = false,
      operator = JoinOperatorKind.comma;

  @override
  Iterable<AstNode> get childNodes => const Iterable.empty();

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitJoinOperator(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {}
}

class Join extends AstNode {
  JoinOperator operator;
  Queryable query;
  final JoinConstraint? constraint;

  Join({required this.operator, required this.query, this.constraint});

  @override
  Iterable<AstNode> get childNodes {
    return [
      operator,
      query,
      if (constraint is OnConstraint) (constraint as OnConstraint).expression,
    ];
  }

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitJoin(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    operator = transformer.transformChild(operator, this, arg);
    query = transformer.transformChild(query, this, arg);
    if (constraint is OnConstraint) {
      final onConstraint = constraint as OnConstraint;
      onConstraint.expression = transformer.transformChild(
        onConstraint.expression,
        this,
        arg,
      );
    }
  }
}

/// https://www.sqlite.org/syntax/join-constraint.html
abstract class JoinConstraint {}

class OnConstraint extends JoinConstraint {
  Expression expression;
  OnConstraint({required this.expression});
}

class UsingConstraint extends JoinConstraint {
  final List<String> columnNames;

  UsingConstraint({required this.columnNames});
}

class TableValuedFunction extends Queryable
    implements
        TableOrSubquery,
        SqlInvocation,
        Renamable,
        ResolvesToResultSet,
        InExpressionTarget {
  @override
  final String? schemaName;
  @override
  final String name;

  @override
  IdentifierToken? schemaNameToken;

  @override
  Token? nameToken;

  @override
  AliasClause? as;

  @override
  FunctionParameters parameters;

  @override
  ResultSet? resultSet;

  TableValuedFunction(this.name, this.parameters, {this.schemaName, this.as});

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitTableValuedFunction(this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [parameters, ?as];

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    parameters = transformer.transformChild(parameters, this, arg);
    as = transformer.transformNullableChild(as, this, arg);
  }

  @override
  bool get visibleToChildren => false;

  @override
  ResultSetAvailableInStatement? availableResultSet;
}
