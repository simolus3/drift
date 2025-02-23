// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../analysis/dialect.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DriftSqliteDialect _$DriftSqliteDialectFromJson(Map json) => DriftSqliteDialect(
      modules: (json['modules'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$SqlModuleEnumMap, e))
              .toList() ??
          const [],
      dateTimesAsText: json['date_times_as_text'] as bool? ?? false,
      binaryJson: json['binary_json'] as bool? ?? true,
      version: json['version'] == null
          ? _defaultSqliteVersion
          : const _SqliteVersionConverter().fromJson(json['version'] as String),
      knownFunctions: (json['known_functions'] as Map?)?.map(
            (k, e) => MapEntry(
                k as String, KnownSqliteFunction.fromJson(e as String)),
          ) ??
          const {},
    );

Map<String, dynamic> _$DriftSqliteDialectToJson(DriftSqliteDialect instance) =>
    <String, dynamic>{
      'modules': instance.modules.map((e) => _$SqlModuleEnumMap[e]!).toList(),
      'date_times_as_text': instance.dateTimesAsText,
      'binary_json': instance.binaryJson,
      'version': const _SqliteVersionConverter().toJson(instance.version),
      'known_functions':
          instance.knownFunctions.map((k, e) => MapEntry(k, e.toJson())),
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
};
