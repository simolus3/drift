import 'ast.dart';

abstract class AstVisitor<A, R> {
  R visitSelectStatement(SelectStatement e, A arg);
  R visitCompoundSelectStatement(CompoundSelectStatement e, A arg);
  R visitCompoundSelectPart(CompoundSelectPart e, A arg);
  R visitValuesSelectStatement(ValuesSelectStatement e, A arg);
  R visitInsertStatement(InsertStatement e, A arg);
  R visitDeleteStatement(DeleteStatement e, A arg);
  R visitUpdateStatement(UpdateStatement e, A arg);
  R visitCreateTableStatement(CreateTableStatement e, A arg);
  R visitCreateVirtualTableStatement(CreateVirtualTableStatement e, A arg);
  R visitCreateTriggerStatement(CreateTriggerStatement e, A arg);
  R visitCreateIndexStatement(CreateIndexStatement e, A arg);
  R visitCreateViewStatement(CreateViewStatement e, A arg);
  R visitInvalidStatement(InvalidStatement e, A arg);

  R visitReturning(Returning e, A arg);
  R visitWithClause(WithClause e, A arg);
  R visitUpsertClause(UpsertClause e, A arg);
  R visitUpsertClauseEntry(UpsertClauseEntry e, A arg);
  R visitCommonTableExpression(CommonTableExpression e, A arg);
  R visitOrderBy(OrderBy e, A arg);
  R visitOrderingTerm(OrderingTerm e, A arg);
  R visitLimit(Limit e, A arg);

  R visitStarResultColumn(StarResultColumn e, A arg);
  R visitExpressionResultColumn(ExpressionResultColumn e, A arg);

  R visitTableReference(TableReference e, A arg);
  R visitSelectStatementAsSource(SelectStatementAsSource e, A arg);
  R visitJoinClause(JoinClause e, A arg);
  R visitTableValuedFunction(TableValuedFunction e, A arg);

  R visitJoin(Join e, A arg);
  R visitGroupBy(GroupBy e, A arg);

  R visitDeleteTriggerTarget(DeleteTarget e, A arg);
  R visitInsertTriggerTarget(InsertTarget e, A arg);
  R visitUpdateTriggerTarget(UpdateTarget e, A arg);

  R visitDoNothing(DoNothing e, A arg);
  R visitDoUpdate(DoUpdate e, A arg);

  R visitSetComponent(SetComponent e, A arg);

  R visitValuesSource(ValuesSource e, A arg);
  R visitSelectInsertSource(SelectInsertSource e, A arg);
  R visitDefaultValues(DefaultValues e, A arg);

  R visitColumnDefinition(ColumnDefinition e, A arg);
  R visitColumnConstraint(ColumnConstraint e, A arg);
  R visitTableConstraint(TableConstraint e, A arg);
  R visitForeignKeyClause(ForeignKeyClause e, A arg);
  R visitDeferrableClause(DeferrableClause e, A arg);

  R visitNumericLiteral(NumericLiteral e, A arg);
  R visitNullLiteral(NullLiteral e, A arg);
  R visitBooleanLiteral(BooleanLiteral e, A arg);
  R visitStringLiteral(StringLiteral e, A arg);
  R visitTimeConstantLiteral(TimeConstantLiteral e, A arg);

  R visitCastExpression(CastExpression e, A arg);
  R visitBinaryExpression(BinaryExpression e, A arg);
  R visitStringComparison(StringComparisonExpression e, A arg);
  R visitCollateExpression(CollateExpression e, A arg);
  R visitUnaryExpression(UnaryExpression e, A arg);
  R visitIsExpression(IsExpression e, A arg);
  R visitIsNullExpression(IsNullExpression e, A arg);
  R visitBetweenExpression(BetweenExpression e, A arg);
  R visitReference(Reference e, A arg);
  R visitFunction(FunctionExpression e, A arg);
  R visitStarFunctionParameter(StarFunctionParameter e, A arg);
  R visitExpressionFunctionParameters(ExprFunctionParameters e, A arg);
  R visitSubQuery(SubQuery e, A arg);
  R visitExists(ExistsExpression e, A arg);
  R visitCaseExpression(CaseExpression e, A arg);
  R visitWhen(WhenComponent e, A arg);
  R visitTuple(Tuple e, A arg);
  R visitParentheses(Parentheses e, A arg);
  R visitInExpression(InExpression e, A arg);
  R visitRaiseExpression(RaiseExpression e, A arg);

  R visitAggregateExpression(AggregateExpression e, A arg);
  R visitWindowDefinition(WindowDefinition e, A arg);
  R visitFrameSpec(FrameSpec e, A arg);
  R visitIndexedColumn(IndexedColumn e, A arg);

  R visitNumberedVariable(NumberedVariable e, A arg);
  R visitNamedVariable(ColonNamedVariable e, A arg);
  R visitNestedQueryVariable(NestedQueryVariable e, A arg);

  R visitBlock(Block block, A arg);
  R visitBeginTransaction(BeginTransactionStatement e, A arg);
  R visitCommitStatement(CommitStatement e, A arg);

  R visitMoorSpecificNode(MoorSpecificNode e, A arg);
}

/// Visitor that walks down the entire tree, visiting all children in order.
class RecursiveVisitor<A, R> implements AstVisitor<A, R?> {
  // Statements

  @override
  R? visitInvalidStatement(InvalidStatement e, A arg) {
    return visitStatement(e, arg);
  }

  @override
  R? visitSelectStatement(SelectStatement e, A arg) {
    return visitBaseSelectStatement(e, arg);
  }

  @override
  R? visitValuesSelectStatement(ValuesSelectStatement e, A arg) {
    return visitBaseSelectStatement(e, arg);
  }

  @override
  R? visitCompoundSelectStatement(CompoundSelectStatement e, A arg) {
    return visitBaseSelectStatement(e, arg);
  }

  @override
  R? visitInsertStatement(InsertStatement e, A arg) {
    return visitCrudStatement(e, arg);
  }

  @override
  R? visitDeleteStatement(DeleteStatement e, A arg) {
    return visitCrudStatement(e, arg);
  }

  @override
  R? visitUpdateStatement(UpdateStatement e, A arg) {
    return visitCrudStatement(e, arg);
  }

  @override
  R? visitCreateTableStatement(CreateTableStatement e, A arg) {
    return visitTableInducingStatement(e, arg);
  }

  @override
  R? visitCreateVirtualTableStatement(CreateVirtualTableStatement e, A arg) {
    return visitTableInducingStatement(e, arg);
  }

  @override
  R? visitCreateViewStatement(CreateViewStatement e, A arg) {
    return visitSchemaStatement(e, arg);
  }

  @override
  R? visitCreateTriggerStatement(CreateTriggerStatement e, A arg) {
    return visitSchemaStatement(e, arg);
  }

  @override
  R? visitCreateIndexStatement(CreateIndexStatement e, A arg) {
    return visitSchemaStatement(e, arg);
  }

  R? visitBaseSelectStatement(BaseSelectStatement stmt, A arg) {
    return visitCrudStatement(stmt, arg);
  }

  R? visitCrudStatement(CrudStatement stmt, A arg) {
    return visitStatement(stmt, arg);
  }

  R? visitTableInducingStatement(TableInducingStatement stmt, A arg) {
    return visitSchemaStatement(stmt, arg);
  }

  R? visitSchemaStatement(SchemaStatement stmt, A arg) {
    return visitStatement(stmt, arg);
  }

  R? visitStatement(Statement statement, A arg) {
    return defaultNode(statement, arg);
  }

  @override
  R? visitCompoundSelectPart(CompoundSelectPart e, A arg) {
    return defaultNode(e, arg);
  }

  // General clauses

  R? visitResultColumn(ResultColumn e, A arg) {
    return defaultNode(e, arg);
  }

  @override
  R? visitStarResultColumn(StarResultColumn e, A arg) {
    return visitResultColumn(e, arg);
  }

  @override
  R? visitExpressionResultColumn(ExpressionResultColumn e, A arg) {
    return visitResultColumn(e, arg);
  }

  @override
  R? visitReturning(Returning e, A arg) {
    return defaultNode(e, arg);
  }

  @override
  R? visitWithClause(WithClause e, A arg) {
    return defaultNode(e, arg);
  }

  @override
  R? visitUpsertClause(UpsertClause e, A arg) {
    return defaultNode(e, arg);
  }

  @override
  R? visitUpsertClauseEntry(UpsertClauseEntry e, A arg) {
    return defaultNode(e, arg);
  }

  @override
  R? visitDeleteTriggerTarget(DeleteTarget e, A arg) {
    return defaultTriggerTarget(e, arg);
  }

  @override
  R? visitInsertTriggerTarget(InsertTarget e, A arg) {
    return defaultTriggerTarget(e, arg);
  }

  @override
  R? visitUpdateTriggerTarget(UpdateTarget e, A arg) {
    return defaultTriggerTarget(e, arg);
  }

  R? defaultTriggerTarget(TriggerTarget e, A arg) {
    return defaultNode(e, arg);
  }

  @override
  R? visitDoNothing(DoNothing e, A arg) {
    return defaultUpsertAction(e, arg);
  }

  @override
  R? visitDoUpdate(DoUpdate e, A arg) {
    return defaultUpsertAction(e, arg);
  }

  R? defaultUpsertAction(UpsertAction e, A arg) {
    return defaultNode(e, arg);
  }

  @override
  R? visitCommonTableExpression(CommonTableExpression e, A arg) {
    return defaultNode(e, arg);
  }

  @override
  R? visitOrderBy(OrderBy e, A arg) {
    return defaultNode(e, arg);
  }

  @override
  R? visitOrderingTerm(OrderingTerm e, A arg) {
    return defaultNode(e, arg);
  }

  @override
  R? visitLimit(Limit e, A arg) {
    return defaultNode(e, arg);
  }

  @override
  R? visitTableReference(TableReference e, A arg) {
    return defaultQueryable(e, arg);
  }

  @override
  R? visitSelectStatementAsSource(SelectStatementAsSource e, A arg) {
    return defaultQueryable(e, arg);
  }

  @override
  R? visitJoinClause(JoinClause e, A arg) {
    return defaultQueryable(e, arg);
  }

  @override
  R? visitTableValuedFunction(TableValuedFunction e, A arg) {
    return defaultQueryable(e, arg);
  }

  R? defaultQueryable(Queryable e, A arg) {
    return defaultNode(e, arg);
  }

  @override
  R? visitJoin(Join e, A arg) {
    return defaultNode(e, arg);
  }

  @override
  R? visitGroupBy(GroupBy e, A arg) {
    return defaultNode(e, arg);
  }

  @override
  R? visitSetComponent(SetComponent e, A arg) {
    return defaultNode(e, arg);
  }

  @override
  R? visitValuesSource(ValuesSource e, A arg) {
    return defaultInsertSource(e, arg);
  }

  @override
  R? visitSelectInsertSource(SelectInsertSource e, A arg) {
    return defaultInsertSource(e, arg);
  }

  @override
  R? visitDefaultValues(DefaultValues e, A arg) {
    return defaultInsertSource(e, arg);
  }

  R? defaultInsertSource(InsertSource e, A arg) {
    return defaultNode(e, arg);
  }

  @override
  R? visitColumnDefinition(ColumnDefinition e, A arg) {
    return defaultNode(e, arg);
  }

  @override
  R? visitColumnConstraint(ColumnConstraint e, A arg) {
    return defaultNode(e, arg);
  }

  @override
  R? visitTableConstraint(TableConstraint e, A arg) {
    return defaultNode(e, arg);
  }

  @override
  R? visitForeignKeyClause(ForeignKeyClause e, A arg) {
    return defaultNode(e, arg);
  }

  @override
  R? visitDeferrableClause(DeferrableClause e, A arg) {
    return defaultNode(e, arg);
  }

  @override
  R? visitWindowDefinition(WindowDefinition e, A arg) {
    return defaultNode(e, arg);
  }

  @override
  R? visitFrameSpec(FrameSpec e, A arg) {
    return defaultNode(e, arg);
  }

  @override
  R? visitIndexedColumn(IndexedColumn e, A arg) {
    return defaultNode(e, arg);
  }

  @override
  R? visitBlock(Block e, A arg) {
    return defaultNode(e, arg);
  }

  @override
  R? visitBeginTransaction(BeginTransactionStatement e, A arg) {
    return visitStatement(e, arg);
  }

  @override
  R? visitCommitStatement(CommitStatement e, A arg) {
    return visitStatement(e, arg);
  }

  @override
  R? visitMoorSpecificNode(MoorSpecificNode e, A arg) {
    return defaultNode(e, arg);
  }

  // Expressions

  @override
  R? visitCastExpression(CastExpression e, A arg) {
    return visitExpression(e, arg);
  }

  @override
  R? visitBinaryExpression(BinaryExpression e, A arg) {
    return visitExpression(e, arg);
  }

  @override
  R? visitCollateExpression(CollateExpression e, A arg) {
    return visitUnaryExpression(e, arg);
  }

  @override
  R? visitUnaryExpression(UnaryExpression e, A arg) {
    return visitExpression(e, arg);
  }

  @override
  R? visitStringComparison(StringComparisonExpression e, A arg) {
    return visitExpression(e, arg);
  }

  @override
  R? visitIsExpression(IsExpression e, A arg) {
    return visitExpression(e, arg);
  }

  @override
  R? visitIsNullExpression(IsNullExpression e, A arg) {
    return visitExpression(e, arg);
  }

  @override
  R? visitBetweenExpression(BetweenExpression e, A arg) {
    return visitExpression(e, arg);
  }

  R? defaultLiteral(Literal e, A arg) {
    return visitExpression(e, arg);
  }

  @override
  R? visitNullLiteral(NullLiteral e, A arg) {
    return defaultLiteral(e, arg);
  }

  @override
  R? visitNumericLiteral(Literal e, A arg) {
    return defaultLiteral(e, arg);
  }

  @override
  R? visitBooleanLiteral(BooleanLiteral e, A arg) {
    return defaultLiteral(e, arg);
  }

  @override
  R? visitStringLiteral(StringLiteral e, A arg) {
    return defaultLiteral(e, arg);
  }

  @override
  R? visitTimeConstantLiteral(TimeConstantLiteral e, A arg) {
    return defaultLiteral(e, arg);
  }

  @override
  R? visitReference(Reference e, A arg) {
    return visitExpression(e, arg);
  }

  @override
  R? visitFunction(FunctionExpression e, A arg) {
    return visitExpressionInvocation(e, arg);
  }

  R? visitFunctionParameters(FunctionParameters e, A arg) {
    return defaultNode(e, arg);
  }

  @override
  R? visitStarFunctionParameter(StarFunctionParameter e, A arg) {
    return visitFunctionParameters(e, arg);
  }

  @override
  R? visitExpressionFunctionParameters(ExprFunctionParameters e, A arg) {
    return visitFunctionParameters(e, arg);
  }

  @override
  R? visitAggregateExpression(AggregateExpression e, A arg) {
    return visitExpressionInvocation(e, arg);
  }

  @override
  R? visitSubQuery(SubQuery e, A arg) {
    return visitExpression(e, arg);
  }

  @override
  R? visitExists(ExistsExpression e, A arg) {
    return visitExpression(e, arg);
  }

  @override
  R? visitCaseExpression(CaseExpression e, A arg) {
    return visitExpression(e, arg);
  }

  @override
  R? visitWhen(WhenComponent e, A arg) {
    return defaultNode(e, arg);
  }

  @override
  R? visitTuple(Tuple e, A arg) {
    return visitExpression(e, arg);
  }

  @override
  R? visitParentheses(Parentheses e, A arg) {
    return visitExpression(e, arg);
  }

  @override
  R? visitInExpression(InExpression e, A arg) {
    return visitExpression(e, arg);
  }

  @override
  R? visitRaiseExpression(RaiseExpression e, A arg) {
    return visitExpression(e, arg);
  }

  @override
  R? visitNumberedVariable(NumberedVariable e, A arg) {
    return visitVariable(e, arg);
  }

  @override
  R? visitNamedVariable(ColonNamedVariable e, A arg) {
    return visitVariable(e, arg);
  }

  @override
  R? visitNestedQueryVariable(NestedQueryVariable e, A arg) {
    return visitVariable(e, arg);
  }

  R? visitVariable(Variable e, A arg) {
    return visitExpression(e, arg);
  }

  R? visitExpressionInvocation(ExpressionInvocation e, A arg) {
    return visitInvocation(e, arg);
  }

  R? visitInvocation(SqlInvocation e, A arg) {
    return defaultNode(e, arg);
  }

  R? visitExpression(Expression e, A arg) {
    return defaultNode(e, arg);
  }

  R? defaultNode(AstNode e, A arg) {
    return visitChildren(e, arg);
  }
}

class Transformer<A> extends RecursiveVisitor<A, AstNode?> {
  @override
  AstNode defaultNode(AstNode e, A arg) => e..transformChildren(this, arg);
}

extension VisitExtension<A, R> on AstVisitor<A, R> {
  /// Visits the node [e] by calling [AstNode.accept].
  R visit(AstNode e, A arg) => e.accept(this, arg);

  /// Visits the node [e] if it's not null. Otherwise, do nothing.
  R? visitNullable(AstNode? e, A arg) => e?.accept(this, arg);
}

extension VisitChildrenExtension<A, R> on AstVisitor<A, R?> {
  /// Visits all children of the node [e], in the order of [AstNode.childNodes].
  R? visitChildren(AstNode e, A arg) {
    return visitList(e.childNodes, arg);
  }

  /// Visits all [nodes] in sequence.
  R? visitList(Iterable<AstNode> nodes, A arg) {
    for (final node in nodes) {
      node.accept(this, arg);
    }
    return null;
  }

  /// Visits all children of [node], except for [skip].
  void visitExcept(AstNode node, AstNode? skip, A arg) {
    for (final child in node.childNodes) {
      if (child != skip) {
        visit(child, arg);
      }
    }
  }
}

extension TransformerUtils<A> on Transformer<A> {
  AstNode? transform(AstNode e, A arg) => visit(e, arg);

  T transformChild<T extends AstNode>(T child, AstNode parent, A arg) {
    final transformed = transform(child, arg)!..parent = parent;
    return transformed as T;
  }

  T? transformNullableChild<T extends AstNode>(
    T? child,
    AstNode parent,
    A arg,
  ) {
    if (child == null) return null;

    final transformed = transform(child, arg);
    transformed?.parent = parent;
    return transformed as T;
  }

  List<T> transformChildren<T extends AstNode>(
      List<T> children, AstNode parent, A arg) {
    final newChildren = <T>[];

    for (final child in children) {
      // ignore: unnecessary_cast, it's a frontend bug in Dart 2.12
      final transformed = transform(child as AstNode, arg) as T?;
      if (transformed != null) {
        newChildren.add(transformed..parent = parent);
      }
    }

    return newChildren;
  }
}
