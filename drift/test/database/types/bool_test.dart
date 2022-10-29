import 'package:drift/drift.dart';
import 'package:test/test.dart';

void main() {
  final typeSystem = DriftDatabaseOptions().types;

  group('bool type', () {
    test('Can read booleans from sqlite', () {
      expect(typeSystem.read(DriftSqlType.bool, 1, SqlDialect.sqlite), true);
      expect(typeSystem.read(DriftSqlType.bool, 0, SqlDialect.sqlite), false);
    });

    test('Can read booleans from postgres', () {
      expect(
          typeSystem.read(DriftSqlType.bool, true, SqlDialect.postgres), true);
      expect(typeSystem.read(DriftSqlType.bool, false, SqlDialect.postgres),
          false);
    });

    test('Can be mapped to sqlite constant', () {
      expect(typeSystem.mapToSqlLiteral(true, SqlDialect.sqlite), '1');
      expect(typeSystem.mapToSqlLiteral(false, SqlDialect.sqlite), '0');
    });

    test('Can be mapped to postgres constant', () {
      expect(typeSystem.mapToSqlLiteral(true, SqlDialect.postgres), 'true');
      expect(typeSystem.mapToSqlLiteral(false, SqlDialect.postgres), 'false');
    });

    test('Can be mapped to sqlite variable', () {
      expect(typeSystem.mapToSqlVariable(true, SqlDialect.sqlite), 1);
      expect(typeSystem.mapToSqlVariable(false, SqlDialect.sqlite), 0);
    });

    test('Can be mapped to postgres variable', () {
      expect(typeSystem.mapToSqlVariable(true, SqlDialect.postgres), true);
      expect(typeSystem.mapToSqlVariable(false, SqlDialect.postgres), false);
    });
  });
}
