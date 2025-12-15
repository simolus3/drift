import '../compiler.dart';
import '../statements/statement.dart';
import 'entities.dart';
import 'table.dart';
import 'view.dart';

/// Represents a `DROP TABLE` statement in SQL.
final class DropStatement extends SqlStatement {
  /// The type of element to delete (either `TABLE`, `VIEW`, `TRIGGER` or
  /// `INDEX`).
  final String kind;

  /// The name of table, view, index of trigger that should be dropped by this
  /// statement.
  final String name;

  /// When set to `true`, don't fail if [name] doesn't exist.
  final bool ifExists;

  /// Create a statement that will `DROP` the [name] when issued.
  DropStatement(this.kind, this.name, {this.ifExists = false});

  /// Creates a `DROP` statement dropping [entity].
  DropStatement.entity(DatabaseSchemaEntity entity, {this.ifExists = false})
      : kind = switch (entity) {
          GeneratedTable() => 'TABLE',
          GeneratedView() => 'VIEW',
          Index() => 'INDEX',
          Trigger() => 'TRIGGER',
          _ => throw ArgumentError.value(
              entity, 'entity', 'Not something can be dropped.'),
        },
        name = entity.entityName;

  @override
  void compileWith(StatementCompiler compiler) {
    return compiler.addDropStatement(this);
  }
}
