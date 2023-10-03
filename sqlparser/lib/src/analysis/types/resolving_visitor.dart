part of 'types.dart';

const _intType = ResolvedType(type: BasicType.int);
const _realType = ResolvedType(type: BasicType.real);
const _textType = ResolvedType(type: BasicType.text);

const _expectCondition = ExactTypeExpectation.laxly(ResolvedType.bool());
const _expectInt = ExactTypeExpectation.laxly(_intType);
const _expectNum = RoughTypeExpectation.numeric();
const _expectString = ExactTypeExpectation.laxly(_textType);

class TypeResolver extends RecursiveVisitor<TypeExpectation, void> {
  final TypeInferenceSession session;

  final Set<Column?> _handledColumns = {};

  TypeResolver(this.session);

  void run(AstNode root) {
    visit(root, const NoTypeExpectation());

    // annotate Columns as well. They implement Typeable, but aren't an ast
    // node, which means this visitor doesn't find them
    root.acceptWithoutArg(_ResultColumnVisitor(this));

    session._finish();
  }

  @override
  void visitSelectStatement(SelectStatement e, TypeExpectation arg) {
    _handleWhereClause(e);

    var currentColumnIndex = 0;
    final columnExpectations = arg is SelectTypeExpectation
        ? arg.columnExpectations
        : const <TypeExpectation>[];

    for (final child in e.childNodes) {
      if (child == e.where) continue; // handled above

      if (child is ResultColumn) {
        if (child is ExpressionResultColumn) {
          final expectation = currentColumnIndex < columnExpectations.length
              ? columnExpectations[currentColumnIndex]
              : const NoTypeExpectation();
          visit(child, expectation);

          currentColumnIndex++;
        } else if (child is StarResultColumn) {
          currentColumnIndex += child.scope.expansionOfStarColumn?.length ?? 1;
        } else if (child is NestedQueryColumn) {
          visit(child.select, arg);
        } else if (child is NestedStarResultColumn) {
          final columns = child.resultSet?.resolvedColumns;
          if (columns != null) {
            for (final column in columns) {
              _handleColumn(column, child);
            }
          }
        }
      } else {
        visit(child, arg);
      }
    }
  }

  @override
  void visitSubQuery(SubQuery e, TypeExpectation arg) {
    final columnsOfQuery = e.select.resolvedColumns!;
    if (columnsOfQuery.isEmpty) {
      return super.visitSubQuery(e, arg);
    }

    // The query should return one column only, but this is not the right place
    // to lint that. Just pick any column and resolve to that.
    final columnForExpr = columnsOfQuery.first;
    session._addRelation(CopyTypeFrom(e, columnForExpr));
    visitChildren(e, arg);
  }

  @override
  void visitInsertStatement(InsertStatement e, TypeExpectation arg) {
    if (e.withClause != null) visit(e.withClause!, arg);
    visitList(e.targetColumns, const NoTypeExpectation());

    final targets = e.resolvedTargetColumns ?? const [];
    for (final column in targets) {
      _handleColumn(column, e);
    }

    final expectations = targets.map((r) {
      if (r != null && session.graph.knowsType(r)) {
        return ExactTypeExpectation(session.typeOf(r)!);
      }
      return const NoTypeExpectation();
    }).toList();

    visit(e.source, SelectTypeExpectation(expectations));
    visitNullable(e.upsert, const NoTypeExpectation());
    visitNullable(e.returning, const NoTypeExpectation());
  }

  @override
  void visitCrudStatement(CrudStatement stmt, TypeExpectation arg) {
    if (stmt is StatementWithWhere) {
      final typedStmt = stmt as StatementWithWhere;
      _handleWhereClause(typedStmt);
      visitExcept(stmt, typedStmt.where, arg);
    } else {
      visitChildren(stmt, arg);
    }
  }

  @override
  void visitCreateIndexStatement(CreateIndexStatement e, TypeExpectation arg) {
    _handleWhereClause(e);
    visitExcept(e, e.where, arg);
  }

  @override
  void visitJoin(Join e, TypeExpectation arg) {
    final constraint = e.constraint;
    if (constraint is OnConstraint) {
      // ON <expr>, <expr> should be boolean
      visit(constraint.expression,
          const ExactTypeExpectation.laxly(ResolvedType.bool()));
      visitExcept(e, constraint.expression, arg);
    } else {
      visitChildren(e, arg);
    }
  }

  @override
  void visitSetComponent(SetComponent e, TypeExpectation arg) {
    visit(e.column, const NoTypeExpectation());
    _lazyCopy(e.expression, e.column);
    visit(e.expression, const NoTypeExpectation());
  }

  @override
  void visitGroupBy(GroupBy e, TypeExpectation arg) {
    visitList(e.by, const NoTypeExpectation());
    visitNullable(e.having, _expectCondition);
  }

  @override
  void visitLimit(Limit e, TypeExpectation arg) {
    visit(e.count, _expectInt);
    visitNullable(e.offset, _expectInt);
  }

  @override
  void visitFrameSpec(FrameSpec e, TypeExpectation arg) {
    // handle something like "RANGE BETWEEN ? PRECEDING AND ? FOLLOWING
    if (e.start.isExpressionOffset) {
      visit(e.start.offset!, _expectInt);
    }
    if (e.end.isExpressionOffset) {
      visit(e.end.offset!, _expectInt);
    }
  }

  @override
  void defaultLiteral(Literal e, TypeExpectation arg) {
    late ResolvedType type;
    var nullable = false;

    if (e is NullLiteral) {
      type = const ResolvedType(type: BasicType.nullType, nullable: true);
      nullable = true;
    } else if (e is StringLiteral) {
      type = e.isBinary ? const ResolvedType(type: BasicType.blob) : _textType;
    } else if (e is BooleanLiteral) {
      type = const ResolvedType.bool();
    } else if (e is NumericLiteral) {
      type = e.isInt ? _intType : _realType;
    } else if (e is TimeConstantLiteral) {
      type = _textType;
    }

    session._hintNullability(e, nullable);
    session._checkAndResolve(e, type, arg);
  }

  @override
  void visitVariable(Variable e, TypeExpectation arg) {
    _inferAsVariable(e, arg);
  }

  @override
  void visitDriftSpecificNode(DriftSpecificNode e, TypeExpectation arg) {
    if (e is DartExpressionPlaceholder) {
      _inferAsVariable(e, arg);
    } else {
      super.visitDriftSpecificNode(e, arg);
    }
  }

  void _inferAsVariable(Expression e, TypeExpectation arg) {
    ResolvedType? resolved;
    if (e is Variable) {
      resolved = session.context.stmtOptions.specifiedTypeOf(e);
    }
    resolved ??= _inferFromContext(arg);

    if (resolved != null) {
      session._checkAndResolve(e, resolved, arg);
    } else if (arg is RoughTypeExpectation) {
      session._addRelation(DefaultType(e, defaultType: arg.defaultType()));
    }

    visitChildren(e, arg);
  }

  @override
  void visitCollateExpression(CollateExpression e, TypeExpectation arg) {
    session._checkAndResolve(e, _textType, arg);
    visit(e.inner, _expectString);
  }

  @override
  void visitColumnDefinition(ColumnDefinition e, TypeExpectation arg) {
    // If we're analyzing a `CREATE TABLE` statement, we might know this colum's
    // type.
    final createTable = e.parent;
    if (createTable is CreateTableStatement) {
      final resolvedTable =
          session.context.rootScope.knownTables[createTable.tableName];
      final resolvedColumn = resolvedTable?.findColumn(e.columnName);

      if (resolvedColumn is ColumnWithType) {
        final type = resolvedColumn.type;

        if (type != null) {
          // Make sure we have compatible types in the constraints
          visitList(e.constraints, ExactTypeExpectation(type));
          return;
        }
      }
    }

    super.visitColumnDefinition(e, arg);
  }

  @override
  void visitExists(ExistsExpression e, TypeExpectation arg) {
    session._checkAndResolve(e, const ResolvedType.bool(), arg);
    visit(e.select, const NoTypeExpectation());
  }

  @override
  void visitUnaryExpression(UnaryExpression e, TypeExpectation arg) {
    final operatorType = e.operator.type;

    if (operatorType == TokenType.plus) {
      // plus is a no-op, so copy type from child
      session._addRelation(CopyTypeFrom(e, e.inner));
      visit(e.inner, arg);
    } else if (operatorType == TokenType.not) {
      // unary not expression - boolean, but nullability depends on child node.
      session._checkAndResolve(e, const ResolvedType.bool(nullable: null), arg);
      session._addRelation(NullableIfSomeOtherIs(e, [e.inner]));
      visit(e.inner, const ExactTypeExpectation.laxly(ResolvedType.bool()));
    } else if (operatorType == TokenType.minus) {
      // unary minus - can be int or real depending on child node
      session._addRelation(CopyAndCast(e, e.inner, CastMode.numeric));
      visit(e.inner, arg.orMoreSpecific(const RoughTypeExpectation.numeric()));
    } else if (operatorType == TokenType.tilde) {
      // bitwise negation - definitely int, but nullability depends on child
      session._checkAndResolve(
          e, const ResolvedType(type: BasicType.int, nullable: null), arg);
      session._addRelation(NullableIfSomeOtherIs(e, [e.inner]));

      visit(e.inner, const NoTypeExpectation());
    } else {
      throw StateError(
          'Unary operator $operatorType not recognized by types2. At $e');
    }
  }

  @override
  void visitTuple(Tuple e, TypeExpectation arg) {
    if (arg is SelectTypeExpectation) {
      // We have a specific type requirement for each entry, let's use that
      final expectations = arg.columnExpectations;
      for (var i = 0; i < e.expressions.length; i++) {
        final expectation = i < expectations.length
            ? expectations[i]
            : const NoTypeExpectation();
        visit(e.expressions[i], expectation);
      }
    } else {
      // Assume that this tuple forms an array, and clear the array expectation
      // for children.
      final expectationForChildren = arg.clearArray();
      visitChildren(e, expectationForChildren);

      // make children non-arrays
      for (final child in e.childNodes) {
        session._addRelation(CopyTypeFrom(child, e, array: false));
      }
    }
  }

  @override
  void visitBetweenExpression(BetweenExpression e, TypeExpectation arg) {
    visitChildren(e, _expectNum);

    session
      .._checkAndResolve(e, const ResolvedType.bool(), arg)
      .._addRelation(NullableIfSomeOtherIs(e, e.childNodes))
      .._addRelation(HaveSameType([e.lower, e.upper, e.check]));
  }

  @override
  void visitBinaryExpression(BinaryExpression e, TypeExpectation arg) {
    switch (e.operator.type) {
      case TokenType.and:
      case TokenType.or:
        session._checkAndResolve(e, const ResolvedType.bool(), arg);
        session._addRelation(NullableIfSomeOtherIs(e, [e.left, e.right]));

        // logic expressions, so children must be boolean
        visitChildren(e, const ExactTypeExpectation.laxly(ResolvedType.bool()));
        break;
      case TokenType.equal:
      case TokenType.doubleEqual:
      case TokenType.exclamationEqual:
      case TokenType.lessMore:
      case TokenType.less:
      case TokenType.lessEqual:
      case TokenType.more:
      case TokenType.moreEqual:
        // comparison. Returns bool, copying nullability from children.
        session._checkAndResolve(e, const ResolvedType.bool(), arg);
        session._addRelation(NullableIfSomeOtherIs(e, [e.left, e.right]));
        // Not technically a requirement, but assume lhs and rhs have the same
        // type.
        session._addRelation(HaveSameType([e.left, e.right]));
        visitChildren(e, const NoTypeExpectation());
        break;
      case TokenType.plus:
      case TokenType.minus:
      case TokenType.star:
      case TokenType.slash:
        session._addRelation(
            CopyEncapsulating(e, [e.left, e.right], CastMode.numericPreferInt));
        visitChildren(e, const RoughTypeExpectation.numeric());
        break;
      // all of those only really make sense for integers
      case TokenType.shiftLeft:
      case TokenType.shiftRight:
      case TokenType.pipe:
      case TokenType.ampersand:
      case TokenType.percent:
        const type = ResolvedType(type: BasicType.int);
        session._checkAndResolve(e, type, arg);
        session._addRelation(NullableIfSomeOtherIs(e, [e.left, e.right]));
        visitChildren(e, const ExactTypeExpectation.laxly(type));
        break;
      case TokenType.doublePipe:
        // string concatenation.
        session._checkAndResolve(e, _textType.withoutNullabilityInfo, arg);
        session._addRelation(NullableIfSomeOtherIs(e, [e.left, e.right]));
        const childExpectation = ExactTypeExpectation.laxly(_textType);
        visit(e.left, childExpectation);
        visit(e.right, childExpectation);
        break;
      case TokenType.dashRangle:
        // Extract as JSON, this takes two strings and returns a string (or
        // `NULL` if the value wasn't found).
        session._checkAndResolve(e, _textType.withNullable(true), arg);
        visit(e.left, _expectString);
        visit(e.right, _expectString);
        break;
      case TokenType.dashRangleRangle:
        // Extract as JSON to SQL value.
        session._hintNullability(e, true);

        visit(e.left, _expectString);
        visit(e.right, _expectString);
        break;
      default:
        throw StateError('Binary operator ${e.operator.type} not recognized '
            'by types2. At $e');
    }
  }

  @override
  void visitIsExpression(IsExpression e, TypeExpectation arg) {
    session
      .._checkAndResolve(e, const ResolvedType.bool(), arg)
      .._addRelation(HaveSameType([e.left, e.right]))
      .._hintNullability(e, false);

    visitChildren(e, const NoTypeExpectation());
  }

  @override
  void visitIsNullExpression(IsNullExpression e, TypeExpectation arg) {
    session._checkAndResolve(e, const ResolvedType.bool(), arg);
    session._hintNullability(e, false);
    visitChildren(e, const NoTypeExpectation());
  }

  @override
  void visitInExpression(InExpression e, TypeExpectation arg) {
    session._checkAndResolve(e, const ResolvedType.bool(), arg);
    session._addRelation(NullableIfSomeOtherIs(e, e.childNodes));

    session._addRelation(CopyTypeFrom(e.inside, e.left, array: true));

    visitChildren(e, const NoTypeExpectation());
  }

  @override
  void visitCaseExpression(CaseExpression e, TypeExpectation arg) {
    session._addRelation(CopyEncapsulating(e, [
      for (final when in e.whens) when.then,
      if (e.elseExpr != null) e.elseExpr!,
    ]));

    if (e.base != null) {
      session._addRelation(
        CopyEncapsulating(e.base!, [for (final when in e.whens) when.when]),
      );
    }

    visitNullable(e.base, const NoTypeExpectation());
    visitExcept(e, e.base, arg);
  }

  @override
  void visitWhen(WhenComponent e, TypeExpectation arg) {
    final parent = e.parent;
    if (parent is CaseExpression && parent.base != null) {
      // case expressions with base -> condition is compared to base
      session._addRelation(CopyTypeFrom(e.when, parent.base!));
      visit(e.when, const NoTypeExpectation());
    } else {
      // case expression without base -> the conditions are booleans
      visit(e.when, const ExactTypeExpectation(ResolvedType.bool()));
    }

    visit(e.then, arg);
  }

  @override
  void visitCastExpression(CastExpression e, TypeExpectation arg) {
    final type = session.context.schemaSupport.resolveColumnType(e.typeName);
    session._checkAndResolve(e, type.withoutNullabilityInfo, arg);
    session._addRelation(NullableIfSomeOtherIs(e, [e.operand]));
    visit(e.operand, const NoTypeExpectation());
  }

  @override
  void visitStarFunctionParameter(
      StarFunctionParameter e, TypeExpectation arg) {
    final available = e.scope.expansionOfStarColumn;
    if (available != null) {
      // Make sure we resolve these columns, the type of some function
      // invocation could depend on it.
      for (final column in available) {
        _handleColumn(column, e);
      }
    }
  }

  @override
  void visitStringComparison(
      StringComparisonExpression e, TypeExpectation arg) {
    session._checkAndResolve(e, const ResolvedType(type: BasicType.text), arg);
    session._addRelation(NullableIfSomeOtherIs(
      e,
      [
        e.left,
        e.right,
        if (e.escape != null) e.escape!,
      ],
    ));

    visit(e.left, _expectString);
    visit(e.right, _expectString);
    visitNullable(e.escape, _expectString);
  }

  @override
  void visitParentheses(Parentheses e, TypeExpectation arg) {
    session._addRelation(CopyTypeFrom(e, e.expression));
    visit(e.expression, arg);
  }

  @override
  void visitReference(Reference e, TypeExpectation arg) {
    final resolved = e.resolvedColumn;
    if (resolved == null) return;

    _handleColumn(resolved, e);
    _lazyCopy(e, resolved);
  }

  @override
  void visitExpressionInvocation(ExpressionInvocation e, TypeExpectation arg) {
    final type = _resolveInvocation(e);
    if (type != null) {
      session._checkAndResolve(e, type, arg);
    }

    final visited = _resolveFunctionArguments(e);
    for (final child in e.childNodes) {
      if (!visited.contains(child)) {
        visit(child, const NoTypeExpectation());
      }
    }
  }

  FunctionHandler? _functionHandlerFor(ExpressionInvocation e) {
    return session.options.addedFunctions[e.name.toLowerCase()];
  }

  ResolvedType? _resolveInvocation(ExpressionInvocation e) {
    final params = e.expandParameters();

    void nullableIfChildIs() {
      session._addRelation(NullableIfSomeOtherIs(e, params));
    }

    void checkArgumentCount(int expectedArgs) {
      if (params.length != expectedArgs) {
        session.context.reportError(AnalysisError(
          type: AnalysisErrorType.invalidAmountOfParameters,
          message:
              '${e.name} expects $expectedArgs arguments, got ${params.length}.',
          relevantNode: e.parameters,
        ));
      }
    }

    final lowercaseName = e.name.toLowerCase();
    switch (lowercaseName) {
      case 'round':
        nullableIfChildIs();
        //if there is only one params, it rounds to int. Otherwise real
        if (params.length == 1) {
          return _intType;
        } else {
          return _realType;
        }
        // ignore: dead_code
        throw AssertionError(); // required so that this switch compiles
      case 'sum':
        session._addRelation(
            CopyAndCast(e, params.first, CastMode.numeric, dropTypeHint: true));
        session._addRelation(DefaultType(e, defaultType: _realType));
        nullableIfChildIs();
        return null;
      case 'lower':
      case 'ltrim':
      case 'printf':
      case 'format':
      case 'replace':
      case 'rtrim':
      case 'substr':
      case 'trim':
      case 'upper':
        nullableIfChildIs();
        return _textType.withoutNullabilityInfo;
      case 'group_concat':
        return _textType.withNullable(true);
      case 'date':
      case 'time':
      case 'julianday':
      case 'strftime':
      case 'char':
      case 'hex':
      case 'quote':
      case 'soundex':
      case 'sqlite_compileoption_set':
      case 'sqlite_version':
      case 'typeof':
      case 'timediff':
        return _textType;
      case 'datetime':
        return _textType.copyWith(hints: const [IsDateTime()], nullable: true);
      case 'changes':
      case 'last_insert_rowid':
      case 'random':
      case 'sqlite_compileoption_used':
      case 'total_changes':
      case 'count':
      case 'row_number':
      case 'rank':
      case 'dense_rank':
      case 'ntile':
      case 'octet_length':
        return _intType;
      case 'instr':
      case 'length':
      case 'unicode':
        nullableIfChildIs();
        return _intType;
      case 'randomblob':
      case 'zeroblob':
        return const ResolvedType(type: BasicType.blob);
      case 'unhex':
        return const ResolvedType(type: BasicType.blob, nullable: true);
      case 'total':
      case 'avg':
      case 'percent_rank':
      case 'cume_dist':
        return _realType;
      case 'abs':
      case 'likelihood':
      case 'likely':
      case 'unlikely':
        session._addRelation(CopyTypeFrom(e, params.first));
        return null;
      case 'iif':
        checkArgumentCount(3);

        if (params.length == 3) {
          // IIF(a, b, c) is essentially CASE WHEN a THEN b ELSE c END
          final cases = [params[1], params[2]];
          session
            .._addRelation(CopyEncapsulating(e, cases))
            .._addRelation(HaveSameType(cases));
        }

        return null;
      case 'coalesce':
      case 'ifnull':
        session._addRelation(CopyEncapsulating(
            e, params, null, EncapsulatingNullability.nullIfAll));
        for (final param in params) {
          session._addRelation(DefaultType(param, isNullable: true));
        }
        return null;
      case 'nullif':
        session._hintNullability(e, true);
        session._addRelation(CopyTypeFrom(e, params.first));
        return null;
      case 'first_value':
      case 'last_value':
      case 'lag':
      case 'lead':
      case 'nth_value':
        session._addRelation(CopyTypeFrom(e, params.first));
        return null;
      case 'max':
      case 'min':
        session._hintNullability(e, true);
        session
          .._addRelation(CopyEncapsulating(e, params))
          .._addRelation(HaveSameType(params));
        return null;
      case 'unixepoch':
        return const ResolvedType(
            type: BasicType.int, nullable: true, hints: [IsDateTime()]);
    }

    final extensionHandler = _functionHandlerFor(e);
    if (extensionHandler != null) {
      return extensionHandler.inferReturnType(session.context, e, params).type;
    }

    session.context.reportError(AnalysisError(
      type: AnalysisErrorType.unknownFunction,
      message: 'Function ${e.name} could not be found',
      relevantNode: e.nameToken ?? e,
    ));
    return null;
  }

  Set<AstNode> _resolveFunctionArguments(SqlInvocation e) {
    final params = e.expandParameters();
    final visited = <AstNode>{};
    final name = e.name.toLowerCase();

    switch (name) {
      case 'iif':
        if (params.isNotEmpty) {
          final condition = params[0];
          if (condition is Expression) {
            visited.add(condition);
            visit(condition, _expectCondition);
          }
        }
        break;
      case 'nth_value':
        if (params.length >= 2 && params[1] is Expression) {
          // the second argument of nth_value is always an integer
          final secondParam = params[1] as Expression;
          visit(secondParam, _expectInt);
          visited.add(secondParam);
        }
        break;
      case 'unhex':
        for (var i = 0; i < min(2, params.length); i++) {
          final param = params[i];
          if (param is Expression) {
            visit(param, _expectString);
            visited.add(param);
          }
        }
      case 'timediff':
        for (var i = 0; i < min(2, params.length); i++) {
          final param = params[i];
          if (param is Expression) {
            visit(
                param,
                const ExactTypeExpectation(ResolvedType(
                  type: BasicType.text,
                  hints: [IsDateTime()],
                )));
            visited.add(param);
          }
        }
        break;
    }

    final extensionHandler =
        e is ExpressionInvocation ? _functionHandlerFor(e) : null;
    if (extensionHandler != null) {
      for (final arg in params) {
        if (arg is! Expression) continue;

        final expressionArgument = arg;

        final result = extensionHandler.inferArgumentType(
            session.context, e, expressionArgument);
        final type = result.type;
        if (type != null) {
          session._markTypeResolved(expressionArgument, type);
        }

        visited.add(expressionArgument);
      }
    }

    return visited;
  }

  @override
  void visitUpsertClauseEntry(UpsertClauseEntry e, TypeExpectation arg) {
    _handleWhereClause(e);
    visitExcept(e, e.where, arg);
  }

  @override
  void visitDoUpdate(DoUpdate e, TypeExpectation arg) {
    _handleWhereClause(e);
    visitExcept(e, e.where, arg);
  }

  void _handleColumn(Column? column, [AstNode? context]) {
    if (column == null ||
        session.graph.knowsType(column) ||
        _handledColumns.contains(column)) {
      return;
    }
    _handledColumns.add(column);

    if (column is ColumnWithType) {
      session._markTypeResolved(column, column.type!);
    } else if (column is ExpressionColumn) {
      _lazyCopy(column, column.expression);
    } else if (column is CompoundSelectColumn) {
      session._addRelation(CopyEncapsulating(column, column.columns));
      column.columns.forEach(_handleColumn);
    } else if (column is ValuesSelectColumn) {
      session._addRelation(CopyEncapsulating(column, column.expressions));
    } else if (column is DelegatedColumn && column.innerColumn != null) {
      _handleColumn(column.innerColumn);

      var makeNullable = false;

      if (column is AvailableColumn) {
        // The nullability depends on whether the column was introduced in an
        // outer join.
        final model = context != null ? JoinModel.of(context) : null;

        makeNullable = model != null && model.availableColumnIsNullable(column);
      }

      _lazyCopy(column, column.innerColumn, makeNullable: makeNullable);
    }
  }

  void _lazyCopy(Typeable to, Typeable? from, {bool makeNullable = false}) {
    if (from == null) return;

    if (session.graph.knowsType(from)) {
      var type = session.typeOf(from)!;
      if (makeNullable) {
        type = type.withNullable(true);
        session._markTypeResolved(to, type);
      } else if (session.graph.knowsNullability(from)) {
        session._markTypeResolved(to, type);
      } else {
        session._markTypeResolved(to, type);
        session._addRelation(NullableIfSomeOtherIs(to, [from]));
      }
    } else {
      session._addRelation(CopyTypeFrom(to, from, makeNullable: makeNullable));
    }
  }

  void _handleWhereClause(HasWhereClause e) {
    if (e.where != null) {
      // assume that a where statement is a boolean expression. Sqlite
      // internally casts (https://www.sqlite.org/lang_expr.html#booleanexpr),
      // so be lax
      visit(e.where!, _expectCondition);
    }
  }

  ResolvedType? _inferFromContext(TypeExpectation expectation) {
    if (expectation is ExactTypeExpectation) {
      return expectation.type;
    }
    return null;
  }
}

class _ResultColumnVisitor extends RecursiveVisitor<void, void> {
  final TypeResolver resolver;

  _ResultColumnVisitor(this.resolver);

  @override
  void visitBaseSelectStatement(BaseSelectStatement stmt, void arg) {
    if (stmt.resolvedColumns != null) {
      for (final column in stmt.resolvedColumns!) {
        resolver._handleColumn(column, stmt);
      }
    }

    visitChildren(stmt, arg);
  }

  void _handleReturning(StatementReturningColumns stmt) {
    final columns = stmt.returnedResultSet?.resolvedColumns;

    if (columns != null) {
      for (final column in columns) {
        resolver._handleColumn(column, stmt);
      }
    }
  }

  @override
  void visitInsertStatement(InsertStatement e, void arg) {
    _handleReturning(e);
    visitChildren(e, arg);
  }

  @override
  void visitUpdateStatement(UpdateStatement e, void arg) {
    _handleReturning(e);
    visitChildren(e, arg);
  }

  @override
  void visitDeleteStatement(DeleteStatement e, void arg) {
    _handleReturning(e);
    visitChildren(e, arg);
  }
}
