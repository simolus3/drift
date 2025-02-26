import 'package:charcode/ascii.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sqlparser/sqlparser.dart' hide JsonKey;
import 'package:drift/drift3.dart' show DriftDialect;
import 'package:drift/dialect/sqlite.dart';
import 'package:string_scanner/string_scanner.dart';

part '../generated/analysis/dialect.g.dart';

/// A static description of a [DriftDialect] used for analysis.
sealed class RegisteredDriftDialect {
  /// A user-visible (and customizable) name of the dialect.
  String get name;

  bool get supportsIndexedParameters;

  DriftDialect instantiate();

  Map<String, Object?> toJson();
}

@JsonSerializable()
final class DriftSqliteDialect implements RegisteredDriftDialect {
  static const _defaultSqliteVersion = SqliteVersion.v3(34);

  @override
  String get name => 'sqlite';

  @override
  bool get supportsIndexedParameters => true;

  final List<SqlModule> modules;
  final bool dateTimesAsText;
  final bool binaryJson;

  /// The assumed sqlite version used when analyzing queries.
  @_SqliteVersionConverter()
  final SqliteVersion version;

  final Map<String, KnownSqliteFunction> knownFunctions;

  const DriftSqliteDialect({
    this.modules = const [],
    this.dateTimesAsText = false,
    this.binaryJson = true,
    this.version = DriftSqliteDialect._defaultSqliteVersion,
    this.knownFunctions = const {},
  });

  factory DriftSqliteDialect.fromJson(Map<String, Object?> json) =>
      _$DriftSqliteDialectFromJson(json);

  /// Whether the [module] has been enabled in this configuration.
  bool hasModule(SqlModule module) => modules.contains(module);

  @override
  Map<String, Object?> toJson() => _$DriftSqliteDialectToJson(this);

  @override
  DriftDialect instantiate() {
    return SqliteDialect(
      options: SqliteOptions(
        strictTablesByDefault: false,
        storeDateTimesAsText: dateTimesAsText,
        useBinaryJsonRepresentation: binaryJson,
      ),
    );
  }
}

final class CustomDriftDialect implements RegisteredDriftDialect {
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  final String name;
  @override
  bool get supportsIndexedParameters => true;

  CustomDriftDialect(this.name);

  @override
  Map<String, Object?> toJson() {
    return const {};
  }

  @override
  DriftDialect instantiate() {
    // Use default sqlite dialect as a fallback
    return SqliteDialect();
  }
}

final class DriftPostgresDialect implements RegisteredDriftDialect {
  @override
  String get name => 'postgres';

  @override
  bool get supportsIndexedParameters => true;

  @override
  Map<String, Object?> toJson() {
    return const {};
  }

  @override
  DriftDialect instantiate() {
    // TODO: Port postgres dialect
    return SqliteDialect();
  }
}

final class DriftMariadbDialect implements RegisteredDriftDialect {
  @override
  String get name => 'mariadb';

  @override
  bool get supportsIndexedParameters => false;

  @override
  Map<String, Object?> toJson() {
    return const {};
  }

  @override
  DriftDialect instantiate() {
    // TODO: Port mariadb dialect
    return SqliteDialect();
  }
}

class KnownSqliteFunction {
  final List<ResolvedType> argumentTypes;
  final ResolvedType returnType;

  KnownSqliteFunction(this.argumentTypes, this.returnType);

  factory KnownSqliteFunction.fromJson(String json) {
    final scanner = StringScanner(json);
    final types = SchemaFromCreateTable(driftExtensions: true);

    ResolvedType parseType() {
      scanner.scan(_whitespace);
      scanner.expect(_word, name: 'Type name');
      final type = types.resolveColumnType(scanner.lastMatch?.group(0));

      return type.copyWith(nullable: scanner.scan(_null));
    }

    final argumentTypes = <ResolvedType>[];
    final returnType = parseType();

    scanner
      ..scan(_whitespace)
      ..expectChar($openParen)
      ..scan(_whitespace);

    if (scanner.peekChar() != $closeParen) {
      argumentTypes.add(parseType());
      while (scanner.scanChar($comma)) {
        argumentTypes.add(parseType());
      }
    }

    scanner
      ..scan(_whitespace)
      ..expectChar($closeParen)
      ..scan(_whitespace)
      ..expectDone();

    return KnownSqliteFunction(argumentTypes, returnType);
  }

  String toJson() {
    String toString(ResolvedType type) {
      switch (type.type!) {
        case BasicType.nullType:
          return 'NULL';
        case BasicType.int:
          return 'INTEGER';
        case BasicType.real:
          return 'REAL';
        case BasicType.text:
          return 'TEXT';
        case BasicType.blob:
          return 'BLOB';
        case BasicType.any:
          return 'ANY';
      }
    }

    final types = argumentTypes.map(toString).join(', ');
    return '${toString(returnType)}($types)';
  }

  static final _word = RegExp(r'\w+');
  static final _null = RegExp(r'\s+null', caseSensitive: false);
  static final _whitespace = RegExp(r'\s*');
}

final class _SqliteVersionConverter
    extends JsonConverter<SqliteVersion, String> {
  static final _versionRegex = RegExp(r'(\d+)\.(\d+)');

  const _SqliteVersionConverter();

  @override
  SqliteVersion fromJson(String json) {
    final match = _versionRegex.firstMatch(json);
    if (match == null) {
      throw ArgumentError.value(
        json,
        'json',
        'Not a valid sqlite version: Expected format major.minor (e.g. 3.34)',
      );
    }

    final major = int.parse(match.group(1)!);
    final minor = int.parse(match.group(2)!);

    final version = SqliteVersion(major, minor, 0);
    if (version < SqliteVersion.minimum) {
      throw ArgumentError.value(
        json,
        'json',
        'Version is not supported for analysis (minimum is '
            '${SqliteVersion.minimum}).',
      );
    } else if (version > SqliteVersion.current) {
      throw ArgumentError.value(
        json,
        'json',
        'Version is not supported for analysis (current maximum is '
            '${SqliteVersion.current}).',
      );
    }

    return version;
  }

  @override
  String toJson(SqliteVersion object) {
    return '${object.major}.${object.minor}';
  }
}

/// Set of sqlite modules that require special knowledge from the generator.
enum SqlModule {
  /// Enables support for the json1 module and its functions when parsing sql
  /// queries.
  json1,

  /// Enables support for the fts5 module and its functions when parsing sql
  /// queries.
  fts5,

  /// Enables support for mathematical functions only available in `moor_ffi`.
  // note: We're ignoring the warning because we can't change the json key
  // ignore: constant_identifier_names
  moor_ffi,

  /// Enables support for [built in math functions][math funs] when analysing
  /// sql queries.
  ///
  /// [math funs]: https://www.sqlite.org/lang_mathfunc.html
  math,

  /// Enables support for the rtree module and its functions when parsing sql
  /// queries.
  rtree,

  spellfix1,

  /// The Geopoly module is an alternative interface to the R-Tree extension
  /// that uses the GeoJSON notation (RFC-7946)
  /// to describe two-dimensional polygons.
  ///
  /// Geopoly includes functions for detecting
  /// when one polygon is contained within or overlaps with another,
  /// for computing the area enclosed by a polygon
  /// for doing linear transformations of polygons,
  /// for rendering polygons as SVG, and other similar operations.
  ///
  /// See more: https://www.sqlite.org/geopoly.html
  geopoly,

  /// Enables the dbstat table providing insights into the disk state occupied
  /// by certain tables.
  dbstat,
}
