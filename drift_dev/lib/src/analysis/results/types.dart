import 'package:drift/drift3.dart' show BuiltinDriftType;

import 'column.dart';
import 'dart.dart';

/// Something that has a type.
///
/// This includes table and result-set column and variables.
abstract class HasType {
  /// Whether the type is nullable in Dart.
  bool get nullable;

  /// Whether this type is an array in sql.
  ///
  /// In this case, [nullable] refers to the inner type as arrays are always
  /// non-nullable.
  bool get isArray;

  /// The associated sql type.
  ColumnType get sqlType;

  /// The applied type converter, or null if no type converter has been applied
  /// to this column.
  AppliedTypeConverter? get typeConverter;
}

/// The underlying SQL type of a column analyzed by drift.
///
/// We distinguish between types directly supported by drift, and types that
/// are supplied by another library. Custom types can hold different Dart types,
/// but are a feature distinct from type converters: They indicate that a type
/// is directly supported by the underlying database driver, whereas a type
/// converter is a mapping done in drift.
///
/// In addition to the SQL type, we also track whether a column is nullable,
/// appears where an array is expected or has a type converter applied to it.
/// [HasType] is the interface for sql-typed elements and is implemented by
/// columns.
sealed class ColumnType {
  const factory ColumnType.drift(BuiltinDriftType builtin) = ColumnDriftType;

  const factory ColumnType.custom(CustomColumnType custom) = ColumnCustomType;
}

final class ColumnDriftType implements ColumnType {
  /// The builtin drift type used by this column.
  final BuiltinDriftType builtin;

  const ColumnDriftType(this.builtin);

  @override
  int get hashCode => Object.hash(ColumnDriftType, builtin);

  @override
  bool operator ==(Object other) {
    return other is ColumnDriftType && other.builtin == builtin;
  }
}

final class ColumnCustomType implements ColumnType {
  final CustomColumnType custom;

  const ColumnCustomType(this.custom);

  @override
  int get hashCode => Object.hash(ColumnCustomType, custom);

  @override
  bool operator ==(Object other) {
    return other is ColumnCustomType && other.custom == custom;
  }
}

extension OperationOnTypes on HasType {
  bool get isUint8ListInDart {
    return typeConverter == null &&
        switch (sqlType) {
          ColumnDriftType(builtin: BuiltinDriftType.byteArray) => true,
          _ => false,
        };
  }

  /// Whether this type is nullable in Dart
  bool get nullableInDart {
    if (isArray) return false; // Is a List<Something> in Dart, not nullable

    final converter = typeConverter;
    if (converter != null) {
      return converter.mapsToNullableDart(nullable);
    }

    return nullable;
  }
}

Map<BuiltinDriftType, DartTopLevelSymbol> dartTypeNames = Map.unmodifiable({
  BuiltinDriftType.bool: DartTopLevelSymbol('bool', Uri.parse('dart:core')),
  BuiltinDriftType.text: DartTopLevelSymbol('String', Uri.parse('dart:core')),
  BuiltinDriftType.int: DartTopLevelSymbol('int', Uri.parse('dart:core')),
  BuiltinDriftType.int64: DartTopLevelSymbol('BigInt', Uri.parse('dart:core')),
  BuiltinDriftType.dateTime:
      DartTopLevelSymbol('DateTime', Uri.parse('dart:core')),
  BuiltinDriftType.byteArray:
      DartTopLevelSymbol('Uint8List', Uri.parse('dart:typed_data')),
  BuiltinDriftType.double: DartTopLevelSymbol('double', Uri.parse('dart:core')),
});
