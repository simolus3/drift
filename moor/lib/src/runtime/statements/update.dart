import 'dart:async';

import 'package:moor/moor.dart';
import 'package:moor/src/runtime/components/component.dart';
import 'package:moor/src/runtime/components/where.dart';
import 'package:moor/src/runtime/expressions/custom.dart';
import 'package:moor/src/runtime/expressions/expression.dart';

class UpdateStatement<T, D> extends Query<T, D> {
  UpdateStatement(QueryEngine database, TableInfo<T, D> table)
      : super(database, table);

  Map<String, Variable> _updatedFields;

  @override
  void writeStartPart(GenerationContext ctx) {
    // TODO support the OR (ROLLBACK / ABORT / REPLACE / FAIL / IGNORE...) thing

    ctx.buffer.write('UPDATE ${table.$tableName} SET ');

    var first = true;
    _updatedFields.forEach((columnName, variable) {
      if (!first) {
        ctx.buffer.write(', ');
      } else {
        first = false;
      }

      ctx.buffer..write(columnName)..write(' = ');

      variable.writeInto(ctx);
    });
  }

  Future<int> _performQuery() async {
    final ctx = constructQuery();
    final rows = await ctx.database.executor.doWhenOpened((e) async {
      return await e.runUpdate(ctx.sql, ctx.boundVariables);
    });

    if (rows > 0) {
      database.markTableUpdated(table.$tableName);
    }

    return rows;
  }

  /// Writes all non-null fields from [entity] into the columns of all rows
  /// that match the set [where] and limit constraints. Warning: That also
  /// means that, when you're not setting a where or limit expression
  /// explicitly, this method will update all rows in the specific table.
  ///
  /// The fields that are null on the [entity] object will not be changed by
  /// this operation.
  ///
  /// Returns the amount of rows that have been affected by this operation.
  ///
  /// See also: [replace], which does not require [where] statements and
  /// supports setting fields to null.
  Future<int> write(D entity) async {
    if (!table.validateIntegrity(entity, false)) {
      throw InvalidDataException(
          'Invalid data: $entity cannot be written into ${table.$tableName}');
    }

    _updatedFields = table.entityToSql(entity)
      ..remove((_, value) => value == null);

    if (_updatedFields.isEmpty) {
      // nothing to update, we're done
      return Future.value(0);
    }

    return await _performQuery();
  }

  /// Replaces the old version of [entity] that is stored in the database with
  /// the fields of the [entity] provided here. This implicitly applies a
  /// [where] clause to rows with the same primary key as [entity], so that only
  /// the row representing outdated data will be replaced.
  ///
  /// If [entity] has fields with null as value, data in the row will be set
  /// back to null. This behavior is different to that of [write], which ignores
  /// null fields.
  ///
  /// Returns true if a row was affected by this operation.
  Future<bool> replace(D entity) async {
    // We set isInserting to true here although we're in an update. This is
    // because all the fields from the entity will be written (as opposed to a
    // regular update, where only non-null fields will be written). If isInserted
    // was false, the null fields would not be validated.
    if (!table.validateIntegrity(entity, true))
      throw InvalidDataException('Invalid data: $entity cannot be used to '
          'replace another row as some required fields are null or invalid.');

    assert(
        whereExpr == null,
        'When using replace on an update statement, you may not use where(...)'
        'as well. The where clause will be determined automatically');

    _updatedFields = table.entityToSql(entity, includeNulls: true);
    final primaryKeys = table.$primaryKey.map((c) => c.$name);

    // Extract values of the primary key as they are needed for the where clause
    final primaryKeyValues = Map.fromEntries(_updatedFields.entries
        .where((entry) => primaryKeys.contains(entry.key)));

    // But remove them from the map of columns that should be changed.
    _updatedFields.removeWhere((key, _) => primaryKeys.contains(key));

    Expression<bool, BoolType> predicate;
    for (var entry in primaryKeyValues.entries) {
      // custom expression that references the column
      final columnExpression = CustomExpression(entry.key);
      final comparison =
          Comparison(columnExpression, ComparisonOperator.equal, entry.value);

      if (predicate == null) {
        predicate = comparison;
      } else {
        predicate = and(predicate, comparison);
      }
    }

    whereExpr = Where(predicate);

    final updatedRows = await _performQuery();
    return updatedRows != 0;
  }
}
