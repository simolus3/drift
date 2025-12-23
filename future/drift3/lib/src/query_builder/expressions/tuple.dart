import '../compiler.dart';
import 'expression.dart';

/// A tuple of multiple expressions.
///
/// In SQLite, this is known as a [row value](https://sqlite.org/rowvalue.html).
/// It implements [Expression] in drift, but can not be used in all places where
/// expressions can be used in all database engines.
final class ExpressionTuple<T extends Object> extends Expression {
  /// The expressions making up this tuple.
  final List<Expression<T>> values;

  /// @nodoc
  ExpressionTuple(this.values) : assert(values.isNotEmpty);

  @override
  Precedence get precedence => Precedence.primary;

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addTuple(this);
  }
}
