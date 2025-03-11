import 'package:meta/meta.dart';

import '../../connections/connection.dart';
import '../../connections/result_set.dart';
import '../../query_builder.dart';
import '../selectable.dart';
import 'connection_user.dart';

/// A select statement that is constructed with a raw sql prepared statement
/// instead of the high-level drift api.
final class CustomSelectStatement with Selectable<CustomRow> {
  /// Tables this select statement reads from. When turning this select query
  /// into an auto-updating stream, that stream will emit new items whenever
  /// any of these tables changes.
  final Set<ResultSet> tables;

  /// The sql query string for this statement.
  final String query;

  /// The variables for the prepared statement, in the order they appear in
  /// [query]. Variables are denoted using a question mark in the query.
  final List<Variable> variables;

  final DatabaseConnectionUser _db;

  /// Constructs a new custom select statement for the query, the variables,
  /// the affected tables and the database.
  CustomSelectStatement(this.query, this.variables, this.tables, this._db);

  @override
  Future<List<CustomRow>> get() async {
    final session = await _db.currentSession();
    final mappedVariables = [
      for (final variable in variables)
        (variable.resolveType(_db.dialect), variable.value)
    ];

    final result = await session.execute(StatementInfo.fromText(query,
        variables: mappedVariables, needsResultSet: true));
    return result.resultSet!.map((e) => CustomRow._(e, _db)).toList();
  }

  @override
  Stream<List<CustomRow>> watch() {
    // TODO: implement watch
    throw UnimplementedError();
  }
}

/// For custom select statements, represents a row in the result set.
final class CustomRow {
  /// The raw data in this row.
  ///
  /// Note that the values in this row aren't mapped to Dart yet. For instance,
  /// a [DateTime] might be stored as an [int] in [row] because that's the way
  /// it's stored in the database. To read a value, use any of the [read]
  /// methods.
  final RawRow row;
  final DatabaseConnectionUser _db;

  CustomRow._(this.row, this._db);

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
    return type.dartValue(_db.dialect, row.byName(key)!);
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
    return switch (row.byName(key)) {
      null => null,
      var other => type.dartValue(_db.dialect, other),
    };
  }
}
