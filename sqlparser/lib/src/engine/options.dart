import 'package:sqlparser/sqlparser.dart';

class EngineOptions {
  /// Moor extends the sql grammar a bit to support type converters and other
  /// features. Enabling this flag will make this engine parse sql with these
  /// extensions enabled.
  final bool useMoorExtensions;

  /// All [Extension]s that have been enabled in this sql engine.
  final List<Extension> enabledExtensions;

  final List<FunctionHandler> _addedFunctionHandlers = [];

  /// A map from lowercase function names to the associated handler.
  final Map<String, FunctionHandler> addedFunctions = {};

  /// A map from lowercase function names (where the function is a table-valued
  /// function) to the associated handler.
  final Map<String, TableValuedFunctionHandler> addedTableFunctions = {};

  EngineOptions({
    this.useMoorExtensions = false,
    this.enabledExtensions = const [],
  });

  void addFunctionHandler(FunctionHandler handler) {
    _addedFunctionHandlers.add(handler);

    for (final function in handler.functionNames) {
      addedFunctions[function.toLowerCase()] = handler;
    }
  }

  void addTableValuedFunctionHandler(TableValuedFunctionHandler handler) {
    addedTableFunctions[handler.functionName.toLowerCase()] = handler;
  }
}
