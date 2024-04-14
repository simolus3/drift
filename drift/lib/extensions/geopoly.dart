/// https://www.sqlite.org/geopoly.html
/// The Geopoly Interface To The SQLite R*Tree Module

library geopoly;

import 'dart:typed_data';

import '../src/runtime/query_builder/query_builder.dart';
import '../src/runtime/types/mapping.dart';

///
final class GeopolyPolygonType implements CustomSqlType<GeopolyPolygon> {
  ///
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

/// In Geopoly, a polygon can be text or a blob
sealed class GeopolyPolygon {
  const GeopolyPolygon._();

  const factory GeopolyPolygon.text(String value) = GeopolyPolygonString;

  const factory GeopolyPolygon.blob(Uint8List value) = GeopolyPolygonBlob;
}

///
final class GeopolyPolygonString extends GeopolyPolygon {
  ///
  final String value;

  ///
  const GeopolyPolygonString(this.value) : super._();
}

///
final class GeopolyPolygonBlob extends GeopolyPolygon {
  ///
  final Uint8List value;

  ///
  const GeopolyPolygonBlob(this.value) : super._();
}
