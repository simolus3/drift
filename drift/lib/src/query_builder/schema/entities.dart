import '../compiler.dart';

/// Some abstract schema entity that can be stored in a database. This includes
/// tables, triggers, views, indexes, etc.
abstract interface class DatabaseSchemaEntity {
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
  @override
  final String entityName;

  /// A function responsible for writing the `CREATE TRIGGER` definition given
  /// a [StatementCompiler].
  final void Function(StatementCompiler) generateDefinition;

  /// Creates a trigger from its name and the (possibly dialect-specific)
  /// definition generator.
  Trigger(this.entityName, this.generateDefinition);

  /// Creates a trigger backed by an [sql] string that's not dialect-specific.
  Trigger.simpleSql(this.entityName, String sql)
      : generateDefinition =
            ((compiler) => compiler.statement.buffer.write(sql));
}
