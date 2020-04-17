part of '../query_builder.dart';

/// Represents an insert statements
class InsertStatement<T extends Table, D extends DataClass> {
  /// The database to use then executing this statement
  @protected
  final QueryEngine database;

  /// The table we're inserting into
  @protected
  final TableInfo<T, D> table;

  /// Constructs an insert statement from the database and the table. Used
  /// internally by moor.
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
  ///
  /// If the table contains an auto-increment column, the generated value will
  /// be returned. If there is no auto-increment column, you can't rely on the
  /// return value, but the future will complete with an error if the insert
  /// fails.
  Future<int> insert(
    Insertable<D> entity, {
    InsertMode mode,
    DoUpdate<T, D> onConflict,
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

  /// Creates a [GenerationContext] which contains the sql necessary to run an
  /// insert statement fro the [entry] with the [mode].
  ///
  /// This method is used internally by moor. Consider using [insert] instead.
  GenerationContext createContext(Insertable<D> entry, InsertMode mode,
      {DoUpdate onConflict}) {
    _validateIntegrity(entry);

    final rawValues = entry.toColumns(true);

    // apply default values for columns that have one
    final map = <String, Expression>{};
    for (final column in table.$columns) {
      final columnName = column.$name;

      if (rawValues.containsKey(columnName)) {
        map[columnName] = rawValues[columnName];
      } else {
        if (column.clientDefault != null) {
          map[columnName] = column._evaluateClientDefault();
        }
      }

      // column not set, and doesn't have a client default. So just don't
      // include this column
    }

    final ctx = GenerationContext.fromDb(database);
    ctx.buffer
      ..write(_insertKeywords[mode])
      ..write(' INTO ')
      ..write(table.$tableName)
      ..write(' ');

    if (map.isEmpty) {
      ctx.buffer.write('DEFAULT VALUES');
    } else {
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

    if (onConflict != null) {
      final updateSet = onConflict._createInsertable(table).toColumns(true);

      ctx.buffer.write(' ON CONFLICT DO UPDATE SET ');

      var first = true;
      for (final update in updateSet.entries) {
        final column = escapeIfNeeded(update.key);

        if (!first) ctx.buffer.write(', ');
        ctx.buffer.write('$column = ');
        update.value.writeInto(ctx);

        first = false;
      }
    }

    return ctx;
  }

  void _validateIntegrity(Insertable<D> d) {
    if (d == null) {
      throw InvalidDataException(
          'Cannot write null row into ${table.$tableName}');
    }

    table.validateIntegrity(d, isInserting: true).throwIfInvalid(d);
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

/// A [DoUpdate] upsert clause can be used to insert or update a custom
/// companion when the underlying companion already exists.
///
/// For an example, see [InsertStatement.insert].
class DoUpdate<T extends Table, D extends DataClass> {
  final Insertable<D> Function(T old) _creator;

  /// For an example, see [InsertStatement.insert].
  DoUpdate(Insertable<D> Function(T old) update) : _creator = update;

  Insertable<D> _createInsertable(T table) {
    return _creator(table);
  }
}
