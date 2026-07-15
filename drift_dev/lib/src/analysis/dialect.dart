import 'package:drift/drift.dart' show SqlDialect;
import 'package:json_annotation/json_annotation.dart';
import 'package:sqlparser/sqlparser.dart' hide JsonKey;

import 'options.dart';

part '../generated/analysis/dialect.g.dart';

base class ResolvedDialect {
  /// The matching drift2 dialect.
  final SqlDialect dialect;

  const ResolvedDialect(this.dialect);

  factory ResolvedDialect.fromJson(Map json) {}

  Map<String, Object?> toJson() {
    return {'dialect': dialect.name};
  }
}

/// A resolved drift3 SQLite dialect with associated options.
@JsonSerializable()
final class Drift3SqliteDialect extends ResolvedDialect {
  @JsonKey(name: 'modules')
  final List<SqlModule> modules;

  @SqliteVersionConverter()
  final SqliteVersion? version;

  final Map<String, KnownSqliteFunction> knownFunctions;

  @TableFromSql()
  final List<Table> knownTables;

  final bool strictTablesByDefault;
  final bool storeDateTimesAsText;
  final bool useBinaryJsonRepresentation;

  const Drift3SqliteDialect({
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
}
