import 'package:meta/meta.dart';

import '../connection/connection.dart';
import '../connection/result_set.dart';
import '../connection/streams/store.dart';
import '../connection/streams/update_rules.dart';
import '../query_builder/results.dart';
import '../query_builder/schema/entities.dart';
import '../query_builder/types.dart';
import 'connection_user.dart';
import 'selectable.dart';

/// A select statement that is constructed with a raw sql prepared statement
/// instead of the high-level drift api.
@internal
abstract base class BaseCustomSelectStatement<T> with Selectable<T> {
  /// Tables this select statement reads from. When turning this select query
  /// into an auto-updating stream, that stream will emit new items whenever
  /// any of these tables changes.
  final Set<SchemaEntityWithResultSet> tables;

  /// The sql query string for this statement.
  final String query;

  /// The variables for the prepared statement, in the order they appear in
  /// [query]. Variables are denoted using a question mark in the query.
  final List<Object?> variables;

  final DatabaseConnectionUser _db;
  final bool isReadOnly;

  BaseCustomSelectStatement(
    this.query,
    this.variables,
    this.tables,
    this._db,
    this.isReadOnly,
  );

  StatementInfo get _statement {
    return StatementInfo(
      query,
      variables: variables,
      needsResultSet: true,
      isReadOnly: isReadOnly,
    );
  }
}

@internal
final class CustomSelectStatement<T> extends BaseCustomSelectStatement<T> {
  /// The function mapping raw rows into the result structure [T].
  T Function(RawRow) Function(RawResultSet) mapper;

  /// Constructs a new custom select statement for the query, the variables,
  /// the affected tables and the database.
  CustomSelectStatement(
    super.query,
    super.variables,
    super.tables,
    this.mapper,
    super._db,
    super.isReadOnly,
  );

  static CustomSelectStatement<CustomRow> unmapped(
    String query,
    List<Object?> variables,
    Set<SchemaEntityWithResultSet> tables,
    DatabaseConnectionUser db,
    bool isReadOnly,
  ) {
    return CustomSelectStatement(
      query,
      variables,
      tables,
      (rs) =>
          (row) => CustomRow(rs, row, db),
      db,
      isReadOnly,
    );
  }

  List<T> _mapResults(QueryResult result) {
    final resultSet = result.resultSet!;
    return resultSet.map(mapper(resultSet)).toList();
  }

  @override
  Future<List<T>> get() async {
    final session = await _db.currentSession();

    final result = await session.execute(_statement);
    return _mapResults(result);
  }

  @override
  QueryStream<List<T>> watch() {
    final streams = _db.currentStreamQueryStore();
    final fetcher = QueryStreamFetcher(
      readsFrom: TableUpdateQuery.onAllTables(tables),
      key: StreamKey(query, variables),
      fetchData: () async {
        final currentSession = await _db.currentSession();
        return currentSession.execute(_statement);
      },
      prepare: () async => await _db.currentSession(),
    );
    final raw = streams.registerStream(fetcher);
    return QueryStream(fetcher: fetcher, stream: raw.map(_mapResults));
  }
}

@internal
final class AsyncCustomSelectStatement<T> extends BaseCustomSelectStatement<T> {
  /// The function mapping raw rows into the result structure [T].
  Future<T> Function(RawRow) Function(RawResultSet) mapper;

  AsyncCustomSelectStatement(
    super.query,
    super.variables,
    super.tables,
    this.mapper,
    super.db,
    super.isReadOnly,
  );

  @override
  Future<List<T>> get() async {
    final session = await _db.currentSession();

    final result = await session.execute(_statement);
    final resultSet = result.resultSet!;
    final map = mapper(resultSet);

    return [for (final row in resultSet) await map(row)];
  }

  @override
  QueryStream<List<T>> watch() {
    final streams = _db.currentStreamQueryStore();
    final fetcher = QueryStreamFetcher(
      readsFrom: TableUpdateQuery.onAllTables(tables),
      // We want this stream to be unique since the mapper might run
      // additional queries we don't know about yet.
      key: null,
      fetchData: () async {
        // Spawn a read transaction since we might need multiple queries.
        return await _db.transaction(
          options: TransactionOptions(readOnly: isReadOnly),
          get,
        );
      },
      prepare: () async => await _db.currentSession(),
    );
    return QueryStream(
      fetcher: fetcher,
      stream: streams.registerStream(fetcher),
    );
  }
}

/// For custom select statements, represents a row in the result set.
final class CustomRow {
  /// The result set containing [row].
  final RawResultSet resultSet;

  /// The raw data in this row.
  ///
  /// Note that the values in this row aren't mapped to Dart yet. For instance,
  /// a [DateTime] might be stored as an [int] in [row] because that's the way
  /// it's stored in the database. To read a value, use any of the [read]
  /// methods.
  final RawRow row;
  final DatabaseConnectionUser _db;

  /// Wraps a raw [row] into a [CustomRow].
  CustomRow(this.resultSet, this.row, this._db);

  int _indexByName(String name) {
    for (final (i, column) in resultSet.columnNames.indexed) {
      if (column == name) {
        return i;
      }
    }

    throw ArgumentError.value(name, 'name', 'No column with that name');
  }

  /// Reads an arbitrary value from the row and maps it to a fitting dart type.
  ///
  /// The dart type [T] must be supported by the type system of the database
  /// used (mostly contains booleans, strings, numbers and dates).
  T read<T extends Object>(String name) {
    final type = BuiltinDriftType.forType<T>();
    if (type == null) {
      throw ArgumentError(
        'Tried to call read() with an unknown type ($T). For '
        'builtin types (String, int, BigInt, double, Uint8List, bool, DateTime, '
        'DatabaseJson), try adding a type argument. For other types, use '
        'readWithType.',
      );
    }

    return readWithType(
      BuiltinDriftType.forType<T>()!.resolveIn(_db.dialect),
      name,
    );
  }

  /// Interprets the column named [key] under the known drift type [type].
  ///
  /// Like [read], except that the [type] is fixed and not inferred from the
  /// type parameter [T]. Also, this method does not support nullable values -
  /// use [readNullableWithType] if needed.
  @optionalTypeArgs
  T readWithType<T extends Object>(SqlType<T> type, String key) {
    final index = _indexByName(key);

    return type.resolveIn(_db.dialect).dartValue(row[index]!);
  }

  /// Reads a nullable value from this row.
  ///
  /// Just like for the non-nullable [read], the type [T] must be supported by
  /// drift (e.g. booleans, strings, numbers, dates, `Uint8List`s).
  T? readNullable<T extends Object>(String key) {
    return readNullableWithType(
      BuiltinDriftType.forType<T>()!.resolveIn(_db.dialect),
      key,
    );
  }

  /// Interprets the column named [key] under the known drift type [type].
  ///
  /// Like [readNullable], except that the [type] is fixed and not inferred from
  /// the type parameter [T].
  @optionalTypeArgs
  T? readNullableWithType<T extends Object>(SqlType<T> type, String key) {
    final index = _indexByName(key);

    return switch (row[index]) {
      null => null,
      var other => type.resolveIn(_db.dialect).dartValue(other),
    };
  }
}

/// Base class for classes generated by custom queries in `.drift` files.
abstract base class CustomResultSet {
  /// The raw [DriftRow] from where this result set was extracted.
  final RawRow row;

  /// Default constructor.
  CustomResultSet(this.row);
}
