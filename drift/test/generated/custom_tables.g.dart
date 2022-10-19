// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_tables.dart';

abstract class _$CustomTablesDb extends GeneratedDatabase {
  _$CustomTablesDb(QueryExecutor e) : super(e);
  _$CustomTablesDb.connect(DatabaseConnection c) : super.connect(c);
  Future<int> writeConfig({required String key, required String value}) {
    return customInsert(
      'REPLACE INTO config (config_key, config_value) VALUES (?1, ?2)',
      variables: [Variable<String>(key), Variable<String>(value)],
      updates: {},
      updateKind: UpdateKind.delete,
    );
  }

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}
