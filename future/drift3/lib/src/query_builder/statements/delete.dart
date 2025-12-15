import '../../connection/result_set.dart';
import '../../connection/streams/update_rules.dart';
import '../../database/connection_user.dart';
import '../../database/data_class.dart';
import '../clauses/returning.dart';
import '../compiler.dart';
import '../schema/table.dart';
import 'query.dart';
import 'statement.dart';

/// A `DELETE` statement in SQL.
final class DeleteStatement<
  Row extends Object,
  RS extends GeneratedTable<Row, RS>
>
    extends SqlStatement
    with SingleTableStatementMixin<Row, RS, DeleteStatement<Row, RS>> {
  /// The table from which rows should be deleted.
  @override
  final GeneratedTable<Row, RS> resultSet;

  /// An optional `RETURNING` clause part of this statement.
  ReturningClause<Row, RS>? returning;

  final DatabaseConnectionUser _database;

  /// This constructor should be called by [DatabaseConnectionUser.delete] for
  /// you.
  DeleteStatement(this._database, this.resultSet);

  void _prepareDeleteOne(Insertable<Row> entity) {
    assert(
      whereClause == null,
      'When deleting an entity, you may not use where(...)'
      'as well. The where clause will be determined automatically',
    );

    whereSamePrimaryKey(entity);
  }

  void _addReturning() {
    returning = ReturningClause(resultSet);
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
    _prepareDeleteOne(entity);
    return go();
  }

  /// Like [delete], but returns the deleted row from the database.
  ///
  /// If no matching row with the same primary key exists, `null` is returned.
  Future<Row?> deleteReturning(Insertable<Row> entity) async {
    _prepareDeleteOne(entity);
    _addReturning();
    return (await _goReturning()).singleOrNull;
  }

  Future<QueryResult> _run() async {
    final result = await _database.runStatement(this);
    if (result.affectedRows case final rows? when rows > 0) {
      _database.notifyUpdates({
        TableUpdate.onTable(resultSet, kind: UpdateKind.delete),
      });
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
    _addReturning();
    return _goReturning();
  }

  Future<List<Row>> _goReturning() async {
    final result = await _run();
    return returning!.interpretResults(_database, result);
  }

  @override
  DeleteStatement<Row, RS> asSelf() => this;
}
