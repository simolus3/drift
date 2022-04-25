import 'package:drift/drift.dart';
import 'tables/filename.dart';

extension GroupByQueries on MyDatabase {
  // #docregion countTodosInCategories
  Future<void> countTodosInCategories() async {
    final amountOfTodos = todos.id.count();

    final query = select(categories).join([
      innerJoin(
        todos,
        todos.category.equalsExp(categories.id),
        useColumns: false,
      )
    ]);
    query
      ..addColumns([amountOfTodos])
      ..groupBy([categories.id]);

    final result = await query.get();

    for (final row in result) {
      print('there are ${row.read(amountOfTodos)} entries in'
          '${row.readTable(categories)}');
    }
  }
  // #enddocregion countTodosInCategories

  // #docregion averageItemLength
  Stream<double> averageItemLength() {
    final avgLength = todos.content.length.avg();
    final query = selectOnly(todos)..addColumns([avgLength]);

    return query.map((row) => row.read(avgLength)!).watchSingle();
  }
  // #enddocregion averageItemLength
}
