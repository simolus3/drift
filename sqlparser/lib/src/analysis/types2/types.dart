import 'package:sqlparser/sqlparser.dart';

part 'expectation.dart';

part 'graph/relationships.dart';
part 'graph/type_graph.dart';

part 'resolving_visitor.dart';

/// Contains all information associated to a single type inference pass.
class TypeInferenceSession {
  final TypeGraph graph = TypeGraph();
  final AnalysisContext context;

  TypeInferenceSession(this.context);

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
