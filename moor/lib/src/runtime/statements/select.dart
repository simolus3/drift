import 'dart:async';

import 'package:meta/meta.dart';
import 'package:moor/moor.dart';
import 'package:moor/src/runtime/components/component.dart';
import 'package:moor/src/runtime/components/join.dart';
import 'package:moor/src/runtime/database.dart';
import 'package:moor/src/runtime/executor/stream_queries.dart';
import 'package:moor/src/runtime/statements/query.dart';
import 'package:moor/src/runtime/structure/table_info.dart';

typedef OrderingTerm OrderClauseGenerator<T>(T tbl);

class JoinedSelectStatement<FirstT, FirstD> extends Query<FirstT, FirstD>
    with LimitContainerMixin {
  JoinedSelectStatement(
      QueryEngine database, TableInfo<FirstT, FirstD> table, this._joins)
      : super(database, table);

  final List<Join> _joins;

  @visibleForOverriding
  Set<TableInfo> get watchedTables => _tables.toSet();

  // fixed order to make testing easier
  Iterable<TableInfo> get _tables =>
      <TableInfo>[table].followedBy(_joins.map((j) => j.table));

  @override
  void writeStartPart(GenerationContext ctx) {
    ctx.hasMultipleTables = true;
    ctx.buffer.write('SELECT ');

    var isFirst = true;
    for (var table in _tables) {
      for (var column in table.$columns) {
        if (!isFirst) {
          ctx.buffer.write(', ');
        }

        column.writeInto(ctx);

        isFirst = false;
      }
    }

    ctx.buffer.write(' FROM ${table.tableWithAlias}');

    if (_joins.isNotEmpty) {
      ctx.writeWhitespace();

      for (var i = 0; i < _joins.length; i++) {
        if (i != 0) ctx.writeWhitespace();

        _joins[i].writeInto(ctx);
      }
    }
  }

  /// Executes this statement and returns the result.
  Future<List<TypedResult>> get() async {
    final ctx = constructQuery();
    final results = await ctx.database.executor.doWhenOpened((e) async {
      return await e.runSelect(ctx.sql, ctx.boundVariables);
    });

    final tables = _tables;

    return results.map((row) {
      final map = <TableInfo, dynamic>{};

      for (var table in tables) {
        final prefix = '${table.$tableName}.';
        // if all columns of this table are null, skip the table
        if (table.$columns.any((c) => row[prefix + c.$name] != null)) {
          map[table] = table.map(row, tablePrefix: table.$tableName);
        } else {
          map[table] = null;
        }
      }

      return TypedResult(map);
    }).toList();
  }
}

/// A select statement that doesn't use joins
class SimpleSelectStatement<T, D> extends Query<T, D>
    with SingleTableQueryMixin<T, D>, LimitContainerMixin<T, D> {
  SimpleSelectStatement(QueryEngine database, TableInfo<T, D> table)
      : super(database, table);

  @visibleForOverriding
  Set<TableInfo> get watchedTables => {table};

  @override
  void writeStartPart(GenerationContext ctx) {
    ctx.buffer.write('SELECT * FROM ${table.tableWithAlias}');
  }

  /// Loads and returns all results from this select query.
  Future<List<D>> get() async {
    final ctx = constructQuery();
    return _getWithQuery(ctx);
  }

  Future<List<D>> _getWithQuery(GenerationContext ctx) async {
    final results = await ctx.database.executor.doWhenOpened((e) async {
      return await e.runSelect(ctx.sql, ctx.boundVariables);
    });
    return results.map(table.map).toList();
  }

  /// Creates a select statement that operates on more than one table by
  /// applying the given joins.
  ///
  /// Example from the todolist example which will load the category for each
  /// item:
  /// ```
  /// final results = await select(todos).join([
  ///   leftOuterJoin(categories, categories.id.equalsExp(todos.category))
  /// ]).get();
  ///
  /// return results.map((row) {
  ///   final entry = row.readTable(todos);
  ///   final category = row.readTable(categories);
  ///   return EntryWithCategory(entry, category);
  /// }).toList();
  /// ```
  ///
  /// See also:
  ///  - [innerJoin], [leftOuterJoin] and [crossJoin], which can be used to
  ///  construct a [Join].
  ///  - [GeneratedDatabase.alias], which can be used to build statements that
  ///  refer to the same table multiple times.
  JoinedSelectStatement join(List<Join> joins) {
    return JoinedSelectStatement(database, table, joins);
  }

  /// Orders the result by the given clauses. The clauses coming first in the
  /// list have a higher priority, the later clauses are only considered if the
  /// first clause considers two rows to be equal.
  ///
  /// Example that first displays the users who are awesome and sorts users by
  /// their id as a secondary criterion:
  /// ```
  /// (db.select(db.users)
  ///    ..orderBy([
  ///      (u) => OrderingTerm(expression: u.isAwesome, mode: OrderingMode.desc),
  ///      (u) => OrderingTerm(expression: u.id)
  ///    ]))
  ///  .get()
  /// ```
  void orderBy(List<OrderClauseGenerator<T>> clauses) {
    orderByExpr = OrderBy(clauses.map((t) => t(table.asDslTable)).toList());
  }

  /// Creates an auto-updating stream that emits new items whenever this table
  /// changes.
  Stream<List<D>> watch() {
    final query = constructQuery();
    final fetcher = QueryStreamFetcher<List<D>>(
      readsFrom: watchedTables,
      fetchData: () => _getWithQuery(query),
      key: StreamKey(query.sql, query.boundVariables, D),
    );

    return database.createStream(fetcher);
  }
}

/// A select statement that is constructed with a raw sql prepared statement
/// instead of the high-level moor api.
class CustomSelectStatement {
  /// Tables this select statement reads from. When turning this select query
  /// into an auto-updating stream, that stream will emit new items whenever
  /// any of these tables changes.
  final Set<TableInfo> tables;

  /// The sql query string for this statement.
  final String query;

  /// The variables for the prepared statement, in the order they appear in
  /// [query]. Variables are denoted using a question mark in the query.
  final List<Variable> variables;
  final QueryEngine _db;

  /// Constructs a new
  CustomSelectStatement(this.query, this.variables, this.tables, this._db);

  /// Constructs a fetcher for this query. The fetcher is responsible for
  /// updating a stream at the right moment.
  QueryStreamFetcher<List<QueryRow>> constructFetcher() {
    final args = _mapArgs();

    return QueryStreamFetcher<List<QueryRow>>(
      readsFrom: tables,
      fetchData: () => _executeWithMappedArgs(args),
      key: StreamKey(query, args, QueryRow),
    );
  }

  /// Executes this query and returns the result.
  Future<List<QueryRow>> execute() async {
    return _executeWithMappedArgs(_mapArgs());
  }

  List<dynamic> _mapArgs() {
    final ctx = GenerationContext(_db);
    return variables.map((v) => v.mapToSimpleValue(ctx)).toList();
  }

  Future<List<QueryRow>> _executeWithMappedArgs(
      List<dynamic> mappedArgs) async {
    final result =
        await _db.executor.doWhenOpened((e) => e.runSelect(query, mappedArgs));

    return result.map((row) => QueryRow(row, _db)).toList();
  }
}

/// A result row in a [JoinedSelectStatement] that can consist of multiple
/// entities.
class TypedResult {
  /// Creates the result from the parsed table data.
  TypedResult(this._data);

  final Map<TableInfo, dynamic> _data;

  /// Reads all data that belongs to the given [table] from this row.
  D readTable<T, D>(TableInfo<T, D> table) {
    return _data[table] as D;
  }
}

/// For custom select statements, represents a row in the result set.
class QueryRow {
  /// The raw data in this row.
  final Map<String, dynamic> data;
  final QueryEngine _db;

  /// Construct a row from the raw data and the query engine that maps the raw
  /// response to appropriate dart types.
  QueryRow(this.data, this._db);

  /// Reads an arbitrary value from the row and maps it to a fitting dart type.
  /// The dart type [T] must be supported by the type system of the database
  /// used (mostly contains booleans, strings, integers and dates).
  T read<T>(String key) {
    final type = _db.typeSystem.forDartType<T>();

    return type.mapFromDatabaseResponse(data[key]);
  }

  /// Reads a bool from the column named [key].
  bool readBool(String key) => read<bool>(key);

  /// Reads a string from the column named [key].
  String readString(String key) => read<String>(key);

  /// Reads a int from the column named [key].
  int readInt(String key) => read<int>(key);

  /// Reads a [DateTime] from the column named [key].
  DateTime readDateTime(String key) => read<DateTime>(key);

  /// Reads a [Uint8List] from the column named [key].
  Uint8List readBlob(String key) => read<Uint8List>(key);
}
