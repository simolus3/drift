import 'dart:isolate';

import 'package:meta/meta.dart';

import '../drift.dart';

/// Generates `CREATE` statements for the given database [schema] for all
/// [dialects] and sends generated statements through the send [port].
///
/// Each statement will be encoded as a `[index, name, sql]` list, where `index`
/// is the index in [dialects], `name` is the [DatabaseSchemaEntity.entityName]
/// and `sql` is the compiled [StatementInfo.sql] statement.
/// A list of these structures is then sent through the port.
///
/// This sequence is used by the `drift_dev schema export` command, which
/// prints `CREATE` statements making up a drift database analyzed from
/// source. For this to work, it emulates a drift build and then creates a
/// Dart program calling this method.
///
/// This method is thus internal to that utility and likely not useful outside
/// of that.
@internal
void sendCreateStatements(
  SendPort port,
  DatabaseSchema schema,
  List<DriftDialect> dialects,
) {
  final statements = <List<Object>>[];

  for (final (index, dialect) in dialects.indexed) {
    for (final entity in schema) {
      StatementInfo compiled;

      switch (entity) {
        case Trigger():
        case Index():
        case SchemaEntityWithResultSet<Object, ResultSet<Object, dynamic>>():
          compiled = dialect.compile(CreateStatement.creatingElement(entity));
        case OnCreateQuery(:final definition):
          compiled = dialect.compile(definition);
      }

      statements.add([index, entity.entityName, compiled.sql]);
    }
  }
}
