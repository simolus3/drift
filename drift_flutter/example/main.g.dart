// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// ignore_for_file: type=lint
class $ExampleTableTable extends ExampleTable
    with ResultSet<ExampleTableData, $ExampleTableTable>
    implements GeneratedTable<ExampleTableData, $ExampleTableTable> {
  @override
  final String? alias;
  $ExampleTableTable([this.alias]);
  @override
  late final TableColumn<int> id = TableColumn<int>(
      name: 'id',
      type: BuiltinDriftType.int,
      isNullable: false,
      requiredDuringInsert: false,
      constraints: () =>
          [const ColumnPrimaryKeyConstraint(isAutoIncrementing: true)])
    ..owningResultSet = this;
  @override
  late final TableColumn<String> description = TableColumn<String>(
      name: 'description',
      type: BuiltinDriftType.text,
      isNullable: false,
      requiredDuringInsert: true)
    ..owningResultSet = this;
  @override
  List<TableColumn> get columns => [id, description];
  @override
  String get entityName => $name;
  static const String $name = 'example_table';
  @override
  $ExampleTableTable asSelfType() => this;

  @override
  Set<TableColumn> get primaryKey => {id};
  @override
  ExampleTableData? Function(DriftRow) createMapperFromPositions(
      List<ColumnPosition> positions) {
    return (DriftRow row) {
      // Not part of row if non-nullable column "id" is missing
      if (row.raw.rawValue(positions[0]) == null) {
        return null;
      }
      return ExampleTableData(
        id: row.readWithType(positions[0], BuiltinDriftType.int)!,
        description: row.readWithType(positions[1], BuiltinDriftType.text)!,
      );
    };
  }

  @override
  $ExampleTableTable withAlias(String alias) {
    return $ExampleTableTable(alias);
  }
}

class ExampleTableData extends LegacyDataClass
    implements Insertable<ExampleTableData> {
  final int id;
  final String description;
  const ExampleTableData({required this.id, required this.description});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['description'] = Variable<String>(description);
    return map;
  }

  ExampleTableCompanion toCompanion(bool nullToAbsent) {
    return ExampleTableCompanion(
      id: Value(id),
      description: Value(description),
    );
  }

  factory ExampleTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExampleTableData(
      id: serializer.fromJson<int>(json['id']),
      description: serializer.fromJson<String>(json['description']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'description': serializer.toJson<String>(description),
    };
  }

  ExampleTableData copyWith({int? id, String? description}) => ExampleTableData(
        id: id ?? this.id,
        description: description ?? this.description,
      );
  ExampleTableData copyWithCompanion(ExampleTableCompanion data) {
    return ExampleTableData(
      id: data.id.present ? data.id.value : this.id,
      description:
          data.description.present ? data.description.value : this.description,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExampleTableData(')
          ..write('id: $id, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, description);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExampleTableData &&
          other.id == this.id &&
          other.description == this.description);
}

class ExampleTableCompanion extends UpdateCompanion<ExampleTableData> {
  final Value<int> id;
  final Value<String> description;
  const ExampleTableCompanion({
    this.id = const Value.absent(),
    this.description = const Value.absent(),
  });
  ExampleTableCompanion.insert({
    this.id = const Value.absent(),
    required String description,
  }) : description = Value(description);
  static Insertable<ExampleTableData> custom({
    Expression<int>? id,
    Expression<String>? description,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (description != null) 'description': description,
    });
  }

  ExampleTableCompanion copyWith({Value<int>? id, Value<String>? description}) {
    return ExampleTableCompanion(
      id: id ?? this.id,
      description: description ?? this.description,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExampleTableCompanion(')
          ..write('id: $id, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }
}

abstract base class _$ExampleDatabase extends GeneratedDatabase {
  _$ExampleDatabase(super.implementation);
  $ExampleDatabaseManager get managers => $ExampleDatabaseManager(this);
  late final $ExampleTableTable exampleTable = $ExampleTableTable();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [exampleTable];
}

typedef $$ExampleTableTableCreateCompanionBuilder = ExampleTableCompanion
    Function({
  Value<int> id,
  required String description,
});
typedef $$ExampleTableTableUpdateCompanionBuilder = ExampleTableCompanion
    Function({
  Value<int> id,
  Value<String> description,
});

class $$ExampleTableTableFilterComposer
    extends Composer<_$ExampleDatabase, $ExampleTableTable> {
  $$ExampleTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));
}

class $$ExampleTableTableOrderingComposer
    extends Composer<_$ExampleDatabase, $ExampleTableTable> {
  $$ExampleTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));
}

class $$ExampleTableTableAnnotationComposer
    extends Composer<_$ExampleDatabase, $ExampleTableTable> {
  $$ExampleTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);
}

class $$ExampleTableTableTableManager extends RootTableManager<
    _$ExampleDatabase,
    $ExampleTableTable,
    ExampleTableData,
    $$ExampleTableTableFilterComposer,
    $$ExampleTableTableOrderingComposer,
    $$ExampleTableTableAnnotationComposer,
    $$ExampleTableTableCreateCompanionBuilder,
    $$ExampleTableTableUpdateCompanionBuilder,
    (
      ExampleTableData,
      BaseReferences<_$ExampleDatabase, $ExampleTableTable, ExampleTableData>
    ),
    ExampleTableData,
    PrefetchHooks Function()> {
  $$ExampleTableTableTableManager(
      _$ExampleDatabase db, $ExampleTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExampleTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExampleTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExampleTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> description = const Value.absent(),
          }) =>
              ExampleTableCompanion(
            id: id,
            description: description,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String description,
          }) =>
              ExampleTableCompanion.insert(
            id: id,
            description: description,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ExampleTableTableProcessedTableManager = ProcessedTableManager<
    _$ExampleDatabase,
    $ExampleTableTable,
    ExampleTableData,
    $$ExampleTableTableFilterComposer,
    $$ExampleTableTableOrderingComposer,
    $$ExampleTableTableAnnotationComposer,
    $$ExampleTableTableCreateCompanionBuilder,
    $$ExampleTableTableUpdateCompanionBuilder,
    (
      ExampleTableData,
      BaseReferences<_$ExampleDatabase, $ExampleTableTable, ExampleTableData>
    ),
    ExampleTableData,
    PrefetchHooks Function()>;

class $ExampleDatabaseManager {
  final _$ExampleDatabase _db;
  $ExampleDatabaseManager(this._db);
  $$ExampleTableTableTableManager get exampleTable =>
      $$ExampleTableTableTableManager(_db, _db.exampleTable);
}
