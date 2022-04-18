import 'package:drift_core/src/builder/context.dart';

import '../schema.dart';
import '../statements/statement.dart';
import 'expression.dart';

class ColumnReference<T> extends Expression<T> {
  final SchemaColumn<T> column;
  final String? tableAlias;

  ColumnReference(this.column, [this.tableAlias])
      : super(precedence: Precedence.primary);

  @override
  void writeInto(GenerationContext context) {
    final scope = context.requireScope<StatementScope>();
    final table = scope.findTable(column.entity, tableAlias);

    if (table == null) {
      final columnDesc =
          tableAlias == null ? column.toString() : '$tableAlias.${column.name}';

      throw ArgumentError(
        'Statement contains a reference to $columnDesc, but its table has not '
        'been added to the statement.',
      );
    }

    if (scope.readsFromMultipleTables) {
      context.buffer
        ..write(context.identifier(table.as ?? table.table.schemaName))
        ..write('.');
    }

    context.buffer.write(context.identifier(column.name));
  }
}
