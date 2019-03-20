import 'dart:async';

import 'package:meta/meta.dart';
import 'package:moor/moor.dart';
import 'package:moor/src/runtime/components/component.dart';
import 'update.dart';

class InsertStatement<DataClass> {
  @protected
  final QueryEngine database;
  @protected
  final TableInfo<dynamic, DataClass> table;

  bool _orReplace = false;

  InsertStatement(this.database, this.table);

  /// Inserts a row constructed from the fields in [entity].
  ///
  /// All fields in the entity that don't have a default value or auto-increment
  /// must be set and non-null. Otherwise, an [InvalidDataException] will be
  /// thrown. An insert will also fail if another row with the same primary key
  /// or unique constraints already exists. If you want to override data in that
  /// case, use [insertOrReplace] instead.
  Future<void> insert(DataClass entity) async {
    if (!table.validateIntegrity(entity, true)) {
      throw InvalidDataException(
          'Invalid data: $entity cannot be written into ${table.$tableName}');
    }

    final map = table.entityToSql(entity)
      ..removeWhere((_, value) => value == null);

    final ctx = GenerationContext(database);
    ctx.buffer
      ..write('INSERT ')
      ..write(_orReplace ? 'OR REPLACE ' : '')
      ..write('INTO ')
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

    await database.executor.doWhenOpened((e) async {
      await database.executor.runInsert(ctx.sql, ctx.boundVariables);
      database.markTablesUpdated({table});
    });
  }

  // TODO insert multiple values

  /// Updates the row with the same primary key in the database or creates one
  /// if it doesn't exist.
  ///
  /// Behaves similar to [UpdateStatement.replace], meaning that all fields from
  /// [entity] will be written to override rows with the same primary key, which
  /// includes setting columns with null values back to null.
  ///
  /// However, if no such row exists, a new row will be written instead.
  Future<void> insertOrReplace(DataClass entity) async {
    _orReplace = true;
    await insert(entity);
  }
}
