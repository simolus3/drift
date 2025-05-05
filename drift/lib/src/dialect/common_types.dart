/// Utilities to implement type mappings from Dart to SQL across dialect
/// implementations.
@internal
library;

import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:drift/drift.dart';
import 'package:meta/meta.dart';

/// Common implementation for a BLOB / byte array type.
final class CommonByteArrayType implements SqlType<Uint8List> {
  /// The name of this type in SQL.
  final String name;

  /// Creates a blob type from its SQL name.
  const CommonByteArrayType(this.name);

  @override
  Uint8List dartValue(DriftDialect dialect, Object databaseValue) {
    if (databaseValue is String) {
      return Uint8List.fromList(databaseValue.codeUnits);
    }
    return databaseValue as Uint8List;
  }

  @override
  String sqlLiteral(DriftDialect dialect, Uint8List value) {
    final String hexString = hex.encode(value);
    return "x'$hexString'";
  }

  @override
  Object sqlParameter(DriftDialect dialect, Uint8List value) => value;

  @override
  String typeName(DriftDialect dialect) => name;
}

/// Common implementation for a `REAL` / [double] type.
final class CommonDoubleType implements SqlType<double> {
  /// The name of this type, typically `REAL`.
  final String name;

  /// Creates a double type from its SQL name.
  const CommonDoubleType({this.name = 'REAL'});

  @override
  double dartValue(DriftDialect dialect, Object databaseValue) {
    return switch (databaseValue) {
      BigInt() => databaseValue.toDouble(),
      _ => (databaseValue as num).toDouble(),
    };
  }

  @override
  String sqlLiteral(DriftDialect dialect, double value) => value.toString();

  @override
  Object sqlParameter(DriftDialect dialect, double value) {
    return value;
  }

  @override
  String typeName(DriftDialect dialect) => name;
}

/// Common implementation for a `TEXT` / [String] type.
final class CommonTextType implements SqlType<String> {
  /// The name of this type, typically `TEXT`.
  final String name;

  /// Creates a text type from its SQL name.
  const CommonTextType({this.name = 'TEXT'});

  @override
  String dartValue(DriftDialect dialect, Object databaseValue) {
    return databaseValue.toString();
  }

  @override
  String sqlLiteral(DriftDialect dialect, String value) {
    // From the sqlite docs: (https://www.sqlite.org/lang_expr.html)
    // A string constant is formed by enclosing the string in single quotes
    // (').
    // A single quote within the string can be encoded by putting two single
    // quotes in a row - as in Pascal. C-style escapes using the backslash
    // character are not supported because they are not standard SQL.
    final escapedChars = value.replaceAll('\'', '\'\'');
    return "'$escapedChars'";
  }

  @override
  Object sqlParameter(DriftDialect dialect, String value) {
    return value;
  }

  @override
  String typeName(DriftDialect dialect) => name;
}
