import 'package:drift_dev/src/analysis/resolver/resolver.dart';

import '../../driver/state.dart';
import '../../results/results.dart';
import '../intermediate_state.dart';
import 'element_resolver.dart';

final class DriftIndexResolver
    extends TwoStageElementResolver<DiscoveredDriftIndex> {
  DriftIndexResolver(super.file, super.discovered, super.resolver, super.state);

  @override
  Future<PendingDriftElement> buildPending() async {
    final stmt = discovered.sqlNode;
    final tableRef = ResolvableSqlReference(stmt.on.tableName);
    final references = await resolveTableReferences(
      stmt,
      additional: [tableRef],
    );
    final createEngine = await newEngineWithTables(references);
    final source = (file.discovery as DiscoveredDriftFile).originalSourceSpan;

    return PendingDriftElement(
      element: DriftIndex(
        DriftElementReference(discovered.ownId),
        DriftDeclaration.driftFile(stmt, file.ownUri),
        table: tableRef.resolved?.reference,
        indexedColumns: [],
        unique: stmt.unique,
        createStmt: source.text.substring(
          stmt.firstPosition,
          stmt.lastPosition,
        ),
      ),
      resolve: (dependencies) {
        final engine = createEngine(dependencies);
        final context = engine.analyzeNode(stmt, source);
        reportLints(context, dependencies, references);
      },
    );
  }
}
