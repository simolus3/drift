import 'package:sqlparser/sqlparser.dart';

import '../../driver/state.dart';
import '../../results/results.dart';
import '../intermediate_state.dart';
import 'element_resolver.dart';

class DriftViewResolver extends DriftElementResolver<DiscoveredDriftView> {
  DriftViewResolver(super.file, super.discovered, super.resolver, super.state);

  @override
  Future<DriftView> resolve() async {
    final stmt = discovered.createView;
    final references = await resolveSqlReferences(stmt);
    final engine = newEngineWithTables(references);

    final source = (file.discovery as DiscoveredDriftFile).originalSource;
    final context = engine.analyzeNode(stmt, source);
    reportLints(context);
  }
}
