import 'package:drift3_preview/drift.dart';

import 'compiler.dart';

/// Enumeration of different insert behaviors. See the documentation on the
/// individual fields for details.
enum InsertMode {
  /// A regular `INSERT INTO` statement. When a row with the same primary or
  /// unique key already exists, the insert statement will fail and an exception
  /// will be thrown. If the exception is caught, previous statements made in
  /// the same transaction will NOT be reverted.
  insert,

  /// Identical to [InsertMode.insertOrReplace], included for the sake of
  /// completeness.
  replace,

  /// Like [insert], but if a row with the same primary or unique key already
  /// exists, it will be deleted and re-created with the row being inserted.
  insertOrReplace,

  /// Similar to [InsertMode.insertOrAbort], but it will revert the surrounding
  /// transaction if a constraint is violated, even if the thrown exception is
  /// caught.
  insertOrRollback,

  /// Identical to [insert], included for the sake of completeness.
  insertOrAbort,

  /// Like [insert], but if multiple values are inserted with the same insert
  /// statement and one of them fails, the others will still be completed.
  insertOrFail,

  /// Like [insert], but failures will be ignored.
  insertOrIgnore,
}

/// Provides the SQLite-specific [mode] function for insert statements.
extension SetInsertMode<Row extends Object, RS extends GeneratedTable<Row, RS>>
    on InsertStatement<Row, RS> {
  /// Applies the [InsertMode] for this statement.
  ///
  /// This is a SQLite-specific API that can be used to customize how the insert
  /// statement behaves with conflicts. For a variant that is better suited for
  /// different SQL dialects, see [DoUpdate].
  InsertStatement<Row, RS> mode(InsertMode mode) {
    dialectSpecificOptions[insertModeKey] = mode;
    return this;
  }
}

/// Extension methods for [Batch] to create insert statements with custom
/// [InsertMode]s.
extension InsertWithMode on Batch {
  /// A variant of [Batch.insert] that supports an [InsertMode] argument.
  BatchedStatement
  insertMode<Row extends Object, RS extends GeneratedTable<Row, RS>>(
    InsertMode mode,
    GeneratedTable<Row, RS> table,
    Insertable<Row> row, {
    UpsertClause<Row, RS>? onConflict,
  }) {
    final stmt = InsertStatement<Row, RS>(database, table)
      ..values(row)
      ..mode(mode);
    if (onConflict != null) {
      stmt.onConflict(onConflict);
    }

    return addStatement(stmt);
  }

  /// A variant of [Batch.insertFromSelect] that supports an [InsertMode]
  /// argument.
  BatchedStatement
  insertFromSelectMode<Row extends Object, RS extends GeneratedTable<Row, RS>>(
    InsertMode mode,
    GeneratedTable<Row, RS> table,
    BaseSelectStatement select, {
    required Map<TableColumn, Expression> columns,
    UpsertClause<Row, RS>? onConflict,
  }) {
    final stmt = InsertStatement<Row, RS>(
      database,
      table,
    ).fromSelect(select, columns: columns).mode(mode);
    if (onConflict != null) {
      stmt.onConflict(onConflict);
    }

    return addStatement(stmt);
  }

  /// Inserts all [rows] into the [table].
  ///
  /// Using [insertAll] will not disable primary keys or any column constraint
  /// checks.
  ///
  /// [onConflict] can be used to create an upsert clause for engines that
  /// support it. For details and examples, see [InsertStatement.insert].
  void insertAllMode<Row extends Object, RS extends GeneratedTable<Row, RS>>(
    InsertMode mode,
    GeneratedTable<Row, RS> table,
    Iterable<Insertable<Row>> rows, {
    UpsertClause<Row, RS>? onConflict,
  }) {
    for (final row in rows) {
      insertMode<Row, RS>(mode, table, row, onConflict: onConflict);
    }
  }
}

/// Extension on [TableStatements] that support [InsertMode].
extension InsertModeTableStatements<
  Row extends Object,
  RS extends GeneratedTable<Row, RS>
>
    on TableOrViewStatements<Row, RS> {
  /// A variant of [TableStatements.insertOne] that supports an [InsertMode]
  /// argument.
  Future<int> insertOneMode(
    InsertMode mode,
    Insertable<Row> row, {
    UpsertClause<Row, RS>? onConflict,
  }) {
    return insert().mode(mode).insert(row, onConflict: onConflict);
  }

  /// A variant of [TableStatements.insertAll] that supports an [InsertMode]
  /// argument.
  Future<void> insertAllMode(
    InsertMode mode,
    Iterable<Insertable<Row>> rows, {
    UpsertClause<Row, RS>? onConflict,
  }) {
    // ignore: invalid_use_of_internal_member
    return database.transaction(
      options: const TransactionOptions(deferForeignKeys: true),
      () async {
        // ignore: invalid_use_of_internal_member
        await database.batch((b) {
          // ignore: invalid_use_of_internal_member
          b.insertAllMode(mode, resultSet, rows, onConflict: onConflict);
        });
      },
    );
  }

  /// A variant of [TableStatements.insertReturning] that supports an
  /// [InsertMode] argument.
  Future<Row> insertReturningMode(
    InsertMode mode,
    Insertable<Row> row, {
    UpsertClause<Row, RS>? onConflict,
  }) {
    return insert().mode(mode).insertReturning(row, onConflict: onConflict);
  }
}
