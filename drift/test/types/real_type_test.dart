import 'package:drift/drift.dart' as moor;
import 'package:test/test.dart';

void main() {
  const type = moor.RealType();

  group('RealType', () {
    test('can be read from floating point values returned by sql', () {
      expect(type.mapFromDatabaseResponse(3.1234), 3.1234);
    });

    test('can read null value from sql', () {
      expect(type.mapFromDatabaseResponse(null), isNull);
    });

    test('can be mapped to sql constants', () {
      expect(type.mapToSqlConstant(1.123), '1.123');
    });

    test('can be mapped to variables', () {
      expect(type.mapToSqlVariable(1.123), 1.123);
    });

    test('map null to null', () {
      expect(type.mapToSqlConstant(null), 'NULL');
      expect(type.mapToSqlVariable(null), null);
    });
  });
}
