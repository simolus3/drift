import 'dart:async';

import 'package:meta/meta.dart';
import 'package:moor/moor.dart';
import 'package:moor/src/runtime/components/component.dart';

class InsertStatement<D extends DataClass> {
  @protected
  final QueryEngine database;
  @protected
  final TableInfo<Table, D> table;

  InsertStatement(this.database, this.table);

  /// Inserts a row constructed from the fields in [entity].
  ///
  /// All fields in the entity that don't have a default value or auto-increment
  /// must be set and non-null. Otherwise, an [InvalidDataException] will be
  /// thrown.
  ///
  /// If [orReplace] is true and a row with the same primary key already exists,
  /// the columns of that row will be updated and now new row will be written.
  /// Otherwise, an exception will be thrown.
  ///
  /// If the table contains an auto-increment column, the generated value will
  /// be returned. If there is no auto-increment column, you can't rely on the
  /// return value, but the future will resolve to an error when the insert
  /// fails.
  Future<int> insert(Insertable<D> entity, {bool orReplace = false}) async {
    _validateIntegrity(entity);
    final ctx = _createContext(entity, orReplace);

    return await database.executor.doWhenOpened((e) async {
      final id = await database.executor.runInsert(ctx.sql, ctx.boundVariables);
      database.markTablesUpdated({table});
      return id;
    });
  }

  /// Inserts all [rows] into the table.
  ///
  /// All fields in a row that don't have a default value or auto-increment
  /// must be set and non-null. Otherwise, an [InvalidDataException] will be
  /// thrown.
  /// When a row with the same primary or unique key already exists in the
  /// database, the insert will fail. Use [orReplace] to replace rows that
  /// already exist.
  Future<void> insertAll(List<Insertable<D>> rows,
      {bool orReplace = false}) async {
    final statements = <String, List<GenerationContext>>{};

    // Not every insert has the same sql, as fields which are set to null are
    // not included. So, we have a map for sql -> list of variables which we can
    // then turn into prepared statements
    for (var row in rows) {
      _validateIntegrity(row);

      final ctx = _createContext(row, orReplace);
      statements.putIfAbsent(ctx.sql, () => []).add(ctx);
    }

    final batchedStatements = statements.entries.map((e) {
      final vars = e.value.map((context) => context.boundVariables).toList();
      return BatchedStatement(e.key, vars);
    }).toList(growable: false);

    await database.executor.doWhenOpened((e) async {
      await e.runBatched(batchedStatements);
    });
    database.markTablesUpdated({table});
  }

  GenerationContext _createContext(Insertable<D> entry, bool replace) {
    final map = table.entityToSql(entry.createCompanion(true))
      ..removeWhere((_, value) => value == null);

    final ctx = GenerationContext.fromDb(database);
    ctx.buffer
      ..write('INSERT ')
      ..write(replace ? 'OR REPLACE ' : '')
      ..write('INTO ')
      ..write(table.$tableName)
      ..write(' ');

    if (map.isEmpty) {
      ctx.buffer.write('DEFAULT VALUES');
    } else {
      ctx.buffer
        ..write('(')
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
    }

    return ctx;
  }

  void _validateIntegrity(Insertable<D> d) {
    if (d == null) {
      throw InvalidDataException(
          'Cannot write null row into ${table.$tableName}');
    }

    table
        .validateIntegrity(d.createCompanion(true), isInserting: true)
        .throwIfInvalid(d);
  }
}
