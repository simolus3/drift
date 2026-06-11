// ignore_for_file: unused_local_variable

import 'package:drift3/drift.dart';
import 'package:drift_sqlite/drift_sqlite.dart';
import 'package:test/test.dart';

import 'database.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late TestDatabase db;

  setUp(() {
    db = TestDatabase.inMemory();
  });

  tearDown(() => db.close());

  test('manager - create', () async {
    // Initial count should be 0
    expect(await db.managers.categories.count(), 0);

    // Creating a row should return the id
    final create1 = db.managers.categories.create(
      (o) => o(priority: Value(CategoryPriority.high), description: "High"),
    );
    expect(await create1, 1);
    expect(await db.managers.categories.count(), 1);

    // Creating another row should increment the id
    final create2 = db.managers.categories.create(
      (o) => o(priority: Value(CategoryPriority.low), description: "Low"),
    );
    expect(await create2, 2);
    expect(await db.managers.categories.count(), 2);

    // Using an existing id should throw an exception
    final create3 = db.managers.categories.create(
      (o) => o(
        priority: Value(CategoryPriority.medium),
        description: "Medium",
        id: Value(1),
      ),
    );
    expect(create3, throwsException);

    // Using on conflict should not throw an exception
    // Only using DoNothing test that onConflict is being passed to the create method
    final create4 = db.managers.categories.create(
      (o) => o(
        priority: Value(CategoryPriority.medium),
        description: "Medium",
        id: Value(1),
      ),
      onConflict: DoNothing(),
    );
    // The is incorrect when using onConflict
    expect(await create4, 2);
    expect(await db.managers.categories.count(), 2);

    // Likewise, test that mode is passed to the create method
    final create5 = db.managers.categories.create(
      (o) => o(
        priority: Value(CategoryPriority.medium),
        description: "Medium",
        id: Value(1),
      ),
      mode: InsertMode.insertOrIgnore,
    );

    // The is incorrect when using mode
    expect(await create5, 2);
    expect(await db.managers.categories.count(), 2);

    // Test the other create methods
    final create6 = db.managers.categories.createReturning(
      (o) =>
          o(priority: Value(CategoryPriority.high), description: "Other High"),
    );
    expect(await create6, isA<Category>());
    expect(await db.managers.categories.count(), 3);

    // Will return null because the description is not unique
    final create7 = db.managers.categories.createReturningOrNull(
      (o) => o(priority: Value(CategoryPriority.high), description: "High"),
      mode: InsertMode.insertOrIgnore,
    );
    expect(await create7, null);

    // Test batch create
    final batch = await db.managers.categories.bulkCreate(
      returning: true,
      (o) => [
        o(priority: Value(CategoryPriority.high), description: "Super High"),
        o(priority: Value(CategoryPriority.low), description: "Super Low"),
        o(
          priority: Value(CategoryPriority.medium),
          description: "Super Medium",
        ),
      ],
    );
    expect(await db.managers.categories.count(), 6);
    expect(batch, [
      Category(
        id: 5,
        description: 'Super High',
        priority: .high,
        descriptionInUpperCase: 'SUPER HIGH',
      ),
      Category(
        id: 6,
        description: 'Super Low',
        priority: .low,
        descriptionInUpperCase: 'SUPER LOW',
      ),
      Category(
        id: 7,
        description: 'Super Medium',
        priority: .medium,
        descriptionInUpperCase: 'SUPER MEDIUM',
      ),
    ]);
  });

  test('manager - update', () async {
    // Create a row
    final obj1 = await db.managers.categories.createReturning(
      (o) => o(priority: Value(CategoryPriority.low), description: "Low"),
    );
    final obj2 = await db.managers.categories.createReturning(
      (o) => o(priority: Value(CategoryPriority.low), description: "Other Low"),
    );

    // Replace the row
    final update1 = db.managers.categories.replace(
      obj1.copyWith(description: "Hello"),
    );
    expect(await update1, true);
    expect(
      await db.managers.categories
          .filter(((f) => f.id(obj1.id)))
          .getSingle()
          .then((value) => value.description),
      "Hello",
    );

    // Bulk Replace
    final rows = await db.managers.categories.bulkReplace(returning: true, [
      obj1.copyWith(description: "Hello"),
      obj2.copyWith(description: "World"),
    ]);
    expect(
      await db.managers.categories
          .filter(((f) => f.id(obj1.id)))
          .getSingle()
          .then((value) => value.description),
      "Hello",
    );
    expect(
      await db.managers.categories
          .filter(((f) => f.id(obj2.id)))
          .getSingle()
          .then((value) => value.description),
      "World",
    );
    expect(rows.map((r) => r.description), ['Hello', 'World']);

    // Update All Rows
    final update2 = db.managers.categories.update(
      (o) => o(priority: Value(CategoryPriority.high)),
    );
    expect(await update2, 2);

    // Update a single row
    final update3 = db.managers.categories
        .filter(((f) => f.id(obj2.id)))
        .update((o) => o(description: Value("World")));
    expect(await update3, 1);
    expect(
      await db.managers.categories
          .filter(((f) => f.id(obj2.id)))
          .getSingle()
          .then((value) => value.description),
      "World",
    );
  });

  test('manager - delete', () async {
    // Create a row
    final obj1 = await db.managers.categories.createReturning(
      (o) => o(priority: Value(CategoryPriority.low), description: "Low"),
    );
    final obj2 = await db.managers.categories.createReturning(
      (o) => o(priority: Value(CategoryPriority.low), description: "Other Low"),
    );

    // Delete a single row
    final delete1 = db.managers.categories
        .filter(((f) => f.id(obj1.id)))
        .delete();
    expect(await delete1, 1);
    expect(await db.managers.categories.count(), 1);

    // Delete all rows
    final delete2 = db.managers.categories.delete();
    expect(await delete2, 1);
    expect(await db.managers.categories.count(), 0);
  });
}
