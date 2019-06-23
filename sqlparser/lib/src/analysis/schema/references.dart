part of '../analysis.dart';

/// Mixin for classes which represent a reference.
mixin ReferenceOwner {}

/// Mixin for classes which can be referenced by a [ReferenceOwner].
mixin Referencable {}

/// Class which keeps track of references tables, columns and functions in a
/// query.
class ReferenceScope {
  final ReferenceScope parent;
  final Map<String, Referencable> _references = {};

  ReferenceScope(this.parent);

  ReferenceScope createChild() {
    return ReferenceScope(this);
  }

  void register(String identifier, Referencable ref) {
    _references[identifier.toUpperCase()] = ref;
  }

  Referencable resolve(String name) {
    var scope = this;
    final upper = name.toUpperCase();

    while (scope != null) {
      if (scope._references.containsKey(upper)) {
        return scope._references[upper];
      }
      scope = scope.parent;
    }

    return null; // not found in any parent scope
  }
}
