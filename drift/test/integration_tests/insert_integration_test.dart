import 'package:drift/drift.dart';
import 'package:test/test.dart';

import '../generated/todos.dart';
import '../skips.dart';
import '../test_utils/test_utils.dart';

void main() {
  late TodoDb db;

  setUp(() {
    db = TodoDb.connect(testInMemoryDatabase());
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
                old.priority.isBiggerOrEqual(excluded.priority)));

    row = await db.select(db.categories).getSingle();
    expect(row.description, 'original description');
  });

  test('insert with DoUpdate and excluded row and where statement false',
      () async {
    await db.into(db.categories).insert(
        CategoriesCompanion.insert(description: 'original description'));

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
                old.priority.isBiggerOrEqual(excluded.priority)));

    row = await db.select(db.categories).getSingle();
    expect(row.description, 'original description new description');
  });

  test('returning', () async {
    final entry = await db.into(db.categories).insertReturning(
        CategoriesCompanion.insert(description: 'Description'));

    expect(
      entry,
      Category(
        id: 1,
        description: 'Description',
        priority: CategoryPriority.low,
        descriptionInUpperCase: 'DESCRIPTION',
      ),
    );
  }, skip: ifOlderThanSqlite335(sqlite3Version));
}
