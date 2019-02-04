import 'package:sally/src/runtime/components/component.dart';
import 'package:sally/src/runtime/executor/executor.dart';
import 'package:sally/src/runtime/statements/query.dart';
import 'package:sally/src/runtime/structure/table_info.dart';

class SelectStatement<UserTable, DataType> extends Query<UserTable> {
  @override
  // ignore: overridden_fields
  covariant TableInfo<UserTable, DataType> table;

  SelectStatement(GeneratedDatabase database, this.table)
      : super(database, table);

  @override
  void writeStartPart(GenerationContext ctx) {
    ctx.buffer.write('SELECT * FROM ${table.$tableName}');
  }

  /// Loads and returns all results from this select query.
  Future<List<DataType>> get() async {
    final ctx = constructQuery();

    final results =
        await ctx.database.executor.runSelect(ctx.sql, ctx.boundVariables);
    return results.map(table.map).toList();
  }
}
