/// https://www.sqlite.org/geopoly.html
/// The Geopoly Interface To The SQLite R*Tree Module

library geopoly;

import 'dart:typed_data';

import '../src/runtime/query_builder/query_builder.dart';
import '../src/runtime/types/mapping.dart';

/// The type used for the `_shape` column in virtual `GEOPOLY` tables.
///
/// This type is responsible for representing shape values in Dart. It is
/// created by drift when the `geopoly` extension is enabled and a `CREATE
/// VIRTUAL TABLE USING geopoly` table is declared in a `.drift` file.
final class GeopolyPolygonType implements CustomSqlType<GeopolyPolygon> {
  /// Default constant constructor for the geopoly type.
  const GeopolyPolygonType();

  @override
  String mapToSqlLiteral(GeopolyPolygon dartValue) {
    throw UnimplementedError();
  }

  @override
  Object mapToSqlParameter(GeopolyPolygon dartValue) {
    switch (dartValue) {
      case GeopolyPolygonString(:final value):
        return value;
      case GeopolyPolygonBlob(:final value):
        return value;
    }
  }

  @override
  GeopolyPolygon read(Object fromSql) {
    return switch (fromSql) {
      Uint8List() => GeopolyPolygon.blob(fromSql),
      String() => GeopolyPolygon.text(fromSql),
      _ => throw UnimplementedError(),
    };
  }

  @override
  String sqlTypeName(GenerationContext context) {
    throw UnimplementedError();
  }
}

/// In Geopoly, a polygon can be text or a blob.
sealed class GeopolyPolygon {
  const GeopolyPolygon._();

  /// Creates a geopoly shape from a textual representation listing its points.
  ///
  /// For details on the syntax for [value], see https://www.sqlite.org/geopoly.html.
  const factory GeopolyPolygon.text(String value) = GeopolyPolygonString;

  /// Creates a geopoly shape from the binary representation used by sqlite3.
  const factory GeopolyPolygon.blob(Uint8List value) = GeopolyPolygonBlob;
}

/// A [GeopolyPolygon] being described as text.
final class GeopolyPolygonString extends GeopolyPolygon {
  /// The textual description of the polygon.
  final String value;

  /// Creates a polygon from the underlying textual [value].
  const GeopolyPolygonString(this.value) : super._();
}

/// A [GeopolyPolygon] being described as binary data.
final class GeopolyPolygonBlob extends GeopolyPolygon {
  /// The binary description of the polygon.
  final Uint8List value;

  /// Creates a polygon from the underlying binary [value].
  const GeopolyPolygonBlob(this.value) : super._();
}
