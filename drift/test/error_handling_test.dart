import 'package:drift/drift.dart';
import 'package:test/test.dart';

import 'data/tables/todos.dart';
import 'test_utils/test_utils.dart';

// the content is set to non-null and the title must be between 4 and 16 chars
// long
const absentContent =
    TodosTableCompanion(title: Value('Test'), content: Value.absent());
const shortTitle =
    TodosTableCompanion(title: Value('A'), content: Value('content'));
final TodosTableCompanion longTitle = TodosTableCompanion(
    title: Value('A ${'very' * 5} long title'), content: const Value('hi'));
const valid =
    TodosTableCompanion(title: Value('Test'), content: Value('Some content'));

void main() {
  late TodoDb db;
  late MockExecutor executor;

  setUp(() {
    executor = MockExecutor();
    db = TodoDb(executor);
  });

  test('detects errors on insert', () {
    expect(
      () => db.into(db.todosTable).insert(absentContent),
      throwsA(predicate<InvalidDataException>(
          (e) => e.message.contains('was required, but'))),
    );
    expect(
      () => db.into(db.todosTable).insert(shortTitle),
      throwsA(predicate<InvalidDataException>(
          (e) => e.message.contains('Must at least be'))),
    );
    expect(
      () => db.into(db.todosTable).insert(longTitle),
      throwsA(predicate<InvalidDataException>(
          (e) => e.message.contains('Must at most be'))),
    );

    expect(db.into(db.todosTable).insert(valid), completes);
  });
}
