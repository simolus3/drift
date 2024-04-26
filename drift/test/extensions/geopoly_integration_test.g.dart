// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'geopoly_integration_test.dart';

// ignore_for_file: type=lint
class GeopolyTest extends Table
    with
        TableInfo<GeopolyTest, GeopolyTestData>,
        VirtualTableInfo<GeopolyTest, GeopolyTestData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  GeopolyTest(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _shapeMeta = const VerificationMeta('shape');
  late final GeneratedColumn<GeopolyPolygon> shape =
      GeneratedColumn<GeopolyPolygon>('_shape', aliasedName, true,
          type: const GeopolyPolygonType(),
          requiredDuringInsert: false,
          $customConstraints: '');
  static const VerificationMeta _aMeta = const VerificationMeta('a');
  late final GeneratedColumn<DriftAny> a = GeneratedColumn<DriftAny>(
      'a', aliasedName, true,
      type: DriftSqlType.any,
      requiredDuringInsert: false,
      $customConstraints: '');
  @override
  List<GeneratedColumn> get $columns => [shape, a];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'geopoly_test';
  @override
  VerificationContext validateIntegrity(Insertable<GeopolyTestData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('_shape')) {
      context.handle(
          _shapeMeta, shape.isAcceptableOrUnknown(data['_shape']!, _shapeMeta));
    }
    if (data.containsKey('a')) {
      context.handle(_aMeta, a.isAcceptableOrUnknown(data['a']!, _aMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  GeopolyTestData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GeopolyTestData(
      shape: attachedDatabase.typeMapping
          .read(const GeopolyPolygonType(), data['${effectivePrefix}_shape']),
      a: attachedDatabase.typeMapping
          .read(DriftSqlType.any, data['${effectivePrefix}a']),
    );
  }

  @override
  GeopolyTest createAlias(String alias) {
    return GeopolyTest(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
  @override
  String get moduleAndArgs => 'geopoly(a)';
}

class GeopolyTestData extends DataClass implements Insertable<GeopolyTestData> {
  final GeopolyPolygon? shape;
  final DriftAny? a;
  const GeopolyTestData({this.shape, this.a});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || shape != null) {
      map['_shape'] =
          Variable<GeopolyPolygon>(shape, const GeopolyPolygonType());
    }
    if (!nullToAbsent || a != null) {
      map['a'] = Variable<DriftAny>(a);
    }
    return map;
  }

  GeopolyTestCompanion toCompanion(bool nullToAbsent) {
    return GeopolyTestCompanion(
      shape:
          shape == null && nullToAbsent ? const Value.absent() : Value(shape),
      a: a == null && nullToAbsent ? const Value.absent() : Value(a),
    );
  }

  factory GeopolyTestData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GeopolyTestData(
      shape: serializer.fromJson<GeopolyPolygon?>(json['_shape']),
      a: serializer.fromJson<DriftAny?>(json['a']),
    );
  }
  factory GeopolyTestData.fromJsonString(String encodedJson,
          {ValueSerializer? serializer}) =>
      GeopolyTestData.fromJson(
          DataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      '_shape': serializer.toJson<GeopolyPolygon?>(shape),
      'a': serializer.toJson<DriftAny?>(a),
    };
  }

  GeopolyTestData copyWith(
          {Value<GeopolyPolygon?> shape = const Value.absent(),
          Value<DriftAny?> a = const Value.absent()}) =>
      GeopolyTestData(
        shape: shape.present ? shape.value : this.shape,
        a: a.present ? a.value : this.a,
      );
  @override
  String toString() {
    return (StringBuffer('GeopolyTestData(')
          ..write('shape: $shape, ')
          ..write('a: $a')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(shape, a);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GeopolyTestData &&
          other.shape == this.shape &&
          other.a == this.a);
}

class GeopolyTestCompanion extends UpdateCompanion<GeopolyTestData> {
  final Value<GeopolyPolygon?> shape;
  final Value<DriftAny?> a;
  final Value<int> rowid;
  const GeopolyTestCompanion({
    this.shape = const Value.absent(),
    this.a = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GeopolyTestCompanion.insert({
    this.shape = const Value.absent(),
    this.a = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  static Insertable<GeopolyTestData> custom({
    Expression<GeopolyPolygon>? shape,
    Expression<DriftAny>? a,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (shape != null) '_shape': shape,
      if (a != null) 'a': a,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GeopolyTestCompanion copyWith(
      {Value<GeopolyPolygon?>? shape, Value<DriftAny?>? a, Value<int>? rowid}) {
    return GeopolyTestCompanion(
      shape: shape ?? this.shape,
      a: a ?? this.a,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (shape.present) {
      map['_shape'] =
          Variable<GeopolyPolygon>(shape.value, const GeopolyPolygonType());
    }
    if (a.present) {
      map['a'] = Variable<DriftAny>(a.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GeopolyTestCompanion(')
          ..write('shape: $shape, ')
          ..write('a: $a, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$_GeopolyTestDatabase extends GeneratedDatabase {
  _$_GeopolyTestDatabase(QueryExecutor e) : super(e);
  _$_GeopolyTestDatabaseManager get managers =>
      _$_GeopolyTestDatabaseManager(this);
  late final GeopolyTest geopolyTest = GeopolyTest(this);
  Selectable<double?> area(int var1) {
    return customSelect(
        'SELECT geopoly_area(_shape) AS _c0 FROM geopoly_test WHERE "rowid" = ?1',
        variables: [
          Variable<int>(var1)
        ],
        readsFrom: {
          geopolyTest,
        }).map((QueryRow row) => row.readNullable<double>('_c0'));
  }

  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [geopolyTest];
}

class $GeopolyTestFilterComposer
    extends FilterComposer<_$_GeopolyTestDatabase, GeopolyTest> {
  $GeopolyTestFilterComposer(super.$db, super.$table, {super.$joinBuilder});
  ColumnFilters<GeopolyPolygon> get shape => $columnFilter($table.shape);
  ColumnFilters<DriftAny> get a => $columnFilter($table.a);
}

class $GeopolyTestOrderingComposer
    extends OrderingComposer<_$_GeopolyTestDatabase, GeopolyTest> {
  $GeopolyTestOrderingComposer(super.$db, super.$table, {super.$joinBuilder});
  ColumnOrderings<GeopolyPolygon> get shape => $columnOrdering($table.shape);
  ColumnOrderings<DriftAny> get a => $columnOrdering($table.a);
}

class $GeopolyTestProcessedTableManager extends ProcessedTableManager<
    _$_GeopolyTestDatabase,
    GeopolyTest,
    GeopolyTestData,
    $GeopolyTestFilterComposer,
    $GeopolyTestOrderingComposer,
    $GeopolyTestProcessedTableManager,
    $GeopolyTestInsertCompanionBuilder,
    $GeopolyTestUpdateCompanionBuilder> {
  const $GeopolyTestProcessedTableManager(super.$state);
}

typedef $GeopolyTestInsertCompanionBuilder = GeopolyTestCompanion Function({
  Value<GeopolyPolygon?> shape,
  Value<DriftAny?> a,
  Value<int> rowid,
});
typedef $GeopolyTestUpdateCompanionBuilder = GeopolyTestCompanion Function({
  Value<GeopolyPolygon?> shape,
  Value<DriftAny?> a,
  Value<int> rowid,
});

class $GeopolyTestTableManager extends RootTableManager<
    _$_GeopolyTestDatabase,
    GeopolyTest,
    GeopolyTestData,
    $GeopolyTestFilterComposer,
    $GeopolyTestOrderingComposer,
    $GeopolyTestProcessedTableManager,
    $GeopolyTestInsertCompanionBuilder,
    $GeopolyTestUpdateCompanionBuilder> {
  $GeopolyTestTableManager(_$_GeopolyTestDatabase db, GeopolyTest table)
      : super(TableManagerState(
            db: db,
            table: table,
            filteringComposer: $GeopolyTestFilterComposer(db, table),
            orderingComposer: $GeopolyTestOrderingComposer(db, table),
            getChildManagerBuilder: (p0) =>
                $GeopolyTestProcessedTableManager(p0),
            getUpdateCompanionBuilder: ({
              Value<GeopolyPolygon?> shape = const Value.absent(),
              Value<DriftAny?> a = const Value.absent(),
              Value<int> rowid = const Value.absent(),
            }) =>
                GeopolyTestCompanion(
                  shape: shape,
                  a: a,
                  rowid: rowid,
                ),
            getInsertCompanionBuilder: ({
              Value<GeopolyPolygon?> shape = const Value.absent(),
              Value<DriftAny?> a = const Value.absent(),
              Value<int> rowid = const Value.absent(),
            }) =>
                GeopolyTestCompanion.insert(
                  shape: shape,
                  a: a,
                  rowid: rowid,
                )));
}

class _$_GeopolyTestDatabaseManager {
  final _$_GeopolyTestDatabase _db;
  _$_GeopolyTestDatabaseManager(this._db);
  $GeopolyTestTableManager get geopolyTest =>
      $GeopolyTestTableManager(_db, _db.geopolyTest);
}
