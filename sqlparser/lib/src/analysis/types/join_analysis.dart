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

  factory JoinModel._resolve(SelectStatement statement) {
    final visitor = _FindNonNullableJoins();
    visitor.visitSelectStatement(statement, true);

    return JoinModel._(visitor.nonNullable);
  }

  static JoinModel? of(AstNode node) {
    final enclosingSelect = node.enclosingOfType<SelectStatement>();
    if (enclosingSelect == null) return null;

    final existing = enclosingSelect.meta<JoinModel>();
    if (existing != null) return existing;

    final created = JoinModel._resolve(enclosingSelect);
    enclosingSelect.setMeta(created);
    return created;
  }

  bool? referenceIsNullable(Reference reference) {
    final resolved = reference.resolvedColumn;
    if (resolved is AvailableColumn) {
      return !nonNullable.contains(resolved.source);
    }

    final resultSet = reference.resultEntity;
    // ignore: avoid_returning_null
    if (resultSet == null) return null;

    return !nonNullable.contains(resultSet);
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
