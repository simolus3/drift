// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'geopoly_integration_test.dart';

// ignore_for_file: type=lint
class GeopolyTest extends Table
    with ResultSet<GeopolyTestData, GeopolyTest>
    implements
        GeneratedTable<GeopolyTestData, GeopolyTest>,
        VirtualTableInfo<GeopolyTestData, GeopolyTest> {
  @override
  final String? alias;
  GeopolyTest([this.alias]);
  late final TableColumn<GeopolyPolygon> shape = TableColumn<GeopolyPolygon>(
      name: '_shape',
      type: const GeopolyPolygonType(),
      isNullable: true,
      requiredDuringInsert: false,
      constraints: () => [ColumnConstraint.customSql('')])
    ..owningResultSet = this;
  late final TableColumn<DriftAny> a = TableColumn<DriftAny>(
      name: 'a',
      type: SqliteDialect.anyType(),
      isNullable: true,
      requiredDuringInsert: false,
      constraints: () => [ColumnConstraint.customSql('')])
    ..owningResultSet = this;
  @override
  List<TableColumn> get columns => [shape, a];
  @override
  String get entityName => $name;
  static const String $name = 'geopoly_test';
  @override
  GeopolyTest asSelfType() => this;

  @override
  Set<TableColumn> get primaryKey => const {};
  @override
  GeopolyTestData? Function(DriftRow) createMapperFromPositions(
      List<ColumnPosition> positions) {
    return (DriftRow row) {
      return GeopolyTestData(
        shape: row.readWithType(positions[0], const GeopolyPolygonType()),
        a: row.readWithType(positions[1], SqliteDialect.anyType()),
      );
    };
  }

  @override
  GeopolyTest withAlias(String alias) {
    return GeopolyTest(alias);
  }

  @override
  bool get dontWriteConstraints => true;
  @override
  String get moduleAndArgs => 'geopoly(a)';
}

class GeopolyTestData extends LegacyDataClass
    implements Insertable<GeopolyTestData> {
  final GeopolyPolygon? shape;
  final DriftAny? a;
  const GeopolyTestData({this.shape, this.a});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || shape != null) {
      map['_shape'] =
          Variable<GeopolyPolygon>(shape, (_) => const GeopolyPolygonType());
    }
    if (!nullToAbsent || a != null) {
      map['a'] = Variable<DriftAny>(a, (_) => SqliteDialect.anyType());
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
          LegacyDataClass.parseJson(encodedJson) as Map<String, dynamic>,
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
  GeopolyTestData copyWithCompanion(GeopolyTestCompanion data) {
    return GeopolyTestData(
      shape: data.shape.present ? data.shape.value : this.shape,
      a: data.a.present ? data.a.value : this.a,
    );
  }

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
      map['_shape'] = Variable<GeopolyPolygon>(
          shape.value, (_) => const GeopolyPolygonType());
    }
    if (a.present) {
      map['a'] = Variable<DriftAny>(a.value, (_) => SqliteDialect.anyType());
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

abstract base class _$_GeopolyTestDatabase extends GeneratedDatabase {
  _$_GeopolyTestDatabase(super.implementation);
  late final GeopolyTest geopolyTest = GeopolyTest();
  Selectable<double?> area(int var1) {
    return customSelectMapped<double?>(
        query:
            'SELECT geopoly_area(_shape) AS _c0 FROM geopoly_test WHERE "rowid" = ?1',
        variables: [(dialect.intType, var1)],
        readsFrom: {
          geopolyTest,
        },
        createMapper: (DriftResultSet resultSet) {
          final type$double = dialect.doubleType;

          return (DriftRow row) =>
              row.readWithType(const (index: 0, name: '_c0'), type$double);
        });
  }

  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [geopolyTest];
}
