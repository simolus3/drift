import 'package:moor_generator/src/analyzer/sql_queries/meta/declarations.dart';
import 'package:recase/recase.dart';

/// An abstract schema entity that isn't a table.
///
/// This includes triggers or indexes.
abstract class SpecifiedEntity {
  final String name;

  String get dartFieldName => ReCase(name).camelCase;

  SpecifiedEntity(this.name);
}

/// Information about a trigger defined in a `.moor` file.
class SpecifiedTrigger extends SpecifiedEntity {
  /// Information on where this trigger was created.
  final BaseDeclaration declaration;

  /// The `CREATE TRIGGER` sql statement that creates this trigger.
  final String sql;

  SpecifiedTrigger(String name, this.sql, this.declaration) : super(name);
}
