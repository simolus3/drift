@Tags(['analyzer'])

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:moor_generator/src/analyzer/dart/parser.dart';
import 'package:moor_generator/src/analyzer/runner/steps.dart';
import 'package:moor_generator/src/model/specified_column.dart';
import 'package:moor_generator/src/model/specified_table.dart';
import 'package:test/test.dart';

import '../../utils/test_backend.dart';

void main() {
  TestBackend backend;
  ParseDartStep dartStep;
  MoorDartParser parser;
  setUpAll(() {
    backend = TestBackend({
      AssetId.parse('test_lib|lib/main.dart'): r'''
      import 'package:moor/moor.dart';
      
      class TableWithCustomName extends Table {
        @override String get tableName => 'my-fancy-table';
      }
      
      class Users extends Table {
        IntColumn get id => integer().autoIncrement()();
        TextColumn get name => text().named("user_name").withLength(min: 6, max: 32)();
        TextColumn get onlyMax => text().withLength(max: 100)();
        
        DateTimeColumn get defaults => dateTime().withDefault(currentDate)();
      }
      
      class CustomPrimaryKey extends Table {
        IntColumn get partA => integer()();
        IntColumn get partB => integer().customConstraint('custom')();
        
        @override
        Set<Column> get primaryKey => {partA, partB};
      }
      
      class WrongName extends Table {
         String constructTableName() => 'my-table-name';
         String get tableName => constructTableName();
      }
      
      mixin IntIdTable on Table {
        IntColumn get id => integer().autoIncrement()();
      }
      
      abstract class HasNameTable extends Table {
        TextColumn get name => text()();
      }
      
      class Foos extends HasNameTable with IntIdTable {
        
      }
      '''
    });
  });
  tearDownAll(() {
    backend.finish();
  });

  setUp(() async {
    final uri = Uri.parse('package:test_lib/main.dart');
    final task = backend.startTask(uri);

    dartStep = ParseDartStep(null, null, await task.resolveDart(uri));
    parser = MoorDartParser(dartStep);
  });

  Future<SpecifiedTable> parse(String name) async {
    return parser.parseTable(dartStep.library.getType(name));
  }

  group('table names', () {
    test('use overridden name', () async {
      final parsed = await parse('TableWithCustomName');
      expect(parsed.sqlName, equals('my-fancy-table'));
    });

    test('use re-cased class name', () async {
      final parsed = await parse('Users');
      expect(parsed.sqlName, equals('users'));
    });

    test('should not parse for complex methods', () async {
      await parse('WrongName');
      expect(dartStep.errors.errors, isNotEmpty);
    });
  });

  group('Columns', () {
    test('should use field name if no name has been set explicitly', () async {
      final table = await parse('Users');
      final idColumn =
          table.columns.singleWhere((col) => col.name.name == 'id');

      expect(idColumn.name, equals(ColumnName.implicitly('id')));
      expect(idColumn.declaration.dartDeclaration,
          const TypeMatcher<PropertyAccessorElement>());
    });

    test('should use explicit name, if it exists', () async {
      final table = await parse('Users');
      final idColumn =
          table.columns.singleWhere((col) => col.name.name == 'user_name');

      expect(idColumn.name, equals(ColumnName.explicitly('user_name')));
    });

    test('should parse min and max length for text columns', () async {
      final table = await parse('Users');
      final idColumn =
          table.columns.singleWhere((col) => col.name.name == 'user_name');

      expect(idColumn.features,
          contains(LimitingTextLength.withLength(min: 6, max: 32)));
    });

    test('should only parse max length when relevant', () async {
      final table = await parse('Users');
      final idColumn =
          table.columns.singleWhere((col) => col.dartGetterName == 'onlyMax');

      expect(
          idColumn.features, contains(LimitingTextLength.withLength(max: 100)));
    });

    test('parses custom constraints', () async {
      final table = await parse('CustomPrimaryKey');

      final partA =
          table.columns.singleWhere((c) => c.dartGetterName == 'partA');
      final partB =
          table.columns.singleWhere((c) => c.dartGetterName == 'partB');

      expect(partB.customConstraints, 'custom');
      expect(partA.customConstraints, isNull);
    });

    test('parsed default values', () async {
      final table = await parse('Users');
      final defaultsColumn =
          table.columns.singleWhere((c) => c.name.name == 'defaults');

      expect(defaultsColumn.defaultArgument.toString(), 'currentDate');
    });
  });

  test('parses custom primary keys', () async {
    final table = await parse('CustomPrimaryKey');

    expect(table.primaryKey, containsAll(table.columns));
    expect(table.columns.any((column) => column.hasAI), isFalse);
  });

  test('handles inheritance in column definitions', () async {
    final table = await parse('Foos');

    expect(table.columns.map((c) => c.name.name), containsAll(['id', 'name']));
  });
}
