import 'package:meta/meta.dart';

import 'expressions/column.dart';
import 'expressions/expression.dart';
import 'types.dart';

abstract class SchemaEntity {
  String get name;
}

abstract class SchemaColumn<T> {
  EntityWithResult get entity;

  String get name;
  SqlType<T> get type;

  Expression<T> ref([String? tableOrViewAlias]) {
    return ColumnReference(this, tableOrViewAlias);
  }
}

abstract class EntityWithResult implements SchemaEntity {
  List<SchemaColumn> get columns;
}

abstract class SchemaTable extends EntityWithResult {
  @protected
  SchemaColumn<T> column<T>(String name, SqlType<T> type) {
    return _SchemaColumn(this, name, type);
  }
}

class _SchemaColumn<T> extends SchemaColumn<T> {
  @override
  final EntityWithResult entity;
  @override
  final String name;
  @override
  final SqlType<T> type;

  _SchemaColumn(this.entity, this.name, this.type);
}
