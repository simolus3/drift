import 'package:meta/meta.dart';
import 'package:sally/sally.dart';

class InsertStatement<DataClass> {

  @protected
  final GeneratedDatabase database;
  @protected
  final TableInfo<dynamic, DataClass> table;

  InsertStatement(this.database, this.table);

  Future<void> insert(DataClass entity) async {
    table.validateIntegrity(entity, true);

    final map = table
        ..entityToSql(entity)
        .removeWhere((_, value) => value == null);

    print(map);
  }

}