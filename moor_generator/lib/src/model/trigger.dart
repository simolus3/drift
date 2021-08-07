import 'package:moor_generator/src/analyzer/options.dart';
import 'package:moor_generator/src/analyzer/runner/file_graph.dart';
import 'package:sqlparser/sqlparser.dart';

import 'model.dart';

class MoorTrigger implements MoorSchemaEntity {
  @override
  final String displayName;

  @override
  final TriggerDeclaration declaration;

  /// The table on which this trigger operates.
  ///
  /// This field can be null in case the table wasn't resolved.
  MoorTable? on;
  List<WrittenMoorTable> bodyUpdates = [];
  List<MoorTable> bodyReferences = [];

  MoorTrigger(this.displayName, this.declaration, this.on);

  factory MoorTrigger.fromMoor(CreateTriggerStatement stmt, FoundFile file) {
    return MoorTrigger(
      stmt.triggerName,
      MoorTriggerDeclaration.fromNodeAndFile(stmt, file),
      null, // must be resolved later
    );
  }

  void clearResolvedReferences() {
    on = null;
    bodyUpdates.clear();
    bodyReferences.clear();
  }

  @override
  Iterable<MoorSchemaEntity> get references =>
      {if (on != null) on!, ...bodyReferences};

  /// The `CREATE TRIGGER` statement that can be used to create this trigger.
  String createSql(MoorOptions options) {
    return declaration.formatSqlIfAvailable(options) ?? declaration.createSql;
  }

  @override
  String get dbGetterName => dbFieldName(displayName);
}
