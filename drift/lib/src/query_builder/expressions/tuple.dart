import 'package:built_collection/built_collection.dart';
import 'package:meta/meta.dart';

import '../compiler.dart';
import 'expression.dart';

@immutable
final class ExpressionTuple<T extends Object> extends Expression {
  final BuiltList<Expression<T>> values;

  ExpressionTuple(Iterable<Expression<T>> values)
      : values = BuiltList.of(values),
        assert(values.isNotEmpty);

  @override
  Precedence get precedence => Precedence.primary;

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addTuple(this);
  }
}
