import 'dart:math';

import 'package:sqlparser/sqlparser.dart';

part 'expectation.dart';
part 'graph/relationships.dart';
part 'graph/type_graph.dart';
part 'resolving_visitor.dart';

/// Contains all information associated to a single type inference pass.
class TypeInferenceSession {
  final TypeGraph graph = TypeGraph();
  final EngineOptions options;
  final AnalysisContext context;
  TypeInferenceResults? results;

  TypeInferenceSession(this.context, [EngineOptions? options])
      : options = options ?? EngineOptions() {
    results = TypeInferenceResults._(this);
  }

  void _markTypeResolved(Typeable t, ResolvedType r) {
    graph[t] = r;
  }

  void _checkAndResolve(
      Typeable t, ResolvedType r, TypeExpectation expectation) {
    if (expectation is ExactTypeExpectation) {
      final expectedType = expectation.type;

      if (expectedType.hints.isNotEmpty &&
          r.hints.isEmpty &&
          expectedType.type == r.type) {
        r = r.copyWith(hints: expectedType.hints);
      }
    }

    _markTypeResolved(t, r);
  }

  /// Returns the inferred type of [t], or `null` if it couldn't be inferred.
  ResolvedType? typeOf(Typeable t) {
    return graph[t];
  }

  ResolvedType? typeOfVariable(int index) {
    final reference = graph._variables.referenceForIndex(index);

    if (reference != null) {
      return graph._lookupWithoutNormalization(reference);
    } else {
      return null;
    }
  }

  void _addRelation(TypeRelation relationship) {
    graph.addRelation(relationship);
  }

  /// This is not currently implemented.
  void _hintNullability(Typeable t, bool nullable) {
    graph.markNullability(t, nullable);
  }

  /// Asks the underlying [TypeGraph] to propagate known types via known
  /// [TypeRelation]s.
  ///
  /// The [SqlEngine] will call this method when analyzing a statement. There's
  /// no need to call it from user code.
  void _finish() {
    graph.performResolve();
  }
}

/// Apis to view results of a type inference session.
class TypeInferenceResults {
  final TypeInferenceSession session;

  TypeInferenceResults._(this.session);

  /// Finds the resolved type of [t], or `null` if the type of [t] could not
  /// be inferred.
  ResolvedType? typeOf(Typeable t) {
    return session.typeOf(t);
  }
}
