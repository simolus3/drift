import 'dart:core';
import 'dart:core' as core;
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:convert/convert.dart';
import 'package:meta/meta.dart';

import '../query_builder/query_builder.dart';

/// Database-specific helper methods mapping Dart values from and to SQL
/// variables or literals.
@sealed
class SqlTypes {
  // Stolen from DateTime._parseFormat
  static final RegExp _timeZoneInDateTime =
      RegExp(r' ?([-+])(\d\d)(?::?(\d\d))?$');

  /// Whether these type mappings have been configured to store date time values
  /// as text.
  ///
  /// When false (the default), date times values are stored as unix timestamps
  /// with second accuracy. When true, date time values are stored as an
  /// ISO-8601 string.
  ///
  /// For more details on the mapping, see [the documentation].
  ///
  /// [the documentation]: https://drift.simonbinder.eu/docs/getting-started/advanced_dart_tables/#supported-column-types
  final bool storeDateTimesAsText;

  final SqlDialect _dialect;

  /// Creates an [SqlTypes] mapper from the provided options.
  @internal
  const SqlTypes(this.storeDateTimesAsText,
      [this._dialect = SqlDialect.sqlite]);

  /// Maps a Dart object to a (possibly simpler) object that can be used as a
  /// parameter in raw sql queries.
  Object? mapToSqlVariable(Object? dartValue) {
    if (dartValue == null) return null;

    // These need special handling, all other types are a direct mapping
    if (dartValue is DateTime) {
      if (storeDateTimesAsText) {
        // sqlite3 assumes UTC by default, so we store the explicit UTC offset
        // along with the value. For UTC datetimes, there's nothing to change
        if (dartValue.isUtc) {
          return dartValue.toIso8601String();
        } else {
          final offset = dartValue.timeZoneOffset;
          // Quick sanity check: We can only store the UTC offset as `hh:mm`,
          // so if the offset has seconds for some reason we should refuse to
          // store that.
          if (offset.inSeconds - 60 * offset.inMinutes != 0) {
            throw ArgumentError.value(dartValue, 'dartValue',
                'Cannot be mapped to SQL: Invalid UTC offset $offset');
          }

          final hours = offset.inHours.abs();
          final minutes = offset.inMinutes.abs() - 60 * hours;

          // For local date times, add the offset as ` +hh:mm` in the end. This
          // format is understood by `DateTime.parse` and date time functions in
          // sqlite.
          final prefix = offset.isNegative ? ' -' : ' +';
          final formattedOffset = '${hours.toString().padLeft(2, '0')}:'
              '${minutes.toString().padLeft(2, '0')}';

          return '${dartValue.toIso8601String()}$prefix$formattedOffset';
        }
      } else {
        return dartValue.millisecondsSinceEpoch ~/ 1000;
      }
    }

    if (dartValue is bool && _dialect == SqlDialect.sqlite) {
      return dartValue ? 1 : 0;
    }

    if (dartValue is DriftAny) {
      return dartValue.rawSqlValue;
    }

    return dartValue;
  }

  /// Maps the [dart] value into a SQL literal that can be embedded in SQL
  /// queries.
  String mapToSqlLiteral(Object? dart) {
    if (dart == null) return 'NULL';

    // todo: Inline and remove types in the next major drift version
    if (dart is bool) {
      if (_dialect == SqlDialect.sqlite) {
        return dart ? '1' : '0';
      } else {
        return dart ? 'true' : 'false';
      }
    } else if (dart is String) {
      // From the sqlite docs: (https://www.sqlite.org/lang_expr.html)
      // A string constant is formed by enclosing the string in single quotes
      // (').
      // A single quote within the string can be encoded by putting two single
      // quotes in a row - as in Pascal. C-style escapes using the backslash
      // character are not supported because they are not standard SQL.
      final escapedChars = dart.replaceAll('\'', '\'\'');
      return "'$escapedChars'";
    } else if (dart is num || dart is BigInt) {
      return dart.toString();
    } else if (dart is DateTime) {
      if (storeDateTimesAsText) {
        final encoded = mapToSqlVariable(dart).toString();
        return "'$encoded'";
      } else {
        return (dart.millisecondsSinceEpoch ~/ 1000).toString();
      }
    } else if (dart is Uint8List) {
      // BLOB literals are string literals containing hexadecimal data and
      // preceded by a single "x" or "X" character. Example: X'53514C697465'
      return "x'${hex.encode(dart)}'";
    } else if (dart is DriftAny) {
      return mapToSqlLiteral(dart.rawSqlValue);
    }

    throw ArgumentError.value(dart, 'dart',
        'Must be null, bool, String, int, DateTime, Uint8List or double');
  }

  /// Maps a raw [sqlValue] to Dart given its sql [type].
  T? read<T extends Object>(DriftSqlType<T> type, Object? sqlValue) {
    if (sqlValue == null) return null;

    // ignore: unnecessary_cast
    switch (type as DriftSqlType<Object>) {
      case DriftSqlType.bool:
        return (sqlValue != 0) as T;
      case DriftSqlType.string:
        return sqlValue.toString() as T;
      case DriftSqlType.bigInt:
        if (sqlValue is BigInt) return sqlValue as T?;
        if (sqlValue is int) return BigInt.from(sqlValue) as T;
        return BigInt.parse(sqlValue.toString()) as T;
      case DriftSqlType.int:
        if (sqlValue is int) return sqlValue as T;
        if (sqlValue is BigInt) return sqlValue.toInt() as T;
        return int.parse(sqlValue.toString()) as T;
      case DriftSqlType.dateTime:
        if (storeDateTimesAsText) {
          final rawValue = read(DriftSqlType.string, sqlValue)!;
          DateTime result;

          // We store date times like this:
          //
          //  - if it's in UTC, we call [DateTime.toIso8601String], so there's a
          //    trailing `Z`. We can just use [DateTime.parse] and get an utc
          //    datetime back.
          //  - for local date times, we append the time zone offset, e.g.
          //    `+02:00`. [DateTime.parse] respects this UTC offset and returns
          //    the correct date, but it returns it in UTC. Since we only use
          //    this format for local times, we need to transform it back to
          //    local.
          //
          // Additionally, complex date time expressions are wrapped in a
          // `datetime` sqlite call, which doesn't append a `Z` or a time zone
          // offset. As sqlite3 always uses UTC for these computations
          // internally, we'll return a UTC datetime as well.
          if (_timeZoneInDateTime.hasMatch(rawValue)) {
            // Case 2: Explicit time zone offset given, we do this for local
            // dates.
            result = DateTime.parse(rawValue).toLocal();
          } else if (rawValue.endsWith('Z')) {
            // Case 1: Date time in UTC, [DateTime.parse] will do the right
            // thing.
            result = DateTime.parse(rawValue);
          } else {
            // Result from complex date tmie transformation. Interpret as UTC,
            // which is what sqlite3 does by default.
            result = DateTime.parse('${rawValue}Z');
          }

          return result as T;
        } else {
          final unixSeconds = read(DriftSqlType.int, sqlValue)!;
          return DateTime.fromMillisecondsSinceEpoch(unixSeconds * 1000) as T;
        }
      case DriftSqlType.blob:
        if (sqlValue is String) {
          final list = sqlValue.codeUnits;
          return Uint8List.fromList(list) as T;
        }
        return sqlValue as T;
      case DriftSqlType.double:
        return (sqlValue as num?)?.toDouble() as T;
      case DriftSqlType.any:
        return DriftAny(sqlValue) as T;
    }
  }
}

/// A drift type around a SQL value with an unknown type.
///
/// In [STRICT tables], a column can be declared with the type `ANY`. In such
/// column, _any_ value can be stored without sqlite3 (or drift) attempting to
/// cast it to a specific type. Thus, the [rawSqlValue] is directly passed to
/// or from the underlying SQL database package.
///
/// To write a custom value into the database with [DriftAny], you can construct
/// it and pass it into a [Variable] or into a companion of a table having a
/// column with an `ANY` type.
///
/// [STRICT tables]: https://www.sqlite.org/stricttables.html
@sealed
class DriftAny {
  /// The direct, unmodified SQL value being wrapped by this [DriftAny]
  /// instance.
  ///
  /// Please note that a [rawSqlValue] can't always be mapped to a unique Dart
  /// interpretation - see [readAs] for a discussion of which additional
  /// information is necessary to interpret this value.
  final Object rawSqlValue;

  /// Constructs a [DriftAny] wrapper around the [rawSqlValue] that will be
  /// written into the database without any modification by drift.
  const DriftAny(this.rawSqlValue) : assert(rawSqlValue is! DriftAny);

  /// Interprets the [rawSqlValue] as a drift [type] under the configuration
  /// given by [types].
  ///
  /// A given [rawSqlValue] may have different Dart representations that would
  /// be given to you by drift. For instance, the SQL value `1` could have the
  /// following possible Dart interpretations:
  ///
  ///   - The [bool] constant `true`.
  ///   - The [int] constant `1`
  ///   - The big integer [BigInt.one].
  ///   - All [DateTime] values having `1` as their UNIX timestamp in seconds
  ///     (this depends on the configuration - drift can be configured to store
  ///     date times [as text] too).
  ///
  /// For this reason, it is not always possible to directly map these raw
  /// values to Dart without further information. Drift also needs to know the
  /// expected type and some configuration options for context. For all SQL
  /// types _except_ `ANY`, drift will do this for you behind the scenes.
  ///
  /// You can obtain a [types] instance from a database or DAO by using
  /// [DatabaseConnectionUser.typeMapping].
  ///
  /// [as text]: https://drift.simonbinder.eu/docs/getting-started/advanced_dart_tables/#datetime-options
  T readAs<T extends Object>(DriftSqlType<T> type, SqlTypes types) {
    return types.read<T>(type, rawSqlValue)!;
  }

  @override
  int get hashCode => Object.hash(DriftAny, rawSqlValue);

  @override
  bool operator ==(other) {
    return identical(this, other) ||
        other is DriftAny && other.rawSqlValue == rawSqlValue;
  }
}

/// In [DriftSqlType.forNullableType], we need to do an `is` check over
/// `DriftSqlType<T>` with a potentially nullable `T`. Since `DriftSqlType` is
/// defined with a non-nullable `T`, this is illegal.
/// The non-nullable upper bound in [DriftSqlType] is generally useful, for
/// instance because it works well with [SqlTypes.read] which can then have a
/// sound nullable return type.
///
/// As a hack, we define this base class that doesn't have this restriction and
/// use this one for type checks.
abstract class _InternalDriftSqlType<T> {}

/// An enumation of type mappings that are builtin to drift and `drift_dev`.
enum DriftSqlType<T extends Object> implements _InternalDriftSqlType<T> {
  /// A boolean type, represented as `0` or `1` (int) in SQL.
  bool<core.bool>(),

  /// A textual type, represented as `TEXT` in sqlite.
  string<String>(),

  /// A 64-bit int type that is represented a [BigInt] in Dart for better
  /// compatibility with the web. Represented as an `INTEGER` in sqlite or as
  /// a `bigint` in postgres.
  bigInt<BigInt>(),

  /// A 64-bit int.
  ///
  /// Represented as an `INTEGER` in sqlite or as a `bigint` in postgres.
  int<core.int>(),

  /// A [DateTime] value.
  ///
  /// Depending on the options choosen at build-time, this is either stored as
  /// an unix timestamp (the default) or as a ISO 8601 string.
  dateTime<DateTime>(),

  /// A [Uint8List] value.
  ///
  /// This is stored as a `BLOB` in sqlite or as a `bytea` type in postgres.
  blob<Uint8List>(),

  /// A [double] value, stored as a `REAL` type in sqlite.
  double<core.double>(),

  /// The drift type for columns declared as `ANY` in [STRICT tables].
  ///
  /// [STRICT tables]: https://www.sqlite.org/stricttables.html
  any<DriftAny>();

  /// Returns a suitable representation of this type in SQL.
  String sqlTypeName(GenerationContext context) {
    final dialect = context.dialect;

    // ignore: unnecessary_cast
    switch (this as DriftSqlType<Object>) {
      case DriftSqlType.bool:
        return dialect == SqlDialect.sqlite ? 'INTEGER' : 'boolean';
      case DriftSqlType.string:
        return dialect == SqlDialect.sqlite ? 'TEXT' : 'text';
      case DriftSqlType.bigInt:
      case DriftSqlType.int:
        return dialect == SqlDialect.sqlite ? 'INTEGER' : 'bigint';
      case DriftSqlType.dateTime:
        if (context.typeMapping.storeDateTimesAsText) {
          return dialect == SqlDialect.sqlite ? 'TEXT' : 'text';
        } else {
          return dialect == SqlDialect.sqlite ? 'INTEGER' : 'bigint';
        }
      case DriftSqlType.blob:
        return dialect == SqlDialect.sqlite ? 'BLOB' : 'bytea';
      case DriftSqlType.double:
        return dialect == SqlDialect.sqlite ? 'REAL' : 'float8';
      case DriftSqlType.any:
        return 'ANY';
    }
  }

  void _addToMap(Map<Type, DriftSqlType> map) {
    _addToTypeMap<T>(map, this);
    // Unfortunately, `T?` by itself is not an expression so we have to jump
    // through hoops to add the nullable variant to the type map.
    _addToTypeMap<T?>(map, this);
  }

  static Map<Type, DriftSqlType> _dartToDrift = () {
    final map = <Type, DriftSqlType>{};

    for (final value in values) {
      value._addToMap(map);
    }

    return map;
  }();

  static void _addToTypeMap<T>(
      Map<Type, DriftSqlType> map, DriftSqlType<Object> type) {
    map[T] = type;
  }

  /// Attempts to find a suitable SQL type for the [Dart] type passed to this
  /// method.
  ///
  /// The [Dart] type must be the type of the instance _after_ applying type
  /// converters.
  static DriftSqlType<Dart> forType<Dart extends Object>() {
    final type = _dartToDrift[Dart];

    if (type == null) {
      throw ArgumentError('Could not find a matching SQL type for $Dart');
    }

    return type as DriftSqlType<Dart>;
  }

  /// A variant of [forType] that also works for nullable [Dart] types.
  ///
  /// Using [forType] should pretty much always be preferred over this method,
  /// this one just exists for backwards compatibility.
  static DriftSqlType forNullableType<Dart>() {
    // Lookup the type in the map first for faster lookups. Go back to a full
    // typecheck where that doesn't work (which can be the case for complex
    // type like `forNullableType<FutureOr<int?>>`).
    final type = _dartToDrift[Dart] ??
        values.whereType<_InternalDriftSqlType<Dart>>().singleOrNull;

    if (type == null) {
      throw ArgumentError('Could not find a matching SQL type for $Dart');
    }

    return type as DriftSqlType;
  }
}
