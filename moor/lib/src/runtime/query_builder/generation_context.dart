part of 'query_builder.dart';

/// Contains information about a query while it's being constructed.
class GenerationContext {
  /// Whether the query obtained by this context operates on multiple tables.
  ///
  /// If it does, columns should prefix their table name to avoid ambiguous
  /// queries.
  bool hasMultipleTables = false;

  /// The [SqlTypeSystem] to use when mapping variables to values that the
  /// underlying database understands.
  final SqlTypeSystem typeSystem;

  /// The [SqlDialect] that should be respected when generating the query.
  final SqlDialect dialect;

  /// The actual [QueryEngine] that's going to execute the generated query.
  final QueryEngine? executor;

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

  /// Constructs a [GenerationContext] by copying the relevant fields from the
  /// database.
  GenerationContext.fromDb(this.executor)
      : typeSystem = executor?.typeSystem ?? SqlTypeSystem.defaultInstance,
        // ignore: invalid_null_aware_operator, (doesn't seem to actually work)
        dialect = executor?.executor?.dialect ?? SqlDialect.sqlite;

  /// Constructs a custom [GenerationContext] by setting the fields manually.
  /// See [GenerationContext.fromDb] for a more convenient factory.
  GenerationContext(this.typeSystem, this.executor,
      {this.dialect = SqlDialect.sqlite});

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
}
