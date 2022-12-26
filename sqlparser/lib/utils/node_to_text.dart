/// Library to convert AST nodes back to text.
///
/// See the [NodeToText] extension for details.
library utils.node_to_text;

import 'package:charcode/charcode.dart';
import 'package:sqlparser/sqlparser.dart';

class NodeSqlBuilder extends AstVisitor<void, void> {
  final StringSink buffer;

  /// Whether we need to insert a space before writing the next identifier.
  bool needsSpace = false;

  NodeSqlBuilder([StringSink? buffer]) : buffer = buffer ?? StringBuffer();

  /// Writes a space character if [needsSpace] is set.
  ///
  /// This also resets [needsSpace] to `false`.
  void spaceIfNeeded() {
    if (needsSpace) {
      needsSpace = false;
      _space();
    }
  }

  @override
  void visitAggregateFunctionInvocation(
      AggregateFunctionInvocation e, void arg) {
    symbol(e.name);

    symbol('(');
    visit(e.parameters, arg);
    symbol(')');

    if (e.filter != null) {
      _keyword(TokenType.filter);
      symbol('(', spaceBefore: true);
      _keyword(TokenType.where);
      visit(e.filter!, arg);
      symbol(')', spaceAfter: true);
    }
  }

  @override
  void visitWindowFunctionInvocation(WindowFunctionInvocation e, void arg) {
    visitAggregateFunctionInvocation(e, arg);

    if (e.windowDefinition != null) {
      _keyword(TokenType.over);
      visit(e.windowDefinition!, arg);
    } else if (e.windowName != null) {
      _keyword(TokenType.over);
      identifier(e.windowName!);
    }
  }

  @override
  void visitBeginTransaction(BeginTransactionStatement e, void arg) {
    _keyword(TokenType.begin);

    switch (e.mode) {
      case TransactionMode.none:
        break;
      case TransactionMode.deferred:
        _keyword(TokenType.deferred);
        break;
      case TransactionMode.immediate:
        _keyword(TokenType.immediate);
        break;
      case TransactionMode.exclusive:
        _keyword(TokenType.exclusive);
        break;
    }
  }

  @override
  void visitBetweenExpression(BetweenExpression e, void arg) {
    visit(e.check, arg);

    if (e.not) {
      _keyword(TokenType.not);
    }

    _keyword(TokenType.between);
    visit(e.lower, arg);
    _keyword(TokenType.and);
    visit(e.upper, arg);
  }

  @override
  void visitBinaryExpression(BinaryExpression e, void arg) {
    visit(e.left, arg);

    final operatorSymbol = const {
      TokenType.doublePipe: '||',
      TokenType.star: '*',
      TokenType.slash: '/',
      TokenType.percent: '%',
      TokenType.plus: '+',
      TokenType.minus: '-',
      TokenType.shiftLeft: '<<',
      TokenType.shiftRight: '>>',
      TokenType.ampersand: '&',
      TokenType.pipe: '|',
      TokenType.less: '<',
      TokenType.lessEqual: '<=',
      TokenType.more: '>',
      TokenType.moreEqual: '>=',
      TokenType.equal: '=',
      TokenType.doubleEqual: '==',
      TokenType.exclamationEqual: '!=',
      TokenType.lessMore: '<>',
      TokenType.dashRangle: '->',
      TokenType.dashRangleRangle: '->>',
    }[e.operator.type];

    if (operatorSymbol != null) {
      symbol(operatorSymbol, spaceBefore: true, spaceAfter: true);
    } else {
      _keyword(e.operator.type);
    }

    visit(e.right, arg);
  }

  void _writeStatements(Iterable<Statement> statements) {
    for (final stmt in statements) {
      visit(stmt, null);
      symbol(';');
    }
  }

  @override
  void visitBlock(Block block, void arg) {
    _keyword(TokenType.begin);
    _writeStatements(block.statements);
    _keyword(TokenType.end);
  }

  @override
  void visitBooleanLiteral(BooleanLiteral e, void arg) {
    _keyword(e.value ? TokenType.$true : TokenType.$false);
  }

  @override
  void visitCaseExpression(CaseExpression e, void arg) {
    _keyword(TokenType.$case);
    visitNullable(e.base, arg);
    visitList(e.whens, arg);

    final elseExpr = e.elseExpr;
    if (elseExpr != null) {
      _keyword(TokenType.$else);
      visit(elseExpr, arg);
    }

    _keyword(TokenType.end);
  }

  @override
  void visitCastExpression(CastExpression e, void arg) {
    _keyword(TokenType.cast);
    symbol('(');
    visit(e.operand, arg);
    _keyword(TokenType.as);
    symbol(e.typeName, spaceBefore: true);
    symbol(')', spaceAfter: true);
  }

  @override
  void visitCollateExpression(CollateExpression e, void arg) {
    visit(e.inner, arg);
    _keyword(TokenType.collate);
    identifier(e.collation);
  }

  @override
  void visitColumnConstraint(ColumnConstraint e, void arg) {
    if (e.name != null) {
      _keyword(TokenType.constraint);
      identifier(e.name!);
    }

    e.when(primaryKey: (primaryKey) {
      _keyword(TokenType.primary);
      _keyword(TokenType.key);
      _orderingMode(primaryKey.mode);
      _conflictClause(primaryKey.onConflict);
      if (primaryKey.autoIncrement) _keyword(TokenType.autoincrement);
    }, notNull: (notNull) {
      _keyword(TokenType.not);
      _keyword(TokenType.$null);
      _conflictClause(notNull.onConflict);
    }, unique: (unique) {
      _keyword(TokenType.unique);
      _conflictClause(unique.onConflict);
    }, check: (check) {
      _keyword(TokenType.check);
      symbol('(', spaceBefore: true);
      visit(check.expression, arg);
      symbol(')', spaceAfter: true);
    }, isDefault: (def) {
      _keyword(TokenType.$default);
      final expr = def.expression;
      if (expr is Literal) {
        visit(expr, arg);
      } else {
        symbol('(', spaceBefore: true);
        visit(expr, arg);
        symbol(')', spaceAfter: true);
      }
    }, collate: (collate) {
      _keyword(TokenType.collate);
      identifier(collate.collation);
    }, foreignKey: (foreignKey) {
      visit(foreignKey.clause, arg);
    }, generatedAs: (generatedAs) {
      _keyword(TokenType.generated);
      _keyword(TokenType.always);
      _keyword(TokenType.as);

      symbol('(', spaceBefore: true);
      visit(generatedAs.expression, arg);
      symbol(')', spaceAfter: true);

      if (generatedAs.stored) {
        _keyword(TokenType.stored);
      } else {
        _keyword(TokenType.virtual);
      }
    });
  }

  @override
  void visitColumnDefinition(ColumnDefinition e, void arg) {
    identifier(e.columnName);
    if (e.typeName != null) {
      symbol(e.typeName!, spaceAfter: true, spaceBefore: true);
    }

    visitList(e.constraints, arg);
  }

  @override
  void visitCommitStatement(CommitStatement e, void arg) {
    _keyword(TokenType.commit);
  }

  @override
  void visitCommonTableExpression(CommonTableExpression e, void arg) {
    identifier(e.cteTableName);
    if (e.columnNames != null) {
      symbol('(', spaceBefore: true);

      var first = true;
      for (final columnName in e.columnNames!) {
        if (!first) {
          symbol(',', spaceAfter: true);
        }

        identifier(columnName, spaceBefore: !first, spaceAfter: false);

        first = false;
      }

      symbol(')', spaceAfter: true);
    }

    _keyword(TokenType.as);
    switch (e.materializationHint) {
      case MaterializationHint.notMaterialized:
        _keyword(TokenType.not);
        _keyword(TokenType.materialized);
        break;
      case MaterializationHint.materialized:
        _keyword(TokenType.materialized);
        break;
      case null:
        break;
    }

    symbol('(', spaceBefore: true);
    visit(e.as, arg);
    symbol(')', spaceAfter: true);
  }

  @override
  void visitCompoundSelectPart(CompoundSelectPart e, void arg) {
    switch (e.mode) {
      case CompoundSelectMode.union:
        _keyword(TokenType.union);
        break;
      case CompoundSelectMode.unionAll:
        _keyword(TokenType.union);
        _keyword(TokenType.all);
        break;
      case CompoundSelectMode.intersect:
        _keyword(TokenType.intersect);
        break;
      case CompoundSelectMode.except:
        _keyword(TokenType.except);
        break;
    }

    visit(e.select, arg);
  }

  @override
  void visitCompoundSelectStatement(CompoundSelectStatement e, void arg) {
    visitNullable(e.withClause, arg);
    visit(e.base, arg);
    visitList(e.additional, arg);
  }

  @override
  void visitCreateIndexStatement(CreateIndexStatement e, void arg) {
    _keyword(TokenType.create);
    if (e.unique) {
      _keyword(TokenType.unique);
    }
    _keyword(TokenType.$index);
    _ifNotExists(e.ifNotExists);

    identifier(e.indexName);
    _keyword(TokenType.on);
    visit(e.on, arg);

    symbol('(', spaceBefore: true);
    _join(e.columns, ',');
    symbol(')', spaceAfter: true);

    _where(e.where);
  }

  @override
  void visitCreateTableStatement(CreateTableStatement e, void arg) {
    _keyword(TokenType.create);
    _keyword(TokenType.table);
    _ifNotExists(e.ifNotExists);

    identifier(e.tableName);
    symbol('(');
    _join([...e.columns, ...e.tableConstraints], ',');
    symbol(')');

    if (e.withoutRowId) {
      _keyword(TokenType.without);
      _keyword(TokenType.rowid);
    }

    if (e.isStrict) {
      if (e.withoutRowId) symbol(',');

      _keyword(TokenType.strict);
    }
  }

  @override
  void visitCreateTriggerStatement(CreateTriggerStatement e, void arg) {
    _keyword(TokenType.create);
    _keyword(TokenType.trigger);
    _ifNotExists(e.ifNotExists);

    identifier(e.triggerName);

    switch (e.mode) {
      case TriggerMode.before:
        _keyword(TokenType.before);
        break;
      case TriggerMode.after:
        _keyword(TokenType.after);
        break;
      case TriggerMode.insteadOf:
        _keyword(TokenType.instead);
        _keyword(TokenType.of);
        break;
      default:
        // Can happen if e.mode == null
        break;
    }

    visit(e.target, arg);

    _keyword(TokenType.on);
    visit(e.onTable, arg);

    if (e.when != null) {
      _keyword(TokenType.when);
      visit(e.when!, arg);
    }

    visit(e.action, arg);
  }

  @override
  void visitCreateViewStatement(CreateViewStatement e, void arg) {
    _keyword(TokenType.create);
    _keyword(TokenType.view);
    _ifNotExists(e.ifNotExists);

    identifier(e.viewName);

    if (e.columns != null) {
      symbol('(', spaceBefore: true);
      symbol(e.columns!.join(','));
      symbol(')', spaceAfter: true);
    }

    _keyword(TokenType.as);
    visit(e.query, arg);
  }

  @override
  void visitCreateVirtualTableStatement(
      CreateVirtualTableStatement e, void arg) {
    _keyword(TokenType.create);
    _keyword(TokenType.virtual);
    _keyword(TokenType.table);
    _ifNotExists(e.ifNotExists);

    identifier(e.tableName);
    _keyword(TokenType.using);
    identifier(e.moduleName);

    symbol('(${e.argumentContent.join(', ')})');
  }

  @override
  void visitDriftSpecificNode(DriftSpecificNode e, void arg) {
    if (e is DartPlaceholder) {
      e.when(
        isLimit: (_) => _keyword(TokenType.limit),
        isOrderBy: (_) {
          _keyword(TokenType.order);
          _keyword(TokenType.by);
        },
      );

      symbol(r'$', spaceBefore: true);
      symbol(e.name, spaceAfter: true);
    } else if (e is DeclaredStatement) {
      identifier(e.identifier.name);

      if (e.parameters.isNotEmpty) {
        symbol('(');
        _join(e.parameters, ',');
        symbol(')');
      }

      visitNullable(e.as, arg);
      symbol(':', spaceAfter: true);
      visit(e.statement, arg);
      symbol(';');
    } else if (e is DriftFile) {
      for (final stmt in e.statements) {
        visit(stmt, arg);
        buffer.write('\n');
        needsSpace = false;
      }
    } else if (e is ImportStatement) {
      _keyword(TokenType.import);
      _stringLiteral(e.importedFile);
      symbol(';', spaceAfter: true);
    } else if (e is StatementParameter) {
      if (e is VariableTypeHint) {
        if (e.isRequired) _keyword(TokenType.required);

        visit(e.variable, arg);
        final typeName = e.typeName;
        if (typeName != null) {
          _keyword(TokenType.as);
          symbol(typeName, spaceBefore: true, spaceAfter: true);
        }

        if (e.orNull) {
          _keyword(TokenType.or);
          _keyword(TokenType.$null);
        }
      } else if (e is DartPlaceholderDefaultValue) {
        symbol('\$${e.variableName}', spaceAfter: true);
        symbol('=', spaceBefore: true, spaceAfter: true);
        visit(e.defaultValue, arg);
      } else {
        throw AssertionError('Unknown StatementParameter: $e');
      }
    } else if (e is DriftTableName) {
      _keyword(e.useExistingDartClass ? TokenType.$with : TokenType.as);
      identifier(e.overriddenDataClassName);
    } else if (e is NestedStarResultColumn) {
      identifier(e.tableName);
      symbol('.**', spaceAfter: true);
    } else if (e is NestedQueryColumn) {
      symbol('LIST(');
      visit(e.select, arg);
      symbol(')', spaceAfter: true);
    } else if (e is TransactionBlock) {
      visit(e.begin, arg);
      _writeStatements(e.innerStatements);
      visit(e.commit, arg);
    }
  }

  @override
  void visitDefaultValues(DefaultValues e, void arg) {
    _keyword(TokenType.$default);
    _keyword(TokenType.$values);
  }

  @override
  void visitDeferrableClause(DeferrableClause e, void arg) {
    if (e.not) {
      _keyword(TokenType.not);
    }
    _keyword(TokenType.deferrable);

    switch (e.declaredInitially) {
      case InitialDeferrableMode.deferred:
        _keyword(TokenType.initially);
        _keyword(TokenType.deferred);
        break;
      case InitialDeferrableMode.immediate:
        _keyword(TokenType.initially);
        _keyword(TokenType.immediate);
        break;
      default:
        // declaredInitially == null, don't do anything
        break;
    }
  }

  @override
  void visitDeleteStatement(DeleteStatement e, void arg) {
    visitNullable(e.withClause, arg);

    _keyword(TokenType.delete);
    _from(e.from);
    _where(e.where);
    visitNullable(e.returning, arg);
  }

  @override
  void visitDeleteTriggerTarget(DeleteTarget e, void arg) {
    _keyword(TokenType.delete);
  }

  @override
  void visitDoNothing(DoNothing e, void arg) {
    _keyword(TokenType.nothing);
  }

  @override
  void visitDoUpdate(DoUpdate e, void arg) {
    _keyword(TokenType.update);
    _keyword(TokenType.set);
    _join(e.set, ',');
    _where(e.where);
  }

  @override
  void visitExists(ExistsExpression e, void arg) {
    _keyword(TokenType.exists);
    symbol('(', spaceBefore: true);
    visit(e.select, null);
    symbol(')', spaceAfter: true);
  }

  @override
  void visitExpressionFunctionParameters(ExprFunctionParameters e, void arg) {
    if (e.distinct) {
      _keyword(TokenType.distinct);
    }
    _join(e.parameters, ',');
  }

  @override
  void visitExpressionResultColumn(ExpressionResultColumn e, void arg) {
    visit(e.expression, arg);
    if (e.as != null) {
      _keyword(TokenType.as);
      identifier(e.as!);
    }
  }

  @override
  void visitForeignKeyClause(ForeignKeyClause e, void arg) {
    _keyword(TokenType.references);
    visit(e.foreignTable, arg);

    if (e.columnNames.isNotEmpty) {
      symbol('(');
      _join(e.columnNames, ',');
      symbol(')');
    }

    void referenceAction(ReferenceAction action) {
      switch (action) {
        case ReferenceAction.setNull:
          _keyword(TokenType.set);
          _keyword(TokenType.$null);
          break;
        case ReferenceAction.setDefault:
          _keyword(TokenType.set);
          _keyword(TokenType.$default);
          break;
        case ReferenceAction.cascade:
          _keyword(TokenType.cascade);
          break;
        case ReferenceAction.restrict:
          _keyword(TokenType.restrict);
          break;
        case ReferenceAction.noAction:
          _keyword(TokenType.no);
          _keyword(TokenType.action);
          break;
      }
    }

    if (e.onUpdate != null) {
      _keyword(TokenType.on);
      _keyword(TokenType.update);
      referenceAction(e.onUpdate!);
    }
    if (e.onDelete != null) {
      _keyword(TokenType.on);
      _keyword(TokenType.delete);
      referenceAction(e.onDelete!);
    }

    visitNullable(e.deferrable, arg);
  }

  @override
  void visitFrameSpec(FrameSpec e, void arg) {
    void frameBoundary(FrameBoundary boundary) {
      void precedingOrFollowing(bool preceding) {
        if (boundary.isUnbounded) {
          _keyword(TokenType.unbounded);
        } else {
          visit(boundary.offset!, arg);
        }

        _keyword(preceding ? TokenType.preceding : TokenType.following);
      }

      if (boundary.isCurrentRow) {
        _keyword(TokenType.current);
        _keyword(TokenType.row);
      } else if (boundary.preceding) {
        precedingOrFollowing(true);
      } else {
        precedingOrFollowing(false);
      }
    }

    _keyword(const {
      FrameType.range: TokenType.range,
      FrameType.rows: TokenType.rows,
      FrameType.groups: TokenType.groups,
    }[e.type!]!);

    _keyword(TokenType.between);
    frameBoundary(e.start);
    _keyword(TokenType.and);
    frameBoundary(e.end);

    if (e.excludeMode != null) {
      _keyword(TokenType.exclude);
      switch (e.excludeMode!) {
        case ExcludeMode.noOthers:
          _keyword(TokenType.no);
          _keyword(TokenType.others);
          break;
        case ExcludeMode.currentRow:
          _keyword(TokenType.current);
          _keyword(TokenType.row);
          break;
        case ExcludeMode.group:
          _keyword(TokenType.group);
          break;
        case ExcludeMode.ties:
          _keyword(TokenType.ties);
          break;
      }
    }
  }

  @override
  void visitFunction(FunctionExpression e, void arg) {
    identifier(e.name);
    symbol('(');
    visit(e.parameters, arg);
    symbol(')', spaceAfter: true);
  }

  @override
  void visitGroupBy(GroupBy e, void arg) {
    _keyword(TokenType.group);
    _keyword(TokenType.by);

    _join(e.by, ',');

    if (e.having != null) {
      _keyword(TokenType.having);
      visit(e.having!, arg);
    }
  }

  @override
  void visitIndexedColumn(IndexedColumn e, void arg) {
    visit(e.expression, arg);
    _orderingMode(e.ordering);
  }

  @override
  void visitInExpression(InExpression e, void arg) {
    visit(e.left, arg);

    if (e.not) {
      _keyword(TokenType.not);
    }
    _keyword(TokenType.$in);

    visit(e.inside, arg);
  }

  @override
  void visitInsertStatement(InsertStatement e, void arg) {
    visitNullable(e.withClause, arg);

    final mode = e.mode;
    if (mode == InsertMode.insert) {
      _keyword(TokenType.insert);
    } else if (mode == InsertMode.replace) {
      _keyword(TokenType.replace);
    } else {
      _keyword(TokenType.insert);
      _keyword(TokenType.or);

      _keyword(const {
        InsertMode.insertOrReplace: TokenType.replace,
        InsertMode.insertOrRollback: TokenType.rollback,
        InsertMode.insertOrAbort: TokenType.abort,
        InsertMode.insertOrFail: TokenType.fail,
        InsertMode.insertOrIgnore: TokenType.ignore,
      }[mode]!);
    }

    _keyword(TokenType.into);
    visit(e.table, arg);

    if (e.targetColumns.isNotEmpty) {
      symbol('(', spaceBefore: true);
      _join(e.targetColumns, ',');
      symbol(')', spaceAfter: true);
    }

    visit(e.source, arg);
    visitNullable(e.upsert, arg);
    visitNullable(e.returning, arg);
  }

  @override
  void visitInsertTriggerTarget(InsertTarget e, void arg) {
    _keyword(TokenType.insert);
  }

  @override
  void visitInvalidStatement(InvalidStatement e, void arg) {
    throw UnsupportedError(
        'InvalidStatement does not have a textual representation');
  }

  @override
  void visitIsExpression(IsExpression e, void arg) {
    visit(e.left, arg);
    _keyword(TokenType.$is);

    // Avoid writing `DISTINCT FROM`, but be aware that it effectively negates
    // the generated `IS` again.
    final negated = e.negated ^ e.distinctFromSyntax;

    if (negated) {
      _keyword(TokenType.not);
    }
    visit(e.right, arg);
  }

  @override
  void visitIsNullExpression(IsNullExpression e, void arg) {
    visit(e.operand, arg);

    if (e.negated) {
      _keyword(TokenType.notNull);
    } else {
      _keyword(TokenType.isNull);
    }
  }

  @override
  void visitJoin(Join e, void arg) {
    visit(e.operator, null);
    visit(e.query, null);

    final constraint = e.constraint;
    if (constraint is OnConstraint) {
      _keyword(TokenType.on);
      visit(constraint.expression, arg);
    } else if (constraint is UsingConstraint) {
      _keyword(TokenType.using);
      symbol('(${constraint.columnNames.join(', ')})');
    }
  }

  @override
  void visitJoinOperator(JoinOperator e, void arg) {
    if (e.operator == JoinOperatorKind.comma) {
      symbol(',');
    } else {
      if (e.natural) {
        _keyword(TokenType.natural);
      }

      switch (e.operator) {
        case JoinOperatorKind.none:
          break;
        case JoinOperatorKind.comma:
          throw AssertionError("Can't happen");
        case JoinOperatorKind.left:
          _keyword(TokenType.left);
          break;
        case JoinOperatorKind.right:
          _keyword(TokenType.right);
          break;
        case JoinOperatorKind.full:
          _keyword(TokenType.full);
          break;
        case JoinOperatorKind.inner:
          _keyword(TokenType.inner);
          break;
        case JoinOperatorKind.cross:
          _keyword(TokenType.cross);
          break;
      }

      if (e.outer) {
        _keyword(TokenType.outer);
      }
      _keyword(TokenType.join);
    }
  }

  @override
  void visitJoinClause(JoinClause e, void arg) {
    visit(e.primary, arg);
    visitList(e.joins, arg);
  }

  @override
  void visitLimit(Limit e, void arg) {
    _keyword(TokenType.limit);
    visit(e.count, arg);

    if (e.offset != null) {
      _keyword(TokenType.offset);
      visit(e.offset!, arg);
    }
  }

  @override
  void visitNamedVariable(ColonNamedVariable e, void arg) {
    // Note: The name already starts with the colon
    symbol(e.name, spaceBefore: true, spaceAfter: true);
  }

  @override
  void visitNullLiteral(NullLiteral e, void arg) {
    _keyword(TokenType.$null);
  }

  @override
  void visitNumberedVariable(NumberedVariable e, void arg) {
    symbol('?', spaceBefore: true, spaceAfter: e.explicitIndex == null);
    if (e.explicitIndex != null) {
      symbol(e.explicitIndex.toString(), spaceAfter: true);
    }
  }

  @override
  void visitNumericLiteral(NumericLiteral e, void arg) {
    symbol(e.value.toString(), spaceBefore: true, spaceAfter: true);
  }

  @override
  void visitOrderBy(OrderBy e, void arg) {
    _keyword(TokenType.order);
    _keyword(TokenType.by);
    _join(e.terms, ',');
  }

  @override
  void visitOrderingTerm(OrderingTerm e, void arg) {
    visit(e.expression, arg);
    _orderingMode(e.orderingMode);

    if (e.nulls != null) {
      _keyword(TokenType.nulls);

      _keyword(const {
        OrderingBehaviorForNulls.first: TokenType.first,
        OrderingBehaviorForNulls.last: TokenType.last,
      }[e.nulls!]!);
    }
  }

  @override
  void visitParentheses(Parentheses e, void arg) {
    symbol('(');
    visit(e.expression, arg);
    symbol(')');
  }

  @override
  void visitRaiseExpression(RaiseExpression e, void arg) {
    _keyword(TokenType.raise);
    symbol('(', spaceBefore: true);
    _keyword(const {
      RaiseKind.ignore: TokenType.ignore,
      RaiseKind.rollback: TokenType.rollback,
      RaiseKind.abort: TokenType.abort,
      RaiseKind.fail: TokenType.fail,
    }[e.raiseKind]!);

    if (e.errorMessage != null) {
      symbol(',', spaceAfter: true);
      _stringLiteral(e.errorMessage!);
    }
    symbol(')', spaceAfter: true);
  }

  @override
  void visitReference(Reference e, void arg) {
    var didWriteSpaceBefore = false;

    if (e.schemaName != null) {
      identifier(e.schemaName!, spaceAfter: false);
      symbol('.');
      didWriteSpaceBefore = true;
    }
    if (e.entityName != null) {
      identifier(e.entityName!,
          spaceAfter: false, spaceBefore: !didWriteSpaceBefore);
      symbol('.');
      didWriteSpaceBefore = true;
    }

    identifier(e.columnName,
        spaceAfter: true, spaceBefore: !didWriteSpaceBefore);
  }

  @override
  void visitReturning(Returning e, void arg) {
    _keyword(TokenType.returning);
    _join(e.columns, ',');
  }

  @override
  void visitSelectInsertSource(SelectInsertSource e, void arg) {
    visit(e.stmt, arg);
  }

  @override
  void visitSelectStatement(SelectStatement e, void arg) {
    visitNullable(e.withClause, arg);
    _keyword(TokenType.select);
    if (e.distinct) {
      _keyword(TokenType.distinct);
    }

    _join(e.columns, ',');

    _from(e.from);
    _where(e.where);
    visitNullable(e.groupBy, arg);
    if (e.windowDeclarations.isNotEmpty) {
      _keyword(TokenType.window);

      var isFirst = true;
      for (final declaration in e.windowDeclarations) {
        if (!isFirst) {
          symbol(',', spaceAfter: true);
        }

        identifier(declaration.name);
        _keyword(TokenType.as);

        visit(declaration.definition, arg);
        isFirst = false;
      }
    }
    visitNullable(e.orderBy, arg);
    visitNullable(e.limit, arg);
  }

  @override
  void visitSelectStatementAsSource(SelectStatementAsSource e, void arg) {
    symbol('(', spaceBefore: true);
    visit(e.statement, arg);
    symbol(')', spaceAfter: true);

    if (e.as != null) {
      _keyword(TokenType.as);
      identifier(e.as!);
    }
  }

  @override
  void visitSetComponent(SetComponent e, void arg) {
    visit(e.column, arg);
    symbol('=', spaceBefore: true, spaceAfter: true);
    visit(e.expression, arg);
  }

  @override
  void visitStarFunctionParameter(StarFunctionParameter e, void arg) {
    symbol('*', spaceAfter: true);
  }

  @override
  void visitStarResultColumn(StarResultColumn e, void arg) {
    if (e.tableName != null) {
      identifier(e.tableName!);
      symbol('.');
    }

    symbol('*', spaceAfter: true, spaceBefore: e.tableName == null);
  }

  @override
  void visitStringComparison(StringComparisonExpression e, void arg) {
    visit(e.left, arg);
    if (e.not) {
      _keyword(TokenType.not);
    }

    _keyword(e.operator.type);
    visit(e.right, arg);

    if (e.escape != null) {
      _keyword(TokenType.escape);
      visit(e.escape!, arg);
    }
  }

  @override
  void visitStringLiteral(StringLiteral e, void arg) {
    _stringLiteral(e.value);
  }

  @override
  void visitSubQuery(SubQuery e, void arg) {
    symbol('(', spaceBefore: true);
    visit(e.select, arg);
    symbol(')', spaceAfter: true);
  }

  @override
  void visitTableConstraint(TableConstraint e, void arg) {
    if (e.name != null) {
      _keyword(TokenType.constraint);
      identifier(e.name!);
    }

    if (e is KeyClause) {
      if (e.isPrimaryKey) {
        _keyword(TokenType.primary);
        _keyword(TokenType.key);
      } else {
        _keyword(TokenType.unique);
      }

      symbol('(');
      _join(e.columns, ',');
      symbol(')');
      _conflictClause(e.onConflict);
    } else if (e is CheckTable) {
      _keyword(TokenType.check);
      symbol('(');
      visit(e.expression, arg);
      symbol(')');
    } else if (e is ForeignKeyTableConstraint) {
      _keyword(TokenType.foreign);
      _keyword(TokenType.key);
      symbol('(');
      _join(e.columns, ',');
      symbol(')');
      visit(e.clause, arg);
    }
  }

  @override
  void visitTableReference(TableReference e, void arg) {
    if (e.schemaName != null) {
      identifier(e.schemaName!, spaceAfter: false);
      symbol('.');
    }
    identifier(e.tableName, spaceBefore: e.schemaName == null);

    if (e.as != null) {
      _keyword(TokenType.as);
      identifier(e.as!);
    }
  }

  @override
  void visitTableValuedFunction(TableValuedFunction e, void arg) {
    identifier(e.name);
    symbol('(');
    visit(e.parameters, arg);
    symbol(')');

    if (e.as != null) {
      _keyword(TokenType.as);
      identifier(e.as!);
    }
  }

  @override
  void visitTimeConstantLiteral(TimeConstantLiteral e, void arg) {
    switch (e.kind) {
      case TimeConstantKind.currentTime:
        _keyword(TokenType.currentTime);
        break;
      case TimeConstantKind.currentDate:
        _keyword(TokenType.currentDate);
        break;
      case TimeConstantKind.currentTimestamp:
        _keyword(TokenType.currentTimestamp);
        break;
    }
  }

  @override
  void visitTuple(Tuple e, void arg) {
    symbol('(', spaceBefore: true);
    _join(e.expressions, ',');
    symbol(')', spaceAfter: true);
  }

  @override
  void visitUnaryExpression(UnaryExpression e, void arg) {
    switch (e.operator.type) {
      case TokenType.minus:
        symbol('-', spaceBefore: true);
        break;
      case TokenType.plus:
        symbol('+', spaceBefore: true);
        break;
      case TokenType.tilde:
        symbol('~', spaceBefore: true);
        break;
      case TokenType.not:
        _keyword(TokenType.not);
        break;
      default:
        throw AssertionError('Unknown unary operator: ${e.operator}');
    }

    visit(e.inner, arg);
  }

  @override
  void visitUpdateStatement(UpdateStatement e, void arg) {
    visitNullable(e.withClause, arg);
    _keyword(TokenType.update);

    if (e.or != null) {
      _keyword(TokenType.or);

      _keyword(const {
        FailureMode.rollback: TokenType.rollback,
        FailureMode.abort: TokenType.abort,
        FailureMode.replace: TokenType.replace,
        FailureMode.fail: TokenType.fail,
        FailureMode.ignore: TokenType.ignore,
      }[e.or!]!);
    }

    visit(e.table, arg);
    _keyword(TokenType.set);
    _join(e.set, ',');
    _from(e.from);
    _where(e.where);
    visitNullable(e.returning, arg);
  }

  @override
  void visitUpdateTriggerTarget(UpdateTarget e, void arg) {
    _keyword(TokenType.update);
    if (e.columnNames.isNotEmpty) {
      _keyword(TokenType.of);
      _join(e.columnNames, ',');
    }
  }

  @override
  void visitUpsertClause(UpsertClause e, void arg) {
    _join(e.entries, '');
  }

  @override
  void visitUpsertClauseEntry(UpsertClauseEntry e, void arg) {
    _keyword(TokenType.on);
    _keyword(TokenType.conflict);

    if (e.onColumns != null) {
      symbol('(', spaceBefore: true);
      _join(e.onColumns!, ',');
      symbol(')', spaceAfter: true);

      _where(e.where);
    }

    _keyword(TokenType.$do);
    visit(e.action, arg);
  }

  @override
  void visitValuesSelectStatement(ValuesSelectStatement e, void arg) {
    _keyword(TokenType.$values);
    _join(e.values, ',');
  }

  @override
  void visitValuesSource(ValuesSource e, void arg) {
    _keyword(TokenType.$values);
    _join(e.values, ',');
  }

  @override
  void visitWhen(WhenComponent e, void arg) {
    _keyword(TokenType.when);
    visit(e.when, arg);
    _keyword(TokenType.then);
    visit(e.then, arg);
  }

  @override
  void visitWindowDefinition(WindowDefinition e, void arg) {
    symbol('(', spaceBefore: true);

    if (e.baseWindowName != null) {
      identifier(e.baseWindowName!);
    }

    if (e.partitionBy.isNotEmpty) {
      _keyword(TokenType.partition);
      _keyword(TokenType.by);
      _join(e.partitionBy, ',');
    }

    visitNullable(e.orderBy, arg);
    visitNullable(e.frameSpec, arg);

    symbol(')', spaceAfter: true);
  }

  @override
  void visitWithClause(WithClause e, void arg) {
    _keyword(TokenType.$with);
    if (e.recursive) {
      _keyword(TokenType.recursive);
    }

    _join(e.ctes, ',');
  }

  void _conflictClause(ConflictClause? clause) {
    if (clause != null) {
      _keyword(TokenType.on);
      _keyword(TokenType.conflict);

      _keyword(const {
        ConflictClause.rollback: TokenType.rollback,
        ConflictClause.abort: TokenType.abort,
        ConflictClause.fail: TokenType.fail,
        ConflictClause.ignore: TokenType.ignore,
        ConflictClause.replace: TokenType.replace,
      }[clause]!);
    }
  }

  void _from(Queryable? from) {
    if (from != null) {
      _keyword(TokenType.from);
      visit(from, null);
    }
  }

  /// Writes an identifier, escaping it if necessary.
  void identifier(String identifier,
      {bool spaceBefore = true, bool spaceAfter = true}) {
    if (isKeywordLexeme(identifier) || _notAKeywordRegex.hasMatch(identifier)) {
      identifier = '"$identifier"';
    }

    symbol(identifier, spaceBefore: spaceBefore, spaceAfter: spaceAfter);
  }

  void _ifNotExists(bool ifNotExists) {
    if (ifNotExists) {
      _keyword(TokenType.$if);
      _keyword(TokenType.not);
      _keyword(TokenType.exists);
    }
  }

  void _join(Iterable<AstNode> nodes, String separatingSymbol) {
    var isFirst = true;

    for (final node in nodes) {
      if (!isFirst) {
        symbol(separatingSymbol, spaceAfter: true);
      }

      visit(node, null);
      isFirst = false;
    }
  }

  void _keyword(TokenType type) {
    symbol(reverseKeywords[type]!, spaceAfter: true, spaceBefore: true);
  }

  void _orderingMode(OrderingMode? mode) {
    if (mode != null) {
      _keyword(const {
        OrderingMode.ascending: TokenType.asc,
        OrderingMode.descending: TokenType.desc,
      }[mode]!);
    }
  }

  void _space() => buffer.writeCharCode($space);

  void _stringLiteral(String content) {
    final escapedChars = content.replaceAll("'", "''");
    symbol("'$escapedChars'", spaceBefore: true, spaceAfter: true);
  }

  /// Writes the [lexeme], unchanged.
  void symbol(String lexeme,
      {bool spaceBefore = false, bool spaceAfter = false}) {
    if (needsSpace && spaceBefore) {
      _space();
    }

    buffer.write(lexeme);
    needsSpace = spaceAfter;
  }

  void _where(Expression? where) {
    if (where != null) {
      _keyword(TokenType.where);
      visit(where, null);
    }
  }
}

/// Defines the [toSql] extension method that turns ast nodes into a compatible
/// textual representation.
///
/// Parsing the output of [toSql] will result in an equal AST.
extension NodeToText on AstNode {
  /// Obtains a textual representation for AST nodes.
  ///
  /// Parsing the output of [toSql] will result in an equal AST. Since only the
  /// AST is used, the output will not contain comments. It's possible for the
  /// output to have more than just whitespace changes if there are multiple
  /// ways to represent an equivalent node (e.g. the no-op `FOR EACH ROW` on
  /// triggers).
  String toSql() {
    final builder = NodeSqlBuilder(null);
    builder.visit(this, null);
    return builder.buffer.toString();
  }
}

// Allow 0, 1, 2, 3 in https://github.com/sqlite/sqlite/blob/665b6b6b35f10a46bb72377ade7c2e5d8ea42cb3/src/tokenize.c#L62-L80
final _notAKeywordRegex = RegExp('[^A-Za-z_0-9]');
