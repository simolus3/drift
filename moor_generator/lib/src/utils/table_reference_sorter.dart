import 'package:moor_generator/src/model/specified_table.dart';

/// Topologically sorts a list of [SpecifiedTable]s by their
/// [SpecifiedTable.references] relationship: Tables appearing first in the
/// output have to be created first so the table creation script doesn't crash
/// because of tables not existing.
///
/// If there is a circular reference between [SpecifiedTable]s, an error will
/// be added that contains the name of the tables in question.
List<SpecifiedTable> sortTablesTopologically(Iterable<SpecifiedTable> tables) {
  final run = _SortRun();

  for (final table in tables) {
    if (!run.didVisitAlready(table)) {
      run.previous[table] = null;
      _visit(table, run);
    }
  }

  return run.result;
}

void _visit(SpecifiedTable table, _SortRun run) {
  for (final reference in table.references) {
    if (run.result.contains(reference)) {
      // already handled, nothing to do
    } else if (run.previous.containsKey(reference)) {
      // that's a circular reference, report
      run.throwCircularException(table, reference);
    } else {
      run.previous[reference] = table;
      _visit(reference, run);
    }
  }

  // now that everything this table references is written, add the table itself
  run.result.add(table);
}

class _SortRun {
  final Map<SpecifiedTable, SpecifiedTable> previous = {};
  final List<SpecifiedTable> result = [];

  /// Throws a [CircularReferenceException] because the [last] table depends on
  /// [first], which (transitively) depends on [last] as well. The path in the
  /// thrown exception will go from [first] to [last].
  void throwCircularException(SpecifiedTable last, SpecifiedTable first) {
    final constructedPath = <SpecifiedTable>[];
    for (var current = last; current != first; current = previous[current]) {
      constructedPath.insert(0, current);
    }
    constructedPath.insert(0, first);

    throw CircularReferenceException(constructedPath);
  }

  bool didVisitAlready(SpecifiedTable table) {
    return previous[table] != null || result.contains(table);
  }
}

/// Thrown by [sortTablesTopologically] when the graph formed by
/// [SpecifiedTable]s and their [SpecifiedTable.references] is not acyclic.
class CircularReferenceException implements Exception {
  /// The list of tables forming a circular reference, so that the first table
  /// in this list references the second one and so on. The last table in this
  /// list references the first one.
  final List<SpecifiedTable> affected;

  CircularReferenceException(this.affected);
}
