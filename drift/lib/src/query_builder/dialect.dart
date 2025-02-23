import 'compiler.dart';
import 'types.dart';

abstract base class DriftDialect implements TypeProvider {
  @override
  SqlType<T> resolveType<T extends Object>() {
    return BuiltinDriftType.forType<T>().resolveIn(this);
  }

  StatementCompiler createCompiler();

  CompiledStatement compile(SqlComponent component) {
    final compiler = createCompiler();
    component.compileWith(compiler);
    return compiler.statement;
  }
}
