part of '../ast.dart';

/// Interface for function calls, either a [FunctionExpression] or a
/// [AggregateExpression].
abstract class SqlInvocation extends Expression {
  /// The name of the function being called
  String get name;

  FunctionParameters get parameters;
}

class FunctionExpression extends Expression
    with ReferenceOwner
    implements SqlInvocation {
  @override
  final String name;
  @override
  final FunctionParameters parameters;

  FunctionExpression({@required this.name, @required this.parameters});

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitFunction(this, arg);
  }

  @override
  Iterable<AstNode> get childNodes {
    return [parameters];
  }

  @override
  bool contentEquals(FunctionExpression other) {
    return other.name == name;
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
  Iterable<AstNode> get childNodes => const Iterable.empty();

  @override
  bool contentEquals(StarFunctionParameter other) {
    return true;
  }
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
  List<AstNode> get childNodes => parameters;

  @override
  bool contentEquals(ExprFunctionParameters other) {
    return other.distinct == distinct && other.parameters == parameters;
  }
}
