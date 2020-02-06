// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// **************************************************************************
// MoorGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps, unnecessary_this
class SomeInt extends DataClass implements Insertable<SomeInt> {
  final int id;
  SomeInt({@required this.id});
  factory SomeInt.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final intType = db.typeSystem.forDartType<int>();
    return SomeInt(
      id: intType.mapFromDatabaseResponse(data['${effectivePrefix}id']),
    );
  }
  factory SomeInt.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return SomeInt(
      id: serializer.fromJson<int>(json['id']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
    };
  }

  @override
  SomeIntsCompanion createCompanion(bool nullToAbsent) {
    return SomeIntsCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
    );
  }

  SomeInt copyWith({int id}) => SomeInt(
        id: id ?? this.id,
      );
  @override
  String toString() {
    return (StringBuffer('SomeInt(')..write('id: $id')..write(')')).toString();
  }

  @override
  int get hashCode => $mrjf(id.hashCode);
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) || (other is SomeInt && other.id == this.id);
}

class SomeIntsCompanion extends UpdateCompanion<SomeInt> {
  final Value<int> id;
  const SomeIntsCompanion({
    this.id = const Value.absent(),
  });
  SomeIntsCompanion.insert({
    this.id = const Value.absent(),
  });
  SomeIntsCompanion copyWith({Value<int> id}) {
    return SomeIntsCompanion(
      id: id ?? this.id,
    );
  }
}

class $SomeIntsTable extends SomeInts with TableInfo<$SomeIntsTable, SomeInt> {
  final GeneratedDatabase _db;
  final String _alias;
  $SomeIntsTable(this._db, [this._alias]);
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
  $SomeIntsTable get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'some_ints';
  @override
  final String actualTableName = 'some_ints';
  @override
  VerificationContext validateIntegrity(SomeIntsCompanion d,
      {bool isInserting = false}) {
    final context = VerificationContext();
    if (d.id.present) {
      context.handle(_idMeta, id.isAcceptableValue(d.id.value, _idMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SomeInt map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return SomeInt.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Map<String, Variable> entityToSql(SomeIntsCompanion d) {
    final map = <String, Variable>{};
    if (d.id.present) {
      map['id'] = Variable<int, IntType>(d.id.value);
    }
    return map;
  }

  @override
  $SomeIntsTable createAlias(String alias) {
    return $SomeIntsTable(_db, alias);
  }
}

abstract class _$Database extends GeneratedDatabase {
  _$Database(QueryExecutor e) : super(SqlTypeSystem.defaultInstance, e);
  $SomeIntsTable _someInts;
  $SomeIntsTable get someInts => _someInts ??= $SomeIntsTable(this);
  @override
  Iterable<TableInfo> get allTables => allSchemaEntities.whereType<TableInfo>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [someInts];
}
