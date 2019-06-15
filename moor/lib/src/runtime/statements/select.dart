import 'dart:async';

import 'package:meta/meta.dart';
import 'package:moor/moor.dart';
import 'package:moor/src/runtime/components/component.dart';
import 'package:moor/src/runtime/components/join.dart';
import 'package:moor/src/runtime/components/where.dart';
import 'package:moor/src/runtime/database.dart';
import 'package:moor/src/runtime/executor/stream_queries.dart';
import 'package:moor/src/runtime/expressions/expression.dart';
import 'package:moor/src/runtime/statements/query.dart';
import 'package:moor/src/runtime/structure/table_info.dart';

typedef OrderingTerm OrderClauseGenerator<T>(T tbl);

class JoinedSelectStatement<FirstT extends Table, FirstD>
    extends Query<FirstT, FirstD>
    with LimitContainerMixin, Selectable<TypedResult> {
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

        // We run into problems when two tables have a column with the same name
        // as we then wouldn't know which column is which. So, we create a
        // column alias that matches what is expected by the mapping function
        // in _getWithQuery by prefixing the table name.
        // We might switch to parsing via the index of the column in a row in
        // the future, but that's the solution for now.

        column.writeInto(ctx);
        ctx.buffer.write(' AS "');
        column.writeInto(ctx, ignoreEscape: true);
        ctx.buffer.write('"');

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

  /// Applies the [predicate] as the where clause, which will be used to filter
  /// results.
  ///
  /// The clause should only refer to columns defined in one of the tables
  /// specified during [SimpleSelectStatement.join].
  ///
  /// With the example of a todos table which refers to categories, we can write
  /// something like
  /// ```dart
  /// final query = select(todos)
  /// .join([
  ///   leftOuterJoin(categories, categories.id.equalsExp(todos.category)),
  /// ])
  /// ..where(and(todos.name.like("%Important"), categories.name.equals("Work")));
  /// ```
  void where(Expression<bool, BoolType> predicate) {
    if (whereExpr == null) {
      whereExpr = Where(predicate);
    } else {
      whereExpr = Where(and(whereExpr.predicate, predicate));
    }
  }

  /// Orders the results of this statement by the ordering [terms].
  void orderBy(List<OrderingTerm> terms) {
    orderByExpr = OrderBy(terms);
  }

  @override
  Stream<List<TypedResult>> watch() {
    final ctx = constructQuery();
    final fetcher = QueryStreamFetcher<List<TypedResult>>(
      readsFrom: watchedTables,
      fetchData: () => _getWithQuery(ctx),
      key: StreamKey(ctx.sql, ctx.boundVariables, TypedResult),
    );

    return database.createStream(fetcher);
  }

  @override
  Future<List<TypedResult>> get() async {
    final ctx = constructQuery();
    return _getWithQuery(ctx);
  }

  Future<List<TypedResult>> _getWithQuery(GenerationContext ctx) async {
    final results = await ctx.executor.doWhenOpened((e) async {
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

      return TypedResult(map, QueryRow(row, database));
    }).toList();
  }
}

/// A select statement that doesn't use joins
class SimpleSelectStatement<T extends Table, D> extends Query<T, D>
    with SingleTableQueryMixin<T, D>, LimitContainerMixin<T, D>, Selectable<D> {
  SimpleSelectStatement(QueryEngine database, TableInfo<T, D> table)
      : super(database, table);

  @visibleForOverriding
  Set<TableInfo> get watchedTables => {table};

  @override
  void writeStartPart(GenerationContext ctx) {
    ctx.buffer.write('SELECT * FROM ${table.tableWithAlias}');
  }

  @override
  Future<List<D>> get() async {
    final ctx = constructQuery();
    return _getWithQuery(ctx);
  }

  Future<List<D>> _getWithQuery(GenerationContext ctx) async {
    final results = await ctx.executor.doWhenOpened((e) async {
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
    final statement = JoinedSelectStatement(database, table, joins);

    if (whereExpr != null) {
      statement.where(whereExpr.predicate);
    }
    if (orderByExpr != null) {
      statement.orderBy(orderByExpr.terms);
    }

    return statement;
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

  @override
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
class CustomSelectStatement with Selectable<QueryRow> {
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

  /// Constructs a new custom select statement for the query, the variables,
  /// the affected tables and the database.
  CustomSelectStatement(this.query, this.variables, this.tables, this._db);

  /// Constructs a fetcher for this query. The fetcher is responsible for
  /// updating a stream at the right moment.
  @Deprecated(
      'There is no need to use this method. Please use watch() directly')
  QueryStreamFetcher<List<QueryRow>> constructFetcher() {
    return _constructFetcher();
  }

  /// Constructs a fetcher for this query. The fetcher is responsible for
  /// updating a stream at the right moment.
  QueryStreamFetcher<List<QueryRow>> _constructFetcher() {
    final args = _mapArgs();

    return QueryStreamFetcher<List<QueryRow>>(
      readsFrom: tables,
      fetchData: () => _executeWithMappedArgs(args),
      key: StreamKey(query, args, QueryRow),
    );
  }

  @override
  Future<List<QueryRow>> get() async {
    return _executeWithMappedArgs(_mapArgs());
  }

  @override
  Stream<List<QueryRow>> watch() {
    return _db.createStream(_constructFetcher());
  }

  /// Executes this query and returns the result.
  @Deprecated('Use get() instead')
  Future<List<QueryRow>> execute() async {
    return get();
  }

  List<dynamic> _mapArgs() {
    final ctx = GenerationContext.fromDb(_db);
    return variables.map((v) => v.mapToSimpleValue(ctx)).toList();
  }

  Future<List<QueryRow>> _executeWithMappedArgs(
      List<dynamic> mappedArgs) async {
    final result =
        await _db.executor.doWhenOpened((e) => e.runSelect(query, mappedArgs));

    return result.map((row) => QueryRow(row, _db)).toList();
  }
}

/// A result row in a [JoinedSelectStatement] that can parse the result of
/// multiple entities.
class TypedResult {
  /// Creates the result from the parsed table data.
  TypedResult(this._parsedData, this.rawData);

  final Map<TableInfo, dynamic> _parsedData;

  /// The raw data contained in this row.
  final QueryRow rawData;

  /// Reads all data that belongs to the given [table] from this row.
  D readTable<T extends Table, D>(TableInfo<T, D> table) {
    return _parsedData[table] as D;
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
