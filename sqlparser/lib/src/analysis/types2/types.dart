import 'package:sqlparser/sqlparser.dart';

part 'expectation.dart';

part 'graph/relationships.dart';
part 'graph/type_graph.dart';

part 'resolving_visitor.dart';

/// Contains all information associated to a single type inference pass.
class TypeInferenceSession {
  final TypeGraph graph = TypeGraph();
  final AnalysisContext context;
  final ResolvedVariables variables;

  TypeInferenceSession(this.context)
      : variables = ResolvedVariables.fromOptions(context.stmtOptions);

  void markTypeResolved(Typeable t, ResolvedType r) {
    if (t is Variable) {
      variables[t] = r;
    }
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

  void addRelationship(TypeRelationship relationship) {}

  void expectIsPossible(ResolvedType r, TypeExpectation expectation) {}

  void hintNullability(Typeable t, bool nullable) {
    assert(nullable != null);
  }
}

/// Keeps track of resolved variable types so that they can be re-used.
/// Different [Variable] instances can refer to the same logical sql variable,
/// so we keep track of them.
class ResolvedVariables {
  final Map<int, ResolvedType> _knownIndexedTypes;
  final Map<String, ResolvedType> _knownNamedTypes;

  ResolvedVariables()
      : _knownNamedTypes = {},
        _knownIndexedTypes = {};

  ResolvedVariables.fromOptions(AnalyzeStatementOptions options)
      : _knownIndexedTypes = Map.of(options.indexedVariableTypes),
        _knownNamedTypes = Map.of(options.namedVariableTypes);

  /// Obtain the stored type for [v] or null, if unknown.
  ResolvedType operator [](Variable v) {
    if (v is ColonNamedVariable) {
      return _knownNamedTypes[v.name] ?? _knownIndexedTypes[v.resolvedIndex];
    }
    return _knownIndexedTypes[v.resolvedIndex];
  }

  /// Store the resolved [type] for the variable [v].
  void operator []=(Variable v, ResolvedType type) {
    if (v is ColonNamedVariable) {
      _knownNamedTypes[v.name] = type;
    }

    // note that we're storing the index for ColonNamedVariables as well. This
    // is because they have an index! In `SELECT :foo = ?1`, there's only one
    // semantic variable, it's just referred to in different ways.
    if (v.resolvedIndex != null) {
      _knownIndexedTypes[v.resolvedIndex] = type;
    }
  }
}
