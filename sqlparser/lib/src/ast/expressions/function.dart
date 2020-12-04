part of '../ast.dart';

/// Interface for function calls.
///
/// Functions that resolve to an [Expression] are subclasses of
/// [ExpressionInvocation], like [FunctionExpression] or [AggregateExpression].
/// There are invocation that don't resolve to an expression, notably
/// [TableValuedFunction].
abstract class SqlInvocation implements AstNode {
  /// The name of the function being called
  String get name;

  FunctionParameters get parameters;
}

/// Interface for [SqlInvocation]s that are also expressions.
abstract class ExpressionInvocation implements SqlInvocation, Expression {}

class FunctionExpression extends Expression
    with ReferenceOwner
    implements ExpressionInvocation {
  @override
  final String name;
  @override
  FunctionParameters parameters;

  FunctionExpression({@required this.name, @required this.parameters});

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitFunction(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    parameters = transformer.transformChild(parameters, this, arg);
  }

  @override
  Iterable<AstNode> get childNodes {
    return [parameters];
  }
}

/// Marker interface for anything that can be inside the parentheses after a
/// function name.
abstract class FunctionParameters extends AstNode {}

/// Using a star as a function parameter. For instance: "COUNT(*)".
class StarFunctionParameter extends FunctionParameters {
  StarFunctionParameter();

  Token starToken;

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitStarFunctionParameter(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {}

  @override
  Iterable<AstNode> get childNodes => const Iterable.empty();
}

class ExprFunctionParameters extends FunctionParameters {
  final bool distinct;
  final List<Expression> parameters;

  ExprFunctionParameters({this.parameters = const [], this.distinct = false});

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitExpressionFunctionParameters(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    transformer.transformChildren(parameters, this, arg);
  }

  @override
  List<AstNode> get childNodes => parameters;
}
