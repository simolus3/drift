import 'package:meta/meta.dart';

import 'types.dart';

abstract class SchemaEntity {
  String get name;
}

abstract class SchemaColumn<T> {
  SchemaEntity get entity;

  String get name;
  SqlType<T> get type;
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
  final SchemaEntity entity;
  @override
  final String name;
  @override
  final SqlType<T> type;

  _SchemaColumn(this.entity, this.name, this.type);
}
