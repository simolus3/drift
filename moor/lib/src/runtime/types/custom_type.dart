part of 'sql_types.dart';

/// Maps a custom dart object of type [D] into a primitive type [S] understood
/// by the sqlite backend.
///
/// Moor currently supports [DateTime], [double], [int], [Uint8List], [bool]
/// and [String] for [S].
///
/// Also see [ColumnBuilder.map] for details.
abstract class TypeConverter<D, S> {
  /// Empty constant constructor so that subclasses can have a constant
  /// constructor.
  const TypeConverter();

  /// Map a value from an object in Dart into something that will be understood
  /// by the database. Be aware that [value] is nullable.
  S mapToSql(D value);

  /// Maps a column from the database back to Dart. Be aware that [fromDb] is
  /// nullable.
  D mapToDart(S fromDb);
}
