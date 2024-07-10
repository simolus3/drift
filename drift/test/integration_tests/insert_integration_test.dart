import 'package:async/async.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:test/test.dart';

import '../generated/todos.dart';
import '../skips.dart';
import '../test_utils/test_utils.dart';

void main() {
  late TodoDb db;

  setUp(() {
    db = TodoDb(testInMemoryDatabase());
  });

  tearDown(() => db.close());

  test('insertOnConflictUpdate', () async {
    await db.into(db.categories).insert(
        CategoriesCompanion.insert(description: 'original description'));

    var row = await db.select(db.categories).getSingle();

    await db.into(db.categories).insertOnConflictUpdate(CategoriesCompanion(
        id: Value(row.id), description: const Value('changed description')));

    row = await db.select(db.categories).getSingle();
    expect(row.description, 'changed description');
  });

  test('insert with DoUpdate and excluded row', () async {
    await db.into(db.categories).insert(
        CategoriesCompanion.insert(description: 'original description'));

    var row = await db.select(db.categories).getSingle();

    await db.into(db.categories).insert(
        CategoriesCompanion(
          id: Value(row.id),
          description: const Value('new description'),
        ),
        onConflict: DoUpdate.withExcluded(
          (old, excluded) => CategoriesCompanion.custom(
              description:
                  old.description + const Constant(' ') + excluded.description),
        ));

    row = await db.select(db.categories).getSingle();
    expect(row.description, 'original description new description');
  });

  test('insert with DoUpdate and excluded row and where statement true',
      () async {
    await db.into(db.categories).insert(
        CategoriesCompanion.insert(description: 'original description'));

    var row = await db.select(db.categories).getSingle();

    await db.into(db.categories).insert(
        CategoriesCompanion(
          id: Value(row.id),
          priority: const Value(CategoryPriority.medium),
          description: const Value('new description'),
        ),
        onConflict: DoUpdate.withExcluded(
            (old, excluded) => CategoriesCompanion.custom(
                description: old.description +
                    const Constant(' ') +
                    excluded.description),
            where: (old, excluded) =>
                excluded.priority.isBiggerOrEqual(old.priority)));

    row = await db.select(db.categories).getSingle();
    expect(row.description, 'original description new description');
  });

  test('insert with DoUpdate and excluded row and where statement false',
      () async {
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          priority: Value(CategoryPriority.medium),
          description: 'original description',
        ));

    var row = await db.select(db.categories).getSingle();

    await db.into(db.categories).insert(
        CategoriesCompanion(
          id: Value(row.id),
          priority: const Value(CategoryPriority.low),
          description: const Value('new description'),
        ),
        onConflict: DoUpdate.withExcluded(
            (old, excluded) => CategoriesCompanion.custom(
                description: old.description +
                    const Constant(' ') +
                    excluded.description),
            where: (old, excluded) =>
                excluded.priority.isBiggerOrEqual(old.priority)));

    row = await db.select(db.categories).getSingle();
    expect(row.description, 'original description');
  });

  group('returning', () {
    test('simple', () async {
      final entry = await db.into(db.categories).insertReturning(
          CategoriesCompanion.insert(description: 'Description'));

      expect(
        entry,
        const Category(
          id: RowId(1),
          description: 'Description',
          priority: CategoryPriority.low,
          descriptionInUpperCase: 'DESCRIPTION',
        ),
      );
    });

    test('when no row gets returned', () async {
      final entry = await db.into(db.categories).insertReturning(
          CategoriesCompanion.insert(description: 'Description'));

      // The failed inserts also shouldn't trigger stream query updates.
      final updates = StreamQueue(db.tableUpdates());
      expect(updates, neverEmits(anything));

      await expectLater(
        db.into(db.categories).insertReturning(
              CategoriesCompanion.insert(
                id: Value(entry.id),
                description: 'Attempted overwrie',
              ),
              mode: InsertMode.insertOrIgnore,
            ),
        throwsA(isStateError.having((e) => e.message, 'message',
            contains('Please use insertReturningOrNull()'))),
      );

      await expectLater(
        db.into(db.categories).insertReturningOrNull(
              CategoriesCompanion.insert(
                id: Value(entry.id),
                description: 'Attempted overwrie',
              ),
              mode: InsertMode.insertOrIgnore,
            ),
        completion(isNull),
      );

      await expectLater(
        db.categories.insertReturningOrNull(
          CategoriesCompanion.insert(
            id: Value(entry.id),
            description: 'Attempted overwrie',
          ),
          mode: InsertMode.insertOrIgnore,
        ),
        completion(isNull),
      );

      await updates.cancel(immediate: true);
    });
  }, skip: ifOlderThanSqlite335(sqlite3Version));

  test('generates working check constraints', () async {
    // creationTime has a constraint ensuring that the value must be larger than
    // 1950.
    expect(
        db.into(db.users).insert(
              UsersCompanion.insert(
                name: 'user name',
                profilePicture: Uint8List(0),
                creationTime: Value(DateTime(1949)),
              ),
            ),
        throwsException);

    expect(
        db.into(db.users).insert(
              UsersCompanion.insert(
                name: 'user name',
                profilePicture: Uint8List(0),
                creationTime: Value(DateTime(1960)),
              ),
            ),
        completes);
  });

  test('insert and select BigInt', () async {
    await db.into(db.tableWithoutPK).insert(CustomRowClass.map(1, 0,
            webSafeInt: BigInt.parse('9223372036854775807'),
            custom: MyCustomObject('custom'))
        .toInsertable());

    final row = await db.select(db.tableWithoutPK).getSingle();
    expect(row.webSafeInt, BigInt.parse('9223372036854775807'));
  });

  group('insertAll', () {
    late CustomTable table;

    setUp(() async {
      table = CustomTable('tbl', db, [
        GeneratedColumn('id', 'tbl', false,
            type: DriftSqlType.int,
            defaultConstraints:
                GeneratedColumn.constraintIsAlways('PRIMARY KEY')),
        GeneratedColumn('parent', 'tbl', true,
            type: DriftSqlType.int,
            defaultConstraints:
                GeneratedColumn.constraintIsAlways('REFERENCES tbl (id)')),
      ]);

      await db.customStatement('pragma foreign_keys = on;');
      await db.createMigrator().create(table);
    });

    test('does not require foreign keys to be ordered', () async {
      await table.insertAll([
        RawValuesInsertable({'id': Variable(3), 'parent': Variable(4)}),
        RawValuesInsertable({'id': Variable(4), 'parent': Variable(null)}),
      ]);

      final stillEnabled =
          (await db.customSelect('PRAGMA defer_foreign_keys').getSingle())
              .read<bool>('defer_foreign_keys');
      expect(stillEnabled, isFalse);

      final rows = await table.select().get();
      expect(rows, hasLength(2));
    });

    test('throws an exception if foreign keys are not met', () async {
      await expectLater(
        table.insertAll([
          RawValuesInsertable({'id': Variable(3), 'parent': Variable(4)}),
          RawValuesInsertable({'id': Variable(44), 'parent': Variable(null)}),
        ]),
        throwsA(isException),
      );
    });
  });

  group('insert from select', () {
    test('simple', () async {
      await db.todosTable
          .insertOne(TodosTableCompanion.insert(content: 'my content'));

      final query = db.select(db.todosTable);
      await db.into(db.todosTable).insertFromSelect(query, columns: {
        db.todosTable.content: db.todosTable.content,
      });

      final entries = await db.todosTable.all().get();
      expect(entries, hasLength(2));
    });

    test('join', () async {
      await db.categories
          .insertOne(CategoriesCompanion.insert(description: 'without entry'));
      final id = await db.categories
          .insertOne(CategoriesCompanion.insert(description: 'with entry'));
      await db.todosTable.insertOne(TodosTableCompanion.insert(
          content: 'my content', category: Value(RowId(id))));

      final amountOfTodos =
          db.todosTable.id.count(filter: db.todosTable.id.isNotNull());
      final newDescription = db.categories.description + amountOfTodos.cast();
      final query = db.selectOnly(db.categories)
        ..join([
          leftOuterJoin(
              db.todosTable, db.categories.id.equalsExp(db.todosTable.category))
        ])
        ..groupBy([db.categories.id])
        ..addColumns([newDescription, db.categories.priority]);

      await db.into(db.categories).insertFromSelect(query, columns: {
        db.categories.description: newDescription,
        db.categories.priority: db.categories.priority,
      });

      final categeories = await db.categories.all().get();
      expect(categeories.map((e) => e.description),
          ['without entry', 'with entry', 'without entry0', 'with entry1']);
    });
  });
}
