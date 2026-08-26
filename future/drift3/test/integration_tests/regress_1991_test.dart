import 'package:drift3_preview/drift.dart';
import 'package:test/test.dart';

import '../generated/todos.dart';
import '../test_utils.dart';

// Regression test for https://github.com/simolus3/drift/issues/1991

Future<int?> _getCategoryIdByDescription(
  TodoDb appDatabase,
  String description,
) async {
  const q = "SELECT id FROM categories WHERE desc = ?";
  final row = await appDatabase
      .customSelect(q, variables: [.withString(description)])
      .getSingleOrNull();
  return row?.read("id");
}

void main() {
  test('type inference for nullable call in async function', () async {
    final db = TodoDb(testInMemoryDatabase());
    addTearDown(db.close);

    final categoryDescription = 'category description';
    expect(await _getCategoryIdByDescription(db, categoryDescription), isNull);

    await db.categoriesQueries.insertOne(
      CategoriesCompanion.insert(description: categoryDescription),
    );

    // This worked in drift 2, but we'd have to mark read() as nullable to fix
    // this which is also annoying. At least we have a decent error message for
    // this now.
    expect(
      () => _getCategoryIdByDescription(db, categoryDescription),
      throwsA(
        isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('Tried to call read() with an unknown type (Never)'),
        ),
      ),
    );
  });
}
