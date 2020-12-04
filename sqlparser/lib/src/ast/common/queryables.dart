part of '../ast.dart';

/// Marker interface for something that can appear after a "FROM" in a select
/// statement.
abstract class Queryable extends AstNode {
  // todo remove this, introduce more visit methods for subclasses
  T when<T>({
    @required T Function(TableReference) isTable,
    @required T Function(SelectStatementAsSource) isSelect,
    @required T Function(JoinClause) isJoin,
    @required T Function(TableValuedFunction) isTableFunction,
  }) {
    if (this is TableReference) {
      return isTable(this as TableReference);
    } else if (this is SelectStatementAsSource) {
      return isSelect(this as SelectStatementAsSource);
    } else if (this is JoinClause) {
      return isJoin(this as JoinClause);
    } else if (this is TableValuedFunction) {
      return isTableFunction(this as TableValuedFunction);
    }

    throw StateError('Unknown subclass');
  }
}

/// https://www.sqlite.org/syntax/table-or-subquery.html
/// Marker interface
abstract class TableOrSubquery extends Queryable {}

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
    implements Renamable, ResolvesToResultSet {
  final String tableName;
  Token tableNameToken;

  @override
  final String as;

  TableReference(this.tableName, [this.as]);

  @override
  Iterable<AstNode> get childNodes => const [];

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitTableReference(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {}

  @override
  ResultSet get resultSet {
    return resolved as ResultSet;
  }

  @override
  bool get visibleToChildren => true;
}

/// A nested select statement that appears after a FROM clause. This is
/// different from nested select expressions, which can only return one value.
class SelectStatementAsSource extends TableOrSubquery implements Renamable {
  @override
  final String as;
  BaseSelectStatement statement;

  SelectStatementAsSource({@required this.statement, this.as});

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitSelectStatementAsSource(this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [statement];

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    statement = transformer.transformChild(statement, this, arg);
  }
}

/// https://www.sqlite.org/syntax/join-clause.html
class JoinClause extends Queryable {
  TableOrSubquery primary;
  final List<Join> joins;

  JoinClause({@required this.primary, @required this.joins});

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitJoinClause(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    primary = transformer.transformChild(primary, this, arg);
    transformer.transformChildren(joins, this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [primary, ...joins];
}

enum JoinOperator {
  none, // just JOIN, no other keywords
  comma,
  left,
  leftOuter,
  inner,
  cross,
}

class Join extends AstNode {
  final bool natural;
  final JoinOperator operator;
  TableOrSubquery query;
  final JoinConstraint /*?*/ constraint;

  Join(
      {this.natural = false,
      @required this.operator,
      @required this.query,
      this.constraint});

  @override
  Iterable<AstNode> get childNodes {
    return [
      query,
      if (constraint is OnConstraint) (constraint as OnConstraint).expression
    ];
  }

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitJoin(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    query = transformer.transformChild(query, this, arg);
    if (constraint is OnConstraint) {
      final onConstraint = constraint as OnConstraint;
      onConstraint.expression =
          transformer.transformChild(onConstraint.expression, this, arg);
    }
  }
}

/// https://www.sqlite.org/syntax/join-constraint.html
abstract class JoinConstraint {}

class OnConstraint extends JoinConstraint {
  Expression expression;
  OnConstraint({@required this.expression});
}

class UsingConstraint extends JoinConstraint {
  final List<String> columnNames;

  UsingConstraint({@required this.columnNames});
}

class TableValuedFunction extends Queryable
    implements TableOrSubquery, SqlInvocation, Renamable, ResolvesToResultSet {
  @override
  final String name;

  @override
  final String as;

  @override
  FunctionParameters parameters;

  @override
  ResultSet resultSet;

  TableValuedFunction(this.name, this.parameters, {this.as});

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitTableValuedFunction(this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [parameters];

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    parameters = transformer.transformChild(parameters, this, arg);
  }

  @override
  bool get visibleToChildren => false;
}
