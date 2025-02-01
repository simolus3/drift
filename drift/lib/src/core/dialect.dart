import 'package:meta/meta.dart';

import 'compiler.dart';
import 'statements/statement.dart';
import 'types.dart';

abstract base class DriftDialect implements TypeProvider {
  @override
  SqlType<T> resolveType<T extends Object>() {
    return BuiltinDriftType.forType<T>().resolveIn(this);
  }

  @protected
  StatementCompiler createCompiler();

  CompiledStatement compile(SqlStatement statement) {
    final compiler = createCompiler();
    statement.compileWith(compiler);
    return compiler.statement;
  }
}
