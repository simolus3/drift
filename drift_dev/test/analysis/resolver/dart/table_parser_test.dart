@Tags(['analyzer'])

import 'package:collection/collection.dart';
import 'package:drift_dev/src/analysis/driver/state.dart';
import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  late TestBackend backend;
  late FileState state;

  setUpAll(() {
    backend = TestBackend({
      'a|lib/main.dart': r'''
      import 'package:drift/drift.dart';

      TypeConverter<Dart, SQL> typeConverter<Dart, SQL>() {
        throw 'stub';
      }

      class TableWithCustomName extends Table {
        @override String get tableName => 'my-fancy-table';

        @override bool get withoutRowId => true;
      }

      class Users extends Table {
        /// The user id
        IntColumn get id => integer().autoIncrement()();
        /// The username
        ///
        /// The username must be between 6-32 characters
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
        TextColumn get name => text().nullable()();
      }

      class Socks extends Table {
        TextColumn get name => text()();
        IntColumn get id => integer()();

        @override
        Set<Column> get primaryKey => {id};
      }

      class ArchivedSocks extends Socks {
        TextColumn get archivedBy => text()();
        DateTimeColumn get archivedOn => dateTime()();
      }

      class WithAliasForRowId extends Table {
        IntColumn get id => integer()();
        TextColumn get name => text()();

        @override
        Set<Column> get primaryKey => {id};
      }

      class PrimaryKeyAndAutoIncrement extends Table {
        IntColumn get id => integer().autoIncrement()();
        TextColumn get other => text()();

        @override
        Set<Column> get primaryKey => {other};
      }

      class DynamicConverter extends Table {
        TextColumn get a1 => text().map<dynamic>(typeConverter<dynamic, String>())();
        TextColumn get a2 => text().map<DoesNotExist>(typeConverter<DoesNotExist, String>())();

        TextColumn get b1 => text().map<List<dynamic>>(typeConverter<List<dynamic>, String>())();
        TextColumn get b2 => text().map<List<DoesNotExist>>(typeConverter<List<DoesNotExist>, String>())();

        TextColumn get c => text().map<Map<String, dynamic>>(typeConverter<Map<String, dynamic>, String>())();
      }
      ''',
      'a|lib/invalid_reference.dart': '''
      import 'package:drift/drift.dart';

      class Foo extends Table {
        IntColumn get id => integer().autoIncrement()();
      }

      @DriftDatabase(tables: [Foo, DoesNotExist])
      class Database {}

      @DriftAccessor(views: [DoesNotExist])
      class Accessor {}
      ''',
      'a|lib/invalid_constraints.dart': '''
      import 'package:drift/drift.dart';

      class InvalidConstraints extends Table {
        IntColumn get a => integer().autoIncrement().customConstraint('foo')();
        IntColumn get b => integer().customConstraint('a').customConstraint('b')();
      }
      ''',
    });
  });
  tearDownAll(() => backend.dispose());

  Future<DriftTable?> parse(String name) async {
    final result = state = await backend.analyze('package:a/main.dart');

    return result.analyzedElements
        .whereType<DriftTable>()
        .firstWhereOrNull((e) => e.baseDartName == name);
  }

  group('table names', () {
    test('use overridden name', () async {
      final parsed = await parse('TableWithCustomName');
      expect(parsed!.schemaName, equals('my-fancy-table'));
      expect(parsed.withoutRowId, isTrue);
    });

    test('use re-cased class name', () async {
      final parsed = await parse('Users');
      expect(parsed!.schemaName, equals('users'));
    });

    test('should not parse for complex methods', () async {
      await parse('WrongName');
      expect(state.allErrors, isNotEmpty);
    });
  });

  group('Columns', () {
    test('should use field name if no name has been set explicitly', () async {
      final table = await parse('Users');
      final idColumn =
          table!.columns.singleWhere((col) => col.nameInSql == 'id');

      expect(
        idColumn.declaration,
        isA<DriftDeclaration>().having((c) => c.name, 'name', 'id'),
      );
    });

    test('should use explicit name, if it exists', () async {
      final table = await parse('Users');
      table!.columns.singleWhere((col) => col.nameInSql == 'user_name');
    });

    test('should parse min and max length for text columns', () async {
      final table = await parse('Users');
      final idColumn =
          table!.columns.singleWhere((col) => col.nameInSql == 'user_name');

      expect(idColumn.constraints,
          contains(LimitingTextLength(minLength: 6, maxLength: 32)));
    });

    test('should only parse max length when relevant', () async {
      final table = await parse('Users');
      final idColumn =
          table!.columns.singleWhere((col) => col.nameInDart == 'onlyMax');

      expect(
          idColumn.constraints, contains(LimitingTextLength(maxLength: 100)));
    });

    test('parses custom constraints', () async {
      final table = await parse('CustomPrimaryKey');

      final partA = table!.columns.singleWhere((c) => c.nameInDart == 'partA');
      final partB = table.columns.singleWhere((c) => c.nameInDart == 'partB');

      expect(partB.customConstraints, 'custom');
      expect(partA.customConstraints, isNull);
    });

    test('parsed default values', () async {
      final table = await parse('Users');
      final defaultsColumn =
          table!.columns.singleWhere((c) => c.nameInSql == 'defaults');

      expect(defaultsColumn.defaultArgument.toString(), 'currentDate');
    });

    test('parses documentation comments', () async {
      final table = await parse('Users');
      final idColumn =
          table!.columns.singleWhere((col) => col.nameInSql == 'id');

      final usernameColumn =
          table.columns.singleWhere((col) => col.nameInSql == 'user_name');

      expect(idColumn.documentationComment, '/// The user id');
      expect(
        usernameColumn.documentationComment,
        '/// The username\n///\n/// The username must be between 6-32 characters',
      );
    });
  });

  test('parses custom primary keys', () async {
    final table = await parse('CustomPrimaryKey');

    expect(table!.fullPrimaryKey, containsAll(table.columns));
    expect(
      table.columns.any(
          (column) => column.constraints.any((e) => e is PrimaryKeyColumn)),
      isFalse,
    );
  });

  test('warns when using primaryKey and autoIncrement()', () async {
    await parse('PrimaryKeyAndAutoIncrement');

    expect(
      state.allErrors,
      contains(isDriftError(
          contains('override primaryKey and use autoIncrement()'))),
    );
  });

  test('recognizes aliases for rowid', () async {
    final table = await parse('WithAliasForRowId');
    final idColumn = table!.columns.singleWhere((c) => c.nameInSql == 'id');

    expect(table.isColumnRequiredForInsert(idColumn), isFalse);
  });

  group('inheritance', () {
    test('from abstract classes or mixins', () async {
      final table = await parse('Foos');

      expect(table!.columns, hasLength(2));
      expect(
          table.columns.map((c) => c.nameInSql), containsAll(['id', 'name']));
    });

    test('from regular classes', () async {
      final socks = await parse('Socks');
      final archivedSocks = await parse('ArchivedSocks');

      expect(socks!.columns, hasLength(2));
      expect(socks.columns.map((c) => c.nameInSql), ['name', 'id']);

      expect(archivedSocks!.columns, hasLength(4));
      expect(archivedSocks.columns.map((c) => c.nameInSql),
          ['name', 'id', 'archived_by', 'archived_on']);
      expect(archivedSocks.fullPrimaryKey.map((e) => e.nameInSql), ['id']);
    });
  });

  test('reports error when using autoIncrement and primaryKey', () async {
    final uri = Uri.parse('package:a/main.dart');
    final file = await backend.driver.fullyAnalyze(uri);

    expect(
      file.allErrors,
      contains(
        isDriftError(
            "Tables can't override primaryKey and use autoIncrement()"),
      ),
    );
  });

  test('reports errors for unknown classes', () async {
    final uri = Uri.parse('package:a/invalid_reference.dart');
    final file = await backend.driver.fullyAnalyze(uri);

    expect(
      file.allErrors,
      containsAll([
        isDriftError(allOf(
          contains('Could not read tables from @DriftDatabase annotation!'),
          contains('Please make sure that all table classes exist.'),
        )),
        isDriftError(allOf(
          contains('Could not read views from @DriftAccessor annotation!'),
          contains('Please make sure that all table classes exist.'),
        )),
      ]),
    );
  });

  test('reports errors around suspicous customConstraint uses', () async {
    final uri = Uri.parse('package:a/invalid_constraints.dart');
    final file = await backend.driver.fullyAnalyze(uri);

    expect(
      file.allErrors,
      containsAll([
        isDriftError(
          allOf(
            contains(
                'This column definition is using both drift-defined constraints'),
            contains('and a customConstraint()'),
          ),
        ).withSpan('a'),
        isDriftError(
          contains("You've already set custom constraints on this column"),
        ).withSpan('customConstraint'),
      ]),
    );
  });
}
