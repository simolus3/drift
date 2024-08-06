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
  /// By default, the [onConflict] clause will only consider the table's primary
  /// key. If you have additional columns with uniqueness constraints, you have
  /// to manually add them to the clause's [DoUpdate.target].
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

    return await database.withCurrentExecutor((e) async {
      final id = await e.runInsert(ctx.sql, ctx.boundVariables);
      database
          .notifyUpdates({TableUpdate.onTable(table, kind: UpdateKind.insert)});
      return id;
    });
  }

  /// Inserts rows from the [select] statement.
  ///
  /// This method creates an `INSERT INTO SELECT` statement in SQL which will
  /// insert a row into this table for each row returned by the [select]
  /// statement.
  ///
  /// The [columns] map describes which column from the select statement should
  /// be written into which column of the table. The keys of the map are the
  /// target column, and values are expressions added to the select statement.
  ///
  /// For an example, see the [documentation website](https://drift.simonbinder.eu/docs/advanced-features/joins/#using-selects-as-insert)
  @experimental
  Future<void> insertFromSelect(
    BaseSelectStatement select, {
    required Map<Column, Expression> columns,
    InsertMode mode = InsertMode.insert,
    UpsertClause<T, D>? onConflict,
  }) async {
    // To be able to reference columns by names instead of by their index like
    // normally done with `INSERT INTO SELECT`, we use a CTE. The final SQL
    // statement will look like this:
    // WITH source AS $select INSERT INTO $table (...) SELECT ... FROM source
    final ctx = GenerationContext.fromDb(database);
    const sourceCte = '_source';

    ctx.buffer.write('WITH $sourceCte AS (');
    select.writeInto(ctx);
    ctx.buffer.write(') ');

    final columnNameToSelectColumnName = <String, String>{};
    columns.forEach((key, value) {
      final name = select._nameForColumn(value);
      if (name == null) {
        throw ArgumentError.value(
            value,
            'column',
            'This column passd to insertFromSelect() was not added to the '
                'source select statement.');
      }

      columnNameToSelectColumnName[key.name] = name;
    });

    mode.writeInto(ctx);
    ctx.buffer
      ..write(' INTO ${ctx.identifier(table.aliasedName)} (')
      ..write(columnNameToSelectColumnName.keys.map(ctx.identifier).join(', '))
      ..write(') SELECT ')
      ..write(
          columnNameToSelectColumnName.values.map(ctx.identifier).join(', '))
      ..write(' FROM $sourceCte');
    _writeOnConflict(ctx, mode, null, onConflict);

    return await database.withCurrentExecutor((e) async {
      await e.runInsert(ctx.sql, ctx.boundVariables);
      database
          .notifyUpdates({TableUpdate.onTable(table, kind: UpdateKind.insert)});
    });
  }

  /// Inserts a row into the table and returns it.
  ///
  /// Depending on the [InsertMode] or the [DoUpdate] `onConflict` clause, the
  /// insert statement may not actually insert a row into the database. Since
  /// this function was declared to return a non-nullable row, it throws an
  /// exception in that case. Use [insertReturningOrNull] when performing an
  /// insert with an insert mode like [InsertMode.insertOrIgnore] or when using
  /// a [DoUpdate] with a `where` clause clause.
  Future<D> insertReturning(Insertable<D> entity,
      {InsertMode? mode, UpsertClause<T, D>? onConflict}) async {
    final row =
        await insertReturningOrNull(entity, mode: mode, onConflict: onConflict);

    if (row == null) {
      throw StateError('The insert statement did not insert any rows that '
          'could be returned. Please use insertReturningOrNull() when using a '
          '`DoUpdate` clause with `where`.');
    }

    return row;
  }

  /// Inserts a row into the table and returns it.
  ///
  /// When no row was inserted and no exception was thrown, for instance because
  /// [InsertMode.insertOrIgnore] was used or because the upsert clause had a
  /// `where` clause that didn't match, `null` is returned instead.
  Future<D?> insertReturningOrNull(Insertable<D> entity,
      {InsertMode? mode, UpsertClause<T, D>? onConflict}) async {
    final ctx = createContext(entity, mode ?? InsertMode.insert,
        onConflict: onConflict, returning: true);

    return database.withCurrentExecutor((e) async {
      final result = await e.runSelect(ctx.sql, ctx.boundVariables);
      if (result.isNotEmpty) {
        database.notifyUpdates(
            {TableUpdate.onTable(table, kind: UpdateKind.insert)});
        return table.map(result.single);
      } else {
        return null;
      }
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
  /// Note: By default, only the primary key is used for detect uniqueness
  /// violations. If you have further uniqueness constraints, please use the
  /// general [insert] method with a [DoUpdate] including those columns in its
  /// [DoUpdate.target].
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

    // The rowid is not included in the list of columns since it doesn't show
    // up in selects, but we should also add that value to the map for inserts.
    if (rawValues.containsKey('rowid')) {
      map['rowid'] = rawValues['rowid']!;
    }

    final ctx = GenerationContext.fromDb(database);
    mode.writeInto(ctx);

    ctx.buffer
      ..write(' INTO ')
      ..write(ctx.identifier(table.aliasedName))
      ..write(' ');

    if (map.isEmpty) {
      ctx.buffer.write('DEFAULT VALUES');
    } else {
      writeInsertable(ctx, map);
    }

    _writeOnConflict(ctx, mode, entry, onConflict);

    if (returning) {
      ctx.buffer.write(' RETURNING *');
    } else if (ctx.dialect == SqlDialect.postgres) {
      if (table.$primaryKey.length == 1) {
        final id = table.$primaryKey.firstOrNull;
        if (id != null && id.type == DriftSqlType.int) {
          ctx.buffer.write(' RETURNING ${id.name}');
        }
      }
    }

    return ctx;
  }

  void _writeOnConflict(
    GenerationContext ctx,
    InsertMode mode,
    Insertable<D>? originalEntry,
    UpsertClause<T, D>? onConflict,
  ) {
    void writeOnConflictConstraint(
        List<Column<Object>>? target, Expression<bool>? where) {
      if (ctx.dialect == SqlDialect.mariadb) {
        ctx.buffer.write(' ON DUPLICATE');
      } else {
        ctx.buffer.write(' ON CONFLICT');

        if (target != null && target.isEmpty) {
          // An empty list indicates that no explicit target should be generated
          // by drift, the default rules by the database will apply instead.
          return;
        }

        ctx.buffer.write('(');
        final conflictTarget = target ?? table.$primaryKey.toList();

        if (conflictTarget.isEmpty) {
          throw ArgumentError(
              'Table has no primary key, so a conflict target is needed.');
        }

        var first = true;
        for (final target in conflictTarget) {
          if (!first) ctx.buffer.write(', ');

          // Writing the escaped name directly because it should not have a table
          // name in front of it.
          ctx.buffer.write(target.escapedNameFor(ctx.dialect));
          first = false;
        }

        ctx.buffer.write(')');
      }

      if (where != null) {
        Where(where).writeInto(ctx);
      }
    }

    if (onConflict is DoUpdate<T, D>) {
      if (onConflict._usesExcludedTable) {
        ctx.hasMultipleTables = true;
      }

      final upsertInsertable = onConflict._createInsertable(table);

      if (!identical(originalEntry, upsertInsertable)) {
        // We run a ON CONFLICT DO UPDATE, so make sure upsertInsertable is
        // valid for updates.
        // the identical check is a performance optimization - for the most
        // common call (insertOnConflictUpdate) we don't have to check twice.
        table
            .validateIntegrity(upsertInsertable, isInserting: false)
            .throwIfInvalid(upsertInsertable);
      }

      final updateSet = upsertInsertable.toColumns(true);

      writeOnConflictConstraint(onConflict.target,
          onConflict._targetCondition?.call(table.asDslTable));

      if (ctx.dialect == SqlDialect.postgres &&
          mode == InsertMode.insertOrIgnore) {
        ctx.buffer.write(' DO NOTHING ');
      } else {
        if (ctx.dialect == SqlDialect.mariadb) {
          ctx.buffer.write(' KEY UPDATE ');
        } else {
          ctx.buffer.write(' DO UPDATE SET ');
        }

        var first = true;
        for (final update in updateSet.entries) {
          final column = ctx.identifier(update.key);

          if (!first) ctx.buffer.write(', ');
          ctx.buffer.write('$column = ');
          update.value.writeInto(ctx);

          first = false;
        }

        if (onConflict._where != null) {
          ctx.writeWhitespace();
          final where = onConflict._where(
              table.asDslTable, table.createAlias('excluded').asDslTable);
          where.writeInto(ctx);
        }
      }
    } else if (onConflict is UpsertMultiple<T, D>) {
      for (final clause in onConflict.clauses) {
        _writeOnConflict(ctx, mode, originalEntry, clause);
      }
    } else if (onConflict is DoNothing<T, D>) {
      writeOnConflictConstraint(onConflict.target, null);
      ctx.buffer.write(' DO NOTHING');
    }
  }

  void _validateIntegrity(Insertable<D>? d) {
    if (d == null) {
      throw InvalidDataException(
          'Cannot write null row into ${table.entityName}');
    }

    table.validateIntegrity(d, isInserting: true).throwIfInvalid(d);
  }

  /// Writes column names and values from the [map].
  @internal
  void writeInsertable(GenerationContext ctx, Map<String, Expression> map) {
    final columns = map.keys.map(ctx.identifier);

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
enum InsertMode implements Component {
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
  insertOrIgnore;

  @override
  void writeInto(GenerationContext ctx) {
    if (ctx.dialect == SqlDialect.postgres &&
        this != InsertMode.insert &&
        this != InsertMode.insertOrIgnore) {
      throw ArgumentError('$this not supported on postgres');
    }

    ctx.buffer.write(_insertKeywords[
        ctx.dialect == SqlDialect.postgres ? InsertMode.insert : this]);
  }
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
  final Expression<bool> Function(T table)? _targetCondition;

  final bool _usesExcludedTable;

  /// An optional list of columns to serve as an "conflict target", which
  /// specifies the uniqueness constraint that will trigger the upsert.
  ///
  /// By default, the primary key of the table will be used.
  /// This can be set to an empty list, in which case no explicit conflict
  /// target will be generated by drift.
  final List<Column>? target;

  /// Creates a `DO UPDATE` clause.
  ///
  /// The [update] function will be used to construct an [Insertable] used to
  /// update an old row that prevented an insert.
  /// If you need to refer to both the old row and the row that would have
  /// been inserted, use [DoUpdate.withExcluded].
  ///
  /// A `DO UPDATE` clause must refer to a set of columns potentially causing a
  /// conflict, and only a conflict on those columns causes this clause to be
  /// applied. The most common conflict would be an existing row with the same
  /// primary key, which is the default for [target]. Other unique indices can
  /// be targeted too. If such a unique index has a condition, it can be set
  /// with [targetCondition] (which forms the rarely used `WHERE` in the
  /// conflict target).
  ///
  /// The optional [where] clause can be used to disable the update based on
  /// the old value. If a [where] clause is set and it evaluates to false, a
  /// conflict will keep the old row without applying the update.
  ///
  /// For an example, see [InsertStatement.insert].
  DoUpdate(
    Insertable<D> Function(T old) update, {
    this.target,
    Expression<bool> Function(T old)? where,
    Expression<bool> Function(T table)? targetCondition,
  })  : _creator = ((old, _) => update(old)),
        _where = where == null ? null : ((old, _) => Where(where(old))),
        _targetCondition = targetCondition,
        _usesExcludedTable = false;

  /// Creates a `DO UPDATE` clause.
  ///
  /// The [update] function will be used to construct an [Insertable] used to
  /// update an old row that prevented an insert.
  /// It can refer to the values from the old row in the first parameter and
  /// to columns in the row that couldn't be inserted with the `excluded`
  /// parameter.
  ///
  /// A `DO UPDATE` clause must refer to a set of columns potentially causing a
  /// conflict, and only a conflict on those columns causes this clause to be
  /// applied. The most common conflict would be an existing row with the same
  /// primary key, which is the default for [target]. Other unique indices can
  /// be targeted too. If such a unique index has a condition, it can be set
  /// with [targetCondition] (which forms the rarely used `WHERE` in the
  /// conflict target).
  ///
  /// The optional [where] clause can be used to disable the update based on
  /// the old value. If a [where] clause is set and it evaluates to false, a
  /// conflict will keep the old row without applying the update.
  ///
  /// For an example, see [InsertStatement.insert].
  DoUpdate.withExcluded(
    Insertable<D> Function(T old, T excluded) update, {
    this.target,
    Expression<bool> Function(T table)? targetCondition,
    Expression<bool> Function(T old, T excluded)? where,
  })  : _creator = update,
        _usesExcludedTable = true,
        _targetCondition = targetCondition,
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
  /// All [DoUpdate] and [DoNothing] clauses that are part of this upsert.
  ///
  /// The first clause with a matching [DoUpdate.target] or [DoNothing.target]
  /// will be considered.
  final List<UpsertClause<T, D>> clauses;

  /// Creates an upsert consisting of multiple [DoUpdate] and [DoNothing]
  /// clauses.
  ///
  /// This requires a fairly recent sqlite3 version (3.35.0, released on 2021-
  /// 03-12).
  UpsertMultiple(this.clauses);
}

/// Upsert clause that does nothing on conflict
class DoNothing<T extends Table, D> extends UpsertClause<T, D> {
  /// An optional list of columns to serve as an "conflict target", which
  /// specifies the uniqueness constraint that will trigger the upsert.
  ///
  /// By default, the primary key of the table will be used.
  final List<Column>? target;

  /// Creates an upsert clause that does nothing on conflict
  DoNothing({this.target});
}
