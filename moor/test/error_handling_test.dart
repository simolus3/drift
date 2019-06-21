import 'package:moor/moor.dart';
import 'package:test_api/test_api.dart';

import 'data/tables/todos.dart';
import 'data/utils/mocks.dart';

// the content is set to non-null and the title must be between 4 and 16 chars
// long
final nullContent = const TodosTableCompanion(
    title: Value.use('Test'), content: Value.use(null));
final absentContent = const TodosTableCompanion(
    title: Value.use('Test'), content: Value.absent());
final shortTitle = TodoEntry(title: 'A', content: 'content');
final longTitle = TodoEntry(title: 'A ${'very' * 5} long title', content: 'hi');
final valid = TodoEntry(title: 'Test', content: 'Some content');

void main() {
  TodoDb db;
  MockExecutor executor;

  setUp(() {
    executor = MockExecutor();
    db = TodoDb(executor);
  });

  test('detects errors on insert', () {
    expect(
      () => db.into(db.todosTable).insert(nullContent),
      throwsA(predicate<InvalidDataException>(
          (e) => e.message.contains('not nullable'))),
    );
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
