part of 'ast.dart';

abstract class AstVisitor<A, R> {
  R visitSelectStatement(SelectStatement e, A arg);
  R visitCompoundSelectStatement(CompoundSelectStatement e, A arg);
  R visitCompoundSelectPart(CompoundSelectPart e, A arg);
  R visitResultColumn(ResultColumn e, A arg);
  R visitInsertStatement(InsertStatement e, A arg);
  R visitDeleteStatement(DeleteStatement e, A arg);
  R visitUpdateStatement(UpdateStatement e, A arg);
  R visitCreateTableStatement(CreateTableStatement e, A arg);
  R visitCreateVirtualTableStatement(CreateVirtualTableStatement e, A arg);
  R visitCreateTriggerStatement(CreateTriggerStatement e, A arg);
  R visitCreateIndexStatement(CreateIndexStatement e, A arg);

  R visitWithClause(WithClause e, A arg);
  R visitCommonTableExpression(CommonTableExpression e, A arg);
  R visitOrderBy(OrderBy e, A arg);
  R visitOrderingTerm(OrderingTerm e, A arg);
  R visitLimit(Limit e, A arg);
  R visitQueryable(Queryable e, A arg);
  R visitJoin(Join e, A arg);
  R visitGroupBy(GroupBy e, A arg);

  R visitSetComponent(SetComponent e, A arg);

  R visitColumnDefinition(ColumnDefinition e, A arg);
  R visitColumnConstraint(ColumnConstraint e, A arg);
  R visitTableConstraint(TableConstraint e, A arg);
  R visitForeignKeyClause(ForeignKeyClause e, A arg);

  R visitCastExpression(CastExpression e, A arg);
  R visitBinaryExpression(BinaryExpression e, A arg);
  R visitStringComparison(StringComparisonExpression e, A arg);
  R visitUnaryExpression(UnaryExpression e, A arg);
  R visitIsExpression(IsExpression e, A arg);
  R visitIsNullExpression(IsNullExpression e, A arg);
  R visitBetweenExpression(BetweenExpression e, A arg);
  R visitLiteral(Literal e, A arg);
  R visitReference(Reference e, A arg);
  R visitFunction(FunctionExpression e, A arg);
  R visitSubQuery(SubQuery e, A arg);
  R visitExists(ExistsExpression e, A arg);
  R visitCaseExpression(CaseExpression e, A arg);
  R visitWhen(WhenComponent e, A arg);
  R visitTuple(Tuple e, A arg);
  R visitInExpression(InExpression e, A arg);

  R visitAggregateExpression(AggregateExpression e, A arg);
  R visitWindowDefinition(WindowDefinition e, A arg);
  R visitFrameSpec(FrameSpec e, A arg);
  R visitIndexedColumn(IndexedColumn e, A arg);

  R visitNumberedVariable(NumberedVariable e, A arg);
  R visitNamedVariable(ColonNamedVariable e, A arg);

  R visitBlock(Block block, A arg);

  R visitMoorFile(MoorFile e, A arg);
  R visitMoorImportStatement(ImportStatement e, A arg);
  R visitMoorDeclaredStatement(DeclaredStatement e, A arg);
  R visitMoorStatementParameter(StatementParameter e, A arg);
  R visitDartPlaceholder(DartPlaceholder e, A arg);
}

/// Visitor that walks down the entire tree, visiting all children in order.
class RecursiveVisitor<A, R> implements AstVisitor<A, R> {
  // Statements

  @override
  R visitSelectStatement(SelectStatement e, A arg) {
    return visitBaseSelectStatement(e, arg);
  }

  @override
  R visitCompoundSelectStatement(CompoundSelectStatement e, A arg) {
    return visitBaseSelectStatement(e, arg);
  }

  @override
  R visitInsertStatement(InsertStatement e, A arg) {
    return visitCrudStatement(e, arg);
  }

  @override
  R visitDeleteStatement(DeleteStatement e, A arg) {
    return visitCrudStatement(e, arg);
  }

  @override
  R visitUpdateStatement(UpdateStatement e, A arg) {
    return visitCrudStatement(e, arg);
  }

  @override
  R visitCreateTableStatement(CreateTableStatement e, A arg) {
    return visitTableInducingStatement(e, arg);
  }

  @override
  R visitCreateVirtualTableStatement(CreateVirtualTableStatement e, A arg) {
    return visitTableInducingStatement(e, arg);
  }

  @override
  R visitCreateTriggerStatement(CreateTriggerStatement e, A arg) {
    return visitSchemaStatement(e, arg);
  }

  @override
  R visitCreateIndexStatement(CreateIndexStatement e, A arg) {
    return visitSchemaStatement(e, arg);
  }

  R visitBaseSelectStatement(BaseSelectStatement stmt, A arg) {
    return visitCrudStatement(stmt, arg);
  }

  R visitCrudStatement(CrudStatement stmt, A arg) {
    return visitStatement(stmt, arg);
  }

  R visitTableInducingStatement(TableInducingStatement stmt, A arg) {
    return visitSchemaStatement(stmt, arg);
  }

  R visitSchemaStatement(SchemaStatement stmt, A arg) {
    return visitStatement(stmt, arg);
  }

  R visitStatement(Statement statement, A arg) {
    return visitChildren(statement, arg);
  }

  @override
  R visitCompoundSelectPart(CompoundSelectPart e, A arg) {
    return visitChildren(e, arg);
  }

  // General clauses

  @override
  R visitResultColumn(ResultColumn e, A arg) {
    return visitChildren(e, arg);
  }

  @override
  R visitWithClause(WithClause e, A arg) {
    return visitChildren(e, arg);
  }

  @override
  R visitCommonTableExpression(CommonTableExpression e, A arg) {
    return visitChildren(e, arg);
  }

  @override
  R visitOrderBy(OrderBy e, A arg) {
    return visitChildren(e, arg);
  }

  @override
  R visitOrderingTerm(OrderingTerm e, A arg) {
    return visitChildren(e, arg);
  }

  @override
  R visitLimit(Limit e, A arg) {
    return visitChildren(e, arg);
  }

  @override
  R visitQueryable(Queryable e, A arg) {
    return visitChildren(e, arg);
  }

  @override
  R visitJoin(Join e, A arg) {
    return visitChildren(e, arg);
  }

  @override
  R visitGroupBy(GroupBy e, A arg) {
    return visitChildren(e, arg);
  }

  @override
  R visitSetComponent(SetComponent e, A arg) {
    return visitChildren(e, arg);
  }

  @override
  R visitColumnDefinition(ColumnDefinition e, A arg) {
    return visitChildren(e, arg);
  }

  @override
  R visitColumnConstraint(ColumnConstraint e, A arg) {
    return visitChildren(e, arg);
  }

  @override
  R visitTableConstraint(TableConstraint e, A arg) {
    return visitChildren(e, arg);
  }

  @override
  R visitForeignKeyClause(ForeignKeyClause e, A arg) {
    return visitChildren(e, arg);
  }

  @override
  R visitWindowDefinition(WindowDefinition e, A arg) {
    return visitChildren(e, arg);
  }

  @override
  R visitFrameSpec(FrameSpec e, A arg) {
    return visitChildren(e, arg);
  }

  @override
  R visitIndexedColumn(IndexedColumn e, A arg) {
    return visitChildren(e, arg);
  }

  @override
  R visitBlock(Block e, A arg) {
    return visitChildren(e, arg);
  }

  // Moor-specific additions
  @override
  R visitMoorFile(MoorFile e, A arg) {
    return visitChildren(e, arg);
  }

  @override
  R visitMoorImportStatement(ImportStatement e, A arg) {
    return visitStatement(e, arg);
  }

  @override
  R visitMoorDeclaredStatement(DeclaredStatement e, A arg) {
    return visitStatement(e, arg);
  }

  @override
  R visitDartPlaceholder(DartPlaceholder e, A arg) {
    return visitChildren(e, arg);
  }

  @override
  R visitMoorStatementParameter(StatementParameter e, A arg) {
    return visitChildren(e, arg);
  }

  // Expressions

  @override
  R visitCastExpression(CastExpression e, A arg) {
    return visitExpression(e, arg);
  }

  @override
  R visitBinaryExpression(BinaryExpression e, A arg) {
    return visitExpression(e, arg);
  }

  @override
  R visitUnaryExpression(UnaryExpression e, A arg) {
    return visitExpression(e, arg);
  }

  @override
  R visitStringComparison(StringComparisonExpression e, A arg) {
    return visitExpression(e, arg);
  }

  @override
  R visitIsExpression(IsExpression e, A arg) {
    return visitExpression(e, arg);
  }

  @override
  R visitIsNullExpression(IsNullExpression e, A arg) {
    return visitExpression(e, arg);
  }

  @override
  R visitBetweenExpression(BetweenExpression e, A arg) {
    return visitExpression(e, arg);
  }

  @override
  R visitLiteral(Literal e, A arg) {
    return visitExpression(e, arg);
  }

  @override
  R visitReference(Reference e, A arg) {
    return visitExpression(e, arg);
  }

  @override
  R visitFunction(FunctionExpression e, A arg) {
    return visitInvocation(e, arg);
  }

  @override
  R visitAggregateExpression(AggregateExpression e, A arg) {
    return visitInvocation(e, arg);
  }

  @override
  R visitSubQuery(SubQuery e, A arg) {
    return visitExpression(e, arg);
  }

  @override
  R visitExists(ExistsExpression e, A arg) {
    return visitExpression(e, arg);
  }

  @override
  R visitCaseExpression(CaseExpression e, A arg) {
    return visitExpression(e, arg);
  }

  @override
  R visitWhen(WhenComponent e, A arg) {
    return visitChildren(e, arg);
  }

  @override
  R visitTuple(Tuple e, A arg) {
    return visitExpression(e, arg);
  }

  @override
  R visitInExpression(InExpression e, A arg) {
    return visitExpression(e, arg);
  }

  @override
  R visitNumberedVariable(NumberedVariable e, A arg) {
    return visitVariable(e, arg);
  }

  @override
  R visitNamedVariable(ColonNamedVariable e, A arg) {
    return visitVariable(e, arg);
  }

  R visitVariable(Variable e, A arg) {
    return visitExpression(e, arg);
  }

  R visitInvocation(SqlInvocation e, A arg) {
    return visitExpression(e, arg);
  }

  R visitExpression(Expression e, A arg) {
    return visitChildren(e, arg);
  }

  R visit(AstNode e, A arg) => e.accept(this, arg);

  R visitNullable(AstNode e, A arg) => e?.accept(this, arg);

  @protected
  R visitChildren(AstNode e, A arg) => visitList(e.childNodes, arg);

  @protected
  R visitList(Iterable<AstNode> nodes, A arg) {
    for (final node in nodes) {
      node.accept(this, arg);
    }
    return null;
  }
}
