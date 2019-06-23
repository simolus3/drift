part of '../analysis.dart';

/// Mixin for classes which represent a reference.
mixin ReferenceOwner {
  /// The resolved reference, or null if it hasn't been resolved yet.
  Referencable resolved;
}

/// Mixin for classes which can be referenced by a [ReferenceOwner].
mixin Referencable {}

/// Class which keeps track of references tables, columns and functions in a
/// query.
class ReferenceScope {
  final ReferenceScope parent;

  final Map<String, List<Referencable>> _references = {};

  ReferenceScope(this.parent);

  ReferenceScope createChild() {
    return ReferenceScope(this);
  }

  void register(String identifier, Referencable ref) {
    _references.putIfAbsent(identifier.toUpperCase(), () => []).add(ref);
  }

  /// Resolves to a [Referencable] with the given [name] and of the type [T].
  T resolve<T extends Referencable>(String name, {Function() orElse}) {
    var scope = this;
    final upper = name.toUpperCase();

    while (scope != null) {
      if (scope._references.containsKey(upper)) {
        final candidates = scope._references[upper];
        final resolved = candidates.whereType<T>();
        if (resolved.isNotEmpty) {
          return resolved.first;
        }
      }
      scope = scope.parent;
    }

    if (orElse != null) orElse();
    return null; // not found in any parent scope
  }

  /// Returns everything that is in scope and a subtype of [T].
  List<T> allOf<T>() {
    var scope = this;
    final collected = <T>[];

    while (scope != null) {
      collected.addAll(
          scope._references.values.expand((list) => list).whereType<T>());
      scope = scope.parent;
    }
    return collected;
  }
}
