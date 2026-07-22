import 'package:drift/drift.dart' show SqlDialect;
import 'package:json_annotation/json_annotation.dart';
import 'package:sqlparser/sqlparser.dart' hide JsonKey;

import '../writer/writer.dart';
import 'options.dart';

part '../generated/analysis/dialect.g.dart';

base class ResolvedDialect {
  /// The matching drift2 dialect.
  final SqlDialect dialect;

  const ResolvedDialect(this.dialect);

  factory ResolvedDialect.fromJson(Map json) {
    return switch (json['dialect']) {
      'sqlite' => _$Drift3SqliteDialectFromJson(json),
      'mysql' || 'mariadb' => ResolvedDialect(SqlDialect.mariadb),
      'postgres' => ResolvedDialect(SqlDialect.postgres),
      'duckdb' => ResolvedDialect(SqlDialect.duckdb),
      _ => throw ArgumentError.value(
        json['dialect'],
        'dialect',
        'Unknown dialect, use one of ${SqlDialect.values.map((e) => e.name).join(', ')}',
      ),
    };
  }

  bool get canInstantiateOptions => false;

  void writeOptions(TextEmitter scope) {}

  Map<String, Object?> toJson() {
    return {'dialect': dialect.name};
  }
}

/// A resolved drift3 SQLite dialect with associated options.
@JsonSerializable()
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
  }) : super(SqlDialect.sqlite);

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
