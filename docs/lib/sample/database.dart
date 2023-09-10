import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:rxdart/rxdart.dart';

part 'database.g.dart';

enum TodoListFilter { all, active, completed }

class TodoItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get description => text()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
}

@DriftDatabase(tables: [TodoItems])
class Database extends _$Database {
  final BehaviorSubject<TodoListFilter> _filterChanges =
      BehaviorSubject.seeded(TodoListFilter.all);

  Database(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();

        // Create some entries by default
        await batch((b) {
          b.insertAll(todoItems, [
            TodoItemsCompanion.insert(description: 'Migrate to drift'),
            TodoItemsCompanion.insert(description: 'Support all platforms'),
            TodoItemsCompanion.insert(
                description: 'Solve local persistence issues'),
          ]);
        });
      },
    );
  }

  TodoListFilter get currentFilter => _filterChanges.value;

  set currentFilter(TodoListFilter value) {
    _filterChanges.add(value);
  }

  Stream<List<TodoItem>> get items => _filterChanges.stream.switchMap(_items);

  Stream<int> get uncompletedItems {
    final all = countAll();
    final query = selectOnly(todoItems)
      ..addColumns([all])
      ..where(todoItems.completed.not());

    return query.map((row) => row.read(all)!).watchSingle();
  }

  Stream<List<TodoItem>> _items(TodoListFilter filter) {
    final query = todoItems.select();

    switch (filter) {
      case TodoListFilter.completed:
        query.where((row) => row.completed);
      case TodoListFilter.active:
        query.where((row) => row.completed.not());
      case TodoListFilter.all:
        break;
    }

    return query.watch();
  }

  Future<void> toggleCompleted(TodoItem item) async {
    final statement = update(todoItems)..whereSamePrimaryKey(item);
    await statement.write(TodoItemsCompanion.custom(
      completed: todoItems.completed.not(),
    ));
  }
}

Future<WasmDatabaseResult> connect() async {
  final result = await WasmDatabase.open(
    databaseName: 'todo_example',
    sqlite3Uri: Uri.parse('sqlite3.wasm'),
    driftWorkerUri: Uri.parse('/drift_worker.dart.js'),
  );

  if (!result.chosenImplementation.fullySupported) {
    print('Using ${result.chosenImplementation} due to unsupported browser '
        'features: ${result.missingFeatures}');
  }

  return result;
}

extension CompatibilityUI on WasmStorageImplementation {
  bool get fullySupported =>
      this != WasmStorageImplementation.inMemory &&
      this != WasmStorageImplementation.unsafeIndexedDb;
}
