import 'package:built_collection/built_collection.dart';
import 'package:drift/src/query_builder/clauses/where.dart';
import 'package:meta/meta.dart';

import '../../connections/result_set.dart';
import '../../runtime/data_class.dart';
import '../../runtime/database/connection_user.dart';
import '../../runtime/streams/update_rules.dart';
import '../clauses/returning.dart';
import '../compiler.dart';
import '../schema/table.dart';
import 'query.dart';
import 'statement.dart';

/// A `DELETE` statement in SQL.
@immutable
final class DeleteStatement<Row extends Object,
        RS extends GeneratedTable<Row, RS>> extends SqlStatement
    with SingleTableStatementMixin<Row, RS, DeleteStatement<Row, RS>> {
  /// The table from which rows should be deleted.
  @override
  final GeneratedTable<Row, RS> resultSet;

  /// An optional `RETURNING` clause part of this statement.
  final ReturningClause<Row, RS>? returning;

  final DatabaseConnectionUser _database;

  @override
  final WhereClause? whereClause;

  @override
  final BuiltMap<Symbol, Object?> dialectSpecificOptions = BuiltMap();

  /// This constructor should be called by [DatabaseConnectionUser.delete] for
  /// you.
  DeleteStatement(this._database, this.resultSet)
      : returning = null,
        whereClause = null;
  DeleteStatement._(this._database,
      {required this.resultSet,
      required this.whereClause,
      required this.returning});

  @override
  DeleteStatement<Row, RS> withWhereClause(WhereClause whereClause) =>
      _copyWith(whereClause: whereClause);

  DeleteStatement<Row, RS> _withReturning() =>
      _copyWith(returning: ReturningClause(resultSet));

  DeleteStatement<Row, RS> _copyWith({
    GeneratedTable<Row, RS>? resultSet,
    WhereClause? whereClause,
    ReturningClause<Row, RS>? returning,
  }) {
    return DeleteStatement._(
      _database,
      resultSet: resultSet ?? this.resultSet,
      whereClause: whereClause ?? this.whereClause,
      returning: returning ?? this.returning,
    );
  }

  DeleteStatement<Row, RS> _withPrepareDeleteOne(Insertable<Row> entity) {
    assert(
        whereClause == null,
        'When deleting an entity, you may not use where(...)'
        'as well. The where clause will be determined automatically');

    return withWhereSamePrimaryKey(entity);
  }

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addDeleteStatement(this);
  }

  /// Deletes just this entity. May not be used together with [where].
  ///
  /// Returns the amount of rows that were deleted by this statement directly
  /// (not including additional rows that might be affected through triggers or
  /// foreign key constraints).
  Future<int> delete(Insertable<Row> entity) {
    return _withPrepareDeleteOne(entity).go();
  }

  /// Like [delete], but returns the deleted row from the database.
  ///
  /// If no matching row with the same primary key exists, `null` is returned.
  Future<Row?> deleteReturning(Insertable<Row> entity) async {
    return (await _withPrepareDeleteOne(entity)._withReturning()._goReturning())
        .singleOrNull;
  }

  Future<QueryResult> _run() async {
    final result = await _database.runStatement(this);
    if (result.affectedRows case final rows? when rows > 0) {
      _database.notifyUpdates(
          {TableUpdate.onTable(resultSet, kind: UpdateKind.delete)});
    }

    return result;
  }

  /// Deletes all rows matched by the set [where] clause and the optional
  /// limit.
  ///
  /// Returns the amount of rows that were deleted by this statement directly
  /// (not including additional rows that might be affected through triggers or
  /// foreign key constraints).
  Future<int> go() async {
    final result = await _run();
    return result.affectedRows!;
  }

  /// Like [go], but it also returns all rows affected by this delete operation.
  Future<List<Row>> goAndReturn() {
    return _withReturning()._goReturning();
  }

  Future<List<Row>> _goReturning() async {
    final result = await _run();
    return returning!.interpretResults(_database, result);
  }
}
