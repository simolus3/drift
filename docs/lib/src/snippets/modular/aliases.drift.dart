// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:drift_website/src/snippets/modular/aliases.drift.dart' as i1;
import 'package:drift_website/src/snippets/modular/aliases.dart' as i2;

typedef $$GeoPointsTableCreateCompanionBuilder =
    i1.GeoPointsCompanion Function({
      i0.Value<int> id,
      required String name,
      required String latitude,
      required String longitude,
    });
typedef $$GeoPointsTableUpdateCompanionBuilder =
    i1.GeoPointsCompanion Function({
      i0.Value<int> id,
      i0.Value<String> name,
      i0.Value<String> latitude,
      i0.Value<String> longitude,
    });

class $$GeoPointsTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$GeoPointsTable> {
  $$GeoPointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => i0.ColumnFilters(column),
  );
}

class $$GeoPointsTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$GeoPointsTable> {
  $$GeoPointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => i0.ColumnOrderings(column),
  );
}

class $$GeoPointsTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$GeoPointsTable> {
  $$GeoPointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  i0.GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  i0.GeneratedColumn<String> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  i0.GeneratedColumn<String> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);
}

class $$GeoPointsTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i1.$GeoPointsTable,
          i1.GeoPoint,
          i1.$$GeoPointsTableFilterComposer,
          i1.$$GeoPointsTableOrderingComposer,
          i1.$$GeoPointsTableAnnotationComposer,
          $$GeoPointsTableCreateCompanionBuilder,
          $$GeoPointsTableUpdateCompanionBuilder,
          (
            i1.GeoPoint,
            i0.BaseReferences<
              i0.GeneratedDatabase,
              i1.$GeoPointsTable,
              i1.GeoPoint
            >,
          ),
          i1.GeoPoint,
          i0.PrefetchHooks Function()
        > {
  $$GeoPointsTableTableManager(
    i0.GeneratedDatabase db,
    i1.$GeoPointsTable table,
  ) : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$$GeoPointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$$GeoPointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i1.$$GeoPointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<int> id = const i0.Value.absent(),
                i0.Value<String> name = const i0.Value.absent(),
                i0.Value<String> latitude = const i0.Value.absent(),
                i0.Value<String> longitude = const i0.Value.absent(),
              }) => i1.GeoPointsCompanion(
                id: id,
                name: name,
                latitude: latitude,
                longitude: longitude,
              ),
          createCompanionCallback:
              ({
                i0.Value<int> id = const i0.Value.absent(),
                required String name,
                required String latitude,
                required String longitude,
              }) => i1.GeoPointsCompanion.insert(
                id: id,
                name: name,
                latitude: latitude,
                longitude: longitude,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), i0.BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GeoPointsTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i1.$GeoPointsTable,
      i1.GeoPoint,
      i1.$$GeoPointsTableFilterComposer,
      i1.$$GeoPointsTableOrderingComposer,
      i1.$$GeoPointsTableAnnotationComposer,
      $$GeoPointsTableCreateCompanionBuilder,
      $$GeoPointsTableUpdateCompanionBuilder,
      (
        i1.GeoPoint,
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i1.$GeoPointsTable,
          i1.GeoPoint
        >,
      ),
      i1.GeoPoint,
      i0.PrefetchHooks Function()
    >;
typedef $$RoutesTableCreateCompanionBuilder =
    i1.RoutesCompanion Function({
      i0.Value<int> id,
      required String name,
      required int start,
      required int destination,
    });
typedef $$RoutesTableUpdateCompanionBuilder =
    i1.RoutesCompanion Function({
      i0.Value<int> id,
      i0.Value<String> name,
      i0.Value<int> start,
      i0.Value<int> destination,
    });

class $$RoutesTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$RoutesTable> {
  $$RoutesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get start => $composableBuilder(
    column: $table.start,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => i0.ColumnFilters(column),
  );
}

class $$RoutesTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$RoutesTable> {
  $$RoutesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get start => $composableBuilder(
    column: $table.start,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => i0.ColumnOrderings(column),
  );
}

class $$RoutesTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$RoutesTable> {
  $$RoutesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  i0.GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  i0.GeneratedColumn<int> get start =>
      $composableBuilder(column: $table.start, builder: (column) => column);

  i0.GeneratedColumn<int> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => column,
  );
}

class $$RoutesTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i1.$RoutesTable,
          i1.Route,
          i1.$$RoutesTableFilterComposer,
          i1.$$RoutesTableOrderingComposer,
          i1.$$RoutesTableAnnotationComposer,
          $$RoutesTableCreateCompanionBuilder,
          $$RoutesTableUpdateCompanionBuilder,
          (
            i1.Route,
            i0.BaseReferences<i0.GeneratedDatabase, i1.$RoutesTable, i1.Route>,
          ),
          i1.Route,
          i0.PrefetchHooks Function()
        > {
  $$RoutesTableTableManager(i0.GeneratedDatabase db, i1.$RoutesTable table)
    : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$$RoutesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$$RoutesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i1.$$RoutesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<int> id = const i0.Value.absent(),
                i0.Value<String> name = const i0.Value.absent(),
                i0.Value<int> start = const i0.Value.absent(),
                i0.Value<int> destination = const i0.Value.absent(),
              }) => i1.RoutesCompanion(
                id: id,
                name: name,
                start: start,
                destination: destination,
              ),
          createCompanionCallback:
              ({
                i0.Value<int> id = const i0.Value.absent(),
                required String name,
                required int start,
                required int destination,
              }) => i1.RoutesCompanion.insert(
                id: id,
                name: name,
                start: start,
                destination: destination,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), i0.BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RoutesTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i1.$RoutesTable,
      i1.Route,
      i1.$$RoutesTableFilterComposer,
      i1.$$RoutesTableOrderingComposer,
      i1.$$RoutesTableAnnotationComposer,
      $$RoutesTableCreateCompanionBuilder,
      $$RoutesTableUpdateCompanionBuilder,
      (
        i1.Route,
        i0.BaseReferences<i0.GeneratedDatabase, i1.$RoutesTable, i1.Route>,
      ),
      i1.Route,
      i0.PrefetchHooks Function()
    >;

class $GeoPointsTable extends i2.GeoPoints
    with i0.TableInfo<$GeoPointsTable, i1.GeoPoint> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GeoPointsTable(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _idMeta = const i0.VerificationMeta('id');
  @override
  late final i0.GeneratedColumn<int> id = i0.GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: i0.GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const i0.VerificationMeta _nameMeta = const i0.VerificationMeta(
    'name',
  );
  @override
  late final i0.GeneratedColumn<String> name = i0.GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _latitudeMeta = const i0.VerificationMeta(
    'latitude',
  );
  @override
  late final i0.GeneratedColumn<String> latitude = i0.GeneratedColumn<String>(
    'latitude',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _longitudeMeta = const i0.VerificationMeta(
    'longitude',
  );
  @override
  late final i0.GeneratedColumn<String> longitude = i0.GeneratedColumn<String>(
    'longitude',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<i0.GeneratedColumn> get $columns => [id, name, latitude, longitude];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'geo_points';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.GeoPoint> instance, {
    bool isInserting = false,
  }) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {id};
  @override
  i1.GeoPoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.GeoPoint(
      id: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}longitude'],
      )!,
    );
  }

  @override
  $GeoPointsTable createAlias(String alias) {
    return $GeoPointsTable(attachedDatabase, alias);
  }
}

class GeoPoint extends i0.DataClass implements i0.Insertable<i1.GeoPoint> {
  final int id;
  final String name;
  final String latitude;
  final String longitude;
  const GeoPoint({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['id'] = i0.Variable<int>(id);
    map['name'] = i0.Variable<String>(name);
    map['latitude'] = i0.Variable<String>(latitude);
    map['longitude'] = i0.Variable<String>(longitude);
    return map;
  }

  i1.GeoPointsCompanion toCompanion(bool nullToAbsent) {
    return i1.GeoPointsCompanion(
      id: i0.Value(id),
      name: i0.Value(name),
      latitude: i0.Value(latitude),
      longitude: i0.Value(longitude),
    );
  }

  factory GeoPoint.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return GeoPoint(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      latitude: serializer.fromJson<String>(json['latitude']),
      longitude: serializer.fromJson<String>(json['longitude']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'latitude': serializer.toJson<String>(latitude),
      'longitude': serializer.toJson<String>(longitude),
    };
  }

  i1.GeoPoint copyWith({
    int? id,
    String? name,
    String? latitude,
    String? longitude,
  }) => i1.GeoPoint(
    id: id ?? this.id,
    name: name ?? this.name,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
  );
  GeoPoint copyWithCompanion(i1.GeoPointsCompanion data) {
    return GeoPoint(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GeoPoint(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, latitude, longitude);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.GeoPoint &&
          other.id == this.id &&
          other.name == this.name &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude);
}

class GeoPointsCompanion extends i0.UpdateCompanion<i1.GeoPoint> {
  final i0.Value<int> id;
  final i0.Value<String> name;
  final i0.Value<String> latitude;
  final i0.Value<String> longitude;
  const GeoPointsCompanion({
    this.id = const i0.Value.absent(),
    this.name = const i0.Value.absent(),
    this.latitude = const i0.Value.absent(),
    this.longitude = const i0.Value.absent(),
  });
  GeoPointsCompanion.insert({
    this.id = const i0.Value.absent(),
    required String name,
    required String latitude,
    required String longitude,
  }) : name = i0.Value(name),
       latitude = i0.Value(latitude),
       longitude = i0.Value(longitude);
  static i0.Insertable<i1.GeoPoint> custom({
    i0.Expression<int>? id,
    i0.Expression<String>? name,
    i0.Expression<String>? latitude,
    i0.Expression<String>? longitude,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    });
  }

  i1.GeoPointsCompanion copyWith({
    i0.Value<int>? id,
    i0.Value<String>? name,
    i0.Value<String>? latitude,
    i0.Value<String>? longitude,
  }) {
    return i1.GeoPointsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (id.present) {
      map['id'] = i0.Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = i0.Variable<String>(name.value);
    }
    if (latitude.present) {
      map['latitude'] = i0.Variable<String>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = i0.Variable<String>(longitude.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GeoPointsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude')
          ..write(')'))
        .toString();
  }
}

class $RoutesTable extends i2.Routes with i0.TableInfo<$RoutesTable, i1.Route> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoutesTable(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _idMeta = const i0.VerificationMeta('id');
  @override
  late final i0.GeneratedColumn<int> id = i0.GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: i0.GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const i0.VerificationMeta _nameMeta = const i0.VerificationMeta(
    'name',
  );
  @override
  late final i0.GeneratedColumn<String> name = i0.GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _startMeta = const i0.VerificationMeta(
    'start',
  );
  @override
  late final i0.GeneratedColumn<int> start = i0.GeneratedColumn<int>(
    'start',
    aliasedName,
    false,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _destinationMeta = const i0.VerificationMeta(
    'destination',
  );
  @override
  late final i0.GeneratedColumn<int> destination = i0.GeneratedColumn<int>(
    'destination',
    aliasedName,
    false,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<i0.GeneratedColumn> get $columns => [id, name, start, destination];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'routes';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.Route> instance, {
    bool isInserting = false,
  }) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('start')) {
      context.handle(
        _startMeta,
        start.isAcceptableOrUnknown(data['start']!, _startMeta),
      );
    } else if (isInserting) {
      context.missing(_startMeta);
    }
    if (data.containsKey('destination')) {
      context.handle(
        _destinationMeta,
        destination.isAcceptableOrUnknown(
          data['destination']!,
          _destinationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_destinationMeta);
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {id};
  @override
  i1.Route map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.Route(
      id: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      start: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}start'],
      )!,
      destination: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}destination'],
      )!,
    );
  }

  @override
  $RoutesTable createAlias(String alias) {
    return $RoutesTable(attachedDatabase, alias);
  }
}

class Route extends i0.DataClass implements i0.Insertable<i1.Route> {
  final int id;
  final String name;
  final int start;
  final int destination;
  const Route({
    required this.id,
    required this.name,
    required this.start,
    required this.destination,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['id'] = i0.Variable<int>(id);
    map['name'] = i0.Variable<String>(name);
    map['start'] = i0.Variable<int>(start);
    map['destination'] = i0.Variable<int>(destination);
    return map;
  }

  i1.RoutesCompanion toCompanion(bool nullToAbsent) {
    return i1.RoutesCompanion(
      id: i0.Value(id),
      name: i0.Value(name),
      start: i0.Value(start),
      destination: i0.Value(destination),
    );
  }

  factory Route.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return Route(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      start: serializer.fromJson<int>(json['start']),
      destination: serializer.fromJson<int>(json['destination']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'start': serializer.toJson<int>(start),
      'destination': serializer.toJson<int>(destination),
    };
  }

  i1.Route copyWith({int? id, String? name, int? start, int? destination}) =>
      i1.Route(
        id: id ?? this.id,
        name: name ?? this.name,
        start: start ?? this.start,
        destination: destination ?? this.destination,
      );
  Route copyWithCompanion(i1.RoutesCompanion data) {
    return Route(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      start: data.start.present ? data.start.value : this.start,
      destination: data.destination.present
          ? data.destination.value
          : this.destination,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Route(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('start: $start, ')
          ..write('destination: $destination')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, start, destination);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.Route &&
          other.id == this.id &&
          other.name == this.name &&
          other.start == this.start &&
          other.destination == this.destination);
}

class RoutesCompanion extends i0.UpdateCompanion<i1.Route> {
  final i0.Value<int> id;
  final i0.Value<String> name;
  final i0.Value<int> start;
  final i0.Value<int> destination;
  const RoutesCompanion({
    this.id = const i0.Value.absent(),
    this.name = const i0.Value.absent(),
    this.start = const i0.Value.absent(),
    this.destination = const i0.Value.absent(),
  });
  RoutesCompanion.insert({
    this.id = const i0.Value.absent(),
    required String name,
    required int start,
    required int destination,
  }) : name = i0.Value(name),
       start = i0.Value(start),
       destination = i0.Value(destination);
  static i0.Insertable<i1.Route> custom({
    i0.Expression<int>? id,
    i0.Expression<String>? name,
    i0.Expression<int>? start,
    i0.Expression<int>? destination,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (start != null) 'start': start,
      if (destination != null) 'destination': destination,
    });
  }

  i1.RoutesCompanion copyWith({
    i0.Value<int>? id,
    i0.Value<String>? name,
    i0.Value<int>? start,
    i0.Value<int>? destination,
  }) {
    return i1.RoutesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      start: start ?? this.start,
      destination: destination ?? this.destination,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (id.present) {
      map['id'] = i0.Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = i0.Variable<String>(name.value);
    }
    if (start.present) {
      map['start'] = i0.Variable<int>(start.value);
    }
    if (destination.present) {
      map['destination'] = i0.Variable<int>(destination.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoutesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('start: $start, ')
          ..write('destination: $destination')
          ..write(')'))
        .toString();
  }
}
