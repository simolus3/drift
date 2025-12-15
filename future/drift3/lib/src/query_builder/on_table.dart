import '../connection/connection.dart';
import '../database/connection_user.dart';
import '../database/data_class.dart';
import 'schema/table.dart';
import 'statements/insert.dart';

/// Easily-accessible methods to compose common operations or statements on
/// tables.
extension TableStatements<
  Row extends Object,
  RS extends GeneratedTable<Row, RS>
>
    on GeneratedTable<Row, RS> {
  /// Creates an insert statment to be used to compose an insert on the table.
  ///
  /// To later run the statement, first call
  /// [InsertStatementWithoutDatabase.onDatabase] followed by methods like
  /// [InsertStatementWithDatabase.insert].
  InsertStatement<Row, RS, Null> insert() => InsertStatement(null, this);

  /// Inserts one row into this table.
  ///
  /// This is equivalent to calling [InsertStatementWithDatabase.insert] - see
  /// that method for more information.
  Future<int> insertOne(
    Insertable<Row> row, {
    required DatabaseConnectionUser database,
    UpsertClause<Row, RS>? onConflict,
  }) {
    return insert().onDatabase(database).insert(row, onConflict: onConflict);
  }

  /// Atomically inserts all [rows] into the table.
  ///
  /// Unlike calling [Batch.insertAll] in a [Batch] directly, foreign keys are
  /// checked only _after_ all inserts ran. In other words, the order in which
  /// the [rows] are in doesn't matter if there are foreign keys between them.
  Future<void> insertAll(
    Iterable<Insertable<Row>> rows, {
    required DatabaseConnectionUser database,
    UpsertClause<Row, RS>? onConflict,
  }) {
    return database.transaction(
      options: const TransactionOptions(deferForeignKeys: true),
      () async {
        await database.batch((b) {
          b.insertAll(this, rows, onConflict: onConflict);
        });
      },
    );
  }

  /// Inserts one row into this table table, replacing an existing row if it
  /// exists already.
  ///
  /// Please note that this method is only available on recent sqlite3 versions.
  /// See also [InsertStatementWithDatabase.insertOnConflictUpdate].
  /// By default, only the primary key is used for detect uniqueness violations.
  /// If you have further uniqueness constraints, please use the general
  /// [insertOne] method with a [DoUpdate] including those columns in its
  /// [DoUpdate.target].
  Future<int> insertOnConflictUpdate(
    Insertable<Row> row, {
    required DatabaseConnectionUser database,
  }) {
    return insert().onDatabase(database).insertOnConflictUpdate(row);
  }

  /// Inserts one row into this table and returns it, along with auto-generated
  /// fields.
  ///
  /// Please note that this function is unsuitable for situations where it is
  /// not guaranteed that a row gets inserted (for instance because an upsert
  /// clause with a `where` clause is used). For those instances,
  /// use [insertReturningOrNull] instead.
  Future<Row> insertReturning(
    Insertable<Row> row, {
    required DatabaseConnectionUser database,
    UpsertClause<Row, RS>? onConflict,
  }) {
    return insert()
        .onDatabase(database)
        .insertReturning(row, onConflict: onConflict);
  }

  /// Inserts one row into this table and returns it, along with auto-generated
  /// fields.
  ///
  /// When neither an insert nor an error happened (for instance because an
  /// [onConflict] clause with a `where` clause was used), returns `null`.
  Future<Row?> insertReturningOrNull(
    Insertable<Row> row, {
    required DatabaseConnectionUser database,
    UpsertClause<Row, RS>? onConflict,
  }) {
    return insert()
        .onDatabase(database)
        .insertReturningOrNull(row, onConflict: onConflict);
  }
}
