import 'package:drift_dev/src/analyzer/options.dart';
import 'package:drift_dev/src/analyzer/runner/file_graph.dart';
import 'package:sqlparser/sqlparser.dart';

import 'model.dart';

class MoorTrigger implements DriftSchemaEntity {
  @override
  final String displayName;

  @override
  final TriggerDeclaration declaration;

  /// The table on which this trigger operates.
  ///
  /// This field can be null in case the table wasn't resolved.
  DriftTable? on;
  List<WrittenMoorTable> bodyUpdates = [];
  List<DriftTable> bodyReferences = [];

  MoorTrigger(this.displayName, this.declaration, this.on);

  factory MoorTrigger.fromMoor(CreateTriggerStatement stmt, FoundFile file) {
    return MoorTrigger(
      stmt.triggerName,
      DriftTriggerDeclaration.fromNodeAndFile(stmt, file),
      null, // must be resolved later
    );
  }

  void clearResolvedReferences() {
    on = null;
    bodyUpdates.clear();
    bodyReferences.clear();
  }

  @override
  Iterable<DriftSchemaEntity> get references =>
      {if (on != null) on!, ...bodyReferences};

  /// The `CREATE TRIGGER` statement that can be used to create this trigger.
  String createSql(DriftOptions options) {
    return declaration.formatSqlIfAvailable(options) ?? declaration.createSql;
  }

  @override
  String get dbGetterName => dbFieldName(displayName);
}
