import 'package:sqlparser/sqlparser.dart';

import '../../options.dart';

class DriftOptionsExtension implements Extension {
  final DriftOptions options;

  DriftOptionsExtension(this.options);

  @override
  void register(SqlEngine engine) {
    final knownFunctions = options.sqliteAnalysisOptions?.knownFunctions;

    if (knownFunctions != null) {
      engine.registerFunctionHandler(_CustomFunctions(knownFunctions));
    }
  }
}

class _CustomFunctions extends FunctionHandler {
  // always has lowercase keys
  final Map<String, KnownSqliteFunction> _functions;

  _CustomFunctions(Map<String, KnownSqliteFunction> functions)
      : _functions = {
          for (final function in functions.entries)
            function.key.toLowerCase(): function.value,
        };

  @override
  late final Set<String> functionNames = _functions.keys.toSet();

  @override
  ResolveResult inferArgumentType(
      AnalysisContext context, SqlInvocation call, Expression argument) {
    final types = _functions[call.name.toLowerCase()]?.argumentTypes;
    if (types == null) {
      return const ResolveResult.unknown();
    }

    final parameters = call.parameters;
    if (parameters is ExprFunctionParameters) {
      final index = parameters.parameters.indexOf(argument);

      if (index < types.length) {
        return ResolveResult(types[index]);
      }
    }

    return const ResolveResult.unknown();
  }

  @override
  ResolveResult inferReturnType(AnalysisContext context, SqlInvocation call,
      List<Typeable> expandedArgs) {
    final type = _functions[call.name.toLowerCase()]?.returnType;

    return type != null ? ResolveResult(type) : const ResolveResult.unknown();
  }
}
