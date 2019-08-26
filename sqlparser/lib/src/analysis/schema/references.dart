part of '../analysis.dart';

/// Mixin for classes which represent a reference.
mixin ReferenceOwner {
  /// The resolved reference, or null if it hasn't been resolved yet.
  Referencable resolved;
}

/// Mixin for classes which can be referenced by a [ReferenceOwner].
mixin Referencable {}

/// A referencable which is still visible in child scopes. This doesn't apply to
/// many things, basically only tables.
///
/// For instance: "SELECT *, 1 AS d, (SELECT id FROM demo WHERE id = out.id) FROM demo AS out;"
/// is a valid sql query when the demo table has an id column. However,
/// "SELECT *, 1 AS d, (SELECT id FROM demo WHERE id = d) FROM demo AS out;" is
/// not, the "d" referencable is not visible for the child select statement.
mixin VisibleToChildren on Referencable {}

/// Class which keeps track of references for tables, columns and functions in a
/// query.
class ReferenceScope {
  final ReferenceScope parent;
  final ReferenceScope root;

  /// Gets the effective root scope. If no [root] scope has been set, this
  /// scope is assumed to be the root scope.
  ReferenceScope get effectiveRoot => root ?? this;

  final Map<String, List<Referencable>> _references = {};

  /// All columns that would be available in this scope. Can be used to resolve
  /// a '*' expression for function calls or result columns
  List<Column> availableColumns;

  ReferenceScope(this.parent, {this.root});

  ReferenceScope createChild() {
    // wonder why we're creating a linked list of reference scopes instead of
    // just passing down a copy of [_references]? In sql, some variables can be
    // used before they're defined, even in child scopes:
    // SELECT *, (SELECT * FROM table2 WHERE id = t1.a) FROM table2 t1
    return ReferenceScope(this, root: effectiveRoot);
  }

  /// Registers something that can be referenced in this and child scopes.
  void register(String identifier, Referencable ref) {
    _references.putIfAbsent(identifier.toUpperCase(), () => []).add(ref);
  }

  /// Resolves to a [Referencable] with the given [name] and of the type [T].
  /// If the reference couldn't be found, null is returned and [orElse] will be
  /// called.
  T resolve<T extends Referencable>(String name, {Function() orElse}) {
    var scope = this;
    var isAtParent = false;
    final upper = name.toUpperCase();

    while (scope != null) {
      if (scope._references.containsKey(upper)) {
        final candidates = scope._references[upper];
        final resolved = candidates.whereType<T>().where((x) {
          return x is VisibleToChildren || !isAtParent;
        });
        if (resolved.isNotEmpty) {
          return resolved.first;
        }
      }

      scope = scope.parent;
      isAtParent = true;
    }

    if (orElse != null) orElse();
    return null; // not found in any parent scope
  }

  /// Returns everything that is in scope and a subtype of [T].
  List<T> allOf<T>() {
    var scope = this;
    var isInCurrentScope = true;
    final collected = <T>[];

    while (scope != null) {
      var foundValues =
          scope._references.values.expand((list) => list).whereType<T>();

      if (!isInCurrentScope) {
        foundValues = foundValues.whereType<VisibleToChildren>().cast();
      }

      collected.addAll(foundValues);
      scope = scope.parent;
      isInCurrentScope = false;
    }
    return collected;
  }
}
