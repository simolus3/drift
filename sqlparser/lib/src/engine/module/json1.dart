import 'package:sqlparser/sqlparser.dart';

class Json1Extension implements Extension {
  const Json1Extension();

  @override
  void register(SqlEngine engine) {
    engine.registerFunctionHandler(const _Json1Functions());
  }
}

class _Json1Functions implements FunctionHandler {
  const _Json1Functions();

  static const Set<String> _returnStrings = {
    'json',
    'json_array',
    'json_insert',
    'json_replace',
    'json_set',
    'json_object',
    'json_patch',
    'json_remove',
    'json_quote',
    'json_group_array',
    'json_group_object',
  };

  @override
  Set<String> get functionNames => const {
        ..._returnStrings,
        'json_type',
        'json_valid',
        'json_extract',
        'json_array_length',
      };

  @override
  ResolveResult inferArgumentType(
      AnalysisContext context, SqlInvocation call, Expression argument) {
    return const ResolveResult.unknown();
  }

  @override
  ResolveResult inferReturnType(AnalysisContext context, SqlInvocation call,
      List<Typeable> expandedArgs) {
    final name = call.name.toLowerCase();

    if (_returnStrings.contains(name)) {
      return const ResolveResult(ResolvedType(type: BasicType.text));
    } else {
      switch (name) {
        case 'json_type':
          return const ResolveResult(
              ResolvedType(type: BasicType.text, nullable: true));
        case 'json_valid':
          return const ResolveResult(ResolvedType.bool());
        case 'json_extract':
          return const ResolveResult.unknown();
        case 'json_array_length':
          return const ResolveResult(ResolvedType(type: BasicType.int));
      }
    }

    throw AssertionError("Can't happen, unknown json1 function");
  }

  @override
  void reportErrors(SqlInvocation call, AnalysisContext context) {}
}
