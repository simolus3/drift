import 'package:sally_example/database.dart';

class TodoBloc {

  final Database _db = Database();

  Stream<List<TodoEntry>> get todosForHomepage => _db.todosWithoutCategories;

  void dispose() {

  }

}