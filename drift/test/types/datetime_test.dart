import 'package:drift/drift.dart' as drift;
import 'package:test/test.dart';

const _exampleUnixSqlite = 1550172560;
const _exampleUnixMillis = 1550172560000;
final _exampleDateTime =
    DateTime.fromMillisecondsSinceEpoch(_exampleUnixMillis);

void main() {
  const type = drift.DateTimeType();

  group('DateTimes', () {
    test('can be read from unix stamps returned by sql', () {
      expect(
          type.mapFromDatabaseResponse(_exampleUnixSqlite), _exampleDateTime);
    });

    test('can read null value from sql', () {
      expect(type.mapFromDatabaseResponse(null), isNull);
    });

    test('can be mapped to sql constants', () {
      expect(type.mapToSqlConstant(_exampleDateTime),
          _exampleUnixSqlite.toString());
    });

    test('can be mapped to variables', () {
      expect(type.mapToSqlVariable(_exampleDateTime), _exampleUnixSqlite);
    });

    test('map null to null', () {
      expect(type.mapToSqlConstant(null), 'NULL');
      expect(type.mapToSqlVariable(null), null);
    });
  });
}
