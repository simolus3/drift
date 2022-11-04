import '../analysis/results/results.dart';

extension SortTopologically on Iterable<DriftElement> {
  /// Topologically sorts a list of [DriftElement]s by their
  /// [DriftElement.references] relationship: Tables appearing first in the
  /// output have to be created first so the table creation script doesn't crash
  /// because of tables not existing.
  ///
  /// If there is a circular reference between [DriftTable]s, an error will
  /// be added that contains the name of the tables in question.
  ///
  /// Note that self-references (e.g. a foreign column in a table referencing
  /// itself or another column in the same table) are _not_ included in
  /// [DriftElement.references]. For example, an element created for the
  /// statement `CREATE TABLE pairs (id INTEGER PRIMARY KEY, partner INTEGER
  /// REFERENCES pairs (id))` has no references in the drift element model.
  List<DriftElement> sortTopologically() {
    final run = _SortRun();

    for (final entity in this) {
      if (!run.didVisitAlready(entity)) {
        run.previous[entity] = null;
        _visit(entity, run);
      }
    }

    return run.result;
  }

  /// Sorts elements topologically (like [sortTopologically]).
  ///
  /// Unlike throwing an exception for circular references, the [reportError]
  /// callback is invoked and the elements are returned unchanged.
  List<DriftElement> sortTopologicallyOrElse(
      void Function(String) reportError) {
    try {
      return sortTopologically();
    } on CircularReferenceException catch (e) {
      final joined = e.affected.map((e) => e.id.name).join('->');
      final last = e.affected.last.id.name;
      final message =
          'Illegal circular reference. This is likely a bug in drift, '
          'generated code may be invalid. Invalid cycle from $joined->$last.';
      reportError(message);

      return toList();
    }
  }

  static void _visit(DriftElement entity, _SortRun run) {
    for (final reference in entity.references) {
      assert(reference != entity, 'Illegal self-reference in $entity');

      if (run.result.contains(reference)) {
        // When the target entity has already been added there's nothing to do.
        // We also ignore self-references
      } else if (run.previous.containsKey(reference)) {
        // that's a circular reference, report
        run.throwCircularException(entity, reference);
      } else {
        run.previous[reference] = entity;
        _visit(reference, run);
      }
    }

    // now that everything this table references is written, add the table itself
    run.result.add(entity);
  }
}

class _SortRun {
  /// Keeps track of how entities were discovered.
  ///
  /// If a pair (a, b) exists in [previous], then b was the first entity to
  /// reference a. We also insert (a, null) when iterating over nodes.
  ///
  /// This means that, when an entity references another entity that is present
  /// in `previous.keys`, that's a circular reference.
  final Map<DriftElement, DriftElement?> previous = {};

  /// Entities that have already been fully handled, in topological order.
  ///
  /// If an entity is in [result], all of it's references are in [result] as
  /// well and it's safe to reference it.
  final List<DriftElement> result = [];

  /// Throws a [CircularReferenceException] because the [last] table depends on
  /// [first], which (transitively) depends on [last] as well. The path in the
  /// thrown exception will go from [first] to [last].
  void throwCircularException(DriftElement last, DriftElement first) {
    final constructedPath = <DriftElement>[];
    for (var current = last; current != first; current = previous[current]!) {
      constructedPath.insert(0, current);
    }
    constructedPath.insert(0, first);

    throw CircularReferenceException._(constructedPath);
  }

  bool didVisitAlready(DriftElement table) {
    return previous[table] != null || result.contains(table);
  }
}

/// Thrown by [SortTopologically] when the graph formed by
/// [DriftElement.references] is not acyclic.
class CircularReferenceException implements Exception {
  /// The list of entities forming a circular reference, so that the first
  /// entity in this list references the second one and so on. The last entity
  /// in this list references the first one, thus forming a cycle.
  final List<DriftElement> affected;

  CircularReferenceException._(this.affected);
}
