/// https://www.sqlite.org/geopoly.html
/// The Geopoly Interface To The SQLite R*Tree Module
library;

import 'dart:typed_data';

import '../../src/query_builder.dart';

/// The type used for the `_shape` column in virtual `GEOPOLY` tables.
///
/// This type is responsible for representing shape values in Dart. It is
/// created by drift when the `geopoly` extension is enabled and a `CREATE
/// VIRTUAL TABLE USING geopoly` table is declared in a `.drift` file.
final class GeopolyPolygonType implements SqlType<GeopolyPolygon> {
  /// Default constant constructor for the geopoly type.
  const GeopolyPolygonType();

  @override
  String sqlLiteral(DriftDialect dialect, GeopolyPolygon value) {
    throw UnimplementedError();
  }

  @override
  Object sqlParameter(DriftDialect dialect, GeopolyPolygon value) {
    switch (value) {
      case GeopolyPolygonString(:final value):
        return value;
      case GeopolyPolygonBlob(:final value):
        return value;
    }
  }

  @override
  GeopolyPolygon dartValue(DriftDialect dialect, Object databaseValue) {
    return switch (databaseValue) {
      Uint8List() => GeopolyPolygon.blob(databaseValue),
      String() => GeopolyPolygon.text(databaseValue),
      _ => throw UnimplementedError(),
    };
  }

  @override
  String typeName(DriftDialect dialect) {
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
