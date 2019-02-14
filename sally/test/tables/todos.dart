import 'package:sally/sally.dart';

@DataClassName('TodoEntry')
class TodosTable extends Table {

  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 4, max: 6)();
  TextColumn get content => text()();

}