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
  /// Constant default constructor to allow const implementations.
  const FunctionHandler();

  /// The set of function names supported by this handler.
  ///
  /// The returned set shouldn't change over time.
  Set<String> get functionNames;

  /// Resolve the return type of a function invocation.
  ///
  /// The [call] refers to a function declared in [functionNames]. To provide
  /// further analysis, the [context] may be used. To support function calls
  /// with a [StarFunctionParameter], [expandedArgs] contains the expanded
  /// arguments from a `function(*)` call.
  ///
  /// If resolving to a type isn't possible, implementations should return
  /// [ResolveResult.unknown].
  ResolveResult inferReturnType(
      AnalysisContext context, SqlInvocation call, List<Typeable> expandedArgs);

  /// Resolve the type of an argument used in a function invocation.
  ///
  /// The [call] refers to a function declared in [functionNames]. To provide
  /// further analysis, the [context] may be used. This method should return
  /// the inferred type of [argument], which is an argument passed to the
  /// [call].
  ///
  /// If resolving to a type isn't possible, implementations should return
  /// [ResolveResult.unknown].
  ResolveResult inferArgumentType(
      AnalysisContext context, SqlInvocation call, Expression argument);

  /// Can optionally be used by implementations to provide [AnalysisError]s
  /// from the [call].
  ///
  /// Errors should be reported via [AnalysisContext.reportError].
  void reportErrors(SqlInvocation call, AnalysisContext context) {}
}

/// Should be mixed on on [FunctionHandler] implementations only.
mixin ArgumentCountLinter {
  /// Returns the amount of arguments expected for [function] (lowercase).
  ///
  /// If the function is unknown, or if the result would be ambiguous, returns
  /// null.
  int? argumentCountFor(String function);

  int actualArgumentCount(SqlInvocation call) {
    return call.expandParameters().length;
  }

  void reportMismatches(SqlInvocation call, AnalysisContext context) {
    final expectedArgs = argumentCountFor(call.name.toLowerCase());

    if (expectedArgs != null) {
      final actualArgs = actualArgumentCount(call);

      if (actualArgs != expectedArgs) {
        reportArgumentCountMismatch(call, context, expectedArgs, actualArgs);
      }
    }
  }

  void reportArgumentCountMismatch(
      SqlInvocation call, AnalysisContext context, int? expected, int actual) {
    context.reportError(AnalysisError(
      relevantNode: call,
      message: '${call.name} expects $expected arguments, '
          'got $actual.',
      type: AnalysisErrorType.other,
    ));
  }
}

/// Interface for a handler which can resolve the result set of a table-valued
/// function.
abstract class TableValuedFunctionHandler {
  /// The name of the table-valued function implemented by this handler.
  String get functionName;

  /// Resolve the result set of a table-valued function.
  ///
  /// Should return null when the result set can't be resolved.
  ///
  /// See also:
  ///  - https://www.sqlite.org/vtab.html#tabfunc2
  ResultSet resolveTableValued(
      AnalysisContext context, TableValuedFunction call);
}

/// An sqlite module, which can be used in a `CREATE VIRTUAL TABLE` statement
/// to find providers.
abstract class Module implements Referencable {
  /// The name of this module, which is referenced by the `USING` clause in a
  /// `CREATE VIRTUAL TABLE` statement.
  final String name;

  Module(this.name);

  /// Extracts the table structure from a `CREATE VIRTUAL TABLE` statement that
  /// refers to this module. The module is responsible for setting
  /// [Table.definition].
  Table parseTable(CreateVirtualTableStatement stmt);

  @override
  bool get visibleToChildren => true;
}
