import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

final _geopolyOptions = EngineOptions(
  enabledExtensions: const [
    GeopolyExtension(),
  ],
);

void main() {
  group('creating geopoly tables', () {
    final engine = SqlEngine(_geopolyOptions);

    test('can create geopoly table', () {
      final result = engine.analyze(
          '''CREATE VIRTUAL TABLE geo USING geopoly(a integer not null, b integer, c);''');

      final table = const SchemaFromCreateTable()
          .read(result.root as TableInducingStatement);

      expect(table.name, 'geo');
      final columns = table.resultColumns;
      expect(columns, hasLength(4));
      expect(columns[0].type.type, equals(BasicType.blob));
      expect(columns[1].type.type, equals(BasicType.int));
      expect(columns[2].type.type, equals(BasicType.int));
      expect(columns[3].type.type, equals(BasicType.any));
    });
  });
}
