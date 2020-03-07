import 'package:sqlparser/sqlparser.dart';

class MoorFfiExtension implements Extension {
  const MoorFfiExtension();

  @override
  void register(SqlEngine engine) {
    engine.registerFunctionHandler(const _MoorFfiFunctions());
  }
}

class _MoorFfiFunctions with ArgumentCountLinter implements FunctionHandler {
  const _MoorFfiFunctions();

  static const Set<String> _unaryFunctions = {
    'sqrt',
    'sin',
    'cos',
    'tan',
    'asin',
    'acos',
    'atan'
  };

  @override
  Set<String> get functionNames => const {'pow', ..._unaryFunctions};

  @override
  int argumentCountFor(String function) {
    if (_unaryFunctions.contains(function)) {
      return 1;
    } else if (function == 'pow') {
      return 2;
    }
    // ignore: avoid_returning_null
    return null;
  }

  @override
  ResolveResult inferArgumentType(
      AnalysisContext context, SqlInvocation call, Expression argument) {
    return const ResolveResult(
        ResolvedType(type: BasicType.real, nullable: false));
  }

  @override
  ResolveResult inferReturnType(AnalysisContext context, SqlInvocation call,
      List<Typeable> expandedArgs) {
    return const ResolveResult(
        ResolvedType(type: BasicType.real, nullable: true));
  }

  @override
  void reportErrors(SqlInvocation call, AnalysisContext context) {
    reportMismatches(call, context);
  }
}
