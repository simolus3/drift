part of '../types.dart';

class TypeGraph {
  final _ResolvedVariables variables = _ResolvedVariables();

  final Map<Typeable, ResolvedType> _knownTypes = {};
  final Map<Typeable, bool> _knownNullability = {};

  final List<TypeRelationship> _relationships = [];

  final Map<Typeable, List<TypeRelationship>> _edges = {};
  final List<DefaultType> _defaultTypes = [];
  final List<CopyEncapsulating> _manyToOne = [];

  TypeGraph();

  ResolvedType operator [](Typeable t) {
    final normalized = variables.normalize(t);

    if (_knownTypes.containsKey(normalized)) {
      return _knownTypes[normalized];
    }

    return null;
  }

  void operator []=(Typeable t, ResolvedType type) {
    final normalized = variables.normalize(t);
    _knownTypes[normalized] = type;

    if (type.nullable != null) {
      // nullability is known
      _knownNullability[normalized] = type.nullable;
    }
  }

  bool knowsType(Typeable t) => _knownTypes.containsKey(variables.normalize(t));

  void addRelation(TypeRelationship relation) {
    _relationships.add(relation);
  }

  void performResolve() {
    _indexRelationships();

    final queue = List.of(_knownTypes.keys);
    while (queue.isNotEmpty) {
      _propagateTypeInfo(queue, queue.removeLast());
    }

    // propagate many-to-one changes
    for (final edge in _manyToOne) {
      if (!knowsType(edge.target)) {
        final fromTypes = edge.from.map((t) => this[t]).where((e) => e != null);
        final encapsulated = _encapsulate(fromTypes);
        if (encapsulated != null) {
          this[edge.target] = encapsulated;
        }
      }
    }

    // apply default types
    for (final applyDefault in _defaultTypes) {
      if (!knowsType(applyDefault.target)) {
        this[applyDefault.target] = applyDefault.defaultType;
      }
    }
  }

  void _propagateTypeInfo(List<Typeable> resolved, Typeable t) {
    if (!_edges.containsKey(t)) return;

    // propagate one-to-one and one-to-many changes
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

  ResolvedType /*?*/ _encapsulate(Iterable<ResolvedType> targets) {
    return targets.fold<ResolvedType>(null, (previous, element) {
      return previous?.union(element) ?? element;
    });
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
        _manyToOne.add(relation);
      } else if (relation is HaveSameType) {
        put(relation.first, relation);
        put(relation.second, relation);
      } else if (relation is DefaultType) {
        _defaultTypes.add(relation);
      } else if (relation is CopyAndCast) {
        put(relation.other, relation);
      } else {
        throw AssertionError('Unknown type relation: $relation');
      }
    }
  }
}

abstract class TypeRelationship {}

/// Keeps track of resolved variable types so that they can be re-used.
/// Different [Variable] instances can refer to the same logical sql variable,
/// so we keep track of them.
class _ResolvedVariables {
  final Map<int, Variable> _referenceForIndex = {};

  Typeable normalize(Typeable t) {
    if (t is! Variable) return t;

    final normalized = t as Variable;
    return _referenceForIndex[normalized.resolvedIndex] ??= normalized;
  }
}

extension on ResolvedType {
  ResolvedType union(ResolvedType other) {
    if (other == this) return this;

    if (other.type == type) {
      return withNullable(nullable || other.nullable);
    }

    // fallback. todo: Support more cases
    return const ResolvedType(type: BasicType.text, nullable: true);
  }
}
