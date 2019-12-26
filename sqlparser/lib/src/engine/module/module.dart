import 'package:sqlparser/sqlparser.dart';

/// Interface for sqlite extensions providing additional functions or module.
///
/// Extension support in the sqlparser package is still experimental, and only
/// supports modules for `CREATE VIRTUAL TABLE` statements at the moment.
abstract class Extension {
  void register(SqlEngine engine);
}

/// Function handlers can be implemented by an [Extension] to add type analysis
/// for additional function.
abstract class FunctionHandler {
  /// The set of function names supported by this handler.
  ///
  /// The returned set shouldn't change over time.
  Set<String> get functionNames;

  /// Resolve the return type of a function invocation.
  ///
  /// The [call] refers to a function declared in [functionNames]. To provide
  /// further analysis, the [resolver] may be used. To support function calls
  /// with a [StarFunctionParameter], [expandedArgs] contains the expanded
  /// arguments from a `function(*)` call.
  ///
  /// If resolving to a type isn't possible, implementations should return
  /// [ResolveResult.unknown].
  ResolveResult inferReturnType(
      TypeResolver resolver, SqlInvocation call, List<Typeable> expandedArgs);

  /// Resolve the type of an argument used in a function invocation.
  ///
  /// The [call] refers to a function declared in [functionNames]. To provide
  /// further analysis, the [resolver] may be used. This method should return
  /// the inferred type of [argument], which is an argument passed to the
  /// [call].
  ///
  /// If resolving to a type isn't possible, implementations should return
  /// [ResolveResult.unknown].
  ResolveResult inferArgumentType(
      TypeResolver resolver, SqlInvocation call, Expression argument);

  /// Can optionally be used by implementations to provide [AnalysisError]s
  /// from the [call].
  ///
  /// Errors should be reported via [AnalysisContext.reportError].
  void reportErrors(SqlInvocation call, AnalysisContext context) {}
}

/// An sqlite module, which can be used in a `CREATE VIRTUAL TABLE` statement
/// to find providers.
abstract class Module implements Referencable, VisibleToChildren {
  /// The name of this module, which is referenced by the `USING` clause in a
  /// `CREATE VIRTUAL TABLE` statement.
  final String name;

  Module(this.name);

  /// Extracts the table structure from a `CREATE VIRTUAL TABLE` statement that
  /// refers to this module. The module is responsible for setting
  /// [Table.definition].
  Table parseTable(CreateVirtualTableStatement stmt);
}
