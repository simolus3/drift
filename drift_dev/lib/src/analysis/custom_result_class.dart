import 'results/results.dart';

/// Transforms queries given in [inputs] so that their result sets respect
/// custom result class names specified by the user.
///
/// The "custom result class name" feature can be used to change the name of a
/// result class and to generate the same result class for multiple custom
/// queries.
///
/// Merging result classes of queries will always happen from the point of a
/// database class or dao. This means that incompatible queries can have the
/// same result class name as long as they're not imported into the same moor
/// accessor.
///
/// This feature doesn't work when we apply other simplifications to query, so
/// we report an error if the query returns a single column or if it has a
/// matching table. This restriction might be lifted in the future, but it makes
/// the implementation easier.
Map<SqlSelectQuery, SqlSelectQuery> transformCustomResultClasses(
  Iterable<SqlQuery> inputs,
  void Function(String) reportError,
) {
  // A group of queries sharing a common result class name.
  final queryGroups = <String, List<SqlSelectQuery>>{};

  // Find and group queries with the same result class name
  for (final query in inputs) {
    if (query is! SqlSelectQuery) continue;
    final selectQuery = query;

    // Doesn't use a custom result class, so it's not affected by this
    if (selectQuery.requestedResultClass == null) continue;

    // Alright, the query wants a custom result class, but is it allowed to
    // have one?
    if (selectQuery.resultSet.singleColumn) {
      reportError("The query ${selectQuery.name} can't have a custom name as "
          'it only returns one column.');
      continue;
    }
    if (selectQuery.resultSet.matchingTable != null) {
      reportError("The query ${selectQuery.name} can't have a custom name as "
          'it returns a single table data class.');
      continue;
    }

    if (selectQuery.requestedResultClass != null) {
      queryGroups
          .putIfAbsent(selectQuery.requestedResultClass!, () => [])
          .add(selectQuery);
    }
  }

  final replacements = <SqlSelectQuery, SqlSelectQuery>{};

  for (final group in queryGroups.entries) {
    final resultSetName = group.key;
    final queries = group.value;

    if (!_resultSetsCompatible(queries.map((e) => e.resultSet))) {
      reportError(
        'Could not merge result sets to $resultSetName: The queries '
        'have different columns and types.',
      );
      continue;
    }

    final referenceResult = queries.first.resultSet;
    final dartNames = {
      for (final column in referenceResult.columns)
        column: referenceResult.dartNameFor(column),
    };

    var isFirst = true;
    for (final query in queries) {
      final newResultSet = InferredResultSet(
        null,
        query.resultSet.columns,
        resultClassName: resultSetName,
        nestedResults: query.resultSet.nestedResults,
        // Only generate a result class for the first query in the group
        dontGenerateResultClass: !isFirst,
      );

      // Make sure compatible columns in the two result sets have the same
      // Dart name.
      newResultSet.forceDartNames({
        for (final entry in dartNames.entries)
          newResultSet.columns.singleWhere((e) => e.compatibleTo(entry.key)):
              entry.value,
      });

      final newQuery = query.replaceResultSet(newResultSet);
      replacements[query] = newQuery;
      isFirst = false;
    }
  }

  return replacements;
}

bool _resultSetsCompatible(Iterable<InferredResultSet> resultSets) {
  InferredResultSet? last;

  for (final current in resultSets) {
    if (last != null && !last.isCompatibleTo(current)) {
      return false;
    }

    last = current;
  }
  return true;
}
