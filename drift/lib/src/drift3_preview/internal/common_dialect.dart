/// Common helpers to implement drift dialects.
library;

import 'dart:typed_data';

import 'package:convert/convert.dart';

import '../drift.dart';

/// Common implementation for a BLOB / byte array type.
final class CommonByteArrayType extends PhysicalSqlType<Uint8List> {
  @override
  final String typeName;

  /// Creates a blob type from its SQL name.
  const CommonByteArrayType(this.typeName);

  @override
  Uint8List dartValue(Object databaseValue) {
    if (databaseValue is String) {
      return Uint8List.fromList(databaseValue.codeUnits);
    }
    return databaseValue as Uint8List;
  }

  @override
  String sqlLiteral(Uint8List value) {
    final String hexString = hex.encode(value);
    return "x'$hexString'";
  }

  @override
  Object? sqlParameter(Uint8List? value) => value;
}

/// Common implementation for a `REAL` / [double] type.
final class CommonDoubleType extends PhysicalSqlType<double> {
  @override
  final String typeName;

  /// Creates a double type from its SQL name.
  const CommonDoubleType({this.typeName = 'REAL'});

  @override
  double dartValue(Object databaseValue) {
    return switch (databaseValue) {
      BigInt() => databaseValue.toDouble(),
      _ => (databaseValue as num).toDouble(),
    };
  }

  @override
  String sqlLiteral(double value) => value.toString();

  @override
  Object? sqlParameter(double? value) {
    return value;
  }
}

/// Common implementation for a `TEXT` / [String] type.
final class CommonTextType extends PhysicalSqlType<String> {
  @override
  final String typeName;

  /// Creates a text type from its SQL name.
  const CommonTextType({this.typeName = 'TEXT'});

  @override
  String dartValue(Object databaseValue) {
    return databaseValue.toString();
  }

  @override
  String sqlLiteral(String value) {
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
  Object? sqlParameter(String? value) {
    return value;
  }
}
