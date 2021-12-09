import 'package:sqlparser/src/analysis/analysis.dart';
import 'package:sqlparser/src/ast/ast.dart';
import 'package:sqlparser/src/engine/options.dart';
import 'package:sqlparser/src/engine/sql_engine.dart';

import 'module.dart';

/// A math extension providing functions built into sqlite.
///
/// This is an extension since it's only available when sqlite 3.35 is used
/// together with the `-DSQLITE_ENABLE_MATH_FUNCTIONS` compile-time option.
class BuiltInMathExtension implements Extension {
  const BuiltInMathExtension();

  @override
  void register(SqlEngine engine) {
    if (engine.options.version < SqliteVersion.v3_35) {
      throw StateError('The math extension is only available with '
          'sqlite3 version 35 or later');
    }

    engine.registerFunctionHandler(const _MathFunctions());
  }
}

class _MathFunctions extends FunctionHandler {
  const _MathFunctions();

  static const _constants = {
    'pi',
  };

  static const _unary = {
    'acos',
    'acosh',
    'asin',
    'asinh',
    'atan',
    'atanh',
    'cos',
    'cosh',
    'degrees',
    'exp',
    'ln',
    'log', // note that log is also binary
    'log10',
    'log2',
    'radians',
    'sin',
    'sinh',
    'sqrt',
    'tan',
    'tanh',
  };

  static const _unaryToInt = {
    'ceil',
    'ceiling',
    'floor',
    'trunc',
  };

  static const _binary = {
    'atan2',
    'pow',
    'power',
    'mod',
  };

  @override
  Set<String> get functionNames =>
      const {..._constants, ..._unary, ..._unaryToInt, ..._binary};

  @override
  ResolveResult inferArgumentType(
      AnalysisContext context, SqlInvocation call, Expression argument) {
    return const ResolveResult(ResolvedType(type: BasicType.real));
  }

  @override
  ResolveResult inferReturnType(AnalysisContext context, SqlInvocation call,
      List<Typeable> expandedArgs) {
    if (_unaryToInt.contains(call.name.toLowerCase())) {
      return const ResolveResult(ResolvedType(type: BasicType.int));
    }

    return const ResolveResult(ResolvedType(type: BasicType.real));
  }

  @override
  void reportErrors(SqlInvocation call, AnalysisContext context) {
    final name = call.name.toLowerCase();
    final argumentCount = call.expandParameters().length;

    // log can be called with one or two arguments
    if (name == 'log') {
      if (argumentCount != 1 && argumentCount != 2) {
        context.reportError(AnalysisError(
          relevantNode: call,
          message: 'log requires one or two arguments, got $argumentCount',
          type: AnalysisErrorType.other,
        ));
      }

      return;
    }

    int expectedArgs;
    if (_constants.contains(name)) {
      expectedArgs = 0;
    } else if (_unary.contains(name) || _unaryToInt.contains(name)) {
      expectedArgs = 1;
    } else if (_binary.contains(name)) {
      expectedArgs = 2;
    } else {
      return; // Can't say how many args are required
    }

    if (expectedArgs != argumentCount) {
      context.reportError(AnalysisError(
        relevantNode: call,
        message: '$name requires $expectedArgs arguments, got $argumentCount',
        type: AnalysisErrorType.other,
      ));
    }
  }
}
