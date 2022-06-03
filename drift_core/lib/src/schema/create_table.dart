import '../builder/context.dart';
import '../schema.dart';

// todo: Database-specific features like column constraints?
class CreateTableStatement extends SqlComponent {
  final SchemaTable table;

  CreateTableStatement(this.table);

  @override
  void writeInto(GenerationContext context) {
    context.buffer
      ..write('CREATE TABLE ')
      ..write(context.identifier(table.tableName))
      ..write('(');

    var first = true;
    for (final column in table.columns) {
      if (!first) {
        context.buffer.write(', ');
      }
      first = false;

      context.buffer
        ..write(context.identifier(column.name))
        ..write(' ')
        ..write(column.type.name);
    }

    context.buffer.write(')');
  }
}
