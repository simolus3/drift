import 'package:json_annotation/json_annotation.dart';
import 'package:sqlparser/sqlparser.dart' hide JsonKey;

import '../writer/writer.dart';
import 'options.dart';

part '../generated/analysis/dialect.g.dart';

enum KnownSqlDialect {
  // Names here must match those of SqlDialect in drift.
  sqlite,
  mysql,
  postgres,
  duckdb,
  mariadb;

  bool get supportsIndexedParameters => this != duckdb && this != mariadb;

  String escape(String original) {
    final escapeChar = this == mariadb ? '`' : '"';

    final source = original.replaceAll(escapeChar, escapeChar * 2);
    return '$escapeChar$source$escapeChar';
  }
}

base class ResolvedDialect {
  /// The matching dialect.
  final KnownSqlDialect dialect;

  const ResolvedDialect(this.dialect);

  factory ResolvedDialect.fromJson(Map json) {
    return switch (json['dialect']) {
      'sqlite' => _$Drift3SqliteDialectFromJson(json),
      'mysql' || 'mariadb' => ResolvedDialect(KnownSqlDialect.mariadb),
      'postgres' => _$Drift3PostgresDialectFromJson(json),
      'duckdb' => ResolvedDialect(KnownSqlDialect.duckdb),
      // TODO: Support custom dialects?
      _ => throw ArgumentError.value(
        json['dialect'],
        'dialect',
        'Unknown dialect, use one of ${KnownSqlDialect.values.map((e) => e.name).join(', ')}',
      ),
    };
  }

  bool get canInstantiateOptions => false;

  void writeOptions(TextEmitter scope) {}

  void writeDialectFactory(TextEmitter scope) {
    final dialectClass = switch (dialect) {
      KnownSqlDialect.sqlite => scope.refUri(
        Uri.parse('package:drift_sqlite/drift_sqlite.dart'),
        'SqliteDialect',
      ),
      KnownSqlDialect.postgres => scope.refUri(
        Uri.parse(
          'package:drift_postgres/src/drift3_preview/drift_postgres.dart',
        ),
        'PostgresDialect',
      ),
      _ => throw UnsupportedError(
        'Drift3 does not support ${dialect.name} yet',
      ),
    };

    scope
      ..write(dialectClass)
      ..write('.new');
  }

  Map<String, Object?> toJson() {
    return {'dialect': dialect.name};
  }
}

/// A resolved drift3 SQLite dialect with associated options.
@JsonSerializable(constructor: 'withOptions')
final class Drift3SqliteDialect extends ResolvedDialect
    implements SqliteAnalysisOptions {
  @JsonKey(name: 'modules')
  @override
  final List<SqlModule> modules;

  @SqliteVersionConverter()
  @override
  final SqliteVersion? version;

  @override
  final Map<String, KnownSqliteFunction> knownFunctions;

  @TableFromSql()
  @override
  final List<Table> knownTables;

  final bool strictTablesByDefault;
  final bool storeDateTimesAsText;
  final bool useBinaryJsonRepresentation;

  const Drift3SqliteDialect.withOptions({
    this.modules = const [],
    this.version,
    this.knownFunctions = const {},
    this.knownTables = const [],
    this.strictTablesByDefault = true,
    this.storeDateTimesAsText = true,
    this.useBinaryJsonRepresentation = true,
  }) : super(KnownSqlDialect.sqlite);

  @override
  Map<String, Object?> toJson() => {
    ...super.toJson(),
    ..._$Drift3SqliteDialectToJson(this),
  };

  @override
  bool get canInstantiateOptions => true;

  @override
  void writeOptions(TextEmitter scope) {
    scope
      ..write('const ')
      ..writeUriRef(_driftSqlite, 'SqliteOptions')
      ..write('(')
      ..write('strictTablesByDefault: $strictTablesByDefault,')
      ..write('storeDateTimesAsText: $storeDateTimesAsText,')
      ..write('useBinaryJsonRepresentation: $useBinaryJsonRepresentation,')
      ..write(')');
  }

  static final _driftSqlite = Uri.parse(
    'package:drift_sqlite/drift_sqlite.dart',
  );
}

@JsonSerializable(constructor: 'withOptions')
final class Drift3PostgresDialect extends ResolvedDialect {
  final bool useBinaryJsonRepresentation;

  Drift3PostgresDialect.withOptions({this.useBinaryJsonRepresentation = true})
    : super(KnownSqlDialect.postgres);

  @override
  Map<String, Object?> toJson() => {
    ...super.toJson(),
    ..._$Drift3PostgresDialectToJson(this),
  };

  @override
  bool get canInstantiateOptions => true;

  @override
  void writeOptions(TextEmitter scope) {
    scope
      ..write('const ')
      ..writeUriRef(_driftPostgres, 'PostgresDialectOptions')
      ..write('(')
      ..write('useJsonb: $useBinaryJsonRepresentation,')
      ..write(')');
  }

  static final _driftPostgres = Uri.parse(
    'package:drift_postgres/drift_postgres.dart',
  );
}
