// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $TestTableTable extends TestTable
    with TableInfo<$TestTableTable, TestTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TestTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, content];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'test_table';
  @override
  VerificationContext validateIntegrity(Insertable<TestTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TestTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TestTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
    );
  }

  @override
  $TestTableTable createAlias(String alias) {
    return $TestTableTable(attachedDatabase, alias);
  }
}

class TestTableData extends DataClass implements Insertable<TestTableData> {
  final int id;
  final String content;
  const TestTableData({required this.id, required this.content});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['content'] = Variable<String>(content);
    return map;
  }

  TestTableCompanion toCompanion(bool nullToAbsent) {
    return TestTableCompanion(
      id: Value(id),
      content: Value(content),
    );
  }

  factory TestTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TestTableData(
      id: serializer.fromJson<int>(json['id']),
      content: serializer.fromJson<String>(json['content']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'content': serializer.toJson<String>(content),
    };
  }

  TestTableData copyWith({int? id, String? content}) => TestTableData(
        id: id ?? this.id,
        content: content ?? this.content,
      );
  TestTableData copyWithCompanion(TestTableCompanion data) {
    return TestTableData(
      id: data.id.present ? data.id.value : this.id,
      content: data.content.present ? data.content.value : this.content,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TestTableData(')
          ..write('id: $id, ')
          ..write('content: $content')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, content);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TestTableData &&
          other.id == this.id &&
          other.content == this.content);
}

class TestTableCompanion extends UpdateCompanion<TestTableData> {
  final Value<int> id;
  final Value<String> content;
  const TestTableCompanion({
    this.id = const Value.absent(),
    this.content = const Value.absent(),
  });
  TestTableCompanion.insert({
    this.id = const Value.absent(),
    required String content,
  }) : content = Value(content);
  static Insertable<TestTableData> custom({
    Expression<int>? id,
    Expression<String>? content,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (content != null) 'content': content,
    });
  }

  TestTableCompanion copyWith({Value<int>? id, Value<String>? content}) {
    return TestTableCompanion(
      id: id ?? this.id,
      content: content ?? this.content,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TestTableCompanion(')
          ..write('id: $id, ')
          ..write('content: $content')
          ..write(')'))
        .toString();
  }
}

abstract class _$TestDatabase extends GeneratedDatabase {
  _$TestDatabase(QueryExecutor e) : super(e);
  $TestDatabaseManager get managers => $TestDatabaseManager(this);
  late final $TestTableTable testTable = $TestTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [testTable];
}

typedef $$TestTableTableCreateCompanionBuilder = TestTableCompanion Function({
  Value<int> id,
  required String content,
});
typedef $$TestTableTableUpdateCompanionBuilder = TestTableCompanion Function({
  Value<int> id,
  Value<String> content,
});

class $$TestTableTableFilterComposer
    extends FilterComposer<_$TestDatabase, $TestTableTable> {
  $$TestTableTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get content => $state.composableBuilder(
      column: $state.table.content,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$TestTableTableOrderingComposer
    extends OrderingComposer<_$TestDatabase, $TestTableTable> {
  $$TestTableTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get content => $state.composableBuilder(
      column: $state.table.content,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$TestTableTableTableManager extends RootTableManager<
    _$TestDatabase,
    $TestTableTable,
    TestTableData,
    $$TestTableTableFilterComposer,
    $$TestTableTableOrderingComposer,
    $$TestTableTableCreateCompanionBuilder,
    $$TestTableTableUpdateCompanionBuilder,
    (
      TestTableData,
      BaseWithReferences<_$TestDatabase, TestTableData,
          $$TestTableTablePrefetchedData>
    ),
    TestTableData,
    $$TestTableTableCreatePrefetchedDataCallback,
    $$TestTableTablePrefetchedData> {
  $$TestTableTableTableManager(_$TestDatabase db, $TestTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$TestTableTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$TestTableTableOrderingComposer(ComposerState(db, table)),
          withReferenceMapper: (p0, p1) =>
              p0.map((e) => (e, BaseWithReferences(db, e, p1))).toList(),
          createPrefetchedDataGetterCallback: () {
            return (db, data) async {
              final managers = data.map((e) => BaseWithReferences(db, e));

              return $$TestTableTablePrefetchedData();
            };
          },
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> content = const Value.absent(),
          }) =>
              TestTableCompanion(
            id: id,
            content: content,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String content,
          }) =>
              TestTableCompanion.insert(
            id: id,
            content: content,
          ),
        ));
}

typedef $$TestTableTableProcessedTableManager = ProcessedTableManager<
    _$TestDatabase,
    $TestTableTable,
    TestTableData,
    $$TestTableTableFilterComposer,
    $$TestTableTableOrderingComposer,
    $$TestTableTableCreateCompanionBuilder,
    $$TestTableTableUpdateCompanionBuilder,
    (
      TestTableData,
      BaseWithReferences<_$TestDatabase, TestTableData,
          $$TestTableTablePrefetchedData>
    ),
    TestTableData,
    $$TestTableTableCreatePrefetchedDataCallback,
    $$TestTableTablePrefetchedData>;
typedef $$TestTableTableCreatePrefetchedDataCallback
    = Future<$$TestTableTablePrefetchedData> Function(
            _$TestDatabase, List<TestTableData>)
        Function();

class $$TestTableTablePrefetchedData {
  $$TestTableTablePrefetchedData();
}

class $TestDatabaseManager {
  final _$TestDatabase _db;
  $TestDatabaseManager(this._db);
  $$TestTableTableTableManager get testTable =>
      $$TestTableTableTableManager(_db, _db.testTable);
}
