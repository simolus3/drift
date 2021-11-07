part of '../query_builder.dart';

/// Represents an insert statement
class InsertStatement<T extends Table, D> {
  /// The database to use then executing this statement
  @protected
  final DatabaseConnectionUser database;

  /// The table we're inserting into
  @protected
  final TableInfo<T, D> table;

  /// Constructs an insert statement from the database and the table. Used
  /// internally by drift.
  InsertStatement(this.database, this.table);

  /// Inserts a row constructed from the fields in [entity].
  ///
  /// All fields in the entity that don't have a default value or auto-increment
  /// must be set and non-null. Otherwise, an [InvalidDataException] will be
  /// thrown.
  ///
  /// By default, an exception will be thrown if another row with the same
  /// primary key already exists. This behavior can be overridden with [mode],
  /// for instance by using [InsertMode.replace] or [InsertMode.insertOrIgnore].
  ///
  /// To apply a partial or custom update in case of a conflict, you can also
  /// use an [upsert clause](https://sqlite.org/lang_UPSERT.html) by using
  /// [onConflict].
  /// For instance, you could increase a counter whenever a conflict occurs:
  ///
  /// ```dart
  /// class Words extends Table {
  ///   TextColumn get word => text()();
  ///   IntColumn get occurrences => integer()();
  /// }
  ///
  /// Future<void> addWord(String word) async {
  ///   await into(words).insert(
  ///     WordsCompanion.insert(word: word, occurrences: 1),
  ///     onConflict: DoUpdate((old) => WordsCompanion.custom(
  ///       occurrences: old.occurrences + Constant(1),
  ///     )),
  ///   );
  /// }
  /// ```
  ///
  /// When calling `addWord` with a word not yet saved, the regular insert will
  /// write it with one occurrence. If it already exists however, the insert
  /// behaves like an update incrementing occurrences by one.
  /// Be aware that upsert clauses and [onConflict] are not available on older
  /// sqlite versions.
  ///
  /// Returns the `rowid` of the inserted row. For tables with an auto-increment
  /// column, the `rowid` is the generated value of that column. The returned
  /// value can be inaccurate when [onConflict] is set and the insert behaved
  /// like an update.
  ///
  /// If the table doesn't have a `rowid`, you can't rely on the return value.
  /// Still, the future will always complete with an error if the insert fails.
  Future<int> insert(
    Insertable<D> entity, {
    InsertMode? mode,
    UpsertClause<T, D>? onConflict,
  }) async {
    final ctx = createContext(entity, mode ?? InsertMode.insert,
        onConflict: onConflict);

    return await database.doWhenOpened((e) async {
      final id = await e.runInsert(ctx.sql, ctx.boundVariables);
      database
          .notifyUpdates({TableUpdate.onTable(table, kind: UpdateKind.insert)});
      return id;
    });
  }

  /// Inserts a row into the table, and returns a generated instance.
  ///
  /// __Note__: This uses the `RETURNING` syntax added in sqlite3 version 3.35,
  /// which is not available on most operating systems by default. When using
  /// this method, make sure that you have a recent sqlite3 version available.
  /// This is the case with `sqlite3_flutter_libs`.
  Future<D> insertReturning(Insertable<D> entity,
      {InsertMode? mode, UpsertClause<T, D>? onConflict}) async {
    final ctx = createContext(entity, mode ?? InsertMode.insert,
        onConflict: onConflict, returning: true);

    return database.doWhenOpened((e) async {
      final result = await e.runSelect(ctx.sql, ctx.boundVariables);
      database
          .notifyUpdates({TableUpdate.onTable(table, kind: UpdateKind.insert)});
      return table.map(result.single);
    });
  }

  /// Attempts to [insert] [entity] into the database. If the insert would
  /// violate a primary key or uniqueness constraint, updates the columns that
  /// are present on [entity].
  ///
  /// Note that this is subtly different from [InsertMode.replace]! When using
  /// [InsertMode.replace], the old row will be deleted and replaced with the
  /// new row. With [insertOnConflictUpdate], columns from the old row that are
  /// not present on [entity] are unchanged, and no row will be deleted.
  ///
  /// Be aware that [insertOnConflictUpdate] uses an upsert clause, which is not
  /// available on older sqlite implementations.
  Future<int> insertOnConflictUpdate(Insertable<D> entity) {
    return insert(entity, onConflict: DoUpdate((_) => entity));
  }

  /// Creates a [GenerationContext] which contains the sql necessary to run an
  /// insert statement fro the [entry] with the [mode].
  ///
  /// This method is used internally by drift. Consider using [insert] instead.
  GenerationContext createContext(Insertable<D> entry, InsertMode mode,
      {UpsertClause<T, D>? onConflict, bool returning = false}) {
    _validateIntegrity(entry);

    final rawValues = entry.toColumns(true);

    // apply default values for columns that have one
    final map = <String, Expression>{};
    for (final column in table.$columns) {
      final columnName = column.$name;

      if (rawValues.containsKey(columnName)) {
        final value = rawValues[columnName]!;
        map[columnName] = value;
      } else {
        if (column.clientDefault != null) {
          map[columnName] = column._evaluateClientDefault();
        }
      }

      // column not set, and doesn't have a client default. So just don't
      // include this column
    }

    final ctx = GenerationContext.fromDb(database);

    if (ctx.dialect == SqlDialect.postgres &&
        mode != InsertMode.insert &&
        mode != InsertMode.insertOrIgnore) {
      throw ArgumentError('$mode not supported on postgres');
    }

    ctx.buffer
      ..write(_insertKeywords[
          ctx.dialect == SqlDialect.postgres ? InsertMode.insert : mode])
      ..write(' INTO ')
      ..write(table.$tableName)
      ..write(' ');

    if (map.isEmpty) {
      ctx.buffer.write('DEFAULT VALUES');
    } else {
      writeInsertable(ctx, map);
    }

    void writeDoUpdate(DoUpdate<T, D> onConflict) {
      if (onConflict._usesExcludedTable) {
        ctx.hasMultipleTables = true;
      }
      final upsertInsertable = onConflict._createInsertable(table);

      if (!identical(entry, upsertInsertable)) {
        // We run a ON CONFLICT DO UPDATE, so make sure upsertInsertable is
        // valid for updates.
        // the identical check is a performance optimization - for the most
        // common call (insertOnConflictUpdate) we don't have to check twice.
        table
            .validateIntegrity(upsertInsertable, isInserting: false)
            .throwIfInvalid(upsertInsertable);
      }

      final updateSet = upsertInsertable.toColumns(true);

      ctx.buffer.write(' ON CONFLICT(');

      final conflictTarget = onConflict.target ?? table.$primaryKey.toList();

      if (conflictTarget.isEmpty) {
        throw ArgumentError(
            'Table has no primary key, so a conflict target is needed.');
      }

      var first = true;
      for (final target in conflictTarget) {
        if (!first) ctx.buffer.write(', ');

        // Writing the escaped name directly because it should not have a table
        // name in front of it.
        ctx.buffer.write(target.escapedName);
        first = false;
      }

      if (ctx.dialect == SqlDialect.postgres &&
          mode == InsertMode.insertOrIgnore) {
        ctx.buffer.write(') DO NOTHING ');
      } else {
        ctx.buffer.write(') DO UPDATE SET ');

        first = true;
        for (final update in updateSet.entries) {
          final column = escapeIfNeeded(update.key);

          if (!first) ctx.buffer.write(', ');
          ctx.buffer.write('$column = ');
          update.value.writeInto(ctx);

          first = false;
        }

        if (onConflict._where != null) {
          ctx.writeWhitespace();
          final where = onConflict._where!(
              table.asDslTable, table.createAlias('excluded').asDslTable);
          where.writeInto(ctx);
        }
      }
    }

    if (onConflict is DoUpdate<T, D>) {
      writeDoUpdate(onConflict);
    } else if (onConflict is UpsertMultiple<T, D>) {
      onConflict.clauses.forEach(writeDoUpdate);
    }

    if (returning) {
      ctx.buffer.write(' RETURNING *');
    } else if (ctx.dialect == SqlDialect.postgres) {
      if (table.$primaryKey.length == 1) {
        final id = table.$primaryKey.firstOrNull;
        if (id is IntType) {
          ctx.buffer.write(' RETURNING $id');
        }
      }
    }

    return ctx;
  }

  void _validateIntegrity(Insertable<D>? d) {
    if (d == null) {
      throw InvalidDataException(
          'Cannot write null row into ${table.$tableName}');
    }

    table.validateIntegrity(d, isInserting: true).throwIfInvalid(d);
  }

  /// Writes column names and values from the [map].
  @internal
  void writeInsertable(GenerationContext ctx, Map<String, Expression> map) {
    final columns = map.keys.map(escapeIfNeeded);

    ctx.buffer
      ..write('(')
      ..write(columns.join(', '))
      ..write(') ')
      ..write('VALUES (');

    var first = true;
    for (final variable in map.values) {
      if (!first) {
        ctx.buffer.write(', ');
      }
      first = false;

      variable.writeInto(ctx);
    }

    ctx.buffer.write(')');
  }
}

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

const _insertKeywords = <InsertMode, String>{
  InsertMode.insert: 'INSERT',
  InsertMode.replace: 'REPLACE',
  InsertMode.insertOrReplace: 'INSERT OR REPLACE',
  InsertMode.insertOrRollback: 'INSERT OR ROLLBACK',
  InsertMode.insertOrAbort: 'INSERT OR ABORT',
  InsertMode.insertOrFail: 'INSERT OR FAIL',
  InsertMode.insertOrIgnore: 'INSERT OR IGNORE',
};

/// A upsert clause controls how to behave when a uniqueness constraint is
/// violated during an insert.
///
/// Typically, one would use [DoUpdate] to run an update instead in this case.
abstract class UpsertClause<T extends Table, D> {}

/// A [DoUpdate] upsert clause can be used to insert or update a custom
/// companion when the underlying companion already exists.
///
/// For an example, see [InsertStatement.insert].
class DoUpdate<T extends Table, D> extends UpsertClause<T, D> {
  final Insertable<D> Function(T old, T excluded) _creator;
  final Where Function(T old, T excluded)? _where;

  final bool _usesExcludedTable;

  /// An optional list of columns to serve as an "conflict target", which
  /// specifies the uniqueness constraint that will trigger the upsert.
  ///
  /// By default, the primary key of the table will be used.
  final List<Column>? target;

  /// Creates a `DO UPDATE` clause.
  ///
  /// The [update] function will be used to construct an [Insertable] used to
  /// update an old row that prevented an insert.
  /// If you need to refer to both the old row and the row that would have
  /// been inserted, use [DoUpdate.withExcluded].
  ///
  /// The optional [where] clause can be used to disable the update based on
  /// the old value. If a [where] clause is set and it evaluates to false, a
  /// conflict will keep the old row without applying the update.
  ///
  /// For an example, see [InsertStatement.insert].
  DoUpdate(Insertable<D> Function(T old) update,
      {this.target, Expression<bool?> Function(T old)? where})
      : _creator = ((old, _) => update(old)),
        _where = where == null ? null : ((old, _) => Where(where(old))),
        _usesExcludedTable = false;

  /// Creates a `DO UPDATE` clause.
  ///
  /// The [update] function will be used to construct an [Insertable] used to
  /// update an old row that prevented an insert.
  /// It can refer to the values from the old row in the first parameter and
  /// to columns in the row that couldn't be inserted with the `excluded`
  /// parameter.
  ///
  /// The optional [where] clause can be used to disable the update based on
  /// the old value. If a [where] clause is set and it evaluates to false, a
  /// conflict will keep the old row without applying the update.
  ///
  /// For an example, see [InsertStatement.insert].
  DoUpdate.withExcluded(Insertable<D> Function(T old, T excluded) update,
      {this.target, Expression<bool?> Function(T old, T excluded)? where})
      : _creator = update,
        _usesExcludedTable = true,
        _where = where == null
            ? null
            : ((old, excluded) => Where(where(old, excluded)));

  Insertable<D> _createInsertable(TableInfo<T, D> table) {
    return _creator(table.asDslTable, table.createAlias('excluded').asDslTable);
  }
}

/// Upsert clause that consists of multiple [clauses].
///
/// The first [DoUpdate.target] matched by this upsert will be run.
class UpsertMultiple<T extends Table, D> extends UpsertClause<T, D> {
  /// All [DoUpdate] clauses that are part of this upsert.
  ///
  /// The first clause with a matching [DoUpdate.target] will be considered.
  final List<DoUpdate<T, D>> clauses;

  /// Creates an upsert consisting of multiple [DoUpdate] clauses.
  ///
  /// This requires a fairly recent sqlite3 version (3.35.0, released on 2021-
  /// 03-12).
  UpsertMultiple(this.clauses);
}
