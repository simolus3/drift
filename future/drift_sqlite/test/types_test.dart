import 'package:drift3_preview/drift.dart';
import 'package:drift_sqlite/drift_sqlite.dart';
import 'package:test/test.dart';

void main() {
  group('bool type', () {
    final sqliteType = BuiltinDriftType.bool.resolveIn(
      const SqliteDialect.withOptions(),
    );

    test('Can read booleans from sqlite', () {
      expect(sqliteType.dartValue(1), true);
      expect(sqliteType.dartValue(0), false);
    });

    test('Can be mapped to sqlite constant', () {
      expect(sqliteType.sqlLiteral(true), '1');
      expect(sqliteType.sqlLiteral(false), '0');
    });

    test('Can be mapped to sqlite variable', () {
      expect(sqliteType.sqlParameter(true), 1);
      expect(sqliteType.sqlParameter(false), 0);
    });
  });

  group('real type', () {
    final sqliteType = BuiltinDriftType.double.resolveIn(
      const SqliteDialect.withOptions(),
    );

    test('can be read from floating point values returned by sql', () {
      expect(sqliteType.dartValue(3.1234), 3.1234);
    });

    test('can read BigInt', () {
      expect(sqliteType.dartValue(BigInt.parse('12345')), 12345.0);
    });

    test('can be mapped to sql constants', () {
      expect(sqliteType.sqlLiteral(1.123), '1.123');
    });

    test('can be mapped to variables', () {
      expect(sqliteType.sqlParameter(1.123), 1.123);
    });
  });
}
