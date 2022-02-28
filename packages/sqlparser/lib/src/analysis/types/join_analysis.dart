import '../../ast/ast.dart';
import '../analysis.dart';

/// Tracks table references that must be non-nullable in a query row.
///
/// This is used to determine the nullability of column references. For
/// instance, consider the following query:
///
/// ```sql
/// SELECT foo.x, bar.y FROM foo
///   LEFT OUTER JOIN bar ON ...
/// ```
///
/// Clearly, `foo.x` is non-nullable in the result if `x` is a non-nullable
/// column in `foo`. We can't say the same thing about `bar.y` though: Even if
/// the column is declared to be `NOT NULL`, `bar` might be nullable in this
/// query.
///
/// A [JoinModel] is attached to each basic [SelectStatement]. You can obtain
/// the model for any ast node via [JoinModel.of]. It will lookup the model from
/// the enclosing [SelectStatement], if there is one.
///
/// If a [Reference] refers to a table that's in [JoinModel.nonNullable] and
/// the resolved column is non-nullable, we can assume that the reference is
/// going to be non-nullable too.
///
/// At the moment, we consider the following tables to be
/// [JoinModel.nonNullable]:
///  - the "primary" table of a select statement (`foo` in the example above)
///  - inner, cross, regular (no keyword, comma) joins
///
/// In the future, we'll also consider foreign key constraints.
class JoinModel {
  final List<ResultSetAvailableInStatement> nonNullable;

  JoinModel._(this.nonNullable);

  factory JoinModel._resolve(AstNode statement) {
    final visitor = _FindNonNullableJoins();
    statement.accept(visitor, true);

    return JoinModel._(visitor.nonNullable);
  }

  static JoinModel? of(AstNode node) {
    final enclosingStatement = node.enclosingOfType<CrudStatement>();
    if (enclosingStatement == null) return null;

    final existing = enclosingStatement.meta<JoinModel>();
    if (existing != null) return existing;

    final created = JoinModel._resolve(enclosingStatement);
    enclosingStatement.setMeta(created);
    return created;
  }

  /// Computes whether the element the [reference] is pointing to is nullable
  /// from the perspective of this join model.
  ///
  /// This does not include the computed nullability of what the reference is
  /// referring to, just whether the reference points to a table that may not
  /// be present because it comes from an outer join.
  bool? referenceIsNullable(Reference reference) {
    final resolved = reference.resolvedColumn;
    if (resolved is AvailableColumn) {
      return availableColumnIsNullable(resolved);
    }

    final resultSet = reference.resultEntity;
    // ignore: avoid_returning_null
    if (resultSet == null) return null;

    return !nonNullable.contains(resultSet);
  }

  /// Returns whether an [AvailableColumn] is nullable from the perspective of
  /// this join model by checking whether it comes from an outer join.
  bool availableColumnIsNullable(AvailableColumn column) {
    return !nonNullable.contains(column.source);
  }

  /// Checks whether the result set is nullable in the surrounding select
  /// statement.
  bool isNullableTable(ResultSet resultSet) {
    return nonNullable.every((nonNullableRef) {
      return nonNullableRef.resultSet.resultSet != resultSet;
    });
  }
}

// The boolean arg indicates whether a visited queryable is needed for the
// result to have any rows (which, in particular, mean's its non-nullable)
class _FindNonNullableJoins extends RecursiveVisitor<bool, void> {
  final List<ResultSetAvailableInStatement> nonNullable = [];

  void _addIfMakesResultStatementAvailable(TableOrSubquery node) {
    final resultSet = node.availableResultSet;
    if (resultSet != null) nonNullable.add(resultSet);
  }

  @override
  void visitSelectStatement(SelectStatement e, bool arg) {
    visitNullable(e.from, true);
  }

  @override
  void visitDeleteStatement(DeleteStatement e, bool arg) {
    visit(e.table, true);
  }

  @override
  void visitInsertStatement(InsertStatement e, bool arg) {
    visit(e.table, true);
  }

  @override
  void visitUpdateStatement(UpdateStatement e, bool arg) {
    visit(e.table, true);
    visitNullable(e.from, true);
  }

  @override
  void visitJoinClause(JoinClause e, bool arg) {
    if (!arg) return;

    visit(e.primary, true);
    for (final additional in e.joins) {
      if (additional.operator != JoinOperator.left &&
          additional.operator != JoinOperator.leftOuter) {
        visit(additional, true);
      }
    }
  }

  @override
  void visitTableReference(TableReference e, bool arg) {
    if (arg) _addIfMakesResultStatementAvailable(e);
  }

  @override
  void visitSelectStatementAsSource(SelectStatementAsSource e, bool arg) {
    if (arg) _addIfMakesResultStatementAvailable(e);
  }

  @override
  void visitTableValuedFunction(TableValuedFunction e, bool arg) {
    if (arg) _addIfMakesResultStatementAvailable(e);
  }
}
