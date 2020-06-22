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

void _regexpImpl(Pointer<FunctionContext> ctx, int argCount,
    Pointer<Pointer<SqliteValue>> args) {
  var multiLine = false;
  var caseSensitive = true;
  var unicode = false;
  var dotAll = false;

  if (argCount < 2 || argCount > 3) {
    ctx.resultError('Expected two or three arguments to regexp');
    return;
  }

  final firstParam = args[0].value;
  final secondParam = args[1].value;

  if (firstParam == null || secondParam == null) {
    ctx.resultNull();
    return;
  }
  if (firstParam is! String || secondParam is! String) {
    ctx.resultError('Expected two strings as parameters to regexp');
    return;
  }

  if (argCount == 3) {
    // In the variant with three arguments, the last (int) arg can be used to
    // enable regex flags. See the regexp() extension in moor for details.
    final value = args[2].value;
    if (value is int) {
      multiLine = (value & 1) == 1;
      caseSensitive = (value & 2) != 2;
      unicode = (value & 4) == 4;
      dotAll = (value & 8) == 8;
    }
  }

  RegExp regex;
  try {
    regex = RegExp(
      firstParam as String,
      multiLine: multiLine,
      caseSensitive: caseSensitive,
      unicode: unicode,
      dotAll: dotAll,
    );
  } on FormatException catch (e) {
    ctx.resultError('Invalid regex: $e');
    return;
  }

  ctx.resultBool(regex.hasMatch(secondParam as String));
}

void _containsImpl(Pointer<FunctionContext> ctx, int argCount,
    Pointer<Pointer<SqliteValue>> args) {
  if (argCount < 2 || argCount > 3) {
    ctx.resultError('Expected 2 or 3 arguments to moor_contains');
    return;
  }

  final first = args[0].value;
  final second = args[1].value;

  if (first is! String || second is! String) {
    ctx.resultError('First two args must be strings');
    return;
  }

  final caseSensitive = argCount == 3 && args[2].value == 1;

  final firstAsString = first as String;
  final secondAsString = second as String;

  final result = caseSensitive
      ? firstAsString.contains(secondAsString)
      : firstAsString.toLowerCase().contains(secondAsString.toLowerCase());

  ctx.resultInt(result ? 1 : 0);
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

  db.createFunction('regexp', 2, Pointer.fromFunction(_regexpImpl),
      isDeterministic: true);
  // Third argument can be used to set flags (like multiline, case sensitivity,
  // etc.)
  db.createFunction('regexp_moor_ffi', 3, Pointer.fromFunction(_regexpImpl));

  final containsImplPointer =
      Pointer.fromFunction<sqlite3_function_handler>(_containsImpl);
  db.createFunction('moor_contains', 2, containsImplPointer,
      isDeterministic: true);
  db.createFunction('moor_contains', 3, containsImplPointer,
      isDeterministic: true);
}
