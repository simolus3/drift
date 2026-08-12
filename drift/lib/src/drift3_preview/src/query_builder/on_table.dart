import '../connection/connection.dart';
import '../database/connection_user.dart';
import '../database/data_class.dart';
import '../database/selectable.dart';
import 'expressions/aggregate.dart';
import 'expressions/expression.dart';
import 'schema/result_set.dart';
import 'schema/table.dart';
import 'statements/insert.dart';
import 'statements/select.dart';

/// Methods to compose common queries and statements on tables or views.
///
/// To obtain an instance of this, use [GetTableOrViewStatements.statements] on
/// a generated table or view instance.
final class TableOrViewStatements<
  Row extends Object,
  RS extends ResultSet<Row, RS>
> {
  final RS _resultSet;
  final DatabaseConnectionUser _database;

  TableOrViewStatements._(this._resultSet, this._database);

  /// Selects all rows that are in this table.
  ///
  /// The returned [Selectable] can be run once as a future with [Selectable.get]
  /// or as an auto-updating stream with [Selectable.watch].
  Selectable<Row> all() {
    return select();
  }

  /// Counts the rows in this table.
  ///
  /// The optional [where] clause can be used to only count rows matching the
  /// condition, similar to [SimpleSelectStatement.where].
  ///
  /// The returned [Selectable] can be run once with [Selectable.getSingle] to
  /// get the count once, or be watched as a stream with [Selectable.watchSingle].
  Selectable<int> count({Expression<bool> Function(RS row)? where}) {
    final count = countAll();
    final stmt = selectOnly()..addColumns([count]);
    if (where != null) {
      stmt.where(where(_resultSet));
    }

    return stmt.map((row) => row.read(count)!);
  }

  /// Composes a `SELECT` statement on the captured table or view.
  ///
  /// This is equivalent to calling [DatabaseConnectionUser.select].
  SingleTableSelectStatement<Row, RS> select({bool distinct = false}) {
    return _database.select(_resultSet, distinct: distinct);
  }

  /// Composes a `SELECT` statement only selecting a subset of columns.
  ///
  /// This is equivalent to calling [DatabaseConnectionUser.selectOnly].
  SelectStatement selectOnly({bool distinct = false}) {
    return _database.selectOnly(_resultSet, distinct: distinct);
  }
}

/// Utility to compose common statements for tables.
extension TableStatements<
  Row extends Object,
  RS extends GeneratedTable<Row, RS>
>
    on TableOrViewStatements<Row, RS> {
  /// Creates an insert statment to be used to compose an insert on the table.
  InsertStatement<Row, RS> insert() {
    return InsertStatement(_database, _resultSet);
  }

  /// Inserts one row into this table.
  ///
  /// This is equivalent to calling [InsertStatement.insert], see that method
  /// for more information.
  Future<int> insertOne(
    Insertable<Row> row, {
    UpsertClause<Row, RS>? onConflict,
  }) {
    return insert().insert(row, onConflict: onConflict);
  }

  /// Atomically inserts all [rows] into the table.
  ///
  /// Unlike calling [Batch.insertAll] in a [Batch] directly, foreign keys are
  /// checked only _after_ all inserts ran. In other words, the order in which
  /// the [rows] are in doesn't matter if there are foreign keys between them.
  Future<void> insertAll(
    Iterable<Insertable<Row>> rows, {
    UpsertClause<Row, RS>? onConflict,
  }) {
    return _database.transaction(
      options: const TransactionOptions(deferForeignKeys: true),
      () async {
        await _database.batch((b) {
          b.insertAll(_resultSet, rows, onConflict: onConflict);
        });
      },
    );
  }

  /// Inserts one row into this table table, replacing an existing row if it
  /// exists already.
  ///
  /// Please note that this method is only available on recent sqlite3 versions.
  /// See also [InsertStatement.insertOnConflictUpdate].
  /// By default, only the primary key is used for detect uniqueness violations.
  /// If you have further uniqueness constraints, please use the general
  /// [insertOne] method with a [DoUpdate] including those columns in its
  /// [DoUpdate.target].
  Future<int> insertOnConflictUpdate(Insertable<Row> row) {
    return insert().insertOnConflictUpdate(row);
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
    UpsertClause<Row, RS>? onConflict,
  }) {
    return insert().insertReturning(row, onConflict: onConflict);
  }

  /// Inserts one row into this table and returns it, along with auto-generated
  /// fields.
  ///
  /// When neither an insert nor an error happened (for instance because an
  /// [onConflict] clause with a `where` clause was used), returns `null`.
  Future<Row?> insertReturningOrNull(
    Insertable<Row> row, {
    UpsertClause<Row, RS>? onConflict,
  }) {
    return insert().insertReturningOrNull(row, onConflict: onConflict);
  }
}

/// Extension providing the [statements] method for tables specifically.
extension GetTableOrViewStatements<
  Row extends Object,
  RS extends ResultSet<Row, RS>
>
    on ResultSet<Row, RS> {
  /// Creates a [TableOrViewStatements] instance that can be used to create
  /// common select statements on this table or view.
  ///
  /// In most cases, it is not necessary to call this directly. On database
  /// classes, a `queries` getter for each table makes [TableOrViewStatements]
  /// available too.
  TableOrViewStatements<Row, RS> statements(DatabaseConnectionUser db) {
    return TableOrViewStatements._(asSelfType(), db);
  }
}
