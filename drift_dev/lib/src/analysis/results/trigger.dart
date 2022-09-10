import 'package:drift/drift.dart';

import 'element.dart';
import 'table.dart';

class DriftTrigger extends DriftElement {
  @override
  final List<DriftElement> references;

  /// The `CREATE TRIGGER` statement creating this trigger.
  final String createStmt;

  /// Writes performed in the body of this trigger.
  final List<TriggerTableWrite> writes;

  DriftTrigger(
    super.id,
    super.declaration, {
    required this.references,
    required this.createStmt,
    required this.writes,
  });
}

/// Information about a write performed by an `INSERT`, `UPDATE` or `DELETE`
/// statement inside a [DriftTrigger] on another [table].
///
/// This information is used to properly invalidate stream queries at runtime,
/// as triggers can cause changes to additional tables after a direct write to
/// another table.
class TriggerTableWrite {
  final DriftTable table;
  final UpdateKind kind;

  TriggerTableWrite(this.table, this.kind);
}
