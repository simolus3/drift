import '../connection/connection.dart';
import 'compiler.dart';
import 'types.dart';

/// An enumeration of SQL dialects supported by drift.
enum KnownSqlDialect {
  /// Generate SQL for SQLite.
  sqlite,

  /// Generate SQL for PostgreSQL.
  postgres,

  /// Generate SQL for MariaDB or MySQL.
  mariadb,
}

/// SQL dialect.
///
/// Different database systems may support a slightly different syntax for some
/// queries, support different types or have specifc functions not avaialable
/// in others.
///
/// To make drift able to generate code for each dialect, a [DriftDialect]
/// implementation has full control over the way high-level drift structures
/// are mapped to SQL.
///
/// This class implements [TypeProvider], which is responsible for mapping
/// values between Dart and SQL. Via [createCompiler], it's also responsible
/// for returning a visitor generating SQL for drift statements and expressions.
abstract base class DriftDialect implements TypeProvider {
  /// @nodoc
  const DriftDialect();

  /// If this dialect is listed in [KnownSqlDialect], returns the dialect
  /// matching this one.
  KnownSqlDialect? get known;

  @override
  PhysicalSqlType<T> resolveType<T extends Object>() {
    return BuiltinDriftType.forType<T>()?.resolveIn(this) ??
        (throw ArgumentError('Unknown type parameter for builtin type: $T'));
  }

  /// Creates a [StatementCompiler] implementation generating SQL for this
  /// dialect.
  StatementCompiler createCompiler();

  /// Compiles the component with a compiler for this dialect.
  StatementInfo compile(SqlComponent component) {
    final compiler = createCompiler();
    component.compileWith(compiler);
    return compiler.statement.toStatementInfo();
  }
}
