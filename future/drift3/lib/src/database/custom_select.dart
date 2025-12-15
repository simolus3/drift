import 'package:meta/meta.dart';

import '../connection/connection.dart';
import '../connection/result_set.dart';
import '../connection/streams/store.dart';
import '../connection/streams/update_rules.dart';
import '../query_builder/results.dart';
import '../query_builder/schema/result_set.dart';
import '../query_builder/types.dart';
import 'connection_user.dart';
import 'selectable.dart';

/// A select statement that is constructed with a raw sql prepared statement
/// instead of the high-level drift api.
@internal
final class CustomSelectStatement<T> with Selectable<T> {
  /// Tables this select statement reads from. When turning this select query
  /// into an auto-updating stream, that stream will emit new items whenever
  /// any of these tables changes.
  final Set<ResultSet> tables;

  /// The sql query string for this statement.
  final String query;

  /// The variables for the prepared statement, in the order they appear in
  /// [query]. Variables are denoted using a question mark in the query.
  final List<MappedValue> variables;

  /// The function creating an optimized reader given the resolved result set.
  T Function(DriftRow) Function(DriftResultSet) createMapper;

  final DatabaseConnectionUser _db;
  final bool isReadOnly;

  /// Constructs a new custom select statement for the query, the variables,
  /// the affected tables and the database.
  CustomSelectStatement(
    this.query,
    this.variables,
    this.tables,
    this.createMapper,
    this._db,
    this.isReadOnly,
  );

  static CustomSelectStatement<CustomRow> unmapped(
    String query,
    List<MappedValue> variables,
    Set<ResultSet> tables,
    DatabaseConnectionUser db,
    bool isReadOnly,
  ) {
    return CustomSelectStatement(
      query,
      variables,
      tables,
      (resultSet) =>
          (row) => CustomRow(resultSet.resultSet, row.raw, db),
      db,
      isReadOnly,
    );
  }

  StatementInfo get _statement {
    return StatementInfo(
      query,
      variables: variables,
      needsResultSet: true,
      isReadOnly: isReadOnly,
    );
  }

  List<T> _mapResults(QueryResult result) {
    final driftResultSet = DriftResultSet(
      ResultSetStructure(),
      result.resultSet!,
      _db.dialect,
    );
    final mapper = createMapper(driftResultSet);
    return driftResultSet.map(mapper).toList();
  }

  @override
  Future<List<T>> get() async {
    final session = await _db.currentSession();

    final result = await session.execute(_statement);
    return _mapResults(result);
  }

  @override
  Stream<List<T>> watch() {
    final streams = _db.currentStreamQueryStore();
    final raw = streams.registerStream(
      QueryStreamFetcher(
        readsFrom: TableUpdateQuery.onAllTables(tables),
        key: StreamKey(query, variables),
        fetchData: () async {
          final currentSession = await _db.currentSession();
          return currentSession.execute(_statement);
        },
        prepare: () async => await _db.currentSession(),
      ),
    );
    return raw.map(_mapResults);
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
    return readWithType(_db.dialect.resolveType<T>(), name);
  }

  /// Interprets the column named [key] under the known drift type [type].
  ///
  /// Like [read], except that the [type] is fixed and not inferred from the
  /// type parameter [T]. Also, this method does not support nullable values -
  /// use [readNullableWithType] if needed.
  @optionalTypeArgs
  T readWithType<T extends Object>(SqlType<T> type, String key) {
    return type.resolveIn(_db.dialect).dartValue(_indexByName(key));
  }

  /// Reads a nullable value from this row.
  ///
  /// Just like for the non-nullable [read], the type [T] must be supported by
  /// drift (e.g. booleans, strings, numbers, dates, `Uint8List`s).
  T? readNullable<T extends Object>(String key) {
    return readNullableWithType(_db.dialect.resolveType<T>(), key);
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
  final DriftRow row;

  /// Default constructor.
  CustomResultSet(this.row);
}
