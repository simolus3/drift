import 'package:meta/meta.dart';

import 'expressions/column.dart';
import 'expressions/expression.dart';
import 'statements/select.dart';
import 'types.dart';

abstract class SchemaEntity {
  String get schemaName;
}

abstract class SchemaColumn<T> {
  EntityWithResult get entity;

  String get name;
  SqlType<T> get type;

  Expression<T> call([String? tableOrViewAlias]) {
    return ColumnReference(this, tableOrViewAlias);
  }
}

/// Base classes for schema entity with a result set.
///
/// This includes tables and views.
abstract class EntityWithResult implements SchemaEntity {
  List<SchemaColumn> get columns;
}

abstract class SchemaTable extends EntityWithResult {
  String get tableName;

  @override
  String get schemaName => tableName;

  @protected
  SchemaColumn<T> column<T>(String name, SqlType<T> type) {
    return _SchemaColumn(this, name, type);
  }

  SelectColumn star([String? tableAlais]) {
    return StarColumn(this, tableAlais);
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
