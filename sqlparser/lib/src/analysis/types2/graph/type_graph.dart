part of '../types.dart';

class TypeGraph {
  final Map<Typeable, ResolvedType> _knownTypes = {};
  final Map<Typeable, bool> _knownNullability = {};

  final List<TypeRelationship> _relationships = [];

  final Map<Typeable, List<TypeRelationship>> _edges = {};

  TypeGraph();

  ResolvedType operator [](Typeable t) {
    return _knownTypes[t];
  }

  void operator []=(Typeable t, ResolvedType type) {
    _knownTypes[t] = type;

    if (type.nullable != null) {
      // nullability is known
      _knownNullability[t] = type.nullable;
    }
  }

  bool knowsType(Typeable t) => _knownTypes.containsKey(t);

  void addRelation(TypeRelationship relation) {
    _relationships.add(relation);
  }

  void performResolve() {
    _indexRelationships();

    final queue = List.of(_knownTypes.keys);
    while (queue.isNotEmpty) {
      _propagateTypeInfo(queue, queue.removeLast());
    }
  }

  void _propagateTypeInfo(List<Typeable> resolved, Typeable t) {
    if (!_edges.containsKey(t)) return;

    for (final edge in _edges[t]) {
      if (edge is CopyTypeFrom) {
        _copyType(resolved, edge.other, edge.target);
      } else if (edge is HaveSameType) {
        _copyType(resolved, t, edge.getOther(t));
      }
    }
  }

  void _copyType(List<Typeable> resolved, Typeable from, Typeable to) {
    // if the target hasn't been resolved yet, copy the current type and
    // visit the target later
    if (!knowsType(to)) {
      this[to] = this[from];
      resolved.add(to);
    }
  }

  void _indexRelationships() {
    _edges.clear();

    void put(Typeable t, TypeRelationship r) {
      _edges.putIfAbsent(t, () => []).add(r);
    }

    void putAll(Iterable<Typeable> t, TypeRelationship r) {
      for (final element in t) {
        put(element, r);
      }
    }

    for (final relation in _relationships) {
      if (relation is NullableIfSomeOtherIs) {
        putAll(relation.other, relation);
      } else if (relation is CopyTypeFrom) {
        put(relation.other, relation);
      } else if (relation is CopyEncapsulating) {
        putAll(relation.from, relation);
      } else if (relation is HaveSameType) {
        put(relation.first, relation);
        put(relation.second, relation);
      } else if (relation is DefaultType) {
        put(relation.target, relation);
      } else if (relation is CopyAndCast) {
        put(relation.other, relation);
      } else {
        throw AssertionError('Unknown type relation: $relation');
      }
    }
  }
}

abstract class TypeRelationship {}
