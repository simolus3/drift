import 'package:drift/drift.dart' hide isNull;
import 'package:test/test.dart';

void main() {
  test('types map null values to null', () {
    const mapping = SqlTypes(false);
    expect(mapping.mapToSqlVariable(null), isNull);

    for (final type in DriftSqlType.values) {
      expect(mapping.read(type, null), isNull,
          reason: '$type should map null response to null value');
    }
  });

  test('keeps `DriftAny` values unchanged', () {
    final values = [
      1,
      'two',
      #whatever,
      1.54,
      String,
      DateTime.now(),
      DateTime.now().toUtc(),
      () {},
    ];

    const mapping = SqlTypes(false);

    for (final value in values) {
      expect(mapping.mapToSqlVariable(DriftAny(value)), value);
      expect(mapping.read(DriftSqlType.any, value), DriftAny(value));
    }
  });

  test('maps `DriftAny` to literal', () {
    const mapping = SqlTypes(false);

    expect(mapping.mapToSqlLiteral(DriftAny(1)), '1');
    expect(mapping.mapToSqlLiteral(DriftAny('two')), "'two'");
  });
}
