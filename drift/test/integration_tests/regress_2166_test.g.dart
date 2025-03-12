// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'regress_2166_test.dart';

// ignore_for_file: type=lint
class $_SomeTableTable extends _SomeTable
    with ResultSet<_SomeTableData, $_SomeTableTable>
    implements GeneratedTable<_SomeTableData, $_SomeTableTable> {
  @override
  final String? alias;
  $_SomeTableTable([this.alias]);
  @override
  late final TableColumn<int> id = TableColumn<int>(
      name: 'id',
      type: BuiltinDriftType.int,
      isNullable: false,
      requiredDuringInsert: false,
      constraints: [const ColumnPrimaryKeyConstraint(isAutoIncrementing: true)])
    ..owningResultSet = this;
  @override
  late final TableColumn<String> name = TableColumn<String>(
      name: 'name',
      type: BuiltinDriftType.text,
      isNullable: true,
      requiredDuringInsert: false)
    ..owningResultSet = this;
  @override
  List<TableColumn> get columns => [id, name];
  @override
  String get entityName => $name;
  static const String $name = 'some_table';
  @override
  $_SomeTableTable asSelfType() => this;

  @override
  Set<TableColumn> get primaryKey => {id};
  @override
  _SomeTableData? Function(DriftRow) createMapperToDart(
      DriftResultSet resultSet) {
    final columnPositions = resultSet.structure.tables[this]!;
    return (DriftRow row) {
      // Not part of row if non-nullable column "id" is missing
      if (row.raw.rawValue(columnPositions[0]) == null) {
        return null;
      }
      return _SomeTableData(
        id: row.readWithType(columnPositions[0], BuiltinDriftType.int)!,
        name: row.readWithType(columnPositions[1], BuiltinDriftType.text),
      );
    };
  }

  @override
  $_SomeTableTable withAlias(String alias) {
    return $_SomeTableTable(alias);
  }
}

class _SomeTableData extends LegacyDataClass
    implements Insertable<_SomeTableData> {
  final int id;
  final String? name;
  const _SomeTableData({required this.id, this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    return map;
  }

  _SomeTableCompanion toCompanion(bool nullToAbsent) {
    return _SomeTableCompanion(
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
    );
  }

  factory _SomeTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return _SomeTableData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
    );
  }
  factory _SomeTableData.fromJsonString(String encodedJson,
          {ValueSerializer? serializer}) =>
      _SomeTableData.fromJson(
          LegacyDataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String?>(name),
    };
  }

  _SomeTableData copyWith(
          {int? id, Value<String?> name = const Value.absent()}) =>
      _SomeTableData(
        id: id ?? this.id,
        name: name.present ? name.value : this.name,
      );
  _SomeTableData copyWithCompanion(_SomeTableCompanion data) {
    return _SomeTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('_SomeTableData(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _SomeTableData &&
          other.id == this.id &&
          other.name == this.name);
}

class _SomeTableCompanion extends UpdateCompanion<_SomeTableData> {
  final Value<int> id;
  final Value<String?> name;
  const _SomeTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  _SomeTableCompanion.insert({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  static Insertable<_SomeTableData> custom({
    Expression<int>? id,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  _SomeTableCompanion copyWith({Value<int>? id, Value<String?>? name}) {
    return _SomeTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('_SomeTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

abstract base class _$_SomeDb extends GeneratedDatabase {
  _$_SomeDb(super.implementation);
  $_SomeDbManager get managers => $_SomeDbManager(this);
  late final $_SomeTableTable someTable = $_SomeTableTable();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [someTable];
}

typedef $$_SomeTableTableCreateCompanionBuilder = _SomeTableCompanion Function({
  Value<int> id,
  Value<String?> name,
});
typedef $$_SomeTableTableUpdateCompanionBuilder = _SomeTableCompanion Function({
  Value<int> id,
  Value<String?> name,
});

class $$_SomeTableTableFilterComposer
    extends Composer<_$_SomeDb, $_SomeTableTable> {
  $$_SomeTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));
}

class $$_SomeTableTableOrderingComposer
    extends Composer<_$_SomeDb, $_SomeTableTable> {
  $$_SomeTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));
}

class $$_SomeTableTableAnnotationComposer
    extends Composer<_$_SomeDb, $_SomeTableTable> {
  $$_SomeTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);
}

class $$_SomeTableTableTableManager extends RootTableManager<
    _$_SomeDb,
    $_SomeTableTable,
    _SomeTableData,
    $$_SomeTableTableFilterComposer,
    $$_SomeTableTableOrderingComposer,
    $$_SomeTableTableAnnotationComposer,
    $$_SomeTableTableCreateCompanionBuilder,
    $$_SomeTableTableUpdateCompanionBuilder,
    (
      _SomeTableData,
      BaseReferences<_$_SomeDb, $_SomeTableTable, _SomeTableData>
    ),
    _SomeTableData,
    PrefetchHooks Function()> {
  $$_SomeTableTableTableManager(_$_SomeDb db, $_SomeTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$_SomeTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$_SomeTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$_SomeTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> name = const Value.absent(),
          }) =>
              _SomeTableCompanion(
            id: id,
            name: name,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> name = const Value.absent(),
          }) =>
              _SomeTableCompanion.insert(
            id: id,
            name: name,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$_SomeTableTableProcessedTableManager = ProcessedTableManager<
    _$_SomeDb,
    $_SomeTableTable,
    _SomeTableData,
    $$_SomeTableTableFilterComposer,
    $$_SomeTableTableOrderingComposer,
    $$_SomeTableTableAnnotationComposer,
    $$_SomeTableTableCreateCompanionBuilder,
    $$_SomeTableTableUpdateCompanionBuilder,
    (
      _SomeTableData,
      BaseReferences<_$_SomeDb, $_SomeTableTable, _SomeTableData>
    ),
    _SomeTableData,
    PrefetchHooks Function()>;

class $_SomeDbManager {
  final _$_SomeDb _db;
  $_SomeDbManager(this._db);
  $$_SomeTableTableTableManager get someTable =>
      $$_SomeTableTableTableManager(_db, _db.someTable);
}
