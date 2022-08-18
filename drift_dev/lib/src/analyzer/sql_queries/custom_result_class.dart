import 'package:drift_dev/moor_generator.dart';
import 'package:drift_dev/src/analyzer/errors.dart';

/// Transforms queries accessible to the [accessor] so that they use custom
/// result names.
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
class CustomResultClassTransformer {
  final BaseDriftAccessor accessor;

  CustomResultClassTransformer(this.accessor);

  void transform(ErrorSink errors) {
    // For efficient replacing later on
    final indexOfOldQueries = <SqlSelectQuery, int>{};
    final queryGroups = <String, List<SqlSelectQuery>>{};

    // Find and group queries with the same result class name
    var index = 0;
    for (final query in accessor.queries ?? const <Never>[]) {
      final indexOfQuery = index++;

      if (query is! SqlSelectQuery) continue;
      final selectQuery = query;

      // Doesn't use a custom result class, so it's not affected by this
      if (selectQuery.requestedResultClass == null) continue;

      // Alright, the query wants a custom result class, but is it allowed to
      // have one?
      if (selectQuery.resultSet.singleColumn) {
        errors.report(ErrorInDartCode(
          message: "The query ${selectQuery.name} can't have a custom name as "
              'it only returns one column.',
          affectedElement: accessor.declaration?.element,
        ));
        continue;
      }
      if (selectQuery.resultSet.matchingTable != null) {
        errors.report(ErrorInDartCode(
          message: "The query ${selectQuery.name} can't have a custom name as "
              'it returns a single table data class.',
          affectedElement: accessor.declaration?.element,
        ));
        continue;
      }

      // query will be replaced, save index for fast replacement later on
      indexOfOldQueries[selectQuery] = indexOfQuery;
      if (selectQuery.requestedResultClass != null) {
        queryGroups
            .putIfAbsent(selectQuery.requestedResultClass!, () => [])
            .add(selectQuery);
      }
    }

    for (final group in queryGroups.entries) {
      final resultSetName = group.key;
      final queries = group.value;

      if (!_resultSetsCompatible(queries.map((e) => e.resultSet))) {
        errors.report(ErrorInDartCode(
          message: 'Could not merge result sets to $resultSetName: The queries '
              'have different columns and types.',
          affectedElement: accessor.declaration?.element,
        ));
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
        accessor.queries![indexOfOldQueries[query]!] = newQuery;

        isFirst = false;
      }
    }
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
}
