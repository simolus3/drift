// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:drift_docs/snippets/modular/many_to_many/shared.drift.dart'
    as i1;
import 'package:drift_docs/snippets/modular/many_to_many/json.drift.dart' as i2;
import 'package:drift_docs/snippets/modular/many_to_many/json.dart' as i3;

abstract class $JsonBasedDatabase extends i0.GeneratedDatabase {
  $JsonBasedDatabase(i0.QueryExecutor e) : super(e);
  $JsonBasedDatabaseManager get managers => $JsonBasedDatabaseManager(this);
  late final i1.$BuyableItemsTable buyableItems = i1.$BuyableItemsTable(this);
  late final i2.$ShoppingCartsTable shoppingCarts =
      i2.$ShoppingCartsTable(this);
  @override
  Iterable<i0.TableInfo<i0.Table, Object?>> get allTables =>
      allSchemaEntities.whereType<i0.TableInfo<i0.Table, Object?>>();
  @override
  List<i0.DatabaseSchemaEntity> get allSchemaEntities =>
      [buyableItems, shoppingCarts];
}

class $JsonBasedDatabaseManager {
  final $JsonBasedDatabase _db;
  $JsonBasedDatabaseManager(this._db);
  i1.$$BuyableItemsTableTableManager get buyableItems =>
      i1.$$BuyableItemsTableTableManager(_db, _db.buyableItems);
  i2.$$ShoppingCartsTableTableManager get shoppingCarts =>
      i2.$$ShoppingCartsTableTableManager(_db, _db.shoppingCarts);
}

class $ShoppingCartsTable extends i3.ShoppingCarts
    with i0.TableInfo<$ShoppingCartsTable, i2.ShoppingCart> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShoppingCartsTable(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _idMeta = const i0.VerificationMeta('id');
  @override
  late final i0.GeneratedColumn<int> id = i0.GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: i0.DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          i0.GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const i0.VerificationMeta _entriesMeta =
      const i0.VerificationMeta('entries');
  @override
  late final i0.GeneratedColumnWithTypeConverter<i3.ShoppingCartEntries, String>
      entries = i0.GeneratedColumn<String>('entries', aliasedName, false,
              type: i0.DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<i3.ShoppingCartEntries>(
              i2.$ShoppingCartsTable.$converterentries);
  @override
  List<i0.GeneratedColumn> get $columns => [id, entries];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shopping_carts';
  @override
  i0.VerificationContext validateIntegrity(
      i0.Insertable<i2.ShoppingCart> instance,
      {bool isInserting = false}) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    context.handle(_entriesMeta, const i0.VerificationResult.success());
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {id};
  @override
  i2.ShoppingCart map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i2.ShoppingCart(
      id: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.int, data['${effectivePrefix}id'])!,
      entries: i2.$ShoppingCartsTable.$converterentries.fromSql(attachedDatabase
          .typeMapping
          .read(i0.DriftSqlType.string, data['${effectivePrefix}entries'])!),
    );
  }

  @override
  $ShoppingCartsTable createAlias(String alias) {
    return $ShoppingCartsTable(attachedDatabase, alias);
  }

  static i0.JsonTypeConverter2<i3.ShoppingCartEntries, String, String>
      $converterentries = i3.ShoppingCartEntries.converter;
}

class ShoppingCart extends i0.DataClass
    implements i0.Insertable<i2.ShoppingCart> {
  final int id;
  final i3.ShoppingCartEntries entries;
  const ShoppingCart({required this.id, required this.entries});
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['id'] = i0.Variable<int>(id);
    {
      map['entries'] = i0.Variable<String>(
          i2.$ShoppingCartsTable.$converterentries.toSql(entries));
    }
    return map;
  }

  i2.ShoppingCartsCompanion toCompanion(bool nullToAbsent) {
    return i2.ShoppingCartsCompanion(
      id: i0.Value(id),
      entries: i0.Value(entries),
    );
  }

  factory ShoppingCart.fromJson(Map<String, dynamic> json,
      {i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return ShoppingCart(
      id: serializer.fromJson<int>(json['id']),
      entries: i2.$ShoppingCartsTable.$converterentries
          .fromJson(serializer.fromJson<String>(json['entries'])),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entries': serializer.toJson<String>(
          i2.$ShoppingCartsTable.$converterentries.toJson(entries)),
    };
  }

  i2.ShoppingCart copyWith({int? id, i3.ShoppingCartEntries? entries}) =>
      i2.ShoppingCart(
        id: id ?? this.id,
        entries: entries ?? this.entries,
      );
  ShoppingCart copyWithCompanion(i2.ShoppingCartsCompanion data) {
    return ShoppingCart(
      id: data.id.present ? data.id.value : this.id,
      entries: data.entries.present ? data.entries.value : this.entries,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingCart(')
          ..write('id: $id, ')
          ..write('entries: $entries')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, entries);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i2.ShoppingCart &&
          other.id == this.id &&
          other.entries == this.entries);
}

class ShoppingCartsCompanion extends i0.UpdateCompanion<i2.ShoppingCart> {
  final i0.Value<int> id;
  final i0.Value<i3.ShoppingCartEntries> entries;
  const ShoppingCartsCompanion({
    this.id = const i0.Value.absent(),
    this.entries = const i0.Value.absent(),
  });
  ShoppingCartsCompanion.insert({
    this.id = const i0.Value.absent(),
    required i3.ShoppingCartEntries entries,
  }) : entries = i0.Value(entries);
  static i0.Insertable<i2.ShoppingCart> custom({
    i0.Expression<int>? id,
    i0.Expression<String>? entries,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (entries != null) 'entries': entries,
    });
  }

  i2.ShoppingCartsCompanion copyWith(
      {i0.Value<int>? id, i0.Value<i3.ShoppingCartEntries>? entries}) {
    return i2.ShoppingCartsCompanion(
      id: id ?? this.id,
      entries: entries ?? this.entries,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (id.present) {
      map['id'] = i0.Variable<int>(id.value);
    }
    if (entries.present) {
      map['entries'] = i0.Variable<String>(
          i2.$ShoppingCartsTable.$converterentries.toSql(entries.value));
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingCartsCompanion(')
          ..write('id: $id, ')
          ..write('entries: $entries')
          ..write(')'))
        .toString();
  }
}

typedef $$ShoppingCartsTableCreateCompanionBuilder = i2.ShoppingCartsCompanion
    Function({
  i0.Value<int> id,
  required i3.ShoppingCartEntries entries,
});
typedef $$ShoppingCartsTableUpdateCompanionBuilder = i2.ShoppingCartsCompanion
    Function({
  i0.Value<int> id,
  i0.Value<i3.ShoppingCartEntries> entries,
});

class $$ShoppingCartsTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.$ShoppingCartsTable> {
  $$ShoppingCartsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => i0.ColumnFilters(column));

  i0.ColumnWithTypeConverterFilters<i3.ShoppingCartEntries,
          i3.ShoppingCartEntries, String>
      get entries => $composableBuilder(
          column: $table.entries,
          builder: (column) => i0.ColumnWithTypeConverterFilters(column));
}

class $$ShoppingCartsTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.$ShoppingCartsTable> {
  $$ShoppingCartsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => i0.ColumnOrderings(column));

  i0.ColumnOrderings<String> get entries => $composableBuilder(
      column: $table.entries, builder: (column) => i0.ColumnOrderings(column));
}

class $$ShoppingCartsTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.$ShoppingCartsTable> {
  $$ShoppingCartsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  i0.GeneratedColumnWithTypeConverter<i3.ShoppingCartEntries, String>
      get entries => $composableBuilder(
          column: $table.entries, builder: (column) => column);
}

class $$ShoppingCartsTableTableManager extends i0.RootTableManager<
    i0.GeneratedDatabase,
    i2.$ShoppingCartsTable,
    i2.ShoppingCart,
    i2.$$ShoppingCartsTableFilterComposer,
    i2.$$ShoppingCartsTableOrderingComposer,
    i2.$$ShoppingCartsTableAnnotationComposer,
    $$ShoppingCartsTableCreateCompanionBuilder,
    $$ShoppingCartsTableUpdateCompanionBuilder,
    (
      i2.ShoppingCart,
      i0.BaseReferences<i0.GeneratedDatabase, i2.$ShoppingCartsTable,
          i2.ShoppingCart>
    ),
    i2.ShoppingCart,
    i0.PrefetchHooks Function()> {
  $$ShoppingCartsTableTableManager(
      i0.GeneratedDatabase db, i2.$ShoppingCartsTable table)
      : super(i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i2.$$ShoppingCartsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i2.$$ShoppingCartsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i2.$$ShoppingCartsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            i0.Value<int> id = const i0.Value.absent(),
            i0.Value<i3.ShoppingCartEntries> entries = const i0.Value.absent(),
          }) =>
              i2.ShoppingCartsCompanion(
            id: id,
            entries: entries,
          ),
          createCompanionCallback: ({
            i0.Value<int> id = const i0.Value.absent(),
            required i3.ShoppingCartEntries entries,
          }) =>
              i2.ShoppingCartsCompanion.insert(
            id: id,
            entries: entries,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), i0.BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ShoppingCartsTableProcessedTableManager = i0.ProcessedTableManager<
    i0.GeneratedDatabase,
    i2.$ShoppingCartsTable,
    i2.ShoppingCart,
    i2.$$ShoppingCartsTableFilterComposer,
    i2.$$ShoppingCartsTableOrderingComposer,
    i2.$$ShoppingCartsTableAnnotationComposer,
    $$ShoppingCartsTableCreateCompanionBuilder,
    $$ShoppingCartsTableUpdateCompanionBuilder,
    (
      i2.ShoppingCart,
      i0.BaseReferences<i0.GeneratedDatabase, i2.$ShoppingCartsTable,
          i2.ShoppingCart>
    ),
    i2.ShoppingCart,
    i0.PrefetchHooks Function()>;
