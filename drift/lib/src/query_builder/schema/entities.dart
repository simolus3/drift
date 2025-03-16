import '../compiler.dart';
import '../statements/statement.dart';

/// Some abstract schema entity that can be stored in a database. This includes
/// tables, triggers, views, indexes, etc.
abstract interface class DatabaseSchemaEntity {
  /// The (unalised) name of this entity in the database.
  String get entityName;
}

/// A statement that creates a [DatabaseSchemaEntity] (such as tables, views,
/// triggers or indices).
abstract base class CreateStatement<T extends DatabaseSchemaEntity>
    extends SqlStatement {
  /// The table, view, trigger or index to create.
  final T entity;

  /// Whether the [entity] should only be created if it doesn't exist alredy.
  final bool ifNotExists;

  /// @nodoc
  CreateStatement(this.entity, {this.ifNotExists = false});
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
final class Trigger extends DatabaseSchemaEntity {
  @override
  final String entityName;

  /// A function responsible for writing the `CREATE TRIGGER` definition given
  /// a [StatementCompiler].
  final CustomComponent definition;

  /// Creates a trigger from its name and the (possibly dialect-specific)
  /// definition generator.
  Trigger(this.entityName, this.definition);
}

/// Represents a `CREATE TRIGGER` statement in SQL.
final class CreateTriggerStatement extends CreateStatement<Trigger> {
  /// Create a statement that will `CREATE` the [entity] when issued.
  CreateTriggerStatement(super.entity, {super.ifNotExists});

  @override
  void compileWith(StatementCompiler compiler) {
    return compiler.addCreateTriggerStatement(this);
  }
}

/// An index on a table.
final class Index extends DatabaseSchemaEntity {
  @override
  final String entityName;

  /// A function responsible for writing the `CREATE INDEX` definition given
  /// a [StatementCompiler].
  final CustomComponent definition;

  /// Creates a trigger from its name and the (possibly dialect-specific)
  /// definition generator.
  Index(this.entityName, this.definition);
}

/// Represents a `CREATE INDEX` statement in SQL.
final class CreateIndexStatement extends CreateStatement<Index> {
  /// Create a statement that will `CREATE` the [entity] when issued.
  CreateIndexStatement(super.entity, {super.ifNotExists});

  @override
  void compileWith(StatementCompiler compiler) {
    return compiler.addCreateIndexStatement(this);
  }
}

/// A query defined in a drift file that should run when the database is
/// created.
final class OnCreateQuery extends DatabaseSchemaEntity {
  @override
  String get entityName => '@create';

  /// The dialect-specific SQL text to write when creating the database.
  final CustomComponent definition;

  /// Creates a trigger from its name and the (possibly dialect-specific)
  /// definition generator.
  OnCreateQuery(this.definition);
}
