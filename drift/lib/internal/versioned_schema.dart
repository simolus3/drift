import 'package:drift/drift.dart';

abstract base class VersionedSchema {
  final DatabaseConnectionUser database;

  VersionedSchema(this.database);

  DatabaseSchemaEntity lookup(String name, int version) {
    return allEntitiesAt(version)
        .singleWhere((element) => element.entityName == name);
  }

  Iterable<DatabaseSchemaEntity> allEntitiesAt(int version);
}

class VersionedTable extends Table with TableInfo<Table, QueryRow> {
  @override
  final String entityName;
  final String? _alias;
  @override
  final bool isStrict;

  @override
  final bool withoutRowId;

  @override
  final DatabaseConnectionUser attachedDatabase;

  @override
  final List<GeneratedColumn> $columns;

  @override
  final List<String> customConstraints;

  VersionedTable({
    required this.entityName,
    required this.isStrict,
    required this.withoutRowId,
    required this.attachedDatabase,
    required List<GeneratedColumn Function(String)> columns,
    required List<String> tableConstraints,
    String? alias,
  })  : customConstraints = tableConstraints,
        $columns = [for (final column in columns) column(alias ?? entityName)],
        _alias = alias;

  @override
  String get actualTableName => entityName;

  @override
  String get aliasedName => _alias ?? entityName;

  @override
  bool get dontWriteConstraints => true;

  @override
  VersionedTable createAlias(String alias) {
    return VersionedTable(
      entityName: entityName,
      isStrict: isStrict,
      withoutRowId: withoutRowId,
      attachedDatabase: attachedDatabase,
      columns: $columns,
      tableConstraints: customConstraints,
      alias: alias,
    );
  }

  @override
  QueryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    return QueryRow(data, attachedDatabase);
  }
}
