import 'package:collection/collection.dart';
import 'package:drift/src/query_builder/compiler.dart';

import '../../connections/result_set.dart';
import '../../runtime/data_class.dart';
import '../../runtime/database/connection_user.dart';
import '../../runtime/streams/update_rules.dart';
import '../clauses/returning.dart';
import '../expressions/expression.dart';
import '../schema/column_constraints.dart';
import '../schema/table.dart';
import 'query.dart';
import 'statement.dart';

/// Represents an `UPDATE` statement in sql.
final class UpdateStatement<Row extends Object,
        RS extends GeneratedTable<Row, RS>> extends SqlStatement
    with SingleTableStatementMixin<Row, RS, UpdateStatement<Row, RS>> {
  /// The table from which rows should be updated.
  @override
  final GeneratedTable<Row, RS> resultSet;
  final DatabaseConnectionUser _database;

  /// An optional `RETURNING` clause part of this statement.
  ReturningClause<Row, RS>? returning;

  /// The columns set by this update statement.
  final Map<String, Expression> updatedColumns = {};

  /// Used internally by drift to construct an update statement
  UpdateStatement(this._database, this.resultSet);

  Future<QueryResult> _run() async {
    final result = await _database.runStatement(this);
    if (result.affectedRows case final rows? when rows > 0) {
      _database.notifyUpdates(
          {TableUpdate.onTable(resultSet, kind: UpdateKind.update)});
    }

    return result;
  }

  void _applyColumns(Insertable<Row> entity, bool nullToAbsent) {
    updatedColumns
      ..clear()
      ..addAll(entity.toColumns(nullToAbsent));
  }

  /// Writes all non-null fields from [entity] into the columns of all rows
  /// that match the [where] clause. Warning: That also means that, when you're
  /// not setting a where clause explicitly, this method will update all rows in
  /// the [table].
  ///
  /// The fields that are null on the [entity] object will not be changed by
  /// this operation, they will be ignored.
  ///
  /// When [dontExecute] is true (defaults to false), the query will __NOT__ be
  /// run, but all the validations are still in place. This is mainly used
  /// internally by drift.
  ///
  /// Returns the amount of rows that have been affected by this operation.
  ///
  /// See also: [replace], which does not require [where] statements and
  /// supports setting fields back to null.
  Future<int> write(Insertable<Row> entity) async {
    _applyColumns(entity, true);

    if (updatedColumns.isEmpty) {
      // nothing to update, we're done
      return Future.value(0);
    }

    final result = await _run();
    return result.affectedRows!;
  }

  /// Applies the updates from [entity] to all rows matching the applied `where`
  /// clause and returns affected rows _after the update_.
  ///
  /// For more details on writing entries, see [write].
  /// Note that this requires sqlite 3.35 or later.
  Future<List<Row>> writeReturning(Insertable<Row> entity) async {
    _applyColumns(entity, true);
    returning = ReturningClause(resultSet);

    final result = await _run();
    return returning!.interpretResults(_database, result);
  }

  /// Replaces the old version of [entity] that is stored in the database with
  /// the fields of the [entity] provided here. This implicitly applies a
  /// [where] clause to rows with the same primary key as [entity], so that only
  /// the row representing outdated data will be replaced.
  ///
  /// If [entity] has absent values (set to null on the [DataClass] or
  /// explicitly to absent on the [UpdateCompanion]), and a default value for
  /// the field exists, that default value will be used. Otherwise, the field
  /// will be reset to null. This behavior is different to [write], which simply
  /// ignores such fields without changing them in the database.
  ///
  /// When [dontExecute] is true (defaults to false), the query will __NOT__ be
  /// run, but all the validations are still in place. This is mainly used
  /// internally by drift.
  ///
  /// Returns true if a row was affected by this operation.
  ///
  /// See also:
  ///  - [write], which doesn't apply a [where] statement itself and ignores
  ///    null values in the entity.
  ///  - [InsertStatement.insert] with the `orReplace` parameter, which behaves
  ///  similar to this method but creates a new row if none exists.
  Future<bool> replace(Insertable<Row> entity) async {
    // We don't turn nulls to absent values here (as opposed to a regular
    // update, where only non-null fields will be written).
    _applyColumns(entity, false);
    assert(
        whereClause == null,
        'When using replace on an update statement, you may not use where(...)'
        'as well. The where clause will be determined automatically');

    whereSamePrimaryKey(entity);

    final primaryKeys = resultSet.primaryKey?.map((c) => c.name) ?? const [];

    // entityToSql doesn't include absent values, so we might have to apply the
    // default value here
    for (final column in resultSet.columns) {
      // if a default value exists and no value is set, apply the default
      if (updatedColumns.containsKey(column.name)) {
        continue;
      }

      final defaultValue = column.constraints
          .whereType<ColumnDefaultConstraint>()
          .firstOrNull
          ?.defaultExpression;

      if (defaultValue != null && !updatedColumns.containsKey(column.name)) {
        updatedColumns[column.name] = defaultValue;
      }
    }

    // Don't update the primary key
    updatedColumns.removeWhere((key, _) => primaryKeys.contains(key));

    final result = await _run();
    return result.affectedRows! != 0;
  }

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addUpdateStatement(this);
  }
}
