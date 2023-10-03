part of '../types.dart';

class TypeGraph {
  final _ResolvedVariables _variables = _ResolvedVariables();

  final Map<Typeable, ResolvedType> _knownTypes = {};
  final Map<Typeable, bool?> _knownNullability = {};

  final List<TypeRelation> _relations = [];

  final Map<Typeable, List<TypeRelation>> _edges = {};
  final Set<Typeable> _candidateForLaxMultiPropagation = {};
  final List<DefaultType> _defaultTypes = [];

  ResolvedType? operator [](Typeable t) {
    final normalized = _variables.normalize(t);
    return _lookupWithoutNormalization(normalized);
  }

  ResolvedType? _lookupWithoutNormalization(Typeable t) {
    if (_knownTypes.containsKey(t)) {
      final type = _knownTypes[t];
      final nullability = _knownNullability[t];

      if (nullability != null) {
        return type!.withNullable(nullability);
      }
      return type;
    }

    return null;
  }

  void operator []=(Typeable t, ResolvedType type) {
    final normalized = _variables.normalize(t);
    _knownTypes[normalized] = type;

    if (type.nullable != null && !_knownNullability.containsKey(normalized)) {
      // nullability is known
      _knownNullability[normalized] = type.nullable;
    }
  }

  bool knowsType(Typeable t) =>
      _knownTypes.containsKey(_variables.normalize(t));

  bool knowsNullability(Typeable t) {
    final normalized = _variables.normalize(t);
    final knownType = _knownTypes[normalized];

    return (knownType != null && knownType.nullable != null) ||
        _knownNullability.containsKey(normalized);
  }

  void addRelation(TypeRelation relation) {
    _relations.add(relation);
  }

  void markNullability(Typeable t, bool isNullable) {
    _knownNullability[_variables.normalize(t)] = isNullable;
  }

  void performResolve() {
    _indexRelations();

    var queue = List.of(_knownTypes.keys);
    while (queue.isNotEmpty) {
      _propagateTypeInfo(queue, queue.removeLast());
    }

    // propagate many-to-one sources where we don't know each source type, but
    // some of them.
    queue = List.of(_candidateForLaxMultiPropagation);
    while (queue.isNotEmpty) {
      _propagateTypeInfo(queue, queue.removeLast(),
          laxMultiSourcePropagation: true);
    }

    // apply default types
    for (final applyDefault in _defaultTypes) {
      final target = applyDefault.target;

      final type = applyDefault.defaultType;
      if (type != null && !knowsType(target)) {
        this[target] = applyDefault.defaultType!;
      }

      final nullability = applyDefault.isNullable;
      if (nullability != null && _knownNullability.containsKey(target)) {
        markNullability(target, nullability);
      }
    }
  }

  void _propagateTypeInfo(List<Typeable> resolved, Typeable t,
      {bool laxMultiSourcePropagation = false}) {
    if (!_edges.containsKey(t)) return;

    // propagate changes
    for (final edge in _edges[t]!) {
      if (edge is CopyTypeFrom) {
        var type = this[edge.other];
        if (edge.array != null) {
          type = type!.toArray(edge.array);
        }
        if (edge.makeNullable) {
          _knownNullability[edge.target] = true;
        }
        _copyType(resolved, edge.other, edge.target, type);
      } else if (edge is HaveSameType) {
        for (final other in edge.getOthers(t)) {
          _copyType(resolved, t, other);
        }
      } else if (edge is CopyAndCast) {
        _copyType(resolved, t, edge.target,
            this[t]!.cast(edge.cast, edge.dropTypeHint));
      } else if (edge is MultiSourceRelation) {
        // handle many-to-one changes, if all targets have been resolved or
        // lax handling is enabled.
        if (laxMultiSourcePropagation || edge.from.every(knowsType)) {
          _propagateManyToOne(edge, resolved);

          _candidateForLaxMultiPropagation.removeAll(edge.from);
        } else {
          _candidateForLaxMultiPropagation.add(t);
        }
      }
    }
  }

  void _propagateManyToOne(MultiSourceRelation edge, List<Typeable?> resolved) {
    if (edge is CopyEncapsulating) {
      if (!knowsType(edge.target)) {
        final fromTypes = edge.from.map((t) => this[t]).where((e) => e != null);
        var encapsulated = _encapsulate(fromTypes, edge.nullability);

        if (encapsulated != null) {
          if (edge.cast != null) {
            encapsulated = encapsulated.cast(edge.cast!, false);
          }
          this[edge.target] = encapsulated;
          resolved.add(edge.target);
        }
      }
    } else if (edge is NullableIfSomeOtherIs &&
        !_knownNullability.containsKey(edge.target)) {
      final nullable = edge.from
          .map((e) => _knownNullability[e])
          .any((nullable) => nullable == true);

      _knownNullability[edge.target] = nullable;
    }
  }

  void _copyType(List<Typeable> resolved, Typeable from, Typeable to,
      [ResolvedType? type]) {
    // if the target hasn't been resolved yet, copy the current type and
    // visit the target later
    if (!knowsType(to)) {
      this[to] = type ?? this[from]!;
      resolved.add(to);
    }
  }

  ResolvedType? _encapsulate(
      Iterable<ResolvedType?> targets, EncapsulatingNullability nullability) {
    return targets.fold<ResolvedType?>(null, (previous, element) {
      if (previous == null) return element;

      final previousType = previous.type;
      final elementType = element!.type;
      bool nullableTogether;
      switch (nullability) {
        case EncapsulatingNullability.nullIfAny:
          nullableTogether =
              previous.nullable == true || element.nullable == true;
          break;
        case EncapsulatingNullability.nullIfAll:
          nullableTogether =
              previous.nullable == true && element.nullable == true;
          break;
      }

      if (previousType == elementType || elementType == BasicType.nullType) {
        return previous.withNullable(nullableTogether);
      }
      if (previousType == BasicType.nullType) {
        return element.withNullable(nullableTogether);
      }

      bool isIntOrNumeric(BasicType? type) {
        return type == BasicType.int || type == BasicType.real;
      }

      // encapsulate two different numeric types to real
      if (isIntOrNumeric(previousType) && isIntOrNumeric(elementType)) {
        return ResolvedType(type: BasicType.real, nullable: nullableTogether);
      }

      // fallback to text if everything else fails
      return const ResolvedType(type: BasicType.text);
    });
  }

  void _indexRelations() {
    _edges.clear();

    void put(Typeable t, TypeRelation r) {
      _edges.putIfAbsent(t, () => []).add(r);
    }

    void putAll(MultiSourceRelation r) {
      for (final element in r.from) {
        put(element, r);
      }
    }

    for (final relation in _relations) {
      if (relation is NullableIfSomeOtherIs) {
        putAll(relation);
      } else if (relation is CopyTypeFrom) {
        put(relation.other, relation);
      } else if (relation is CopyEncapsulating) {
        putAll(relation);
      } else if (relation is HaveSameType) {
        for (final element in relation.elements) {
          put(element, relation);
        }
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

/// Describes how the type of different [Typeable] instances has an effect on
/// others.
///
/// Note that all logic is handled in the type graph, these are logic-less model
/// classes only.
abstract class TypeRelation {}

/// Relation that only has an effect on one [Typeable] -- namely, [target].
abstract class DirectedRelation implements TypeRelation {
  /// The only [Typeable] effected by this relation.
  Typeable get target;
}

/// Relation where the type of multiple [Typeable] instances must be known.
abstract class MultiSourceRelation implements DirectedRelation {
  List<Typeable> get from;
}

/// Keeps track of resolved variable types so that they can be re-used.
/// Different [Variable] instances can refer to the same logical sql variable,
/// so we keep track of them.
class _ResolvedVariables {
  final Map<int, Variable> _referenceForIndex = {};

  Typeable normalize(Typeable t) {
    if (t is! Variable) return t;

    final normalized = t;
    final index = normalized.resolvedIndex;
    if (index != null) {
      return _referenceForIndex[index] ??= normalized;
    } else {
      return t;
    }
  }

  Typeable? referenceForIndex(int resolvedVariableIndex) {
    return _referenceForIndex[resolvedVariableIndex];
  }
}

extension ResolvedTypeUtils on ResolvedType {
  ResolvedType cast(CastMode mode, bool dropTypeHint) {
    switch (mode) {
      case CastMode.numeric:
      case CastMode.numericPreferInt:
        if (type == BasicType.int || type == BasicType.real) {
          if (dropTypeHint && hints.isNotEmpty) {
            return ResolvedType(
              type: type,
              hints: const [],
              nullable: nullable,
              isArray: isArray,
            );
          } else {
            return this;
          }
        }

        return mode == CastMode.numeric
            ? const ResolvedType(type: BasicType.real)
            : const ResolvedType(type: BasicType.int);
      case CastMode.boolean:
        return const ResolvedType.bool();
    }
  }
}
