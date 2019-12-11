// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saves_after_migration_regression_test.dart';

// **************************************************************************
// MoorGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps, unnecessary_this
class Foo extends DataClass implements Insertable<Foo> {
  final int id;
  Foo({@required this.id});
  factory Foo.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final intType = db.typeSystem.forDartType<int>();
    return Foo(
      id: intType.mapFromDatabaseResponse(data['${effectivePrefix}id']),
    );
  }
  factory Foo.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer = const ValueSerializer.defaults()}) {
    return Foo(
      id: serializer.fromJson<int>(json['id']),
    );
  }
  factory Foo.fromJsonString(String encodedJson,
          {ValueSerializer serializer = const ValueSerializer.defaults()}) =>
      Foo.fromJson(DataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson(
      {ValueSerializer serializer = const ValueSerializer.defaults()}) {
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
    };
  }

  @override
  FoosCompanion createCompanion(bool nullToAbsent) {
    return FoosCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
    );
  }

  Foo copyWith({int id}) => Foo(
        id: id ?? this.id,
      );
  @override
  String toString() {
    return (StringBuffer('Foo(')..write('id: $id')..write(')')).toString();
  }

  @override
  int get hashCode => $mrjf(id.hashCode);
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) || (other is Foo && other.id == this.id);
}

class FoosCompanion extends UpdateCompanion<Foo> {
  final Value<int> id;
  const FoosCompanion({
    this.id = const Value.absent(),
  });
  FoosCompanion.insert({
    this.id = const Value.absent(),
  });
  FoosCompanion copyWith({Value<int> id}) {
    return FoosCompanion(
      id: id ?? this.id,
    );
  }
}

class $FoosTable extends Foos with TableInfo<$FoosTable, Foo> {
  final GeneratedDatabase _db;
  final String _alias;
  $FoosTable(this._db, [this._alias]);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  GeneratedIntColumn _id;
  @override
  GeneratedIntColumn get id => _id ??= _constructId();
  GeneratedIntColumn _constructId() {
    return GeneratedIntColumn('id', $tableName, false,
        hasAutoIncrement: true, declaredAsPrimaryKey: true);
  }

  @override
  List<GeneratedColumn> get $columns => [id];
  @override
  $FoosTable get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'foos';
  @override
  final String actualTableName = 'foos';
  @override
  VerificationContext validateIntegrity(FoosCompanion d,
      {bool isInserting = false}) {
    final context = VerificationContext();
    if (d.id.present) {
      context.handle(_idMeta, id.isAcceptableValue(d.id.value, _idMeta));
    } else if (id.isRequired && isInserting) {
      context.missing(_idMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Foo map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return Foo.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Map<String, Variable> entityToSql(FoosCompanion d) {
    final map = <String, Variable>{};
    if (d.id.present) {
      map['id'] = Variable<int, IntType>(d.id.value);
    }
    return map;
  }

  @override
  $FoosTable createAlias(String alias) {
    return $FoosTable(_db, alias);
  }
}

class Bar extends DataClass implements Insertable<Bar> {
  final int id;
  Bar({@required this.id});
  factory Bar.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final intType = db.typeSystem.forDartType<int>();
    return Bar(
      id: intType.mapFromDatabaseResponse(data['${effectivePrefix}id']),
    );
  }
  factory Bar.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer = const ValueSerializer.defaults()}) {
    return Bar(
      id: serializer.fromJson<int>(json['id']),
    );
  }
  factory Bar.fromJsonString(String encodedJson,
          {ValueSerializer serializer = const ValueSerializer.defaults()}) =>
      Bar.fromJson(DataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson(
      {ValueSerializer serializer = const ValueSerializer.defaults()}) {
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
    };
  }

  @override
  BarsCompanion createCompanion(bool nullToAbsent) {
    return BarsCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
    );
  }

  Bar copyWith({int id}) => Bar(
        id: id ?? this.id,
      );
  @override
  String toString() {
    return (StringBuffer('Bar(')..write('id: $id')..write(')')).toString();
  }

  @override
  int get hashCode => $mrjf(id.hashCode);
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) || (other is Bar && other.id == this.id);
}

class BarsCompanion extends UpdateCompanion<Bar> {
  final Value<int> id;
  const BarsCompanion({
    this.id = const Value.absent(),
  });
  BarsCompanion.insert({
    this.id = const Value.absent(),
  });
  BarsCompanion copyWith({Value<int> id}) {
    return BarsCompanion(
      id: id ?? this.id,
    );
  }
}

class $BarsTable extends Bars with TableInfo<$BarsTable, Bar> {
  final GeneratedDatabase _db;
  final String _alias;
  $BarsTable(this._db, [this._alias]);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  GeneratedIntColumn _id;
  @override
  GeneratedIntColumn get id => _id ??= _constructId();
  GeneratedIntColumn _constructId() {
    return GeneratedIntColumn('id', $tableName, false,
        hasAutoIncrement: true, declaredAsPrimaryKey: true);
  }

  @override
  List<GeneratedColumn> get $columns => [id];
  @override
  $BarsTable get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'bars';
  @override
  final String actualTableName = 'bars';
  @override
  VerificationContext validateIntegrity(BarsCompanion d,
      {bool isInserting = false}) {
    final context = VerificationContext();
    if (d.id.present) {
      context.handle(_idMeta, id.isAcceptableValue(d.id.value, _idMeta));
    } else if (id.isRequired && isInserting) {
      context.missing(_idMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Bar map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return Bar.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Map<String, Variable> entityToSql(BarsCompanion d) {
    final map = <String, Variable>{};
    if (d.id.present) {
      map['id'] = Variable<int, IntType>(d.id.value);
    }
    return map;
  }

  @override
  $BarsTable createAlias(String alias) {
    return $BarsTable(_db, alias);
  }
}

abstract class _$_FakeDb extends GeneratedDatabase {
  _$_FakeDb(QueryExecutor e) : super(SqlTypeSystem.defaultInstance, e);
  _$_FakeDb.connect(DatabaseConnection c) : super.connect(c);
  $FoosTable _foos;
  $FoosTable get foos => _foos ??= $FoosTable(this);
  $BarsTable _bars;
  $BarsTable get bars => _bars ??= $BarsTable(this);
  @override
  List<TableInfo> get allTables => [foos, bars];
}
