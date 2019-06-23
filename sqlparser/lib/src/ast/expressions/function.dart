part of '../ast.dart';

class FunctionExpression extends Expression {
  final String name;
  final FunctionParameters parameters;

  FunctionExpression({@required this.name, @required this.parameters});

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitFunction(this);

  @override
  Iterable<AstNode> get childNodes {
    return [
      if (parameters is ExprFunctionParameters)
        ...(parameters as ExprFunctionParameters).parameters
    ];
  }

  @override
  bool contentEquals(FunctionExpression other) {
    if (other.name != name) {
      return false;
    }

    if (parameters is StarFunctionParameter) {
      return other.parameters is StarFunctionParameter;
    } else if (parameters is ExprFunctionParameters) {
      final typedParams = parameters as ExprFunctionParameters;
      final typedOther = other.parameters as ExprFunctionParameters;
      return typedParams.equals(typedOther);
    }

    return true;
  }
}

/// Marker interface for anything that can be inside the parentheses after a
/// function name.
abstract class FunctionParameters {}

/// Using a star as a function parameter. For instance: "COUNT(*)".
class StarFunctionParameter implements FunctionParameters {
  const StarFunctionParameter();
}

class ExprFunctionParameters implements FunctionParameters {
  final bool distinct;
  final List<Expression> parameters;

  ExprFunctionParameters({this.parameters = const [], this.distinct = false});

  bool equals(ExprFunctionParameters other) {
    return other.distinct == distinct && other.parameters == parameters;
  }
}
