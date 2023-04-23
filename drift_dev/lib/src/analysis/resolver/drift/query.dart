import 'package:analyzer/dart/element/type.dart';
import 'package:sqlparser/sqlparser.dart';

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

    final source = (file.discovery as DiscoveredDriftFile).originalSource;

    final isCreate =
        discovered.sqlNode.identifier is SpecialStatementIdentifier;

    // Note: We don't analyze the query here, that happens in
    // `file_analysis.dart` after elements have been resolved.

    String? resultClassName;
    RequestedQueryResultType? existingType;

    final as = discovered.sqlNode.as;
    if (as != null) {
      if (as.useExistingDartClass) {
        final type =
            await findDartTypeOrReportError(as.overriddenDataClassName, as);
        if (type != null) {
          existingType = RequestedQueryResultType(type, as.constructorName);
        }
      } else {
        resultClassName = as.overriddenDataClassName;
      }
    }

    final resolvedDartTypes = <String, DartType>{};
    for (final entry in references.dartTypes.entries) {
      final dartType = await findDartTypeOrReportError(entry.value, entry.key);
      if (dartType != null) {
        resolvedDartTypes[entry.value] = dartType;
      }
    }

    return DefinedSqlQuery(
      discovered.ownId,
      DriftDeclaration.driftFile(stmt, file.ownUri),
      references: references.referencedElements,
      sql: source.substring(stmt.firstPosition, stmt.lastPosition),
      sqlOffset: stmt.firstPosition,
      mode: isCreate ? QueryMode.atCreate : QueryMode.regular,
      resultClassName: resultClassName,
      existingDartType: existingType,
      dartTypes: resolvedDartTypes,
      dartTokens: references.dartExpressions,
    );
  }
}
