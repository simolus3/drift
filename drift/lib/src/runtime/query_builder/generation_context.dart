part of 'query_builder.dart';

/// Contains information about a query while it's being constructed.
class GenerationContext {
  /// Whether the query obtained by this context operates on multiple tables.
  ///
  /// If it does, columns should prefix their table name to avoid ambiguous
  /// queries.
  bool hasMultipleTables = false;

  /// When set to a non-null value, [Variable]s in this context will generate
  /// explicit indices starting at [explicitVariableIndex].
  int? explicitVariableIndex;

  /// When set to an entity name (view or table), generated column in that
  /// entity definition will written into query as expression
  String? generatingForView;

  /// All tables that the generated query reads from.
  final List<ResultSetImplementation> watchedTables = [];

  /// The options to use when mapping values from and to the database.
  @Deprecated('Use typeMapping instead')
  final DriftDatabaseOptions options;

  /// The [SqlTypes] configuration used for mapping values to the database.
  final SqlTypes typeMapping;

  /// The [SqlDialect] that should be respected when generating the query.
  SqlDialect get dialect => executor?.executor.dialect ?? SqlDialect.sqlite;

  /// The actual [DatabaseConnectionUser] that's going to execute the generated
  /// query.
  final DatabaseConnectionUser? executor;

  /// Whether variables are supported and can be written as `?` to be bound
  /// later.
  ///
  /// This is almost always the case, but not in a `CREATE VIEW` statement.
  final bool supportsVariables;

  final List<dynamic> _boundVariables = [];

  /// The values of [introducedVariables] that will be sent to the underlying
  /// engine.
  List<dynamic> get boundVariables => _boundVariables;

  /// All variables ("?" in sql) that were added to this context.
  final List<Variable> introducedVariables = [];

  /// Returns the amount of variables that have been introduced when writing
  /// this query.
  int get amountOfVariables => boundVariables.length;

  /// The string buffer contains the sql query as it's being constructed.
  final StringBuffer buffer = StringBuffer();

  /// Gets the generated sql statement
  String get sql => buffer.toString();

  /// The variable indices occupied by this generation context.
  ///
  /// SQL variables are 1-indexed, so a context with three variables would
  /// cover the variables `1`, `2` and `3` by default.
  Iterable<int> get variableIndices {
    final start = explicitVariableIndex ?? 1;
    return Iterable.generate(amountOfVariables, (i) => start + i);
  }

  /// Constructs a [GenerationContext] by copying the relevant fields from the
  /// database.
  GenerationContext.fromDb(DatabaseConnectionUser this.executor,
      {this.supportsVariables = true})
      // ignore: deprecated_member_use_from_same_package
      : options = executor.options,
        typeMapping = executor.typeMapping;

  /// Constructs a custom [GenerationContext] by setting the fields manually.
  /// See [GenerationContext.fromDb] for a more convenient factory.
  GenerationContext(this.options, this.executor,
      {this.supportsVariables = true})
      : typeMapping = options
            .createTypeMapping(executor?.executor.dialect ?? SqlDialect.sqlite);

  /// Introduces a variable that will be sent to the database engine. Whenever
  /// this method is called, a question mark should be added to the [buffer] so
  /// that the prepared statement can be executed with the variable. The value
  /// must be a type that is supported by the sqflite library. A list of
  /// supported types can be found [here](https://github.com/tekartik/sqflite#supported-sqlite-types).
  void introduceVariable(Variable v, dynamic value) {
    introducedVariables.add(v);
    _boundVariables.add(value);
  }

  /// Shortcut to add a single space to the buffer because it's used very often.
  void writeWhitespace() => buffer.write(' ');

  /// Turns [columnName] into a safe SQL identifier by wrapping it in double
  /// quotes, or backticks depending on the dialect.
  String identifier(String columnName) => dialect.escape(columnName);
}
