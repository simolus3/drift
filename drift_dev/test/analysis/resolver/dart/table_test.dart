import 'package:collection/collection.dart';
import 'package:drift_dev/src/analysis/driver/state.dart';
import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  late TestBackend backend;

  setUpAll(() {
    backend = TestBackend({
      'a|lib/main.dart': '''
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

class InvalidConstraints extends Table {
  IntColumn get a => integer().autoIncrement().customConstraint('foo')();
  IntColumn get b => integer().customConstraint('a').customConstraint('b')();
}
''',
    });
  });

  tearDownAll(() => backend.dispose());

  final uri = Uri.parse('package:a/main.dart');

  Future<ElementAnalysisState?> findTable(String dartName) async {
    final state = await backend.driver.resolveElements(uri);

    return state.analysis.values.firstWhereOrNull((e) {
      final result = e.result;
      if (result is DriftTable) {
        return result.baseDartName == dartName;
      } else {
        return false;
      }
    });
  }

  group('table names', () {
    test('use overridden name', () async {
      final result = await findTable('TableWithCustomName');
      final table = result!.result as DriftTable;

      expect(result.errorsDuringAnalysis, isEmpty);
      expect(table.schemaName, 'my-fancy-table');
      expect(table.withoutRowId, isTrue);
    });

    test('use re-cased class name', () async {
      final parsed = await findTable('Users');
      final table = parsed!.result as DriftTable;

      expect(parsed.errorsDuringAnalysis, isEmpty);
      expect(table.schemaName, 'users');
    });

    test('reports discovery error for table with wrong name', () async {
      final state = await backend.driver.resolveElements(uri);
      expect(state.errorsDuringDiscovery, [
        isDriftError(
          contains('This getter must directly return a string literal'),
        ).withSpan('tableName'),
      ]);
    });
  });

  group('Columns', () {
    test('should use field name if no name has been set explicitly', () async {
      final result = await findTable('Users');
      final table = result!.result as DriftTable;
      final idColumn =
          table.columns.singleWhere((col) => col.nameInDart == 'id');

      expect(idColumn.nameInSql, 'id');
    });

    test('should use explicit name, if it exists', () async {
      final result = await findTable('Users');
      final table = result!.result as DriftTable;
      final idColumn =
          table.columns.singleWhere((col) => col.nameInDart == 'name');

      expect(idColumn.nameInSql, 'user_name');
    });

    test('should parse min and max length for text columns', () async {
      final result = await findTable('Users');
      final table = result!.result as DriftTable;
      final idColumn =
          table.columns.singleWhere((col) => col.nameInDart == 'name');

      expect(idColumn.constraints,
          contains(LimitingTextLength(minLength: 6, maxLength: 32)));
    });

    test('should only parse max length when relevant', () async {
      final table = (await findTable('Users'))!.result as DriftTable;
      final idColumn =
          table.columns.singleWhere((col) => col.nameInDart == 'onlyMax');

      expect(
          idColumn.constraints, contains(LimitingTextLength(maxLength: 100)));
    });

    test('parses custom constraints', () async {
      final table = (await findTable('CustomPrimaryKey'))!.result as DriftTable;

      final partA = table.columns.singleWhere((c) => c.nameInDart == 'partA');
      final partB = table.columns.singleWhere((c) => c.nameInDart == 'partB');

      expect(partB.customConstraints, 'custom');
      expect(partA.customConstraints, isNull);
    });

    test('parsed default values', () async {
      final table = (await findTable('Users'))!.result as DriftTable;
      final defaultsColumn =
          table.columns.singleWhere((c) => c.nameInSql == 'defaults');

      expect(defaultsColumn.defaultArgument.toString(), 'currentDate');
    });

    test('parses documentation comments', () async {
      final table = (await findTable('Users'))!.result as DriftTable;
      final idColumn =
          table.columns.singleWhere((col) => col.nameInSql == 'id');

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
    final table = (await findTable('CustomPrimaryKey'))!.result as DriftTable;

    final pkFromTable =
        table.tableConstraints.whereType<PrimaryKeyColumns>().first;
    expect(pkFromTable.primaryKey, containsAll(table.columns));
    expect(
      table.columns.any(
          (column) => column.constraints.any((c) => c is PrimaryKeyColumn)),
      isFalse,
    );
  });

  test('warns when using primaryKey and autoIncrement()', () async {
    final result = await findTable('PrimaryKeyAndAutoIncrement');

    expect(
      result!.errorsDuringAnalysis,
      contains(isDriftError(
          contains('override primaryKey and use autoIncrement()'))),
    );
  });

  test('recognizes aliases for rowid', () async {
    final table = (await findTable('WithAliasForRowId'))!.result as DriftTable;
    final idColumn = table.columns.singleWhere((c) => c.nameInSql == 'id');

    expect(table.isColumnRequiredForInsert(idColumn), isFalse);
  });

  group('inheritance', () {
    test('from abstract classes or mixins', () async {
      final table = (await findTable('Foos'))!.result as DriftTable;

      expect(table.columns, hasLength(2));
      expect(
          table.columns.map((c) => c.nameInSql), containsAll(['id', 'name']));
    });

    test('from regular classes', () async {
      final socks = (await findTable('Socks'))!.result as DriftTable;
      final archivedSocks =
          (await findTable('ArchivedSocks'))!.result as DriftTable;

      expect(socks.columns, hasLength(2));
      expect(socks.columns.map((c) => c.nameInSql), ['name', 'id']);

      expect(archivedSocks.columns, hasLength(4));
      expect(archivedSocks.columns.map((c) => c.nameInSql),
          ['name', 'id', 'archived_by', 'archived_on']);

      final pkFromTable =
          archivedSocks.tableConstraints.whereType<PrimaryKeyColumns>().first;
      expect(pkFromTable.primaryKey.map((e) => e.nameInSql), ['id']);
    });
  });

  test('reports errors around suspicous customConstraint uses', () async {
    final result = await findTable('InvalidConstraints');

    expect(
      result!.errorsDuringAnalysis,
      containsAll(
        [
          isDriftError(allOf(contains('both drift-defined constraints'),
                  contains('and a customConstraint()')))
              .withSpan('a'),
          isDriftError(contains(
                  "You've already set custom constraints on this column"))
              .withSpan('customConstraint'),
        ],
      ),
    );
  });
}
