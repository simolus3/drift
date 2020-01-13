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
  TypeInferenceResults results;

  TypeInferenceSession(this.context, [EngineOptions options])
      : options = options ?? EngineOptions() {
    results = TypeInferenceResults._(this);
  }

  void markTypeResolved(Typeable t, ResolvedType r) {
    graph[t] = r;
  }

  void checkAndResolve(
      Typeable t, ResolvedType r, TypeExpectation expectation) {
    expectIsPossible(r, expectation);
    markTypeResolved(t, r);
  }

  ResolvedType typeOf(Typeable t) {
    return graph[t];
  }

  void addRelationship(TypeRelationship relationship) {
    graph.addRelation(relationship);
  }

  void expectIsPossible(ResolvedType r, TypeExpectation expectation) {}

  void hintNullability(Typeable t, bool nullable) {
    assert(nullable != null);
  }

  void finish() {
    graph.performResolve();
  }
}

/// Apis to view results of a type inference session.
class TypeInferenceResults {
  final TypeInferenceSession session;

  TypeInferenceResults._(this.session);

  /// Finds the resolved type of [t], or `null` if the type of [t] could not
  /// be inferred.
  ResolvedType typeOf(Typeable t) {
    return session.typeOf(t);
  }
}
