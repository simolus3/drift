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

  /// Utilities to read types.
  final SchemaFromCreateTable schemaSupport;

  /// A resolver that can be used to obtain the type of a [Typeable]. This
  /// mostly applies to [Expression]s, [Reference]s, [Variable]s and
  /// [ResultSet.resolvedColumns] of a select statement.
  /* late final */ TypeResolver types;

  /// Experimental new type resolver with better support for nullability and
  /// complex structures.
  ///
  /// By using [TypeInferenceResults.typeOf], the type of an [Expression],
  /// a [Variable] and [ResultSet.resolvedColumns] may be resolved or inferred.
  ///
  /// This field is null when experimental type inference is disabled.
  ///
  /// Please note that types2 is experimental at the moment. Changes to how
  /// [types] resolves types are considered breaking and are handled
  /// accordingly. [types2] may change results in any update.
  @experimental
  TypeInferenceResults types2;

  /// Constructs a new analysis context from the AST and the source sql.
  AnalysisContext(this.root, this.sql, EngineOptions options,
      {AnalyzeStatementOptions stmtOptions, this.schemaSupport})
      : stmtOptions = stmtOptions ?? const AnalyzeStatementOptions() {
    if (!options.enableExperimentalTypeInference) {
      types = TypeResolver(this, options);
    }
  }

  /// Reports an analysis error.
  void reportError(AnalysisError error) {
    errors.add(error);
  }

  /// Obtains the result of any typeable component. See the information at
  /// [types] on important [Typeable]s.
  ResolveResult typeOf(Typeable t) => types.resolveOrInfer(t);

  /// Compares two [AstNode]s by their first position in the query.
  static int compareNodesByOrder(AstNode first, AstNode second) {
    if (first.first == null || second.first == null) {
      return 0; // position not set. should we throw in that case?
    }
    return first.firstPosition.compareTo(second.firstPosition);
  }
}
