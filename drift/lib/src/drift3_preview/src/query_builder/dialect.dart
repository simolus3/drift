import '../connection/connection.dart';
import 'compiler.dart';
import 'expressions/variables.dart';
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

  /// Whether this dialect supports indexed parameters.
  ///
  /// For dialects that support this features, an explicit index can be given
  /// for parameters, even if it doesn't match the order of occurrences in the
  /// given statement (e.g. `INSERT INTO foo VALUES (?1, ?2, ?3, ?4)`).
  /// In dialects without this feature, every syntactic occurrence of a variable
  /// introduces a new logical variable with a new index, variables also can't
  /// be re-used.
  bool get supportsIndexedParameters => true;

  /// Creates a [StatementCompiler] implementation generating SQL for this
  /// dialect.
  StatementCompiler createCompiler();

  /// Compiles the component with a compiler for this dialect.
  StatementInfo compile(SqlComponent component) {
    final compiler = createCompiler();
    component.compileWith(compiler);
    return compiler.statement.toStatementInfo();
  }

  /// For dialects that don't support named or explicitly-indexed variables,
  /// translates a variable assignment to avoid using that feature.
  ///
  /// For instance, the SQL snippet `WHERE x = :a OR y = :a` would be translated
  /// to `WHERE x = ? OR y = ?`. Then, [original] would contain the value for
  /// the single variable and [syntacticOccurences] would contain two values
  /// (`1` and `1`) referencing the original variable.
  List<Variable> desugarDuplicateVariables(
    List<Variable> original,
    List<int> syntacticOccurences,
  ) {
    if (supportsIndexedParameters) return original;

    return [
      for (final occurence in syntacticOccurences)
        // Variables in SQL are 1-indexed
        original[occurence - 1],
    ];
  }
}

/// A factory to create [DriftDialect] implementations based on available
/// options.
typedef DriftDialectFactory =
    DriftDialect Function(Map<KnownSqlDialect, Object> dialectOptions);
