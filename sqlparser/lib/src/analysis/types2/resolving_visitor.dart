part of 'types.dart';

const _intType = ResolvedType(type: BasicType.int);
const _realType = ResolvedType(type: BasicType.real);
const _textType = ResolvedType(type: BasicType.text);

const _expectInt = ExactTypeExpectation.laxly(_intType);
const _expectNum = RoughTypeExpectation.numeric();
const _expectString = ExactTypeExpectation.laxly(_textType);

class TypeResolver extends RecursiveVisitor<TypeExpectation, void> {
  final TypeInferenceSession session;

  TypeResolver(this.session);

  void run(AstNode root) {
    visit(root, const NoTypeExpectation());
    session.finish();
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
          currentColumnIndex += child.scope.availableColumns.length;
        }
      } else {
        visit(child, arg);
      }
    }
  }

  @override
  void visitInsertStatement(InsertStatement e, TypeExpectation arg) {
    if (e.withClause != null) visit(e.withClause, arg);
    visitList(e.targetColumns, const NoTypeExpectation());

    final targets = e.resolvedTargetColumns ?? const [];
    targets.forEach(_handleColumn);

    final expectations = targets.map((r) {
      if (session.graph.knowsType(r)) {
        return ExactTypeExpectation(session.typeOf(r));
      }
      return const NoTypeExpectation();
    }).toList();

    e.source.when(
      isSelect: (select) {
        visit(select.stmt, SelectTypeExpectation(expectations));
      },
      isValues: (values) {
        for (final tuple in values.values) {
          for (var i = 0; i < tuple.expressions.length; i++) {
            final expectation = i < expectations.length
                ? expectations[i]
                : const NoTypeExpectation();
            visit(tuple.expressions[i], expectation);
          }
        }
      },
    );
  }

  @override
  void visitCrudStatement(CrudStatement stmt, TypeExpectation arg) {
    if (stmt is HasWhereClause) {
      final typedStmt = stmt as HasWhereClause;
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
  void visitLimit(Limit e, TypeExpectation arg) {
    visit(e.count, _expectInt);
    visitNullable(e.offset, _expectInt);
  }

  @override
  void visitLiteral(Literal e, TypeExpectation arg) {
    ResolvedType type;

    if (e is NullLiteral) {
      type = const ResolvedType(type: BasicType.nullType, nullable: true);
      session.hintNullability(e, true);
    } else if (e is StringLiteral) {
      type = e.isBinary ? const ResolvedType(type: BasicType.blob) : _textType;
      session.hintNullability(e, false);
    } else if (e is BooleanLiteral) {
      type = const ResolvedType.bool();
      session.hintNullability(e, false);
    } else if (e is NumericLiteral) {
      type = e.isInt ? _intType : _realType;
      session.hintNullability(e, false);
    }

    session.checkAndResolve(e, type, arg);
  }

  @override
  void visitVariable(Variable e, TypeExpectation arg) {
    final resolved = session.context.stmtOptions.specifiedTypeOf(e) ??
        _inferFromContext(arg);

    if (resolved != null) {
      session.checkAndResolve(e, resolved, arg);
    } else if (arg is RoughTypeExpectation) {
      session.addRelationship(DefaultType(e, arg.defaultType()));
    }

    visitChildren(e, arg);
  }

  @override
  void visitUnaryExpression(UnaryExpression e, TypeExpectation arg) {
    final operatorType = e.operator.type;

    if (operatorType == TokenType.plus) {
      // plus is a no-op, so copy type from child
      session.addRelationship(CopyTypeFrom(e, e.inner));
      visit(e.inner, arg);
    } else if (operatorType == TokenType.not) {
      // unary not expression - boolean, but nullability depends on child node.
      session.checkAndResolve(e, const ResolvedType.bool(nullable: null), arg);
      session.addRelationship(NullableIfSomeOtherIs(e, [e.inner]));
      visit(e.inner, const ExactTypeExpectation.laxly(ResolvedType.bool()));
    } else if (operatorType == TokenType.minus) {
      // unary minus - can be int or real depending on child node
      session.addRelationship(CopyAndCast(e, e.inner, CastMode.numeric));
      visit(e.inner, const RoughTypeExpectation.numeric());
    } else if (operatorType == TokenType.tilde) {
      // bitwise negation - definitely int, but nullability depends on child
      session.checkAndResolve(
          e, const ResolvedType(type: BasicType.int, nullable: null), arg);
      session.addRelationship(NullableIfSomeOtherIs(e, [e.inner]));

      visit(e.inner, const NoTypeExpectation());
    } else {
      throw StateError(
          'Unary operator $operatorType not recognized by types2. At $e');
    }
  }

  @override
  void visitBetweenExpression(BetweenExpression e, TypeExpectation arg) {
    visitChildren(e, _expectNum);

    session
      ..addRelationship(NullableIfSomeOtherIs(e, e.childNodes))
      ..addRelationship(HaveSameType(e.lower, e.upper))
      ..addRelationship(HaveSameType(e.check, e.lower));
  }

  @override
  void visitBinaryExpression(BinaryExpression e, TypeExpectation arg) {
    switch (e.operator.type) {
      case TokenType.and:
      case TokenType.or:
        session.checkAndResolve(e, const ResolvedType.bool(), arg);
        session.addRelationship(NullableIfSomeOtherIs(e, [e.left, e.right]));

        // logic expressions, so children must be boolean
        visitChildren(e, const ExactTypeExpectation.laxly(ResolvedType.bool()));
        break;
      case TokenType.equal:
      case TokenType.exclamationEqual:
      case TokenType.lessMore:
      case TokenType.less:
      case TokenType.lessEqual:
      case TokenType.more:
      case TokenType.moreEqual:
        // comparison. Returns bool, copying nullability from children.
        session.checkAndResolve(e, const ResolvedType.bool(), arg);
        session.addRelationship(NullableIfSomeOtherIs(e, [e.left, e.right]));
        // Not technically a requirement, but assume lhs and rhs have the same
        // type.
        session.addRelationship(HaveSameType(e.left, e.right));
        visitChildren(e, const NoTypeExpectation());
        break;
      case TokenType.plus:
      case TokenType.minus:
        session.addRelationship(CopyEncapsulating(e, [e.left, e.right]));
        break;
      // all of those only really make sense for integers
      case TokenType.shiftLeft:
      case TokenType.shiftRight:
      case TokenType.pipe:
      case TokenType.ampersand:
      case TokenType.percent:
        const type = ResolvedType(type: BasicType.int);
        session.checkAndResolve(e, type, arg);
        session.addRelationship(NullableIfSomeOtherIs(e, [e.left, e.right]));
        visitChildren(e, const ExactTypeExpectation.laxly(type));
        break;
      case TokenType.doublePipe:
        // string concatenation.
        const stringType = ResolvedType(type: BasicType.text);
        session.checkAndResolve(e, stringType, arg);
        session.addRelationship(NullableIfSomeOtherIs(e, [e.left, e.right]));
        const childExpectation = ExactTypeExpectation.laxly(stringType);
        visit(e.left, childExpectation);
        visit(e.right, childExpectation);
        break;
      default:
        throw StateError('Binary operator ${e.operator.type} not recognized '
            'by types2. At $e');
    }
  }

  @override
  void visitIsExpression(IsExpression e, TypeExpectation arg) {
    session.checkAndResolve(e, const ResolvedType.bool(), arg);
    session.hintNullability(e, false);
    visitChildren(e, const NoTypeExpectation());
  }

  @override
  void visitIsNullExpression(IsNullExpression e, TypeExpectation arg) {
    session.checkAndResolve(e, const ResolvedType.bool(), arg);
    session.hintNullability(e, false);
    visitChildren(e, const NoTypeExpectation());
  }

  @override
  void visitCaseExpression(CaseExpression e, TypeExpectation arg) {
    session.addRelationship(CopyEncapsulating(e, [
      for (final when in e.whens) when.then,
      if (e.elseExpr != null) e.elseExpr,
    ]));

    if (e.base != null) {
      session.addRelationship(
        CopyEncapsulating(e.base, [for (final when in e.whens) when.when]),
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
      session.addRelationship(CopyTypeFrom(e.when, parent.base));
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
    session.checkAndResolve(e, type, arg);
    session.addRelationship(NullableIfSomeOtherIs(e, [e.operand]));
    visit(e.operand, const NoTypeExpectation());
  }

  @override
  void visitStringComparison(
      StringComparisonExpression e, TypeExpectation arg) {
    session.checkAndResolve(e, const ResolvedType(type: BasicType.text), arg);
    session.addRelationship(NullableIfSomeOtherIs(
      e,
      [
        e.left,
        e.right,
        if (e.escape != null) e.escape,
      ],
    ));

    visit(e.left, _expectString);
    visit(e.right, _expectString);
    visitNullable(e.escape, _expectString);
  }

  @override
  void visitReference(Reference e, TypeExpectation arg) {
    final resolved = e.resolvedColumn;
    if (resolved == null) return;

    _handleColumn(resolved);
    _lazyCopy(e, resolved);
  }

  @override
  void visitInvocation(SqlInvocation e, TypeExpectation arg) {
    final type = _resolveInvocation(e);
    if (type != null) {
      session.checkAndResolve(e, type, arg);
    }
    visitChildren(e, const NoTypeExpectation());
  }

  ResolvedType _resolveInvocation(SqlInvocation e) {
    final params = e.expandParameters();
    void nullableIfChildIs() {
      session.addRelationship(NullableIfSomeOtherIs(e, params));
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
        session.addRelationship(CopyAndCast(e, params.first, CastMode.numeric));
        session.addRelationship(DefaultType(e, _realType));
        nullableIfChildIs();
        return null;
      case 'lower':
      case 'ltrim':
      case 'printf':
      case 'replace':
      case 'rtrim':
      case 'substr':
      case 'trim':
      case 'upper':
      case 'group_concat':
        nullableIfChildIs();
        return _textType;
      case 'date':
      case 'time':
      case 'datetime':
      case 'julianday':
      case 'strftime':
      case 'char':
      case 'hex':
      case 'quote':
      case 'soundex':
      case 'sqlite_compileoption_set':
      case 'sqlite_version':
      case 'typeof':
        return _textType;
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
        return _intType;
      case 'instr':
      case 'length':
      case 'unicode':
        nullableIfChildIs();
        return _intType;
      case 'randomblob':
      case 'zeroblob':
        return const ResolvedType(type: BasicType.blob);
      case 'total':
      case 'avg':
      case 'percent_rank':
      case 'cume_dist':
        return _realType;
      case 'abs':
      case 'likelihood':
      case 'likely':
      case 'unlikely':
        session.addRelationship(CopyTypeFrom(e, params.first));
        return null;
      case 'coalesce':
      case 'ifnull':
        session.addRelationship(CopyEncapsulating(e, params));
        return null;
      case 'nullif':
        session.hintNullability(e, true);
        session.addRelationship(CopyTypeFrom(e, params.first));
        return null;
      case 'first_value':
      case 'last_value':
      case 'lag':
      case 'lead':
      case 'nth_value':
        session.addRelationship(CopyTypeFrom(e, params.first));
        return null;
      case 'max':
      case 'min':
        session.hintNullability(e, true);
        session.addRelationship(CopyEncapsulating(e, params));
        return null;
    }

    final options = session.options;
    if (options.enableJson1) {
      switch (lowercaseName) {
        case 'json':
        case 'json_array':
        case 'json_insert':
        case 'json_replace':
        case 'json_set':
        case 'json_object':
        case 'json_patch':
        case 'json_remove':
        case 'json_quote':
        case 'json_group_array':
        case 'json_group_object':
          return _textType;
        case 'json_type':
          return _textType;
        case 'json_valid':
          return const ResolvedType.bool();
        case 'json_extract':
          return null;
        case 'json_array_length':
          return _intType;
      }
    }

    if (options.addedFunctions.containsKey(lowercaseName)) {
      return options.addedFunctions[lowercaseName]
          .inferReturnType(session.context, e, params)
          ?.type;
    }

    session.context.reportError(AnalysisError(
      type: AnalysisErrorType.unknownFunction,
      message: 'Function ${e.name} could not be found',
    ));
    return null;
  }

  void _handleColumn(Column column) {
    if (session.graph.knowsType(column)) return;

    if (column is TableColumn) {
      session.markTypeResolved(column, column.type);
    } else if (column is ExpressionColumn) {
      _lazyCopy(column, column.expression);
    } else if (column is DelegatedColumn && column.innerColumn != null) {
      _handleColumn(column.innerColumn);
      _lazyCopy(column, column.innerColumn);
    }
  }

  void _lazyCopy(Typeable to, Typeable from) {
    if (session.graph.knowsType(from)) {
      session.markTypeResolved(to, session.typeOf(from));
    } else {
      session.addRelationship(CopyTypeFrom(to, from));
    }
  }

  void _handleWhereClause(HasWhereClause stmt) {
    if (stmt.where != null) {
      // assume that a where statement is a boolean expression. Sqlite
      // internally casts (https://www.sqlite.org/lang_expr.html#booleanexpr),
      // so be lax
      visit(stmt.where, const ExactTypeExpectation.laxly(ResolvedType.bool()));
    }
  }

  ResolvedType _inferFromContext(TypeExpectation expectation) {
    if (expectation is ExactTypeExpectation) {
      return expectation.type;
    }
    return null;
  }
}
