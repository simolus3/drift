import 'package:sqlparser/sqlparser.dart';

/// Analysis support for nested queries.
///
/// In drift, nested queries can be added with the `LIST` pseudofunction used
/// as a column. At runtime, the nested query is executed and its result are
/// collected as a list used as result for the main query.
/// As an example, consider the following query which selects all friends for
/// all users in a hypothetical social network:
///
/// ```sql
/// SELECT u.**, LIST(SELECT friend.* FROM users friend
///     INNER JOIN friendships f ON f.user_a = friend.id OR f.user_b = friend.id
///     INNER JOIN users other
///       ON other.id IN (f.user_a, f.user_b) AND other.id != friend.id
///     WHERE other.id = u.id) friends
///   FROM users u
/// ```
///
/// This would generate a class with a `User u` and a `List<User> friends;`
/// fields.
///
/// As shown in the example, nested queries can refer to columns from outer
/// queries (here, `WHERE other.id = u.id` refers to `u.id` from the outer
/// query). To implement this with separate runtime queries, a transformation
/// is needed. First, we mark all [Reference]s that capture a value from an
/// outer query. The outer query is then modified to include this reference in
/// its result set. In the inner query, the variable is replaced with a
/// variable. In generated code, we first run the outer query and, for each
/// result, then set the variable and run the inner query.
/// In the example, the two transformed queries could look like this:
///
/// ```
/// a: SELECT u.**, u.id AS "helper0" FROM users u;
/// b: SELECT friend.* FROM users friend
///      ...
///      WHERE other.id = ?;
/// ```
///
/// At runtime, we'd first run `a` and then run `b` with `?` instantiated to
/// `helper0` for each row in `a`.
///
/// When a nested query appears outside of a [NestedQueriesContainer], an
/// error will be reported.
class NestedQueryAnalyzer extends RecursiveVisitor<_AnalyzerState, void> {
  int _capturingVariableCounter = 0;

  final List<AnalysisError> errors = [];

  NestedQueriesContainer analyzeRoot(SelectStatement node) {
    final container = NestedQueriesContainer(node);

    final state = _AnalyzerState(container);
    node.accept(this, state);
    state._process();
    return container;
  }

  @override
  void visitMoorSpecificNode(MoorSpecificNode e, _AnalyzerState arg) {
    if (e is NestedQueryColumn) {
      final expectedParent = arg.container.select;
      if (e.parent != expectedParent || !expectedParent.columns.contains(e)) {
        // Not in a valid container or placed in an illegal position - report
        // error!
        errors.add(AnalysisError(
          relevantNode: e,
          message: 'A `LIST` result cannot be used here!',
          type: AnalysisErrorType.other,
        ));
      }

      final nested = NestedQuery(arg.container, e);
      arg.container.nestedQueries[e] = nested;

      final childState = _AnalyzerState(nested);
      super.visitMoorSpecificNode(e, childState);
      childState._process();
      return;
    }

    super.visitMoorSpecificNode(e, arg);
  }

  @override
  void visitReference(Reference e, _AnalyzerState arg) {
    final resultEntity = e.resultEntity;
    final container = arg.container;

    if (resultEntity != null && container is NestedQuery) {
      if (!resultEntity.origin.isChildOf(arg.container.select)) {
        // Reference captures a variable outside of this query
        final capture = container.capturedVariables[e] =
            CapturedVariable(e, _capturingVariableCounter++);

        // Keep track of the position of the variable so that we can later
        // assign it the right index.
        capture.introducedVariable.setSpan(e.first!, e.last!);
        arg.actualAndAddedVariables.add(capture.introducedVariable);
      }
    } else {
      // todo: Reference not resolved properly. An error should have been
      // reported already, but we'll definitely not generate correct code for
      // this.
    }
  }
}

class _AnalyzerState {
  final NestedQueriesContainer container;
  final List<Variable> actualAndAddedVariables = [];

  _AnalyzerState(this.container);

  void _process() => container._processAfterVisit(actualAndAddedVariables);
}

/// Something that can contain nested queries.
///
/// This contains the root select statement and all nested queries that appear
/// in a nested queries container.
class NestedQueriesContainer {
  final SelectStatement select;
  final Map<NestedQueryColumn, NestedQuery> nestedQueries = {};

  NestedQueriesContainer(this.select);

  /// Columns that should be added to the [select] statement to read variables
  /// captured by children.
  ///
  /// These columns aren't mounted to the same syntax tree as [select], they
  /// will be mounted into the tree returned by [addHelperNodes].
  final List<ExpressionResultColumn> addedColumns = [];

  Iterable<CapturedVariable> get variablesCapturedByChildren {
    return nestedQueries.values
        .expand((nested) => nested.capturedVariables.values);
  }

  void _processAfterVisit(List<Variable> variables) {
    // Add necessary columns
    for (final variable in variablesCapturedByChildren) {
      addedColumns.add(
        ExpressionResultColumn(
          expression: Reference(
            entityName: variable.reference.entityName,
            columnName: variable.reference.columnName,
          ),
          as: variable.helperColumn,
        ),
      );
    }

    // Re-index variables, this time also considering the synthetic variables
    // that we'll insert in [addHelperNodes] later.
    AstPreparingVisitor.resolveIndexOfVariables(variables);
  }
}

class NestedQuery extends NestedQueriesContainer {
  final NestedQueryColumn queryColumn;
  final NestedQueriesContainer parent;

  /// All references that read from a table only available in the outer
  /// select statement. It will need to be transformed in a later step.
  final Map<Reference, CapturedVariable> capturedVariables = {};

  NestedQuery(this.parent, this.queryColumn) : super(queryColumn.select);
}

class CapturedVariable {
  final Reference reference;

  /// A number uniquely identifying this captured variable in the select
  /// statement analyzed.
  ///
  /// This is used to add the necessary helper column later.
  final int queryGlobalId;

  /// The variable introduced to replace the original reference.
  ///
  /// This variable is not mounted to the same syntax tree as [reference], it
  /// will be mounted into the tree returned by [addHelperNodes].
  final ColonNamedVariable introducedVariable;

  String get helperColumn => '\$n_$queryGlobalId';

  CapturedVariable(this.reference, this.queryGlobalId)
      : introducedVariable = ColonNamedVariable.synthetic(':r$queryGlobalId') {
    introducedVariable.setMeta<CapturedVariable>(this);
  }
}

/// Rewrites the query backing the [rootContainer] to
///
/// - add result columns for outgoing references in nested queries
/// - replace outgoing references with variables
SelectStatement addHelperNodes(NestedQueriesContainer rootContainer) {
  return _NestedQueryTransformer()
      .transform(rootContainer.select, rootContainer) as SelectStatement;
}

class _NestedQueryTransformer extends Transformer<NestedQueriesContainer> {
  @override
  AstNode? visitSelectStatement(SelectStatement e, NestedQueriesContainer arg) {
    if (e == arg.select) {
      for (final column in arg.addedColumns) {
        e.columns.add(column..parent = e);
      }
    }
    return super.visitSelectStatement(e, arg);
  }

  @override
  AstNode? visitMoorSpecificNode(
      MoorSpecificNode e, NestedQueriesContainer arg) {
    if (e is NestedQueryColumn) {
      final child = arg.nestedQueries[e];
      if (child != null) {
        e.transformChildren(this, child);
      }

      // Remove nested query colums from the parent query
      return null;
    }
    return super.visitMoorSpecificNode(e, arg);
  }

  @override
  AstNode? visitReference(Reference e, NestedQueriesContainer arg) {
    final captured = arg is NestedQuery ? arg.capturedVariables[e] : null;
    if (captured != null) {
      return captured.introducedVariable;
    }
    return super.visitReference(e, arg);
  }
}
