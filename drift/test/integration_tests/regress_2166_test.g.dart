// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'regress_2166_test.dart';

// ignore_for_file: type=lint
class $_SomeTableTable extends _SomeTable
    with TableInfo<$_SomeTableTable, _SomeTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $_SomeTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'some_table';
  @override
  VerificationContext validateIntegrity(Insertable<_SomeTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  _SomeTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return _SomeTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name']),
    );
  }

  @override
  $_SomeTableTable createAlias(String alias) {
    return $_SomeTableTable(attachedDatabase, alias);
  }
}

class _SomeTableData extends DataClass implements Insertable<_SomeTableData> {
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
          DataClass.parseJson(encodedJson) as Map<String, dynamic>,
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

abstract class _$_SomeDb extends GeneratedDatabase {
  _$_SomeDb(QueryExecutor e) : super(e);
  $_SomeDbManager get managers => $_SomeDbManager(this);
  late final $_SomeTableTable someTable = $_SomeTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
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
    extends FilterComposer<_$_SomeDb, $_SomeTableTable> {
  $$_SomeTableTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$_SomeTableTableOrderingComposer
    extends OrderingComposer<_$_SomeDb, $_SomeTableTable> {
  $$_SomeTableTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$_SomeTableTableTableManager extends RootTableManager<
    _$_SomeDb,
    $_SomeTableTable,
    _SomeTableData,
    $$_SomeTableTableFilterComposer,
    $$_SomeTableTableOrderingComposer,
    $$_SomeTableTableCreateCompanionBuilder,
    $$_SomeTableTableUpdateCompanionBuilder,
    (_SomeTableData, BaseWithReferences<_$_SomeDb, _SomeTableData>),
    _SomeTableData> {
  $$_SomeTableTableTableManager(_$_SomeDb db, $_SomeTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$_SomeTableTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$_SomeTableTableOrderingComposer(ComposerState(db, table)),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e, BaseWithReferences(db, e))).toList(),
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
        ));
}

typedef $$_SomeTableTableProcessedTableManager = ProcessedTableManager<
    _$_SomeDb,
    $_SomeTableTable,
    _SomeTableData,
    $$_SomeTableTableFilterComposer,
    $$_SomeTableTableOrderingComposer,
    $$_SomeTableTableCreateCompanionBuilder,
    $$_SomeTableTableUpdateCompanionBuilder,
    (_SomeTableData, BaseWithReferences<_$_SomeDb, _SomeTableData>),
    _SomeTableData>;

class $_SomeDbManager {
  final _$_SomeDb _db;
  $_SomeDbManager(this._db);
  $$_SomeTableTableTableManager get someTable =>
      $$_SomeTableTableTableManager(_db, _db.someTable);
}
