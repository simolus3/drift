import 'package:analyzer/dart/element/element.dart';
import 'package:sally_generator/src/model/specified_column.dart';
import 'package:sally_generator/src/parser/column_parser.dart';
import 'package:sally_generator/src/parser/table_parser.dart';
import 'package:sally_generator/src/sally_generator.dart';
import 'package:test_api/test_api.dart';
import 'package:build_test/build_test.dart';

void main() async {
  LibraryElement testLib;
  SallyGenerator generator;

  setUpAll(() async {
    testLib = await resolveSource(r''' 
     library test_parser;
     
     import 'package:sally/sally.dart';
     
     class TableWithCustomName extends Table {
       @override
       String get tableName => "my-fancy-table"
     }
     
     class Users extends Table {
       IntColumn get id => integer().autoIncrement()();
       TextColumn get name => text().named("user_name").withLength(min: 6, max: 32)();
       TextColumn get onlyMax => text().withLength(max: 100)();
     }
     
     class CustomPrimaryKey extends Table {
        IntColumn get partA => integer()();
        IntColumn get partB => integer()();
        
        @override
        Set<Column> get primaryKey => {partA, partB};
     }
     
     class WrongName extends Table {
        
         String constructTableName() {
            return "my-table-name";
         }
       
         @override
         String get tableName => constructTableName();
     }
    ''', (r) => r.findLibraryByName('test_parser'));
  });

  setUp(() {
    generator = SallyGenerator();
    generator
      ..columnParser = ColumnParser(generator)
      ..tableParser = TableParser(generator);
  });

  group('SQL table name', () {
    test('should parse correctly when valid', () {
      expect(
          TableParser(generator)
              .parse(testLib.getType('TableWithCustomName'))
              .sqlName,
          equals('my-fancy-table'));
    });

    test('should use class name if table name is not specified', () {
      expect(TableParser(generator).parse(testLib.getType('Users')).sqlName,
          equals('users'));
    });

    test('should not parse for complex methods', () async {
      TableParser(generator).parse(testLib.getType('WrongName'));

      expect(generator.errors.errors, isNotEmpty);
    });
  });

  group('Columns', () {
    test('should use field name if no name has been set explicitely', () {
      final table = TableParser(generator).parse(testLib.getType('Users'));
      final idColumn =
          table.columns.singleWhere((col) => col.name.name == 'id');

      expect(idColumn.name, equals(ColumnName.implicitly('id')));
    });

    test('should use explicit name, if it exists', () {
      final table = TableParser(generator).parse(testLib.getType('Users'));
      final idColumn =
          table.columns.singleWhere((col) => col.name.name == 'user_name');

      expect(idColumn.name, equals(ColumnName.explicitly('user_name')));
    });

    test('should parse min and max length for text columns', () {
      final table = TableParser(generator).parse(testLib.getType('Users'));
      final idColumn =
          table.columns.singleWhere((col) => col.name.name == 'user_name');

      expect(idColumn.features,
          contains(LimitingTextLength.withLength(min: 6, max: 32)));
    });

    test('should only parse max length when relevant', () {
      final table = TableParser(generator).parse(testLib.getType('Users'));
      final idColumn =
          table.columns.singleWhere((col) => col.dartGetterName == 'onlyMax');

      expect(
          idColumn.features, contains(LimitingTextLength.withLength(max: 100)));
    });
  });

  test('parses custom primary keys', () {
    final table = TableParser(generator).parse(testLib.getType('CustomPrimaryKey'));

    expect(table.primaryKey, containsAll(table.columns));
  });
}
