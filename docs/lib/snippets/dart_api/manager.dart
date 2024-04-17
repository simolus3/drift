import '../setup/database.dart';

extension ManagerExamples on AppDatabase {
  // #docregion create
  Future<void> createTodoItem() async {
    await managers.todoItems.create((o) => o(title: '', content: ''));
  }
  // #enddocregion create
}
