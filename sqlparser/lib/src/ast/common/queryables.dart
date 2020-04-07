part of '../ast.dart';

/// Marker interface for something that can appear after a "FROM" in a select
/// statement.
abstract class Queryable extends AstNode {
  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitQueryable(this, arg);
  }

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
  bool contentEquals(TableReference other) {
    return other.tableName == tableName && other.as == as;
  }

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
  final BaseSelectStatement statement;

  SelectStatementAsSource({@required this.statement, this.as});

  @override
  Iterable<AstNode> get childNodes => [statement];

  @override
  bool contentEquals(SelectStatementAsSource other) {
    return other.as == as;
  }
}

/// https://www.sqlite.org/syntax/join-clause.html
class JoinClause extends Queryable {
  final TableOrSubquery primary;
  final List<Join> joins;

  JoinClause({@required this.primary, @required this.joins});

  @override
  Iterable<AstNode> get childNodes => [primary, ...joins];

  @override
  bool contentEquals(JoinClause other) {
    return true; // equality is defined by child nodes
  }
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
  final TableOrSubquery query;
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
  bool contentEquals(Join other) {
    if (other.natural != natural || other.operator != operator) {
      return false;
    }

    if (constraint is OnConstraint) {
      return other.constraint is OnConstraint;
    } else if (constraint is UsingConstraint) {
      final typedConstraint = constraint as UsingConstraint;
      if (other.constraint is! UsingConstraint) {
        return false;
      }
      final typedOther = other.constraint as UsingConstraint;

      return const ListEquality()
          .equals(typedConstraint.columnNames, typedOther.columnNames);
    }
    return true;
  }

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitJoin(this, arg);
  }
}

/// https://www.sqlite.org/syntax/join-constraint.html
abstract class JoinConstraint {}

class OnConstraint extends JoinConstraint {
  final Expression expression;
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
  final FunctionParameters parameters;

  @override
  ResultSet resultSet;

  TableValuedFunction(this.name, this.parameters, {this.as});

  @override
  Iterable<AstNode> get childNodes => [parameters];

  @override
  bool get visibleToChildren => false;

  @override
  bool contentEquals(TableValuedFunction other) {
    return other.name == name;
  }
}
