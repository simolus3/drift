import '../../driver/state.dart';
import '../../results/results.dart';
import '../intermediate_state.dart';
import '../resolver.dart';
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
    final index = DriftIndex(
      resolver.ownElementReference,
      DriftDeclaration.driftFile(stmt, file.ownUri),
      table: null,
      indexedColumns: [],
      unique: stmt.unique,
      createStmt: source.text.substring(stmt.firstPosition, stmt.lastPosition),
    );

    return PendingDriftElement(
      element: index,
      resolve: (dependencies) {
        index.table =
            dependencies.resolveNullable(tableRef.resolved) as DriftTable?;

        final engine = createEngine(dependencies);
        final context = engine.analyzeNode(stmt, source);
        reportLints(context, dependencies, references);
      },
    );
  }
}
