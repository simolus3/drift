import 'package:drift/src/dsl/table.dart';

import 'column.dart';
import 'result_set.dart';

abstract interface class GeneratedTable<Row extends Object,
        Self extends GeneratedTable<Row, Self>> extends Table
    implements ResultSet<Row, Self> {}

final class TableColumn<T extends Object> extends SchemaColumn<T> {
  TableColumn({required super.name, required super.type});
}
