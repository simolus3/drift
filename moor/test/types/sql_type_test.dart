import 'package:moor/moor.dart' hide isNull;
import 'package:test/test.dart';

void main() {
  test('types map null values to null', () {
    final typeSystem = const SqlTypeSystem.withDefaults();

    for (var type in typeSystem.types) {
      expect(type.mapToSqlVariable(null), isNull,
          reason: '$type should map null to null variables');
      expect(type.mapFromDatabaseResponse(null), isNull,
          reason: '$type should map null response to null value');
    }
  });
}
