import 'package:drift/drift.dart' hide isNull;
import 'package:test/test.dart';

void main() {
  test('types map null values to null', () {
    const options = DriftDatabaseOptions();
    expect(options.types.mapToSqlVariable(null), isNull);

    for (final type in DriftSqlType.values) {
      expect(options.types.read(type, null), isNull,
          reason: '$type should map null response to null value');
    }
  });
}
