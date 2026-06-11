@TestOn('dart-vm')
library;

import 'package:drift3/drift.dart';
import 'package:drift3/internal/versioned_schema.dart';
import 'package:drift_sqlite/drift_sqlite.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  const jsonObject = {
    'foo': 'bar',
    'array': ['one', 'two', 'three'],
  };

  late _TestDatabase db;

  for (final binary in [false, true]) {
    group(binary ? 'binary' : 'text', () {
      setUp(() {
        db = _TestDatabase(
          DriftConnection(
            dialect: SqliteDialect(
              options: SqliteOptions(useBinaryJsonRepresentation: binary),
            ),
            openConnection: () async =>
                SqliteConnection(sqlite3.openInMemory()),
          ),
        );
      });
      tearDown(() => db.close());

      test('array length', () async {
        final length = Variable(
          DatabaseJson(jsonObject),
        ).jsonArrayLength(r'$.array');
        final row = await db.selectExpressions([
          Variable(DatabaseJson(jsonObject)).jsonArrayLength(r'$.array'),
        ]).getSingle();
        expect(row.read(length), 3);
      });

      test('json_each', () async {
        final function = Variable(DatabaseJson(jsonObject)).jsonEach();
        final rows = await db.select(function).get();

        expect(rows, hasLength(2));

        expect(rows[0].read(function.key), DriftAny('foo'));
        expect(rows[0].read(function.value), DriftAny('bar'));
        expect(rows[0].read(function.type), 'text');
        expect(rows[0].read(function.atom), DriftAny('bar'));
        expect(rows[0].read(function.id), binary ? 9 : 2);
        expect(rows[0].read(function.parent), isNull);
        expect(rows[0].read(function.fullKey), r'$.foo');
        expect(rows[0].read(function.path), r'$');
      });

      test('json_tree', () async {
        // Make sure we can use aliases as well
        final function = Literal(DatabaseJson(jsonObject)).jsonTree();
        final parent = db.alias(function, 'parent');

        final query = db
            .selectOnly(function)
            .leftOuterJoin(parent, on: parent.id.equalsExp(function.parent))
            .addColumns([function.atom, parent.id])
            .where(function.atom.isNotNull());

        final rows = await query
            .map((row) => (row.read(function.atom), row.read(parent.id)))
            .get();

        expect(rows, [
          (DriftAny('bar'), 0),
          (DriftAny('one'), binary ? 17 : 10),
          (DriftAny('two'), binary ? 17 : 10),
          (DriftAny('three'), binary ? 17 : 10),
        ]);
      });

      group('aggregate', () {
        setUp(() async {
          await db.batch((batch) {
            batch
              ..insert(db.categories, RawValuesInsertable<RawRow>({}))
              ..insertAll(db.todos, [
                RawValuesInsertable<RawRow>({
                  'title': Variable('first title'),
                  'content': Variable('entry in category'),
                  'category': Variable(1),
                }),
                RawValuesInsertable<RawRow>({
                  'content': Variable('not in category'),
                }),
                RawValuesInsertable<RawRow>({
                  'title': Variable('second title'),
                  'content': Variable('another in category'),
                  'category': Variable(1),
                }),
              ]);
          });
        });

        test('json_group_array', () async {
          final todosId = db.todos.columnsByName['id']!;
          final categoriesId = db.categories.columnsByName['id']!;

          final query = db
              .select(db.categories)
              .leftOuterJoin(
                db.todos,
                on: db.todos.columnsByName['category']!.equalsExp(categoriesId),
              );

          final array = jsonGroupArray(
            todosId,
            orderBy: OrderBy([OrderingTerm.desc(todosId)]),
          );
          query
            ..groupBy([categoriesId])
            ..addColumns([array]);

          final row = await query.getSingle();
          expect(row.read(array)?.dartValue, [3, 1]);
        });

        test('json_group_object', () async {
          final categoriesId = db.categories.columnsByName['id']!;

          final query = db
              .select(db.categories)
              .leftOuterJoin(
                db.todos,
                on: db.todos.columnsByName['category']!.equalsExp(categoriesId),
              );

          final object = jsonGroupObject({
            db.todos.columnsByName['title']!.dartCast():
                db.todos.columnsByName['content']!,
          });
          query
            ..groupBy([categoriesId])
            ..addColumns([object]);

          final row = await query.getSingle();
          expect(row.read(object)?.dartValue, {
            'first title': 'entry in category',
            'second title': 'another in category',
          });
        });
      });
    });
  }
}

final class _TestDatabase extends GeneratedDatabase {
  _TestDatabase(super.implementation);

  @override
  DatabaseSchema get schema => DatabaseSchema([categories, todos]);

  @override
  int get schemaVersion => 1;

  late final categories = VersionedTable(
    entityName: 'categories',
    isStrict: false,
    withoutRowId: false,
    columns: [
      (name) => TableColumn(
        name: 'id',
        sqlType: BuiltinDriftType.int,
        constraints: () => [
          ColumnPrimaryKeyConstraint(isAutoIncrementing: true),
        ],
      ),
    ],
    tableConstraints: [],
  );

  late final todos = VersionedTable(
    entityName: 'todos',
    isStrict: false,
    withoutRowId: false,
    columns: [
      (name) => TableColumn(
        name: 'id',
        sqlType: BuiltinDriftType.int,
        constraints: () => [
          ColumnPrimaryKeyConstraint(isAutoIncrementing: true),
        ],
      ),
      (name) => TableColumn(name: 'category', sqlType: BuiltinDriftType.int),
      (name) => TableColumn(name: 'title', sqlType: BuiltinDriftType.int),
      (name) => TableColumn(name: 'content', sqlType: BuiltinDriftType.int),
    ],
    tableConstraints: [],
  );
}
