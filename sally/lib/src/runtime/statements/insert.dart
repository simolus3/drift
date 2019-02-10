import 'package:meta/meta.dart';
import 'package:sally/sally.dart';
import 'package:sally/src/runtime/components/component.dart';

class InsertStatement<DataClass> {
  @protected
  final GeneratedDatabase database;
  @protected
  final TableInfo<dynamic, DataClass> table;

  InsertStatement(this.database, this.table);

  Future<void> insert(DataClass entity) async {
    table.validateIntegrity(entity, true);

    final map = table.entityToSql(entity)
      ..removeWhere((_, value) => value == null);

    final ctx = GenerationContext(database);
    ctx.buffer
      ..write('INSERT INTO ')
      ..write(table.$tableName)
      ..write(' (')
      ..write(map.keys.join(', '))
      ..write(') ')
      ..write('VALUES (');

    var first = true;
    for (var variable in map.values) {
      if (!first) {
        ctx.buffer.write(', ');
      }
      first = false;

      variable.writeInto(ctx);
    }

    ctx.buffer.write(')');

    return database.executor.runInsert(ctx.sql, ctx.boundVariables);
  }

  // TODO insert multiple values

}
