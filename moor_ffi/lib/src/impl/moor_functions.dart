part of 'database.dart';

void _powImpl(Pointer<FunctionContext> ctx, int argCount,
    Pointer<Pointer<SqliteValue>> args) {
  // sqlite will ensure that this is only called with 2 arguments
  final first = args[0].value;
  final second = args[1].value;

  if (first == null || second == null || first is! num || second is! num) {
    ctx.resultNull();
    return;
  }

  final result = pow(first as num, second as num);
  ctx.resultNum(result);
}

/// Base implementation for a sqlite function that takes one numerical argument
/// and returns one numerical argument.
///
/// If [argCount] is not `1` or the single argument is not of a numerical type,
/// [ctx] will complete to null. Otherwise, it will complete to the result of
/// [calculation] with the casted argument.
void _unaryNumFunction(Pointer<FunctionContext> ctx, int argCount,
    Pointer<Pointer<SqliteValue>> args, num Function(num) calculation) {
  // sqlite will ensure that this is only called with one argument
  final value = args[0].value;
  if (value is num) {
    ctx.resultNum(calculation(value));
  } else {
    ctx.resultNull();
  }
}

void _sinImpl(Pointer<FunctionContext> ctx, int argCount,
    Pointer<Pointer<SqliteValue>> args) {
  _unaryNumFunction(ctx, argCount, args, sin);
}

void _cosImpl(Pointer<FunctionContext> ctx, int argCount,
    Pointer<Pointer<SqliteValue>> args) {
  _unaryNumFunction(ctx, argCount, args, cos);
}

void _tanImpl(Pointer<FunctionContext> ctx, int argCount,
    Pointer<Pointer<SqliteValue>> args) {
  _unaryNumFunction(ctx, argCount, args, tan);
}

void _sqrtImpl(Pointer<FunctionContext> ctx, int argCount,
    Pointer<Pointer<SqliteValue>> args) {
  _unaryNumFunction(ctx, argCount, args, sqrt);
}

void _asinImpl(Pointer<FunctionContext> ctx, int argCount,
    Pointer<Pointer<SqliteValue>> args) {
  _unaryNumFunction(ctx, argCount, args, asin);
}

void _acosImpl(Pointer<FunctionContext> ctx, int argCount,
    Pointer<Pointer<SqliteValue>> args) {
  _unaryNumFunction(ctx, argCount, args, acos);
}

void _atanImpl(Pointer<FunctionContext> ctx, int argCount,
    Pointer<Pointer<SqliteValue>> args) {
  _unaryNumFunction(ctx, argCount, args, atan);
}

void _registerOn(Database db) {
  final powImplPointer =
      Pointer.fromFunction<sqlite3_function_handler>(_powImpl);
  db.createFunction('power', 2, powImplPointer, isDeterministic: true);
  db.createFunction('pow', 2, powImplPointer, isDeterministic: true);

  db.createFunction('sqrt', 1, Pointer.fromFunction(_sqrtImpl),
      isDeterministic: true);

  db.createFunction('sin', 1, Pointer.fromFunction(_sinImpl),
      isDeterministic: true);
  db.createFunction('cos', 1, Pointer.fromFunction(_cosImpl),
      isDeterministic: true);
  db.createFunction('tan', 1, Pointer.fromFunction(_tanImpl),
      isDeterministic: true);
  db.createFunction('asin', 1, Pointer.fromFunction(_asinImpl),
      isDeterministic: true);
  db.createFunction('acos', 1, Pointer.fromFunction(_acosImpl),
      isDeterministic: true);
  db.createFunction('atan', 1, Pointer.fromFunction(_atanImpl),
      isDeterministic: true);
}
