import '../compiler.dart';
import '../dialect.dart';
import '../types.dart';

abstract base class Expression<T extends Object> extends SqlComponent {
  SqlType<T> resolveType(DriftDialect dialect);

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addExpression(this);
  }
}
