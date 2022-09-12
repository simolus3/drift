import '../../driver/state.dart';
import '../../results/results.dart';
import '../intermediate_state.dart';
import 'element_resolver.dart';

class DriftQueryResolver
    extends DriftElementResolver<DiscoveredDriftStatement> {
  DriftQueryResolver(super.file, super.discovered, super.resolver, super.state);

  @override
  Future<DefinedSqlQuery> resolve() async {
    final stmt = discovered.sqlNode.statement;
    final references = await resolveSqlReferences(stmt);

    final engine = newEngineWithTables(references);

    final source = (file.discovery as DiscoveredDriftFile).originalSource;
    final context = engine.analyzeNode(stmt, source);
    reportLints(context);

    return DefinedSqlQuery(
      discovered.ownId,
      DriftDeclaration.driftFile(stmt, file.ownUri),
      references: references,
      sql: source.substring(stmt.firstPosition, stmt.lastPosition),
      sqlOffset: stmt.firstPosition,
    );
  }
}
