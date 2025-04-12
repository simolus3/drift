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
