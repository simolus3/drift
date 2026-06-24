import 'package:collection/collection.dart';
import 'package:drift/drift.dart' as drift;
import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/utils/find_referenced_tables.dart';

import '../../driver/state.dart';
import '../../results/results.dart';
import '../intermediate_state.dart';
import '../resolver.dart';
import 'element_resolver.dart';

class DriftTriggerResolver
    extends DriftElementResolver<DiscoveredDriftTrigger> {
  DriftTriggerResolver(
    super.file,
    super.discovered,
    super.resolver,
    super.state,
  );

  @override
  Future<PendingDriftElement> buildPending() async {
    final stmt = discovered.sqlNode;
    final on = ResolvableSqlReference(stmt.onTable.tableName);
    final references = await resolveTableReferences(stmt, additional: [on]);
    final engineFactory = await newEngineWithTables(references);
    final writes = <WrittenDriftTable>[];

    final trigger = DriftTrigger(
      DriftElementReference(discovered.ownId),
      DriftDeclaration.driftFile(stmt, file.ownUri),
      on: on.resolved?.reference,
      onWrite: drift.UpdateKind.delete, // Set in resolve
      references: resolver.references,
      createStmt: stmt.span!.text,
      writes: writes,
    );

    return PendingDriftElement(
      element: trigger,
      resolve: (deps) {
        final engine = engineFactory(deps);
        final source =
            (file.discovery as DiscoveredDriftFile).originalSourceSpan;
        final context = engine.analyzeNode(stmt, source);
        reportLints(context, deps, references);

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

          final table = references.whereType<DriftTable>().firstWhereOrNull(
            (e) => e.schemaName == parserWrite.table.name,
          );
          if (table != null) {
            return WrittenDriftTable(table, kind);
          } else {
            return null;
          }
        }

        for (final table in findWrittenTables(stmt)) {
          if (mapWrite(table) case final written?) {
            writes.add(written);
          }
        }

        if (stmt.target is DeleteTarget) {
          trigger.onWrite = drift.UpdateKind.delete;
        } else if (stmt.target is UpdateTarget) {
          trigger.onWrite = drift.UpdateKind.update;
        } else {
          trigger.onWrite = drift.UpdateKind.insert;
        }
      },
    );
  }
}
