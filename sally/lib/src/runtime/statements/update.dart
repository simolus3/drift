import 'package:sally/sally.dart';
import 'package:sally/src/runtime/components/component.dart';

class UpdateStatement<T, D> extends Query<T, D> {
  UpdateStatement(GeneratedDatabase database, TableInfo<T, D> table)
      : super(database, table);

  /// The object to update. The non-null fields of this object will be written
  /// into the rows matched by [whereExpr] and [limitExpr].
  D _updateReference;

  @override
  void writeStartPart(GenerationContext ctx) {
    // TODO support the OR (ROLLBACK / ABORT / REPLACE / FAIL / IGNORE...) thing

    final map = table.entityToSql(_updateReference)
      ..remove((_, value) => value == null);

    ctx.buffer.write('UPDATE ${table.$tableName} SET ');

    var first = true;
    map.forEach((columnName, variable) {
      if (!first) {
        ctx.writeWhitespace();
      } else {
        first = false;
      }

      ctx.buffer..write(columnName)..write(' = ');

      variable.writeInto(ctx);
    });
  }

  /// Writes all non-null fields from [entity] into the columns of all rows
  /// that match the set [where] and [limit] constraints. Warning: That also
  /// means that, when you're not setting a where or limit expression
  /// explicitly, this method will update all rows in the specific table.
  Future<int> write(D entity) async {
    _updateReference = entity;
    if (!table.validateIntegrity(_updateReference, false)) {
      throw InvalidDataException('Invalid data: $entity cannot be written into ${table.$tableName}');
    }

    final ctx = constructQuery();
    final rows = await ctx.database.executor.runUpdate(ctx.sql, ctx.boundVariables);

    if (rows > 0) {
      database.markTableUpdated(table.$tableName);
    }

    return rows;
  }
}
