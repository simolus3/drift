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

    if (onTable is Table) {
      target = references
          .whereType<DriftTable>()
          .firstWhere((e) => e.schemaName == onTable.name);
    }

    return DriftIndex(
      discovered.ownId,
      DriftDeclaration.driftFile(stmt, file.ownUri),
      table: target,
      indexedColumns: [],
      unique: stmt.unique,
      createStmt: source.substring(stmt.firstPosition, stmt.lastPosition),
    );
  }
}
