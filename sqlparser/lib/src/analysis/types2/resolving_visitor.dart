part of 'types.dart';

class TypeResolver extends RecursiveVisitor<TypeExpectation, void> {
  final TypeInferenceSession session;

  TypeResolver(this.session);

  void start(AstNode root) {
    visit(root, const NoTypeExpectation());
  }

  @override
  void visitCrudStatement(CrudStatement stmt, TypeExpectation arg) {
    if (stmt is HasWhereClause && stmt.where != null) {
      _handleWhereClause(stmt);
      _visitExcept(stmt, stmt.where, arg);
    } else {
      visitChildren(stmt, arg);
    }
  }

  @override
  void visitJoin(Join e, TypeExpectation arg) {
    final constraint = e.constraint;
    if (constraint is OnConstraint) {
      // ON <expr>, <expr> should be boolean
      visit(constraint.expression,
          const ExactTypeExpectation.laxly(ResolvedType.bool()));
      _visitExcept(e, constraint.expression, arg);
    } else {
      visitChildren(e, arg);
    }
  }

  @override
  void visitLiteral(Literal e, TypeExpectation arg) {
    ResolvedType type;

    if (e is NullLiteral) {
      type = const ResolvedType(type: BasicType.nullType, nullable: true);
    } else if (e is StringLiteral) {
      type = e.isBinary
          ? const ResolvedType(type: BasicType.blob)
          : const ResolvedType(type: BasicType.text);
    } else if (e is BooleanLiteral) {
      type = const ResolvedType.bool();
    } else if (e is NumericLiteral) {
      type = e.isInt
          ? const ResolvedType(type: BasicType.int)
          : const ResolvedType(type: BasicType.real);
    }

    session.checkAndResolve(e, type, arg);
  }

  @override
  void visitVariable(Variable e, TypeExpectation arg) {
    final resolved = _inferFromContext(arg);
    if (resolved != null) {
      session.markTypeResolved(e, resolved);
    }
    // todo support when arg is RoughTypeExpectation
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

  void _handleWhereClause(HasWhereClause stmt) {
    // assume that a where statement is a boolean expression. Sqlite internally
    // casts (https://www.sqlite.org/lang_expr.html#booleanexpr), so be lax
    visit(stmt.where, const ExactTypeExpectation.laxly(ResolvedType.bool()));
  }

  void _visitExcept(AstNode node, AstNode skip, TypeExpectation arg) {
    for (final child in node.childNodes) {
      if (child != skip) {
        visit(child, arg);
      }
    }
  }

  ResolvedType _inferFromContext(TypeExpectation expectation) {
    if (expectation is ExactTypeExpectation) {
      return expectation.type;
    }
    return null;
  }
}
