import 'package:collection/collection.dart';
import 'package:drift/drift.dart' as drift;
import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/utils/find_referenced_tables.dart';

import '../../driver/state.dart';
import '../../results/results.dart';
import '../intermediate_state.dart';
import 'element_resolver.dart';

class DriftTriggerResolver
    extends DriftElementResolver<DiscoveredDriftTrigger> {
  DriftTriggerResolver(
      super.file, super.discovered, super.resolver, super.state);

  @override
  Future<DriftTrigger> resolve() async {
    final stmt = discovered.sqlNode;
    final references = await resolveTableReferences(stmt);
    final engine = await newEngineWithTables(references);

    final source = (file.discovery as DiscoveredDriftFile).originalSource;
    final context = engine.analyzeNode(stmt, source);
    reportLints(context, references);

    WrittenDriftTable? mapWrite(TableWrite parserWrite) {
      drift.UpdateKind kind;
      switch (parserWrite.kind) {
        case UpdateKind.insert:
          kind = drift.UpdateKind.insert;
          break;
        case UpdateKind.update:
          kind = drift.UpdateKind.update;
          break;
        case UpdateKind.delete:
          kind = drift.UpdateKind.delete;
          break;
      }

      final table = references
          .whereType<DriftTable>()
          .firstWhereOrNull((e) => e.schemaName == parserWrite.table.name);
      if (table != null) {
        return WrittenDriftTable(table, kind);
      } else {
        return null;
      }
    }

    drift.UpdateKind onWrite;

    if (stmt.target is DeleteTarget) {
      onWrite = drift.UpdateKind.delete;
    } else if (stmt.target is UpdateTarget) {
      onWrite = drift.UpdateKind.update;
    } else {
      onWrite = drift.UpdateKind.insert;
    }

    return DriftTrigger(
      discovered.ownId,
      DriftDeclaration.driftFile(stmt, file.ownUri),
      on: findInResolved(references, stmt.onTable.tableName) as DriftTable?,
      onWrite: onWrite,
      references: references,
      createStmt: source.substring(stmt.firstPosition, stmt.lastPosition),
      writes: findWrittenTables(stmt)
          .map(mapWrite)
          .whereType<WrittenDriftTable>()
          .toList(),
    );
  }
}
