import 'package:db_viewer/db_viewer.dart';
import 'package:drift/drift.dart';
// ignore: invalid_use_of_internal_member, implementation_imports
import 'package:drift/src/runtime/devtools/shared.dart';
import 'package:flutter/widgets.dart';
import 'package:rxdart/streams.dart';

import '../remote_database.dart';

class ViewerDatabase implements DbViewerDatabase {
  final RemoteDatabase database;

  final Map<String, FilterData> _cachedFilters = {};

  ViewerDatabase({required this.database});

  @override
  Widget buildWhereWidget(
      {required VoidCallback onAddClicked,
      required List<WhereClause> whereClauses}) {
    return Container();
  }

  @override
  Stream<int> count(String entityName) {
    return customSelectStream('SELECT COUNT(*) AS r FROM "$entityName"')
        .map((rows) => rows.first['r'] as int);
  }

  @override
  Future<List<Map<String, dynamic>>> customSelect(String query,
      {Set<String>? fromEntityNames}) {
    return database.select(query, const []);
  }

  @override
  Stream<List<Map<String, dynamic>>> customSelectStream(String query,
      {Set<String>? fromEntityNames}) {
    fromEntityNames ??= const {};

    final updates = database.tableUpdates
        .where(
            (e) => e.any((updated) => fromEntityNames!.contains(updated.table)))
        .asyncMap((event) => customSelect(query));

    return ConcatStream([
      Stream.fromFuture(customSelect(query)),
      updates,
    ]);
  }

  @override
  List<String> get entityNames => [
        for (final entity in database.description.entities)
          if (entity.type == 'table' ||
              entity.type == 'virtual_table' ||
              entity.type == 'view')
            entity.name,
      ];

  @override
  FilterData getCachedFilterData(String entityName) {
    return _cachedFilters.putIfAbsent(
        entityName, () => getFilterData(entityName));
  }

  @override
  List<String> getColumnNamesByEntityName(String entityName) {
    return database.description.entitiesByName[entityName]!.columnsByName.keys
        .toList();
  }

  @override
  FilterData getFilterData(String entityName) {
    return DriftFilterData(
        entity: database.description.entitiesByName[entityName]!);
  }

  @override
  String getType(String entityName, String columnName) {
    final type = database.description.entitiesByName[entityName]!
        .columnsByName[columnName]!.type;
    final genContext = GenerationContext(
      DriftDatabaseOptions(
          storeDateTimeAsText: database.description.dateTimeAsText),
      null,
    );

    return type.type?.sqlTypeName(genContext) ?? type.customTypeName!;
  }

  @override
  List<Map<String, dynamic>> remapData(
      String entityName, List<Map<String, dynamic>> data) {
    // ignore: invalid_use_of_internal_member
    final types = SqlTypes(database.description.dateTimeAsText);
    final mapped = <Map<String, dynamic>>[];
    final entity = database.description.entitiesByName[entityName]!;

    for (final row in data) {
      final mappedRow = <String, dynamic>{};

      for (var MapEntry(key: column, :value) in row.entries) {
        final resolvedColumn = entity.columnsByName[column];

        if (resolvedColumn != null) {
          final type = resolvedColumn.type.type ?? DriftSqlType.any;

          mappedRow[column] = types.read(type, value);
        } else {
          mappedRow[column] = value;
        }
      }

      mapped.add(mappedRow);
    }

    return mapped;
  }

  @override
  Future<void> runCustomStatement(String query) {
    return database.execute(query, const []);
  }

  @override
  void updateFilterData(String entityName, FilterData filterData) {
    _cachedFilters[entityName] = filterData;
  }
}

class DriftFilterData extends FilterData {
  final EntityDescription entity;

  DriftFilterData({required this.entity});

  @override
  DriftFilterData copy() {
    return DriftFilterData(entity: entity);
  }

  @override
  Map<String, bool> getSelectedColumns() {
    return {
      for (final column in entity.columns ?? const <ColumnDescription>[])
        column.name: false,
    };
  }

  @override
  WhereClause? getWhereClause(String columnName) {
    return null;
  }

  @override
  String get tableName => entity.name;
}
