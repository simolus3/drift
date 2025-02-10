import 'column.dart';
import 'result_set.dart';

abstract base class GeneratedTable<Row extends Object,
    Self extends GeneratedTable<Row, Self>> extends ResultSet<Row, Self> {
  GeneratedTable({required super.entityName, required super.alias});
}

final class TableColumn<T extends Object> extends SchemaColumn<T> {
  TableColumn({required super.name, required super.type});
}
