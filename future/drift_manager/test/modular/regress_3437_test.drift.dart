// ignore_for_file: unused_local_variable
// ignore_for_file: type=lint
import 'package:drift3_preview/drift.dart' as i0;
import 'regress_3437_test.drift.dart' as i1;
import 'regress_3437_test.dart' as i2;
import 'package:drift_sqlite/drift_sqlite.dart' as i3;
import 'package:drift_manager/drift_manager.dart' as i4;

typedef $$GroupsTableCreateCompanionBuilder =
    i1.GroupsCompanion Function({i0.Value<int> id, required String name});
typedef $$GroupsTableUpdateCompanionBuilder =
    i1.GroupsCompanion Function({i0.Value<int> id, i0.Value<String> name});

final class $$GroupsTableReferences
    extends i4.BaseReferences<i0.GeneratedDatabase, i1.$GroupsTable, i1.Group> {
  $$GroupsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static i4.MultiTypedResultKey<List<i2.Member>> _membersRefsTable(
    i0.GeneratedDatabase db,
  ) => i4.MultiTypedResultKey.fromTable(
    i1.$MembersTable(),
    aliasName: 'groups__id__members__group',
  );

  i1.$$MembersTableProcessedTableManager get membersRefs {
    final manager = i1
        .$$MembersTableTableManager($_db, i1.$MembersTable())
        .filter((f) => f.group.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_membersRefsTable($_db));
    return i4.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$GroupsTableFilterComposer
    extends i4.Composer<i0.GeneratedDatabase, i1.$GroupsTable> {
  $$GroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i4.ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => i4.ColumnFilters(column),
  );

  i4.ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => i4.ColumnFilters(column),
  );

  i0.Expression<bool> membersRefs(
    i0.Expression<bool> Function(i1.$$MembersTableFilterComposer f) f,
  ) {
    final i1.$$MembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: i1.$MembersTable(),
      getReferencedColumn: (t) => t.group,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i1.$$MembersTableFilterComposer(
            $db: $db,
            $table: i1.$MembersTable(),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GroupsTableOrderingComposer
    extends i4.Composer<i0.GeneratedDatabase, i1.$GroupsTable> {
  $$GroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i4.ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => i4.ColumnOrderings(column),
  );

  i4.ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => i4.ColumnOrderings(column),
  );
}

class $$GroupsTableAnnotationComposer
    extends i4.Composer<i0.GeneratedDatabase, i1.$GroupsTable> {
  $$GroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.TableColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  i0.TableColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  i0.Expression<T> membersRefs<T extends Object>(
    i0.Expression<T> Function(i1.$$MembersTableAnnotationComposer a) f,
  ) {
    final i1.$$MembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: i1.$MembersTable(),
      getReferencedColumn: (t) => t.group,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i1.$$MembersTableAnnotationComposer(
            $db: $db,
            $table: i1.$MembersTable(),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GroupsTableTableManager
    extends
        i4.RootTableManager<
          i0.GeneratedDatabase,
          i1.$GroupsTable,
          i1.Group,
          i1.$$GroupsTableFilterComposer,
          i1.$$GroupsTableOrderingComposer,
          i1.$$GroupsTableAnnotationComposer,
          $$GroupsTableCreateCompanionBuilder,
          $$GroupsTableUpdateCompanionBuilder,
          (i1.Group, i1.$$GroupsTableReferences),
          i1.Group,
          i4.PrefetchHooks Function({bool membersRefs})
        > {
  $$GroupsTableTableManager(i0.GeneratedDatabase db, i1.$GroupsTable table)
    : super(
        i4.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$$GroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$$GroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i1.$$GroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<int> id = const i0.Value.absent(),
                i0.Value<String> name = const i0.Value.absent(),
              }) => i1.GroupsCompanion(id: id, name: name),
          createCompanionCallback:
              ({
                i0.Value<int> id = const i0.Value.absent(),
                required String name,
              }) => i1.GroupsCompanion.insert(id: id, name: name),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<i1.$GroupsTable, i1.Group>(table),
                  i1.$$GroupsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({membersRefs = false}) {
            return i4.PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (membersRefs) i1.$MembersTable()],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (membersRefs)
                    await i4.$_getPrefetchedDataByColumns<
                      i1.Group,
                      i1.$GroupsTable,
                      i2.Member,
                      i1.$MembersTable
                    >(
                      currentTable: table,
                      referencedTable: i1.$$GroupsTableReferences
                          ._membersRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          i1.$$GroupsTableReferences(db, table, p0).membersRefs,
                      currentColumn: 'id',
                      referencedColumn: 'group',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$GroupsTableProcessedTableManager =
    i4.ProcessedTableManager<
      i0.GeneratedDatabase,
      i1.$GroupsTable,
      i1.Group,
      i1.$$GroupsTableFilterComposer,
      i1.$$GroupsTableOrderingComposer,
      i1.$$GroupsTableAnnotationComposer,
      $$GroupsTableCreateCompanionBuilder,
      $$GroupsTableUpdateCompanionBuilder,
      (i1.Group, i1.$$GroupsTableReferences),
      i1.Group,
      i4.PrefetchHooks Function({bool membersRefs})
    >;
typedef $$MembersTableCreateCompanionBuilder =
    i1.MembersCompanion Function({i0.Value<int> id, required int group});
typedef $$MembersTableUpdateCompanionBuilder =
    i1.MembersCompanion Function({i0.Value<int> id, i0.Value<int> group});

final class $$MembersTableReferences
    extends
        i4.BaseReferences<i0.GeneratedDatabase, i1.$MembersTable, i2.Member> {
  $$MembersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static i1.$GroupsTable _groupTable(i0.GeneratedDatabase db) =>
      i1.$GroupsTable().withAlias('members__group__groups__id');

  i1.$$GroupsTableProcessedTableManager get group {
    final $_column = $_itemColumn<int>('group')!;

    final manager = i1
        .$$GroupsTableTableManager($_db, i1.$GroupsTable())
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupTable($_db));
    if (item == null) return manager;
    return i4.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MembersTableFilterComposer
    extends i4.Composer<i0.GeneratedDatabase, i1.$MembersTable> {
  $$MembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i4.ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => i4.ColumnFilters(column),
  );

  i1.$$GroupsTableFilterComposer get group {
    final i1.$$GroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.group,
      referencedTable: i1.$GroupsTable(),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i1.$$GroupsTableFilterComposer(
            $db: $db,
            $table: i1.$GroupsTable(),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MembersTableOrderingComposer
    extends i4.Composer<i0.GeneratedDatabase, i1.$MembersTable> {
  $$MembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i4.ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => i4.ColumnOrderings(column),
  );

  i1.$$GroupsTableOrderingComposer get group {
    final i1.$$GroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.group,
      referencedTable: i1.$GroupsTable(),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i1.$$GroupsTableOrderingComposer(
            $db: $db,
            $table: i1.$GroupsTable(),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MembersTableAnnotationComposer
    extends i4.Composer<i0.GeneratedDatabase, i1.$MembersTable> {
  $$MembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.TableColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  i1.$$GroupsTableAnnotationComposer get group {
    final i1.$$GroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.group,
      referencedTable: i1.$GroupsTable(),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i1.$$GroupsTableAnnotationComposer(
            $db: $db,
            $table: i1.$GroupsTable(),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MembersTableTableManager
    extends
        i4.RootTableManager<
          i0.GeneratedDatabase,
          i1.$MembersTable,
          i2.Member,
          i1.$$MembersTableFilterComposer,
          i1.$$MembersTableOrderingComposer,
          i1.$$MembersTableAnnotationComposer,
          $$MembersTableCreateCompanionBuilder,
          $$MembersTableUpdateCompanionBuilder,
          (i2.Member, i1.$$MembersTableReferences),
          i2.Member,
          i4.PrefetchHooks Function({bool group})
        > {
  $$MembersTableTableManager(i0.GeneratedDatabase db, i1.$MembersTable table)
    : super(
        i4.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$$MembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$$MembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i1.$$MembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<int> id = const i0.Value.absent(),
                i0.Value<int> group = const i0.Value.absent(),
              }) => i1.MembersCompanion(id: id, group: group),
          createCompanionCallback:
              ({
                i0.Value<int> id = const i0.Value.absent(),
                required int group,
              }) => i1.MembersCompanion.insert(id: id, group: group),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<i1.$MembersTable, i2.Member>(table),
                  i1.$$MembersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({group = false}) {
            return i4.PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends i4.TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (group) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.group,
                                referencedTable: i1.$$MembersTableReferences
                                    ._groupTable(db),
                                referencedColumn: i1.$$MembersTableReferences
                                    ._groupTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MembersTableProcessedTableManager =
    i4.ProcessedTableManager<
      i0.GeneratedDatabase,
      i1.$MembersTable,
      i2.Member,
      i1.$$MembersTableFilterComposer,
      i1.$$MembersTableOrderingComposer,
      i1.$$MembersTableAnnotationComposer,
      $$MembersTableCreateCompanionBuilder,
      $$MembersTableUpdateCompanionBuilder,
      (i2.Member, i1.$$MembersTableReferences),
      i2.Member,
      i4.PrefetchHooks Function({bool group})
    >;

abstract base class $_TestDatabase extends i0.GeneratedDatabase {
  $_TestDatabase(super.implementation);
  $_TestDatabaseManager get managers => $_TestDatabaseManager(this);
  i1.$GroupsTable get groups => i1.$GroupsTable();
  i1.$MembersTable get members => i1.$MembersTable();
  i0.TableOrViewStatements<i1.Group, i1.$GroupsTable> get groupsQueries =>
      this.groups.statements(this);
  i0.TableOrViewStatements<i2.Member, i1.$MembersTable> get membersQueries =>
      this.members.statements(this);
  @override
  Map<i0.KnownSqlDialect, Object> get dialectOptions => {
    i0.KnownSqlDialect.sqlite: const i3.SqliteOptions(
      strictTablesByDefault: true,
      storeDateTimesAsText: true,
      useBinaryJsonRepresentation: true,
    ),
  };
  @override
  i0.DatabaseSchema get schema => _$schema;
  static final i0.DatabaseSchema _$schema = i0.DatabaseSchema([
    i1.$GroupsTable(),
    i1.$MembersTable(),
  ]);
}

class $_TestDatabaseManager {
  final $_TestDatabase _db;
  $_TestDatabaseManager(this._db);
  i1.$$GroupsTableTableManager get groups =>
      i1.$$GroupsTableTableManager(_db, _db.groups);
  i1.$$MembersTableTableManager get members =>
      i1.$$MembersTableTableManager(_db, _db.members);
}

class $GroupsTable extends i2.Groups
    with i0.ResultSet<i1.Group, $GroupsTable>
    implements i0.GeneratedTable<i1.Group, $GroupsTable> {
  @override
  final String? alias;
  $GroupsTable([this.alias]);
  @override
  late final i0.TableColumn<int> id = i0.TableColumn<int>(
    name: 'id',
    sqlType: i0.SqlType.int,
    requiredDuringInsert: false,
    constraints: () => [
      const i0.ColumnPrimaryKeyConstraint(isAutoIncrementing: true),
      const i0.ColumnNotNullConstraint(),
    ],
  )..owningResultSet = this;
  @override
  late final i0.TableColumn<String> name = i0.TableColumn<String>(
    name: 'name',
    sqlType: i0.SqlType.text,
    requiredDuringInsert: true,
    constraints: () => [const i0.ColumnNotNullConstraint()],
  )..owningResultSet = this;
  @override
  List<i0.TableColumn> get columns => [id, name];
  @override
  String get entityName => $name;
  static const String $name = 'groups';
  @override
  $GroupsTable asSelfType() => this;

  @override
  i1.Group? Function(i0.RawRow) createMapperFromPositions(
    i0.DriftDialect dialect,
    List<i0.ColumnPosition> positions,
  ) {
    final pos$id = positions[0].index;
    final type$0 = dialect.intType;
    final pos$name = positions[1].index;
    final type$1 = dialect.textType;
    return (i0.RawRow row) {
      // Not part of row if non-nullable column "id" is missing
      if (row[pos$id] == null) {
        return null;
      }
      return i1.Group(
        id: type$0.dartValue(row[pos$id]!),
        name: type$1.dartValue(row[pos$name]!),
      );
    };
  }

  @override
  $GroupsTable withAlias(String alias) {
    return $GroupsTable(alias);
  }
}

class Group extends i0.LegacyDataClass implements i0.Insertable<i1.Group> {
  final int id;
  final String name;
  const Group({required this.id, required this.name});
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['id'] = i0.Variable<int>(id, i0.SqlType.int);
    map['name'] = i0.Variable<String>(name, i0.SqlType.text);
    return map;
  }

  i1.GroupsCompanion toCompanion(bool nullToAbsent) {
    return i1.GroupsCompanion(id: i0.Value(id), name: i0.Value(name));
  }

  factory Group.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return Group(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  i1.Group copyWith({int? id, String? name}) =>
      i1.Group(id: id ?? this.id, name: name ?? this.name);
  Group copyWithCompanion(i1.GroupsCompanion data) {
    return Group(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Group(')
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
      (other is i1.Group && other.id == this.id && other.name == this.name);
}

class GroupsCompanion extends i0.UpdateCompanion<i1.Group> {
  final i0.Value<int> id;
  final i0.Value<String> name;
  const GroupsCompanion({
    this.id = const i0.Value.absent(),
    this.name = const i0.Value.absent(),
  });
  GroupsCompanion.insert({
    this.id = const i0.Value.absent(),
    required String name,
  }) : name = i0.Value(name);
  static i0.Insertable<i1.Group> custom({
    i0.Expression<int>? id,
    i0.Expression<String>? name,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  i1.GroupsCompanion copyWith({i0.Value<int>? id, i0.Value<String>? name}) {
    return i1.GroupsCompanion(id: id ?? this.id, name: name ?? this.name);
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (id.present) {
      map['id'] = i0.Variable<int>(id.value, i0.SqlType.int);
    }
    if (name.present) {
      map['name'] = i0.Variable<String>(name.value, i0.SqlType.text);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $MembersTable extends i2.Members
    with i0.ResultSet<i2.Member, $MembersTable>
    implements i0.GeneratedTable<i2.Member, $MembersTable> {
  @override
  final String? alias;
  $MembersTable([this.alias]);
  @override
  late final i0.TableColumn<int> id = i0.TableColumn<int>(
    name: 'id',
    sqlType: i0.SqlType.int,
    requiredDuringInsert: false,
    constraints: () => [
      const i0.ColumnPrimaryKeyConstraint(isAutoIncrementing: true),
      const i0.ColumnNotNullConstraint(),
    ],
  )..owningResultSet = this;
  @override
  late final i0.TableColumn<int> group = i0.TableColumn<int>(
    name: 'group',
    sqlType: i0.SqlType.int,
    requiredDuringInsert: true,
    constraints: () => [
      const i0.ColumnNotNullConstraint(),
      const i0.ColumnForeignKeyConstraint(
        otherTableName: 'groups',
        otherColumnName: 'id',
      ),
    ],
  )..owningResultSet = this;
  @override
  List<i0.TableColumn> get columns => [id, group];
  @override
  String get entityName => $name;
  static const String $name = 'members';
  @override
  $MembersTable asSelfType() => this;

  @override
  i2.Member? Function(i0.RawRow) createMapperFromPositions(
    i0.DriftDialect dialect,
    List<i0.ColumnPosition> positions,
  ) {
    final pos$id = positions[0].index;
    final type$0 = dialect.intType;
    final pos$group = positions[1].index;
    return (i0.RawRow row) {
      // Not part of row if non-nullable column "id" is missing
      if (row[pos$id] == null) {
        return null;
      }
      return i2.Member(id: type$0.dartValue(row[pos$id]!));
    };
  }

  @override
  $MembersTable withAlias(String alias) {
    return $MembersTable(alias);
  }
}

class MembersCompanion extends i0.UpdateCompanion<i2.Member> {
  final i0.Value<int> id;
  final i0.Value<int> group;
  const MembersCompanion({
    this.id = const i0.Value.absent(),
    this.group = const i0.Value.absent(),
  });
  MembersCompanion.insert({
    this.id = const i0.Value.absent(),
    required int group,
  }) : group = i0.Value(group);
  static i0.Insertable<i2.Member> custom({
    i0.Expression<int>? id,
    i0.Expression<int>? group,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (group != null) 'group': group,
    });
  }

  i1.MembersCompanion copyWith({i0.Value<int>? id, i0.Value<int>? group}) {
    return i1.MembersCompanion(id: id ?? this.id, group: group ?? this.group);
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (id.present) {
      map['id'] = i0.Variable<int>(id.value, i0.SqlType.int);
    }
    if (group.present) {
      map['group'] = i0.Variable<int>(group.value, i0.SqlType.int);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MembersCompanion(')
          ..write('id: $id, ')
          ..write('group: $group')
          ..write(')'))
        .toString();
  }
}
