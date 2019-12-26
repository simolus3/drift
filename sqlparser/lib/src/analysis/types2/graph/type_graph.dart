part of '../types.dart';

class TypeGraph {
  final Map<Typeable, ResolvedType> _knownTypes = {};

  TypeGraph();

  ResolvedType operator [](Typeable t) {
    return _knownTypes[t];
  }

  void operator []=(Typeable t, ResolvedType type) {
    _knownTypes[t] = type;
  }
}

abstract class TypeRelationship {}
