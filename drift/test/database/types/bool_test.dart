import 'package:drift/drift.dart';
import 'package:test/test.dart';

void main() {
  final sqliteTypes =
      DriftDatabaseOptions().createTypeMapping(SqlDialect.sqlite);
  final postgresTypes =
      DriftDatabaseOptions().createTypeMapping(SqlDialect.postgres);

  group('bool type', () {
    test('Can read booleans from sqlite', () {
      expect(sqliteTypes.read(DriftSqlType.bool, 1), true);
      expect(sqliteTypes.read(DriftSqlType.bool, 0), false);
    });

    test('Can read booleans from postgres', () {
      expect(postgresTypes.read(DriftSqlType.bool, true), true);
      expect(postgresTypes.read(DriftSqlType.bool, false), false);
    });

    test('Can be mapped to sqlite constant', () {
      expect(sqliteTypes.mapToSqlLiteral(true), '1');
      expect(sqliteTypes.mapToSqlLiteral(false), '0');
    });

    test('Can be mapped to postgres constant', () {
      expect(postgresTypes.mapToSqlLiteral(true), 'true');
      expect(postgresTypes.mapToSqlLiteral(false), 'false');
    });

    test('Can be mapped to sqlite variable', () {
      expect(sqliteTypes.mapToSqlVariable(true), 1);
      expect(sqliteTypes.mapToSqlVariable(false), 0);
    });

    test('Can be mapped to postgres variable', () {
      expect(postgresTypes.mapToSqlVariable(true), true);
      expect(postgresTypes.mapToSqlVariable(false), false);
    });
  });
}
