import 'package:moor_generator/moor_generator.dart';

/// Topologically sorts a list of [MoorSchemaEntity]s by their
/// [MoorSchemaEntity.references] relationship: Tables appearing first in the
/// output have to be created first so the table creation script doesn't crash
/// because of tables not existing.
///
/// If there is a circular reference between [MoorTable]s, an error will
/// be added that contains the name of the tables in question.
List<MoorSchemaEntity> sortEntitiesTopologically(
    Iterable<MoorSchemaEntity> tables) {
  final run = _SortRun();

  for (final entity in tables) {
    if (!run.didVisitAlready(entity)) {
      run.previous[entity] = null;
      _visit(entity, run);
    }
  }

  return run.result;
}

void _visit(MoorSchemaEntity table, _SortRun run) {
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
  final Map<MoorSchemaEntity, MoorSchemaEntity> previous = {};
  final List<MoorSchemaEntity> result = [];

  /// Throws a [CircularReferenceException] because the [last] table depends on
  /// [first], which (transitively) depends on [last] as well. The path in the
  /// thrown exception will go from [first] to [last].
  void throwCircularException(MoorSchemaEntity last, MoorSchemaEntity first) {
    final constructedPath = <MoorSchemaEntity>[];
    for (var current = last; current != first; current = previous[current]) {
      constructedPath.insert(0, current);
    }
    constructedPath.insert(0, first);

    throw CircularReferenceException._(constructedPath);
  }

  bool didVisitAlready(MoorSchemaEntity table) {
    return previous[table] != null || result.contains(table);
  }
}

/// Thrown by [sortEntitiesTopologically] when the graph formed by
/// [MoorSchemaEntity.references] is not acyclic.
class CircularReferenceException implements Exception {
  /// The list of entities forming a circular reference, so that the first
  /// entity in this list references the second one and so on. The last entity
  /// in this list references the first one, thus forming a cycle.
  final List<MoorSchemaEntity> affected;

  CircularReferenceException._(this.affected);
}
