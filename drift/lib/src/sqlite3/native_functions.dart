import 'dart:math';

import 'package:sqlite3/common.dart';

// ignore_for_file: avoid_returning_null, only_throw_errors

/// Extension to register moor-specific sql functions.
extension EnableNativeFunctions on CommonDatabase {
  /// Enables moor-specific sql functions on this database.
  void useNativeFunctions() {
    createFunction(
      functionName: 'power',
      deterministic: true,
      argumentCount: const AllowedArgumentCount(2),
      function: _pow,
    );
    createFunction(
      functionName: 'pow',
      deterministic: true,
      argumentCount: const AllowedArgumentCount(2),
      function: _pow,
    );

    createFunction(
      functionName: 'sqrt',
      deterministic: true,
      argumentCount: const AllowedArgumentCount(1),
      function: _unaryNumFunction(sqrt),
    );
    createFunction(
      functionName: 'sin',
      deterministic: true,
      argumentCount: const AllowedArgumentCount(1),
      function: _unaryNumFunction(sin),
    );
    createFunction(
      functionName: 'cos',
      deterministic: true,
      argumentCount: const AllowedArgumentCount(1),
      function: _unaryNumFunction(cos),
    );
    createFunction(
      functionName: 'tan',
      deterministic: true,
      argumentCount: const AllowedArgumentCount(1),
      function: _unaryNumFunction(tan),
    );
    createFunction(
      functionName: 'asin',
      deterministic: true,
      argumentCount: const AllowedArgumentCount(1),
      function: _unaryNumFunction(asin),
    );
    createFunction(
      functionName: 'acos',
      deterministic: true,
      argumentCount: const AllowedArgumentCount(1),
      function: _unaryNumFunction(acos),
    );
    createFunction(
      functionName: 'atan',
      deterministic: true,
      argumentCount: const AllowedArgumentCount(1),
      function: _unaryNumFunction(atan),
    );

    createFunction(
      functionName: 'regexp',
      deterministic: true,
      argumentCount: const AllowedArgumentCount(2),
      function: _regexpImpl,
    );
    // Third argument can be used to set flags (like multiline, case
    // sensitivity, etc.)
    createFunction(
      functionName: 'regexp_moor_ffi',
      deterministic: true,
      argumentCount: const AllowedArgumentCount(3),
      function: _regexpImpl,
    );

    createFunction(
      functionName: 'moor_contains',
      deterministic: true,
      argumentCount: const AllowedArgumentCount(2),
      function: _containsImpl,
    );
    createFunction(
      functionName: 'moor_contains',
      deterministic: true,
      argumentCount: const AllowedArgumentCount(3),
      function: _containsImpl,
    );
    createFunction(
      functionName: 'current_time_millis',
      deterministic: true,
      directOnly: false,
      argumentCount: const AllowedArgumentCount(0),
      function: (List<Object?> args) => DateTime.now().millisecondsSinceEpoch,
    );
  }
}

num? _pow(List<Object?> args) {
  final first = args[0];
  final second = args[1];

  if (first == null || second == null || first is! num || second is! num) {
    return null;
  }

  return pow(first, second);
}

/// Base implementation for a sqlite function that takes one numerical argument
/// and returns one numerical argument.
///
/// When not called with a number, returns will null. Otherwise, returns with
/// [calculation].
num? Function(List<Object?>) _unaryNumFunction(num Function(num) calculation) {
  return (List<Object?> args) {
    // sqlite will ensure that this is only called with one argument
    final value = args[0];
    if (value is num) {
      return calculation(value);
    } else {
      return null;
    }
  };
}

bool? _regexpImpl(List<Object?> args) {
  var multiLine = false;
  var caseSensitive = true;
  var unicode = false;
  var dotAll = false;

  final argCount = args.length;
  if (argCount < 2 || argCount > 3) {
    throw 'Expected two or three arguments to regexp';
  }

  final firstParam = args[0];
  final secondParam = args[1];

  if (firstParam == null || secondParam == null) {
    return null;
  }
  if (firstParam is! String || secondParam is! String) {
    throw 'Expected two strings as parameters to regexp';
  }

  if (argCount == 3) {
    // In the variant with three arguments, the last (int) arg can be used to
    // enable regex flags. See the regexp() extension in moor for details.
    final value = args[2];
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
      firstParam,
      multiLine: multiLine,
      caseSensitive: caseSensitive,
      unicode: unicode,
      dotAll: dotAll,
    );
  } on FormatException {
    throw 'Invalid regex';
  }

  return regex.hasMatch(secondParam);
}

bool _containsImpl(List<dynamic> args) {
  final argCount = args.length;
  if (argCount < 2 || argCount > 3) {
    throw 'Expected 2 or 3 arguments to moor_contains';
  }

  final first = args[0];
  final second = args[1];

  if (first is! String || second is! String) {
    throw 'First two args to contains must be strings';
  }

  final caseSensitive = argCount == 3 && args[2] == 1;

  final result = caseSensitive
      ? first.contains(second)
      : first.toLowerCase().contains(second.toLowerCase());

  return result;
}
