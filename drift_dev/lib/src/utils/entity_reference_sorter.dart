import 'dart:collection';

import 'package:collection/collection.dart';

import '../analysis/results/results.dart';

extension SortTopologically on Iterable<DriftElement> {
  /// Topologically sorts a list of [DriftElement]s by their
  /// [DriftElement.references] relationship: Tables appearing first in the
  /// output have to be created first.
  ///
  /// For a reference cycle, the order within the cycle is arbitrary.
  List<DriftElement> sortByReferences() {
    return stronglyConnectedComponents(
      _ReferenceGraph(this),
    ).reversed.flattened.toList();
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

final class _ReferenceGraph
    extends UnmodifiableMapBase<DriftElement, Iterable<DriftElement>> {
  @override
  final Iterable<DriftElement> keys;

  _ReferenceGraph(this.keys);

  @override
  Iterable<DriftElement>? operator [](Object? key) {
    return key is DriftElement ? key.references : null;
  }
}
