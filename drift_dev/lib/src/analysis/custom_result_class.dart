import 'dart:collection';

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

    for (final query in queries) {
      final newResultSet =
          _makeResultSetsCompatible(query.resultSet, referenceResult);
      final newQuery = query.replaceResultSet(newResultSet);
      replacements[query] = newQuery;
    }
  }

  return replacements;
}

InferredResultSet _makeResultSetsCompatible(
    InferredResultSet target, InferredResultSet reference) {
  var columns = target.columns;
  Map<ResultColumn, String>? newNames;

  if (target != reference) {
    // Make sure the result sets agree on the Dart column names to use.
    final remainingColumns = LinkedHashSet.of(target.columns);
    newNames = <ResultColumn, String>{};
    columns = [];

    for (final column in reference.columns) {
      var columnFromThisResultSet =
          remainingColumns.firstWhere((e) => e.isCompatibleTo(column));
      remainingColumns.remove(columnFromThisResultSet);

      newNames[columnFromThisResultSet] = reference.dartNameFor(column);

      // For list columns, we need to apply the same unification to the
      // result set of this column as well.
      if (columnFromThisResultSet is NestedResultQuery) {
        final nested = columnFromThisResultSet.query.resultSet;
        if (nested.needsOwnClass) {
          final transformed = _makeResultSetsCompatible(
            nested,
            (column as NestedResultQuery).query.resultSet,
          );

          columnFromThisResultSet = NestedResultQuery(
            from: columnFromThisResultSet.from,
            query: columnFromThisResultSet.query.replaceResultSet(transformed),
          );
        }
      }

      columns.add(columnFromThisResultSet);
    }
  }

  final newResultSet = InferredResultSet(
    null,
    columns,
    resultClassName: reference.resultClassName,
    // Only generate a result class for the first query in the group
    dontGenerateResultClass: target != reference,
  );
  if (newNames != null) {
    newResultSet.forceDartNames(newNames);
  }

  return newResultSet;
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
