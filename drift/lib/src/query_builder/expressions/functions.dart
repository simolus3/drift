import 'package:built_collection/built_collection.dart';
import 'package:drift/src/query_builder/compiler.dart';
import 'package:meta/meta.dart';
import 'expression.dart';

/// A sql expression that calls a function.
///
/// This class is mainly used by drift internally. If you find yourself using
/// this class, consider [creating an issue](https://github.com/simolus3/drift/issues/new)
/// to request native support in drift.
@immutable
final class FunctionCallExpression<R extends Object> extends Expression<R> {
  /// The name of the function to call
  final String functionName;

  /// The arguments passed to the function, as expressions.
  final BuiltList<Expression> arguments;

  @override
  Precedence get precedence => Precedence.primary;

  /// Constructs a function call expression in sql from the [functionName] and
  /// the target [arguments].
  FunctionCallExpression(this.functionName, Iterable<Expression> arguments)
      : arguments = BuiltList.of(arguments);
  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addFunctionCallExpression(this);
  }

  @override
  int get hashCode => Object.hash(functionName, arguments);

  @override
  bool operator ==(Object other) {
    return other is FunctionCallExpression &&
        other.functionName == functionName &&
        arguments == other.arguments;
  }
}
