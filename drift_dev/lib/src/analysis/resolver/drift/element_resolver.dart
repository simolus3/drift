import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/utils/find_referenced_tables.dart';

import '../../driver/error.dart';
import '../../driver/state.dart';
import '../../results/results.dart';
import '../resolver.dart';
import 'sqlparser/drift_lints.dart';

abstract class DriftElementResolver<T extends DiscoveredElement>
    extends LocalElementResolver<T> {
  DriftElementResolver(
      super.file, super.discovered, super.resolver, super.state);

  void reportLints(AnalysisContext context) {
    context.errors.forEach(reportLint);

    // Also run drift-specific lints on the query
    final linter = DriftSqlLinter(context, this)..collectLints();
    linter.sqlParserErrors.forEach(reportLint);
  }

  SqlEngine newEngineWithTables(Iterable<DriftElement> references) {
    final driver = resolver.driver;
    final engine = driver.newSqlEngine();

    for (final reference in references) {
      if (reference is DriftTable) {
        engine.registerTable(driver.typeMapping.asSqlParserTable(reference));
      }
    }

    return engine;
  }

  Future<List<DriftElement>> resolveSqlReferences(AstNode stmt) async {
    final references =
        resolver.driver.newSqlEngine().findReferencedSchemaTables(stmt);
    final found = <DriftElement>[];

    for (final table in references) {
      final result = await resolver.resolveReference(discovered.ownId, table);

      if (result is ResolvedReferenceFound) {
        found.add(result.element);
      } else {
        final referenceNode = stmt.allDescendants
            .firstWhere((e) => e is TableReference && e.tableName == table);

        reportErrorForUnresolvedReference(result,
            (msg) => DriftAnalysisError.inDriftFile(referenceNode, msg));
      }
    }

    return found;
  }

  void reportLint(AnalysisError parserError) {
    reportError(
        DriftAnalysisError(parserError.span, parserError.message ?? ''));
  }
}
