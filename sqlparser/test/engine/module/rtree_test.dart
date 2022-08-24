import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

final _rtreeOptions =
    EngineOptions(enabledExtensions: const [RTreeExtension()]);

void main() {
  group('creating rtree tables', () {
    final engine = SqlEngine(_rtreeOptions);

    test('can create rtree table', () {
      final result = engine.analyze('''
CREATE VIRTUAL TABLE demo_index USING rtree(
   id,              -- Integer primary key
   minX, maxX,      -- Minimum and maximum X coordinate
   minY, maxY       -- Minimum and maximum Y coordinate
);''');

      final table = const SchemaFromCreateTable()
          .read(result.root as TableInducingStatement);

      expect(table.name, 'demo_index');
      final columns = table.resultColumns;
      expect(columns, hasLength(5));
      expect(columns.first.type.type, equals(BasicType.int));
      expect(columns.last.type.type, equals(BasicType.real));
    });

    group('validate arguments', () {
      test('invalid coordinate count', () {
        final result = engine.analyze('''
CREATE VIRTUAL TABLE demo_index USING rtree(
   id,              -- Integer primary key
   minX, maxX,      -- Minimum and maximum X coordinate
   minY
);''');

        expect(
            () => const SchemaFromCreateTable()
                .read(result.root as TableInducingStatement),
            throwsArgumentError);
      });

      test('no coordinates', () {
        final result = engine.analyze('''
CREATE VIRTUAL TABLE demo_index USING rtree(
   id              -- Integer primary key
);''');

        expect(
            () => const SchemaFromCreateTable()
                .read(result.root as TableInducingStatement),
            throwsArgumentError);
      });

      test('too many dimensions', () {
        final result = engine.analyze('''
CREATE VIRTUAL TABLE demo_index USING rtree(
   id,              -- Integer primary key
   minX, maxX,      -- Minimum and maximum X coordinate
   minY, maxY,
   minY, maxY,
   minY, maxY,
   minY, maxY,
   minY, maxY
);''');

        expect(
            () => const SchemaFromCreateTable()
                .read(result.root as TableInducingStatement),
            throwsArgumentError);
      });
    });
  });

  group('type inference for function arguments', () {
    late SqlEngine engine;
    setUp(() {
      engine = SqlEngine(_rtreeOptions);
      // add an fts5 table for the following queries
      final result = engine.analyze('''
CREATE VIRTUAL TABLE demo_index USING rtree(
   id,              -- Integer primary key
   minX, maxX,      -- Minimum and maximum X coordinate
   minY, maxY       -- Minimum and maximum Y coordinate
);''');

      engine.registerTable(const SchemaFromCreateTable()
          .read(result.root as TableInducingStatement));
    });

    test('insert', () {
      final result = engine.analyze('INSERT INTO demo_index VALUES '
          '(28215, -80.781227, -80.604706, 35.208813, 35.297367);');
      expect(result.errors, isEmpty);
    });

    test('select', () {
      final result = engine.analyze('''
SELECT A.* FROM demo_index AS A, demo_index AS B
 WHERE A.maxX>=B.minX AND A.minX<=B.maxX
   AND A.maxY>=B.minY AND A.minY<=B.maxY
   AND B.id=28269;''');

      final columns = (result.root as SelectStatement).resolvedColumns;

      expect(result.errors, isEmpty);
      expect(columns, hasLength(5));
    });
  });
}
