import 'package:drift/drift.dart';

import 'element.dart';
import 'query.dart';
import 'table.dart';

class DriftTrigger extends DriftSchemaElement {
  /// The table whose writes trigger this trigger.
  final DriftTable? on;

  /// The kind of write (insert, update, delete) causing this trigger to run.
  final UpdateKind onWrite;

  @override
  final List<DriftElement> references;

  /// The `CREATE TRIGGER` statement creating this trigger.
  final String createStmt;

  /// Writes performed in the body of this trigger.
  final List<WrittenDriftTable> writes;

  DriftTrigger(
    super.id,
    super.declaration, {
    required this.on,
    required this.onWrite,
    required this.references,
    required this.createStmt,
    required this.writes,
  });

  @override
  String get dbGetterName => DriftSchemaElement.dbFieldName(id.name);
}
