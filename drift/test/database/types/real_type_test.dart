import 'package:drift/drift.dart' as drift;
import 'package:test/test.dart';

void main() {
  final typeSystem = const drift.DriftDatabaseOptions()
      .createTypeMapping(drift.SqlDialect.sqlite);

  group('RealType', () {
    test('can be read from floating point values returned by sql', () {
      expect(typeSystem.read(drift.DriftSqlType.double, 3.1234), 3.1234);
    });

    test('can read null value from sql', () {
      expect(typeSystem.read(drift.DriftSqlType.double, null), isNull);
    });

    test('can read BigInt', () {
      expect(typeSystem.read(drift.DriftSqlType.double, BigInt.parse('12345')),
          12345.0);
    });

    test('can be mapped to sql constants', () {
      expect(typeSystem.mapToSqlLiteral(1.123), '1.123');
    });

    test('can be mapped to variables', () {
      expect(typeSystem.mapToSqlVariable(1.123), 1.123);
    });

    test('map null to null', () {
      expect(typeSystem.mapToSqlLiteral(null), 'NULL');
      expect(typeSystem.mapToSqlVariable(null), null);
    });
  });
}
