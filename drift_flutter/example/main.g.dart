// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// ignore_for_file: type=lint
class $ExampleTableTable extends ExampleTable
    with TableInfo<$ExampleTableTable, ExampleTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExampleTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, description];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'example_table';
  @override
  VerificationContext validateIntegrity(Insertable<ExampleTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExampleTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExampleTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
    );
  }

  @override
  $ExampleTableTable createAlias(String alias) {
    return $ExampleTableTable(attachedDatabase, alias);
  }
}

class ExampleTableData extends DataClass
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

abstract class _$ExampleDatabase extends GeneratedDatabase {
  _$ExampleDatabase(QueryExecutor e) : super(e);
  $ExampleDatabaseManager get managers => $ExampleDatabaseManager(this);
  late final $ExampleTableTable exampleTable = $ExampleTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
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
    extends FilterComposer<_$ExampleDatabase, $ExampleTableTable> {
  $$ExampleTableTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get description => $state.composableBuilder(
      column: $state.table.description,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$ExampleTableTableOrderingComposer
    extends OrderingComposer<_$ExampleDatabase, $ExampleTableTable> {
  $$ExampleTableTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get description => $state.composableBuilder(
      column: $state.table.description,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$ExampleTableTableTableManager extends RootTableManager<
    _$ExampleDatabase,
    $ExampleTableTable,
    ExampleTableData,
    $$ExampleTableTableFilterComposer,
    $$ExampleTableTableOrderingComposer,
    $$ExampleTableTableCreateCompanionBuilder,
    $$ExampleTableTableUpdateCompanionBuilder,
    (
      ExampleTableData,
      BaseWithReferences<_$ExampleDatabase, ExampleTableData,
          $$ExampleTableTablePrefetchedData>
    ),
    ExampleTableData,
    $$ExampleTableTableCreatePrefetchedDataCallback,
    $$ExampleTableTablePrefetchedData> {
  $$ExampleTableTableTableManager(
      _$ExampleDatabase db, $ExampleTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$ExampleTableTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$ExampleTableTableOrderingComposer(ComposerState(db, table)),
          withReferenceMapper: (p0, p1) =>
              p0.map((e) => (e, BaseWithReferences(db, e, p1))).toList(),
          createPrefetchedDataGetterCallback: () {
            return (db, data) async {
              final managers = data.map((e) => BaseWithReferences(db, e));

              return $$ExampleTableTablePrefetchedData();
            };
          },
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
        ));
}

typedef $$ExampleTableTableProcessedTableManager = ProcessedTableManager<
    _$ExampleDatabase,
    $ExampleTableTable,
    ExampleTableData,
    $$ExampleTableTableFilterComposer,
    $$ExampleTableTableOrderingComposer,
    $$ExampleTableTableCreateCompanionBuilder,
    $$ExampleTableTableUpdateCompanionBuilder,
    (
      ExampleTableData,
      BaseWithReferences<_$ExampleDatabase, ExampleTableData,
          $$ExampleTableTablePrefetchedData>
    ),
    ExampleTableData,
    $$ExampleTableTableCreatePrefetchedDataCallback,
    $$ExampleTableTablePrefetchedData>;
typedef $$ExampleTableTableCreatePrefetchedDataCallback
    = Future<$$ExampleTableTablePrefetchedData> Function(
            _$ExampleDatabase, List<ExampleTableData>)
        Function();

class $$ExampleTableTablePrefetchedData {
  $$ExampleTableTablePrefetchedData();
}

class $ExampleDatabaseManager {
  final _$ExampleDatabase _db;
  $ExampleDatabaseManager(this._db);
  $$ExampleTableTableTableManager get exampleTable =>
      $$ExampleTableTableTableManager(_db, _db.exampleTable);
}
