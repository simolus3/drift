import 'package:collection/collection.dart';
import 'package:sqlparser/src/ast/ast.dart';

/// Visitor enforcing the equality of two ast nodes.
class EqualityEnforcingVisitor implements AstVisitor<void, void> {
  // The current ast node. Visitor methods will compare the node they receive to
  // this one.
  AstNode _current;
  // Whether to check for deep equality too.
  final bool _considerChildren;

  /// Creates a visitor enforcing equality to the given node.
  ///
  /// The [visit] methods of this visitor will throw an [NotEqualException]
  /// if they receive a node that is different to the node passed here.
  ///
  /// When [considerChildren] is true (the default), it also considers child
  /// nodes, thus enforcing deep equality.
  EqualityEnforcingVisitor(this._current, {bool considerChildren = true})
      : _considerChildren = considerChildren;

  void _check(AstNode childOfCurrent, AstNode childOfOther) {
    if (identical(childOfCurrent, childOfOther)) return;

    if ((childOfCurrent == null) != (childOfOther == null)) {
      throw NotEqualException('$childOfCurrent and $childOfOther');
    }

    // Both non nullable here
    final savedCurrent = _current;
    _current = childOfCurrent;
    visit(childOfOther, null);
    _current = savedCurrent;
  }

  void _checkChildren(AstNode other) {
    if (!_considerChildren) return;

    final currentChildren = _current.childNodes.iterator;
    final otherChildren = other.childNodes.iterator;

    // always move both iterators
    while (currentChildren.moveNext() & otherChildren.moveNext()) {
      _check(currentChildren.current, otherChildren.current);
    }

    if (currentChildren.moveNext() || otherChildren.moveNext()) {
      throw NotEqualException(
          "$_current and $other don't have an equal amount of children");
    }
  }

  Null /*Never*/ _notEqual(AstNode other) {
    throw NotEqualException('$_current and $other');
  }

  T _currentAs<T extends AstNode>(T context) {
    final current = _current;
    if (current is T) return current;

    _notEqual(context);
    return null;
  }

  void _assert(bool contentEqual, AstNode context) {
    if (!contentEqual) _notEqual(context);
  }

  @override
  void visitAggregateExpression(AggregateExpression e, void arg) {
    final current = _currentAs<AggregateExpression>(e);
    _assert(current.name == e.name && current.windowName == e.windowName, e);
    _checkChildren(e);
  }

  @override
  void visitBetweenExpression(BetweenExpression e, void arg) {
    final current = _currentAs<BetweenExpression>(e);
    _assert(current.not == e.not, e);
    _checkChildren(e);
  }

  @override
  void visitBinaryExpression(BinaryExpression e, void arg) {
    final current = _currentAs<BinaryExpression>(e);
    _assert(current.operator.type == e.operator.type, e);
    _checkChildren(e);
  }

  @override
  void visitBlock(Block block, void arg) {
    _currentAs<Block>(block);
    _checkChildren(block);
  }

  @override
  void visitBooleanLiteral(BooleanLiteral e, void arg) {
    final current = _currentAs<BooleanLiteral>(e);
    _assert(current.value == e.value, e);
    _checkChildren(e);
  }

  @override
  void visitCaseExpression(CaseExpression e, void arg) {
    _currentAs<CaseExpression>(e);
    _checkChildren(e);
  }

  @override
  void visitCastExpression(CastExpression e, void arg) {
    final current = _currentAs<CastExpression>(e);
    _assert(current.typeName == e.typeName, e);
    _checkChildren(e);
  }

  @override
  void visitCollateExpression(CollateExpression e, void arg) {
    final current = _currentAs<CollateExpression>(e);
    _assert(current.collateFunction.type == e.collateFunction.type, e);
    _checkChildren(e);
  }

  @override
  void visitColumnConstraint(ColumnConstraint e, void arg) {
    final current = _currentAs<ColumnConstraint>(e);
    _assert(current.name == e.name, e);

    if (e is NotNull) {
      _assert(current is NotNull && current.onConflict == e.onConflict, e);
    } else if (e is PrimaryKeyColumn) {
      _assert(
          current is PrimaryKeyColumn &&
              current.autoIncrement == e.autoIncrement &&
              current.mode == e.mode &&
              current.onConflict == e.onConflict,
          e);
    } else if (e is UniqueColumn) {
      _assert(current is UniqueColumn && current.onConflict == e.onConflict, e);
    } else if (e is CheckColumn) {
      _assert(current is CheckColumn, e);
    } else if (e is MappedBy) {
      _assert(
          current is MappedBy && current.mapper.dartCode == e.mapper.dartCode,
          e);
    } else if (e is JsonKey) {
      _assert(current is JsonKey && current.jsonKey == e.jsonKey, e);
    } else {
      _assert(current.runtimeType == e.runtimeType, e);
    }

    _checkChildren(e);
  }

  @override
  void visitColumnDefinition(ColumnDefinition e, void arg) {
    final current = _currentAs<ColumnDefinition>(e);
    _assert(
        current.columnName == e.columnName && current.typeName == e.typeName,
        e);
    _checkChildren(e);
  }

  @override
  void visitCommonTableExpression(CommonTableExpression e, void arg) {
    final current = _currentAs<CommonTableExpression>(e);
    _assert(current.cteTableName == e.cteTableName, e);
    _checkChildren(e);
  }

  @override
  void visitCompoundSelectPart(CompoundSelectPart e, void arg) {
    final current = _currentAs<CompoundSelectPart>(e);
    _assert(current.mode == e.mode, e);
    _checkChildren(e);
  }

  @override
  void visitCompoundSelectStatement(CompoundSelectStatement e, void arg) {
    _currentAs<CompoundSelectStatement>(e);
    _checkChildren(e);
  }

  @override
  void visitCreateIndexStatement(CreateIndexStatement e, void arg) {
    final current = _currentAs<CreateIndexStatement>(e);
    _assert(
        current.indexName == e.indexName &&
            current.unique == e.unique &&
            current.ifNotExists == e.ifNotExists,
        e);
    _checkChildren(e);
  }

  @override
  void visitCreateTableStatement(CreateTableStatement e, void arg) {
    final current = _currentAs<CreateTableStatement>(e);
    _assert(
        current.ifNotExists == e.ifNotExists &&
            current.tableName == e.tableName &&
            current.withoutRowId == e.withoutRowId &&
            current.overriddenDataClassName == e.overriddenDataClassName,
        e);
    _checkChildren(e);
  }

  @override
  void visitCreateTriggerStatement(CreateTriggerStatement e, void arg) {
    final current = _currentAs<CreateTriggerStatement>(e);
    _assert(
        current.ifNotExists == e.ifNotExists &&
            current.triggerName == e.triggerName &&
            current.mode == e.mode,
        e);
    _checkChildren(e);
  }

  @override
  void visitCreateViewStatement(CreateViewStatement e, void arg) {
    final current = _currentAs<CreateViewStatement>(e);
    _assert(
        current.ifNotExists == e.ifNotExists &&
            current.viewName == e.viewName &&
            const ListEquality().equals(current.columns, e.columns),
        e);
    _checkChildren(e);
  }

  @override
  void visitCreateVirtualTableStatement(
      CreateVirtualTableStatement e, void arg) {
    final current = _currentAs<CreateVirtualTableStatement>(e);
    _assert(
        current.ifNotExists == e.ifNotExists &&
            current.tableName == e.tableName &&
            current.moduleName == e.moduleName &&
            const ListEquality()
                .equals(current.argumentContent, e.argumentContent),
        e);
    _checkChildren(e);
  }

  @override
  void visitDartPlaceholder(DartPlaceholder e, void arg) {
    final current = _currentAs<DartPlaceholder>(e);
    _assert(current.name == e.name && current.runtimeType == e.runtimeType, e);
    _checkChildren(e);
  }

  @override
  void visitDefaultValues(DefaultValues e, void arg) {
    _currentAs<DefaultValues>(e);
    _checkChildren(e);
  }

  @override
  void visitDeferrableClause(DeferrableClause e, void arg) {
    final current = _currentAs<DeferrableClause>(e);
    _assert(
        current.not == e.not &&
            current.declaredInitially == e.declaredInitially,
        e);
    _checkChildren(e);
  }

  @override
  void visitDeleteStatement(DeleteStatement e, void arg) {
    _currentAs<DeleteStatement>(e);
    _checkChildren(e);
  }

  @override
  void visitDeleteTriggerTarget(DeleteTarget e, void arg) {
    _currentAs<DeleteTarget>(e);
    _checkChildren(e);
  }

  @override
  void visitDoNothing(DoNothing e, void arg) {
    _currentAs<DoNothing>(e);
    _checkChildren(e);
  }

  @override
  void visitDoUpdate(DoUpdate e, void arg) {
    _currentAs<DoUpdate>(e);
    _checkChildren(e);
  }

  @override
  void visitExists(ExistsExpression e, void arg) {
    _currentAs<ExistsExpression>(e);
    _checkChildren(e);
  }

  @override
  void visitExpressionFunctionParameters(ExprFunctionParameters e, void arg) {
    final current = _currentAs<ExprFunctionParameters>(e);
    _assert(current.distinct == e.distinct, e);
    _checkChildren(e);
  }

  @override
  void visitExpressionResultColumn(ExpressionResultColumn e, void arg) {
    final current = _currentAs<ExpressionResultColumn>(e);
    _assert(current.as == e.as, e);
    _checkChildren(e);
  }

  @override
  void visitForeignKeyClause(ForeignKeyClause e, void arg) {
    final current = _currentAs<ForeignKeyClause>(e);
    _assert(
        current.onDelete == e.onDelete && current.onUpdate == e.onUpdate, e);
    _checkChildren(e);
  }

  @override
  void visitFrameSpec(FrameSpec e, void arg) {
    final current = _currentAs<FrameSpec>(e);
    _assert(
        current.type == e.type &&
            current.excludeMode == e.excludeMode &&
            current.start == e.start &&
            e.end == e.end,
        e);
    _checkChildren(e);
  }

  @override
  void visitFunction(FunctionExpression e, void arg) {
    final current = _currentAs<FunctionExpression>(e);
    _assert(current.name == e.name, e);
    _checkChildren(e);
  }

  @override
  void visitGroupBy(GroupBy e, void arg) {
    _currentAs<GroupBy>(e);
    _checkChildren(e);
  }

  @override
  void visitInExpression(InExpression e, void arg) {
    final current = _currentAs<InExpression>(e);
    _assert(current.not == e.not, e);
    _checkChildren(e);
  }

  @override
  void visitIndexedColumn(IndexedColumn e, void arg) {
    final current = _currentAs<IndexedColumn>(e);
    _assert(current.ordering == e.ordering, e);
    _checkChildren(e);
  }

  @override
  void visitInsertStatement(InsertStatement e, void arg) {
    final current = _currentAs<InsertStatement>(e);
    _assert(current.mode == e.mode, e);
    _checkChildren(e);
  }

  @override
  void visitInsertTriggerTarget(InsertTarget e, void arg) {
    _currentAs<InsertTarget>(e);
    _checkChildren(e);
  }

  @override
  void visitInvalidStatement(InvalidStatement e, void arg) {
    _currentAs<InvalidStatement>(e);
    _checkChildren(e);
  }

  @override
  void visitIsExpression(IsExpression e, void arg) {
    final current = _currentAs<IsExpression>(e);
    _assert(current.negated == e.negated, e);
    _checkChildren(e);
  }

  @override
  void visitIsNullExpression(IsNullExpression e, void arg) {
    final current = _currentAs<IsNullExpression>(e);
    _assert(current.negated == e.negated, e);
    _checkChildren(e);
  }

  @override
  void visitJoin(Join e, void arg) {
    final current = _currentAs<Join>(e);

    if (current.natural != e.natural || current.operator != e.operator) {
      _notEqual(e);
    }

    final constraint = current.constraint;
    if (constraint is OnConstraint) {
      _assert(e.constraint is OnConstraint, e);
    } else if (constraint is UsingConstraint) {
      if (e.constraint is! UsingConstraint) {
        _notEqual(e);
      }
      final typedOther = e.constraint as UsingConstraint;

      _assert(
          const ListEquality()
              .equals(constraint.columnNames, typedOther.columnNames),
          e);
    }

    _checkChildren(e);
  }

  @override
  void visitJoinClause(JoinClause e, void arg) {
    _currentAs<JoinClause>(e);
    _checkChildren(e);
  }

  @override
  void visitLimit(Limit e, void arg) {
    _currentAs<Limit>(e);
    _checkChildren(e);
  }

  @override
  void visitMoorDeclaredStatement(DeclaredStatement e, void arg) {
    final current = _currentAs<DeclaredStatement>(e);
    _assert(current.identifier == e.identifier && current.as == e.as, e);
    _checkChildren(e);
  }

  @override
  void visitMoorFile(MoorFile e, void arg) {
    _currentAs<MoorFile>(e);
    _checkChildren(e);
  }

  @override
  void visitMoorImportStatement(ImportStatement e, void arg) {
    final current = _currentAs<ImportStatement>(e);
    _assert(current.importedFile == e.importedFile, e);
    _checkChildren(e);
  }

  @override
  void visitMoorNestedStarResultColumn(NestedStarResultColumn e, void arg) {
    final current = _currentAs<NestedStarResultColumn>(e);
    _assert(current.tableName == e.tableName, e);
    _checkChildren(e);
  }

  @override
  void visitMoorStatementParameter(StatementParameter e, void arg) {
    if (e is VariableTypeHint) {
      final current = _currentAs<VariableTypeHint>(e);
      _assert(current.typeName == e.typeName, e);
    } else if (e is DartPlaceholderDefaultValue) {
      final current = _currentAs<DartPlaceholderDefaultValue>(e);
      _assert(current.variableName == e.variableName, e);
    }

    _checkChildren(e);
  }

  @override
  void visitNamedVariable(ColonNamedVariable e, void arg) {
    final current = _currentAs<ColonNamedVariable>(e);
    _assert(current.name == e.name, e);
    _checkChildren(e);
  }

  @override
  void visitNullLiteral(NullLiteral e, void arg) {
    _currentAs<NullLiteral>(e);
    _checkChildren(e);
  }

  @override
  void visitNumberedVariable(NumberedVariable e, void arg) {
    final current = _currentAs<NumberedVariable>(e);
    _assert(current.explicitIndex == e.explicitIndex, e);
    _checkChildren(e);
  }

  @override
  void visitNumericLiteral(NumericLiteral e, void arg) {
    final current = _currentAs<NumericLiteral>(e);
    _assert(current.value == e.value, e);
    _checkChildren(e);
  }

  @override
  void visitOrderBy(OrderBy e, void arg) {
    _currentAs<OrderBy>(e);
    _checkChildren(e);
  }

  @override
  void visitOrderingTerm(OrderingTerm e, void arg) {
    final current = _currentAs<OrderingTerm>(e);
    _assert(
        current.orderingMode == e.orderingMode && current.nulls == e.nulls, e);
    _checkChildren(e);
  }

  @override
  void visitParentheses(Parentheses e, void arg) {
    _currentAs<Parentheses>(e);
    _checkChildren(e);
  }

  @override
  void visitReference(Reference e, void arg) {
    final current = _currentAs<Reference>(e);
    _assert(
        current.tableName == e.tableName && current.columnName == e.columnName,
        e);
    _checkChildren(e);
  }

  @override
  void visitSelectInsertSource(SelectInsertSource e, void arg) {
    _currentAs<SelectInsertSource>(e);
    _checkChildren(e);
  }

  @override
  void visitSelectStatement(SelectStatement e, void arg) {
    final current = _currentAs<SelectStatement>(e);
    _assert(current.distinct == e.distinct, e);
    _checkChildren(e);
  }

  @override
  void visitSelectStatementAsSource(SelectStatementAsSource e, void arg) {
    final current = _currentAs<SelectStatementAsSource>(e);
    _assert(current.as == e.as, e);
    _checkChildren(e);
  }

  @override
  void visitSetComponent(SetComponent e, void arg) {
    _currentAs<SetComponent>(e);
    _checkChildren(e);
  }

  @override
  void visitStarFunctionParameter(StarFunctionParameter e, void arg) {
    _currentAs<StarFunctionParameter>(e);
    _checkChildren(e);
  }

  @override
  void visitStarResultColumn(StarResultColumn e, void arg) {
    final current = _currentAs<StarResultColumn>(e);
    _assert(current.tableName == e.tableName, e);
    _checkChildren(e);
  }

  @override
  void visitStringComparison(StringComparisonExpression e, void arg) {
    final current = _currentAs<StringComparisonExpression>(e);
    _assert(current.not == e.not, e);
    _checkChildren(e);
  }

  @override
  void visitStringLiteral(StringLiteral e, void arg) {
    final current = _currentAs<StringLiteral>(e);
    _assert(current.value == e.value, e);
    _checkChildren(e);
  }

  @override
  void visitSubQuery(SubQuery e, void arg) {
    _currentAs<SubQuery>(e);
    _checkChildren(e);
  }

  @override
  void visitTableConstraint(TableConstraint e, void arg) {
    final current = _currentAs<TableConstraint>(e);
    _assert(current.name == e.name && e.constraintEquals(current), e);
    _checkChildren(e);
  }

  @override
  void visitTableReference(TableReference e, void arg) {
    final current = _currentAs<TableReference>(e);
    _assert(current.tableName == e.tableName && current.as == e.as, e);
    _checkChildren(e);
  }

  @override
  void visitTableValuedFunction(TableValuedFunction e, void arg) {
    final current = _currentAs<TableValuedFunction>(e);
    _assert(current.name == e.name, e);
    _checkChildren(e);
  }

  @override
  void visitTimeConstantLiteral(TimeConstantLiteral e, void arg) {
    final current = _currentAs<TimeConstantLiteral>(e);
    _assert(current.kind == e.kind, e);
    _checkChildren(e);
  }

  @override
  void visitTuple(Tuple e, void arg) {
    _currentAs<Tuple>(e);
    _checkChildren(e);
  }

  @override
  void visitUnaryExpression(UnaryExpression e, void arg) {
    final current = _currentAs<UnaryExpression>(e);
    _assert(current.operator.type == e.operator.type, e);
    _checkChildren(e);
  }

  @override
  void visitUpdateStatement(UpdateStatement e, void arg) {
    final current = _currentAs<UpdateStatement>(e);
    _assert(current.or == e.or, e);
    _checkChildren(e);
  }

  @override
  void visitUpdateTriggerTarget(UpdateTarget e, void arg) {
    _currentAs<UpdateTarget>(e);
    _checkChildren(e);
  }

  @override
  void visitUpsertClause(UpsertClause e, void arg) {
    _currentAs<UpsertClause>(e);
    _checkChildren(e);
  }

  @override
  void visitValuesSelectStatement(ValuesSelectStatement e, void arg) {
    _currentAs<ValuesSelectStatement>(e);
    _checkChildren(e);
  }

  @override
  void visitValuesSource(ValuesSource e, void arg) {
    _currentAs<ValuesSource>(e);
    _checkChildren(e);
  }

  @override
  void visitWhen(WhenComponent e, void arg) {
    _currentAs<WhenComponent>(e);
    _checkChildren(e);
  }

  @override
  void visitWindowDefinition(WindowDefinition e, void arg) {
    final current = _currentAs<WindowDefinition>(e);
    _assert(current.baseWindowName == e.baseWindowName, e);
    _checkChildren(e);
  }

  @override
  void visitWithClause(WithClause e, void arg) {
    final current = _currentAs<WithClause>(e);
    _assert(current.recursive == e.recursive, e);
    _checkChildren(e);
  }
}

/// Checks whether [a] and [b] are equal. If they aren't, throws an exception.
void enforceEqual(AstNode a, AstNode b) {
  EqualityEnforcingVisitor(a).visit(b, null);
}

/// Thrown by the [EqualityEnforcingVisitor] when two nodes were determined to
/// be non-equal.
class NotEqualException implements Exception {
  final String message;

  NotEqualException(this.message);

  @override
  String toString() {
    return 'Not equal: $message';
  }
}

void enforceEqualIterable(Iterable<AstNode> a, Iterable<AstNode> b) {
  final childrenA = a.iterator;
  final childrenB = b.iterator;

  // always move both iterators
  while (childrenA.moveNext() & childrenB.moveNext()) {
    enforceEqual(childrenA.current, childrenB.current);
  }

  if (childrenA.moveNext() || childrenB.moveNext()) {
    throw ArgumentError("$a and $b don't have an equal amount of children");
  }
}
