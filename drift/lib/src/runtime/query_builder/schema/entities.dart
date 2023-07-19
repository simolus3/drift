part of '../query_builder.dart';

/// Some abstract schema entity that can be stored in a database. This includes
/// tables, triggers, views, indexes, etc.
abstract class DatabaseSchemaEntity {
  /// The (unalised) name of this entity in the database.
  String get entityName;
}

/// A sqlite trigger that's executed before, after or instead of a subset of
/// writes on a specific tables.
/// In drift, triggers can only be declared in `.drift` files.
///
/// For more information on triggers, see the [CREATE TRIGGER][sqlite-docs]
/// documentation from sqlite, or the [entry on sqlitetutorial.net][sql-tut].
///
/// [sqlite-docs]: https://sqlite.org/lang_createtrigger.html
/// [sql-tut]: https://www.sqlitetutorial.net/sqlite-trigger/
class Trigger extends DatabaseSchemaEntity {
  /// The `CREATE TRIGGER` sql statement that can be used to create this
  /// trigger.
  final String createTriggerStmt;
  @override
  final String entityName;

  /// Creates a trigger representation by the [createTriggerStmt] and its
  /// [entityName]. Mainly used by generated code.
  Trigger(this.createTriggerStmt, this.entityName);
}

/// A sqlite index on columns or expressions.
///
/// For more information on triggers, see the [CREATE TRIGGER][sqlite-docs]
/// documentation from sqlite, or the [entry on sqlitetutorial.net][sql-tut].
///
/// [sqlite-docs]: https://www.sqlite.org/lang_createindex.html
/// [sql-tut]: https://www.sqlitetutorial.net/sqlite-index/
class Index extends DatabaseSchemaEntity {
  @override
  final String entityName;

  /// The `CREATE INDEX` sql statement that can be used to create this index.
  final String createIndexStmt;

  /// Creates an index model by the [createIndexStmt] and its [entityName].
  /// Mainly used by generated code.
  Index(this.entityName, this.createIndexStmt);
}

/// An internal schema entity to run an sql statement when the database is
/// created.
///
/// The generator uses this entity to implement `@create` statements in drift
/// files:
/// ```sql
/// CREATE TABLE users (name TEXT);
///
/// @create: INSERT INTO users VALUES ('Bob');
/// ```
/// A [OnCreateQuery] is emitted for each `@create` statement in an included
/// drift file.
class OnCreateQuery extends DatabaseSchemaEntity {
  /// The sql statement that should be run in the default `onCreate` clause.
  final String sql;

  /// Create a query that will be run in the default `onCreate` migration.
  OnCreateQuery(this.sql);

  @override
  String get entityName => r'$internal$';
}

/// Interface for schema entities that have a result set.
///
/// [Tbl] is the generated Dart class which implements [ResultSetImplementation]
/// and the user-defined [Table] class. [Row] is the class used to hold a result
/// row.
abstract class ResultSetImplementation<Tbl, Row> extends DatabaseSchemaEntity {
  /// The generated database instance that this view or table is attached to.
  @internal
  DatabaseConnectionUser get attachedDatabase;

  /// The (potentially aliased) name of this table or view.
  ///
  /// If no alias is active, this is the same as [entityName].
  String get aliasedName => entityName;

  /// Type system sugar. Implementations are likely to inherit from both
  /// [TableInfo] and [Tbl] and can thus just return their instance.
  Tbl get asDslTable;

  /// All columns from this table or view.
  List<GeneratedColumn> get $columns;

  /// Maps the given row returned by the database into the fitting data class.
  FutureOr<Row> map(Map<String, dynamic> data, {String? tablePrefix});

  /// Creates an alias of this table or view that will write the name [alias]
  /// when used in a query.
  ResultSetImplementation<Tbl, Row> createAlias(String alias) =>
      _AliasResultSet(alias, this);

  /// Gets all [$columns] in this table or view, indexed by their (non-escaped)
  /// name.
  Map<String, GeneratedColumn> get columnsByName;
}

class _AliasResultSet<Tbl, Row> extends ResultSetImplementation<Tbl, Row> {
  final String _alias;
  final ResultSetImplementation<Tbl, Row> _inner;

  _AliasResultSet(this._alias, this._inner);

  @override
  DatabaseConnectionUser get attachedDatabase => _inner.attachedDatabase;

  @override
  List<GeneratedColumn> get $columns => _inner.$columns;

  @override
  String get aliasedName => _alias;

  @override
  ResultSetImplementation<Tbl, Row> createAlias(String alias) {
    return _AliasResultSet(alias, _inner);
  }

  @override
  String get entityName => _inner.entityName;

  @override
  FutureOr<Row> map(Map<String, dynamic> data, {String? tablePrefix}) {
    return _inner.map(data, tablePrefix: tablePrefix);
  }

  @override
  Tbl get asDslTable => _inner.asDslTable;

  @override
  Map<String, GeneratedColumn<Object>> get columnsByName =>
      _inner.columnsByName;
}

/// Extension to generate an alias for a table or a view.
extension NameWithAlias on ResultSetImplementation<dynamic, dynamic> {
  /// The table name, optionally suffixed with the alias if one exists. This
  /// can be used in select statements, as it returns something like "users u"
  /// for a table called users that has been aliased as "u".
  String get tableWithAlias {
    var dialect = attachedDatabase.executor.dialect;
    if (aliasedName == entityName) {
      return dialect == SqlDialect.mariadb ? '`$entityName`' : '"$entityName"';
    } else {
      return dialect == SqlDialect.mariadb
          ? '`$entityName` `$aliasedName`'
          : '"$entityName" "$aliasedName"';
    }
  }
}
