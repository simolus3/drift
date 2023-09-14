import 'package:sqlparser/sqlparser.dart';

import '../../driver/state.dart';
import '../../results/results.dart';
import '../intermediate_state.dart';
import 'element_resolver.dart';

class DriftIndexResolver extends DriftElementResolver<DiscoveredDriftIndex> {
  DriftIndexResolver(super.file, super.discovered, super.resolver, super.state);

  @override
  Future<DriftIndex> resolve() async {
    final stmt = discovered.sqlNode;
    final references = await resolveTableReferences(stmt);
    final engine = newEngineWithTables(references);

    final source = (file.discovery as DiscoveredDriftFile).originalSource;
    final context = engine.analyzeNode(stmt, source);
    reportLints(context, references);

    final onTable = stmt.on.resolved;
    DriftTable? target;
    List<DriftColumn> indexedColumns = [];

    if (onTable is Table) {
      target = references
          .whereType<DriftTable>()
          .firstWhere((e) => e.schemaName == onTable.name);

      for (final indexedColumn in stmt.columns) {
        final name = (indexedColumn.expression as Reference).columnName;
        final tableColumn = target.columnBySqlName[name];

        if (tableColumn != null) {
          indexedColumns.add(tableColumn);
        }
      }
    }

    return DriftIndex(
      discovered.ownId,
      DriftDeclaration.driftFile(stmt, file.ownUri),
      table: target,
      indexedColumns: indexedColumns,
      unique: stmt.unique,
      createStmt: source.substring(stmt.firstPosition, stmt.lastPosition),
    );
  }
}
