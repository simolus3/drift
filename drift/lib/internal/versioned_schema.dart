import 'package:drift/drift.dart';

abstract base class VersionedSchema {
  final DatabaseConnectionUser database;
  final int version;

  VersionedSchema({required this.database, required this.version});

  Iterable<DatabaseSchemaEntity> get entities;

  DatabaseSchemaEntity lookup(String name) {
    return entities.singleWhere((element) => element.entityName == name);
  }
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

  /// List of columns, represented as a function that returns the generated
  /// column when given the resolved table name.
  final List<GeneratedColumn Function(String)> _columnFactories;

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
  })  : _columnFactories = columns,
        customConstraints = tableConstraints,
        $columns = [for (final column in columns) column(alias ?? entityName)],
        _alias = alias;

  VersionedTable.aliased({
    required VersionedTable source,
    required String? alias,
  })  : entityName = source.entityName,
        isStrict = source.isStrict,
        withoutRowId = source.withoutRowId,
        attachedDatabase = source.attachedDatabase,
        customConstraints = source.customConstraints,
        _columnFactories = source._columnFactories,
        $columns = [
          for (final column in source._columnFactories)
            column(alias ?? source.entityName)
        ],
        _alias = alias;

  @override
  String get actualTableName => entityName;

  @override
  String get aliasedName => _alias ?? entityName;

  @override
  bool get dontWriteConstraints => true;

  @override
  QueryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    return QueryRow(data, attachedDatabase);
  }

  @override
  VersionedTable createAlias(String alias) {
    return VersionedTable.aliased(source: this, alias: alias);
  }
}

class VersionedVirtualTable extends VersionedTable
    with VirtualTableInfo<Table, QueryRow> {
  @override
  final String moduleAndArgs;

  VersionedVirtualTable({
    required super.entityName,
    required super.attachedDatabase,
    required super.columns,
    required this.moduleAndArgs,
    super.alias,
  }) : super(
          isStrict: false,
          withoutRowId: false,
          tableConstraints: [],
        );

  VersionedVirtualTable.aliased(
      {required VersionedVirtualTable source, required String? alias})
      : moduleAndArgs = source.moduleAndArgs,
        super.aliased(source: source, alias: alias);

  @override
  VersionedVirtualTable createAlias(String alias) {
    return VersionedVirtualTable.aliased(
      source: this,
      alias: alias,
    );
  }
}

class VersionedView implements ViewInfo<HasResultSet, QueryRow>, HasResultSet {
  @override
  final String entityName;
  final String? _alias;

  @override
  final String createViewStmt;

  @override
  final List<GeneratedColumn> $columns;

  @override
  late final Map<String, GeneratedColumn> columnsByName = {
    for (final column in $columns) column.name: column,
  };

  /// List of columns, represented as a function that returns the generated
  /// column when given the resolved table name.
  final List<GeneratedColumn Function(String)> _columnFactories;

  @override
  final DatabaseConnectionUser attachedDatabase;

  VersionedView({
    required this.entityName,
    required this.attachedDatabase,
    required this.createViewStmt,
    required List<GeneratedColumn Function(String)> columns,
    String? alias,
  })  : _columnFactories = columns,
        $columns = [for (final column in columns) column(alias ?? entityName)],
        _alias = alias;

  VersionedView.aliased({required VersionedView source, required String? alias})
      : entityName = source.entityName,
        attachedDatabase = source.attachedDatabase,
        createViewStmt = source.createViewStmt,
        _columnFactories = source._columnFactories,
        $columns = [
          for (final column in source._columnFactories)
            column(alias ?? source.entityName)
        ],
        _alias = alias;

  @override
  String get aliasedName => _alias ?? entityName;

  @override
  HasResultSet get asDslTable => this;

  @override
  VersionedView createAlias(String alias) {
    return VersionedView.aliased(source: this, alias: alias);
  }

  @override
  QueryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    return QueryRow(data, attachedDatabase);
  }

  @override
  Query<HasResultSet, dynamic>? get query => null;

  @override
  Set<String> get readTables => const {};
}
