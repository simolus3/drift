import 'dart:collection';

import 'package:meta/meta.dart';

import '../../connection/result_set.dart';
import '../../connection/streams/update_rules.dart';
import '../../database/connection_user.dart';
import '../../database/data_class.dart';
import '../clauses/returning.dart';
import '../clauses/where.dart';
import '../compiler.dart';
import '../expressions/expression.dart';
import '../expressions/variables.dart';
import '../results.dart';
import '../schema/table.dart';
import 'select.dart';
import 'statement.dart';

/// An `INSERT` statement in SQL.
final class InsertStatement<
  Row extends Object,
  RS extends GeneratedTable<Row, RS>,
  DB extends DatabaseConnectionUser?
>
    extends SqlStatement {
  /// The table we're inserting into.
  final GeneratedTable<Row, RS> table;

  /// The database used to run this insert statement.
  final DB _database;

  /// The values to use for the rows being inserted.
  InsertSource? source;

  /// An `ON CONFLICT DO UPDATE` clause added to this statement.
  UpsertClause<Row, RS>? upsertClause;

  /// An optional `RETURNING` clause part of this statement.
  ReturningClause<Row, RS>? returning;

  /// Constructs an insert statement from the database and the table. Used
  /// internally by drift.
  InsertStatement(this._database, this.table);

  void _checkNoSource() {
    assert(
      source == null,
      'A source has already been set on this insert statement.',
    );
  }

  /// Configures this insert statement to insert values from the Dart object
  /// [row].
  ///
  /// Typically, [row] is an instance of the companion class drift generates for
  /// tables, which allows specifying which columns to use.
  InsertStatement<Row, RS, DB> values(Insertable<Row> row) {
    _checkNoSource();

    final rawValues = row.toColumns(true);

    // apply default values for columns that have one
    LinkedHashMap<String, Expression> map = LinkedHashMap();
    for (final column in table.columns) {
      final columnName = column.name;

      if (rawValues.containsKey(columnName)) {
        final value = rawValues[columnName]!;
        map[columnName] = value;
      } else {
        if (column.clientDefault case final clientDefault?) {
          map[columnName] = Variable(clientDefault(), column.resolveType);
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

    if (map.isNotEmpty) {
      source = InsertFromValues._(map);
    }

    return this;
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
  InsertStatement<Row, RS, DB> fromSelect(
    BaseSelectStatement select, {
    required Map<TableColumn, Expression> columns,
  }) {
    _checkNoSource();

    LinkedHashMap<String, ColumnPosition> columnNameToSelectColumnName =
        LinkedHashMap();
    columns.forEach((key, value) {
      final position = select.structure.expressions[value];
      if (position == null) {
        throw ArgumentError.value(
          value,
          'column',
          'This column passd to insertFromSelect() was not added to the '
              'source select statement.',
        );
      }

      columnNameToSelectColumnName[key.name] = position;
    });

    source = InsertFromSelect._(select, columnNameToSelectColumnName);
    return this;
  }

  /// Adds an [upsert] clause to this insert statement.
  InsertStatement<Row, RS, DB> onConflict(UpsertClause<Row, RS> upsert) {
    assert(upsertClause == null, 'upsert clause already set');
    upsertClause = upsert;
    return this;
  }

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addInsertStatement(this);
  }
}

///
extension InsertStatementWithDatabase<
  Row extends Object,
  RS extends GeneratedTable<Row, RS>,
  DB extends DatabaseConnectionUser
>
    on InsertStatement<Row, RS, DB> {
  Future<QueryResult> _run() async {
    final result = await _database.runStatement(this);
    if (result.affectedRows case final rows? when rows > 0) {
      _database.notifyUpdates({
        TableUpdate.onTable(table, kind: UpdateKind.insert),
      });
    }

    return result;
  }

  void _addReturning() {
    returning = ReturningClause(table);
  }

  /// Runs this insert statement with a `RETURNING` clause, returning inserted
  /// rows.
  ///
  /// This method requires that [source] (and optionally also an [upsertClause])
  /// have already been set (e.g. through [values]).
  /// For a method that does all of this, use [insertReturning] or
  /// [insertReturningOrNull].
  Future<List<Row>> runReturning() async {
    _addReturning();

    final result = await _run();
    return returning!.interpretResults(_database, result);
  }

  /// Inserts a row constructed from the fields in [entity].
  ///
  /// All fields in the entity that don't have a default value or auto-increment
  /// must be set and non-null.
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
    Insertable<Row> entity, {
    UpsertClause<Row, RS>? onConflict,
  }) async {
    source = null;
    values(entity);
    if (onConflict != null) {
      this.onConflict(onConflict);
    }

    final result = await _run();
    return result.lastInsertRowId!;
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
  Future<QueryResult> insertFromSelect(
    BaseSelectStatement select, {
    required Map<TableColumn, Expression> columns,
    UpsertClause<Row, RS>? onConflict,
  }) async {
    source = null;
    fromSelect(select, columns: columns);
    if (onConflict != null) {
      this.onConflict(onConflict);
    }

    return await _run();
  }

  /// Inserts a row into the table and returns it.
  ///
  /// Depending on how the statement is configured, it's possible that an insert
  /// does not actually insert a row (e.g. if a [DoNothing] clause has been
  /// added as an [upsertClause]).
  /// In this case, this method throws a [StateError]. In cases where that's
  /// possible, consider using [insertReturningOrNull] or [runReturning]
  /// instead.
  Future<Row> insertReturning(
    Insertable<Row> entity, {
    UpsertClause<Row, RS>? onConflict,
  }) async {
    source = null;
    final row = await insertReturningOrNull(entity, onConflict: onConflict);

    if (row == null) {
      throw StateError(
        'The insert statement did not insert any rows that '
        'could be returned. Please use insertReturningOrNull() when using a '
        '`DoUpdate` clause with `where`.',
      );
    }

    return row;
  }

  /// Inserts a row into the table and returns it.
  ///
  /// Depending on how the statement is configured, it's possible that an insert
  /// does not actually insert a row (e.g. if a [DoNothing] clause has been
  /// added as an [upsertClause]). This method returns null in that case.
  Future<Row?> insertReturningOrNull(
    Insertable<Row> entity, {
    UpsertClause<Row, RS>? onConflict,
  }) async {
    source = null;
    values(entity);
    if (onConflict != null) {
      this.onConflict(onConflict);
    }

    final rows = await runReturning();
    if (rows.isNotEmpty) {
      return rows.single;
    } else {
      return null;
    }
  }

  /// Attempts to [insert] [entity] into the database. If the insert would
  /// violate a primary key or uniqueness constraint, updates the columns that
  /// are present on [entity].
  ///
  /// Be aware that [insertOnConflictUpdate] uses an upsert clause, which is not
  /// available on older sqlite implementations.
  /// Note: By default, only the primary key is used for detect uniqueness
  /// violations. If you have further uniqueness constraints, please use the
  /// general [insert] method with a [DoUpdate] including those columns in its
  /// [DoUpdate.target].
  ///
  /// Like the other [insert] methods, this returns the rowid of the last
  /// insert. When the insert was turned into an update due to a conflicting
  /// row, this behavior is somewhat confusing because the id of an (likely
  /// unrelated) insert is returned instead.
  /// Use [insertReturning] with an `onConflict` clause of
  /// `DoUpdate((_) => entity)` to reliably get the written entity instead.
  Future<int> insertOnConflictUpdate(Insertable<Row> entity) {
    return insert(entity, onConflict: DoUpdate((_) => entity));
  }
}

/// Exposes the [onDatabase] method to add a database to this insert statement.
extension InsertStatementWithoutDatabase<
  Row extends Object,
  RS extends GeneratedTable<Row, RS>
>
    on InsertStatement<Row, RS, Null> {
  /// Attaches a [DatabaseConnectionUser] to this [InsertStatement] so that it
  /// can be executed.
  InsertStatement<Row, RS, DatabaseConnectionUser> onDatabase(
    DatabaseConnectionUser db,
  ) {
    return InsertStatement(db, table)
      ..source = source
      ..upsertClause = upsertClause
      ..returning = returning;
  }
}

/// Possible values for [InsertStatement.source].
sealed class InsertSource implements SqlComponent {}

/// Insert the default values for each column.
final class InsertDefaultValues extends InsertSource {
  /// Insert `DEFAULT VALUES` for an insert statement.
  InsertDefaultValues();

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addInsertDefaultValues(this);
  }
}

/// Insert values from an [values] map.
final class InsertFromValues extends InsertSource {
  /// An ordered map from column names to expressions for inserts.
  final LinkedHashMap<String, Expression> values;

  InsertFromValues._(this.values);

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addInsertFromValues(this);
  }
}

/// Insert rows returned by a select statement.
final class InsertFromSelect extends InsertSource {
  /// The select statement for which returning rows will be inserted into the
  /// table.
  final BaseSelectStatement select;

  /// Map from column names in the table to insert to result positions in the
  /// used select statement.
  final LinkedHashMap<String, ColumnPosition> columnNameToSelectColumnName;

  InsertFromSelect._(this.select, this.columnNameToSelectColumnName);

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addInsertFromSelect(this);
  }
}

/// A upsert clause controls how to behave when a uniqueness constraint is
/// violated during an insert.
///
/// Typically, one would use [DoUpdate] to run an update instead in this case.
sealed class UpsertClause<
  Row extends Object,
  RS extends GeneratedTable<Row, RS>
>
    implements SqlComponent {}

/// A [DoUpdate] upsert clause can be used to insert or update a custom
/// companion when the underlying companion already exists.
///
/// For an example, see [InsertStatement.insert].
final class DoUpdate<Row extends Object, RS extends GeneratedTable<Row, RS>>
    extends UpsertClause<Row, RS> {
  final Insertable<Row> Function(RS old, RS excluded) _creator;

  /// Change the [DoUpdate] into a no-op if [where] evaluates to false.f
  final WhereClause Function(RS old, RS excluded)? where;

  /// Only applies the [DoUpdate] if the target table matches a condition.
  final Expression<bool> Function(RS table)? targetCondition;

  /// Whether the insertable, [where] or [targetCondition] use both the old and
  /// the excluded rows.
  final bool usesExcludedTable;

  /// An optional list of columns to serve as an "conflict target", which
  /// specifies the uniqueness constraint that will trigger the upsert.
  ///
  /// By default, the primary key of the table will be used.
  /// This can be set to an empty list, in which case no explicit conflict
  /// target will be generated by drift.
  final List<TableColumn>? target;

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
    Insertable<Row> Function(RS old) update, {
    this.target,
    Expression<bool> Function(RS old)? where,
    this.targetCondition,
  }) : _creator = ((old, _) => update(old)),
       where = where == null ? null : ((old, _) => WhereClause(where(old))),
       usesExcludedTable = false;

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
    Insertable<Row> Function(RS old, RS excluded) update, {
    this.target,
    this.targetCondition,
    Expression<bool> Function(RS old, RS excluded)? where,
  }) : _creator = update,
       usesExcludedTable = true,
       where = where == null
           ? null
           : ((old, excluded) => WhereClause(where(old, excluded)));

  /// Generates the [Insertable]
  @internal
  Insertable<Row> createInsertable(GeneratedTable<Row, RS> table) {
    return _creator(
      table.asSelfType(),
      table.withAlias('excluded').asSelfType(),
    );
  }

  /// Generates the `WHERE` filter for this update action, if one has been set.
  @internal
  WhereClause? buildWhereClause(GeneratedTable<Row, RS> table) {
    return switch (where) {
      null => null,
      final where => where(
        table.asSelfType(),
        table.withAlias('excluded').asSelfType(),
      ),
    };
  }

  /// Generates the `WHERE` filter for this target condition, if one has been set.
  @internal
  WhereClause? buildTargetCondition(GeneratedTable<Row, RS> table) {
    return switch (targetCondition) {
      null => null,
      final condition => WhereClause(condition(table.asSelfType())),
    };
  }

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addDoUpdate(this);
  }
}

/// Upsert clause that consists of multiple [clauses].
///
/// The first [DoUpdate.target] matched by this upsert will be run.
final class UpsertMultiple<
  Row extends Object,
  RS extends GeneratedTable<Row, RS>
>
    extends UpsertClause<Row, RS> {
  /// All [DoUpdate] and [DoNothing] clauses that are part of this upsert.
  ///
  /// The first clause with a matching [DoUpdate.target] or [DoNothing.target]
  /// will be considered.
  final List<UpsertClause<Row, RS>> clauses;

  /// Creates an upsert consisting of multiple [DoUpdate] and [DoNothing]
  /// clauses.
  ///
  /// This requires a fairly recent sqlite3 version (3.35.0, released on 2021-
  /// 03-12).
  UpsertMultiple(this.clauses);

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addUpsertMultiple(this);
  }
}

/// Upsert clause that does nothing on conflict
final class DoNothing<Row extends Object, RS extends GeneratedTable<Row, RS>>
    extends UpsertClause<Row, RS> {
  /// An optional list of columns to serve as an "conflict target", which
  /// specifies the uniqueness constraint that will trigger the upsert.
  ///
  /// By default, the primary key of the table will be used.
  final List<TableColumn>? target;

  /// Creates an upsert clause that does nothing on conflict
  DoNothing({this.target});

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addDoNothing(this);
  }
}
