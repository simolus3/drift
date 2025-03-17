import 'compiler.dart';
import 'types.dart';

enum KnownSqlDialect {
  sqlite,
  postgres,
  mariadb,
}

abstract base class DriftDialect implements TypeProvider {
  const DriftDialect();

  KnownSqlDialect? get known;

  @override
  SqlType<T> resolveType<T extends Object>() {
    return BuiltinDriftType.forType<T>()?.resolveIn(this) ??
        (throw ArgumentError('Unknown type parameter for builtin type: $T'));
  }

  StatementCompiler createCompiler();

  CompiledStatement compile(SqlComponent component) {
    final compiler = createCompiler();
    component.compileWith(compiler);
    return compiler.statement;
  }
}
