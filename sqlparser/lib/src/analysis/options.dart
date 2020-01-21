part of 'analysis.dart';

/// Options to analyze a sql statement. This can be used if the type of a
/// variable is known from the outside.
class AnalyzeStatementOptions {
  final Map<int, ResolvedType> indexedVariableTypes;
  final Map<String, ResolvedType> namedVariableTypes;

  const AnalyzeStatementOptions({
    this.indexedVariableTypes = const {},
    this.namedVariableTypes = const {},
  });

  /// Looks up the defined type for that variable.
  ///
  /// Returns null if the type of that variable hasn't been set.
  ResolvedType specifiedTypeOf(Variable variable) {
    // colon-named variables also have an index!
    if (variable.resolvedIndex != null &&
        indexedVariableTypes.containsKey(variable.resolvedIndex)) {
      return indexedVariableTypes[variable.resolvedIndex];
    } else if (variable is ColonNamedVariable) {
      return namedVariableTypes[variable.name];
    }
    return null;
  }
}
