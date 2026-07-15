// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../analysis/dialect.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Drift3SqliteDialect _$Drift3SqliteDialectFromJson(Map json) =>
    Drift3SqliteDialect(
      modules:
          (json['modules'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$SqlModuleEnumMap, e))
              .toList() ??
          const [],
      version: _$JsonConverterFromJson<String, SqliteVersion>(
        json['version'],
        const SqliteVersionConverter().fromJson,
      ),
      knownFunctions:
          (json['known_functions'] as Map?)?.map(
            (k, e) => MapEntry(
              k as String,
              KnownSqliteFunction.fromJson(e as String),
            ),
          ) ??
          const {},
      knownTables:
          (json['known_tables'] as List<dynamic>?)
              ?.map((e) => const TableFromSql().fromJson(e as String))
              .toList() ??
          const [],
      strictTablesByDefault: json['strict_tables_by_default'] as bool? ?? true,
      storeDateTimesAsText: json['store_date_times_as_text'] as bool? ?? true,
      useBinaryJsonRepresentation:
          json['use_binary_json_representation'] as bool? ?? true,
    );

Map<String, dynamic> _$Drift3SqliteDialectToJson(
  Drift3SqliteDialect instance,
) => <String, dynamic>{
  'modules': instance.modules.map((e) => _$SqlModuleEnumMap[e]!).toList(),
  'version': _$JsonConverterToJson<String, SqliteVersion>(
    instance.version,
    const SqliteVersionConverter().toJson,
  ),
  'known_functions': instance.knownFunctions.map(
    (k, e) => MapEntry(k, e.toJson()),
  ),
  'known_tables': instance.knownTables
      .map(const TableFromSql().toJson)
      .toList(),
  'strict_tables_by_default': instance.strictTablesByDefault,
  'store_date_times_as_text': instance.storeDateTimesAsText,
  'use_binary_json_representation': instance.useBinaryJsonRepresentation,
};

const _$SqlModuleEnumMap = {
  SqlModule.json1: 'json1',
  SqlModule.fts5: 'fts5',
  SqlModule.moor_ffi: 'moor_ffi',
  SqlModule.math: 'math',
  SqlModule.rtree: 'rtree',
  SqlModule.spellfix1: 'spellfix1',
  SqlModule.geopoly: 'geopoly',
  SqlModule.dbstat: 'dbstat',
  SqlModule.powersync: 'powersync',
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
