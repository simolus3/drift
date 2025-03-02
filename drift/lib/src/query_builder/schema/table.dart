import 'package:drift/src/dsl/table.dart';

import 'column.dart';
import 'column_constraints.dart';
import 'result_set.dart';

abstract interface class GeneratedTable<Row extends Object,
        Self extends GeneratedTable<Row, Self>> extends Table
    implements ResultSet<Row, Self> {}

final class TableColumn<T extends Object> extends SchemaColumn<T> {
  /// Whether this column is required when inserting new rows into the table.
  ///
  /// All non-nullable columns that don't have a default value or are part of
  /// an auto-incrementing primary key are required.
  final bool requiredDuringInsert;

  /// Constraints that have been applied to this column.
  ///
  /// This reflects the actual syntactic column constraints to apply to the
  /// definition for this column in SQL. For instance, a single-column primary
  /// key defined by overriding the [Table.primaryKey] getter will _not_ add a
  /// [ColumnPrimaryKeyConstraint] to this column.
  final List<ColumnConstraint> constraints;

  TableColumn({
    required super.name,
    required super.type,
    super.isNullable,
    this.requiredDuringInsert = true,
    this.constraints = const [],
  });
}
