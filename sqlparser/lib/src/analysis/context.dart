part of 'analysis.dart';

/// Result of parsing and analyzing an sql statement. Contains the AST with
/// resolved references, information about result columns and errors that were
/// reported during analysis.
class AnalysisContext {
  /// All errors that occurred during analysis
  final List<AnalysisError> errors = [];

  /// The root node of the abstract syntax tree
  final AstNode root;

  /// The raw sql statement that was used to construct this [AnalysisContext].
  final String sql;

  /// Additional information about variables in this context, passed from the
  /// outside.
  final AnalyzeStatementOptions stmtOptions;

  /// Options passed to the surrounding engine.
  ///
  /// This contains information about enabled sqlite modules and how to resolve
  /// some functions.
  final EngineOptions engineOptions;

  /// Utilities to read types.
  final SchemaFromCreateTable schemaSupport;

  /// New type resolver with better support for nullability and
  /// complex structures.
  ///
  /// By using [TypeInferenceResults.typeOf], the type of an [Expression],
  /// a [Variable] and [ResultSet.resolvedColumns] may be resolved or inferred.
  late final TypeInferenceResults types2;

  /// Constructs a new analysis context from the AST and the source sql.
  AnalysisContext(this.root, this.sql, this.engineOptions,
      {AnalyzeStatementOptions? stmtOptions, required this.schemaSupport})
      : stmtOptions = stmtOptions ?? const AnalyzeStatementOptions();

  /// Reports an analysis error.
  void reportError(AnalysisError error) {
    errors.add(error);
  }

  /// Obtains the result of any typeable component. See the information at
  /// [types2] on important [Typeable]s.
  ResolveResult typeOf(Typeable t) {
    final type = types2.typeOf(t);
    return type != null ? ResolveResult(type) : const ResolveResult.unknown();
  }

  /// Compares two [AstNode]s by their first position in the query.
  static int compareNodesByOrder(AstNode first, AstNode second) {
    if (first.first == null || second.first == null) {
      return 0; // position not set. should we throw in that case?
    }
    return first.firstPosition.compareTo(second.firstPosition);
  }
}
