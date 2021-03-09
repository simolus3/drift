//@dart=2.9
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
  Set<String> get functionNames {
    return const {'pow', 'current_time_millis', ..._unaryFunctions};
  }

  @override
  int argumentCountFor(String function) {
    if (_unaryFunctions.contains(function)) {
      return 1;
    } else if (function == 'pow') {
      return 2;
    } else if (function == 'current_time_millis') {
      return 0;
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
    if (call.name == 'current_time_millis') {
      return const ResolveResult(
          ResolvedType(type: BasicType.int, nullable: false));
    }

    return const ResolveResult(
        ResolvedType(type: BasicType.real, nullable: true));
  }

  @override
  void reportErrors(SqlInvocation call, AnalysisContext context) {
    reportMismatches(call, context);
  }
}
