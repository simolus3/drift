// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saves_after_migration_regression_test.dart';

// **************************************************************************
// MoorGenerator
// **************************************************************************

// ignore_for_file: type=lint
class Foo extends DataClass implements Insertable<Foo> {
  final int id;
  Foo({required this.id});
  factory Foo.fromData(Map<String, dynamic> data, {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return Foo(
      id: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}id'])!,
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    return map;
  }

  FoosCompanion toCompanion(bool nullToAbsent) {
    return FoosCompanion(
      id: Value(id),
    );
  }

  factory Foo.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Foo(
      id: serializer.fromJson<int>(json['id']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
    };
  }

  Foo copyWith({int? id}) => Foo(
        id: id ?? this.id,
      );
  @override
  String toString() {
    return (StringBuffer('Foo(')
          ..write('id: $id')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => id.hashCode;
  @override
  bool operator ==(Object other) =>
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
  static Insertable<Foo> custom({
    Expression<int>? id,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
    });
  }

  FoosCompanion copyWith({Value<int>? id}) {
    return FoosCompanion(
      id: id ?? this.id,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoosCompanion(')
          ..write('id: $id')
          ..write(')'))
        .toString();
  }
}

class $FoosTable extends Foos with TableInfo<$FoosTable, Foo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoosTable(this.attachedDatabase, [this._alias]);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int?> id = GeneratedColumn<int?>(
      'id', aliasedName, false,
      type: const IntType(),
      requiredDuringInsert: false,
      defaultConstraints: 'PRIMARY KEY AUTOINCREMENT');
  @override
  List<GeneratedColumn> get $columns => [id];
  @override
  String get aliasedName => _alias ?? 'foos';
  @override
  String get actualTableName => 'foos';
  @override
  VerificationContext validateIntegrity(Insertable<Foo> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Foo map(Map<String, dynamic> data, {String? tablePrefix}) {
    return Foo.fromData(data,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  $FoosTable createAlias(String alias) {
    return $FoosTable(attachedDatabase, alias);
  }
}

class Bar extends DataClass implements Insertable<Bar> {
  final int id;
  Bar({required this.id});
  factory Bar.fromData(Map<String, dynamic> data, {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return Bar(
      id: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}id'])!,
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    return map;
  }

  BarsCompanion toCompanion(bool nullToAbsent) {
    return BarsCompanion(
      id: Value(id),
    );
  }

  factory Bar.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Bar(
      id: serializer.fromJson<int>(json['id']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
    };
  }

  Bar copyWith({int? id}) => Bar(
        id: id ?? this.id,
      );
  @override
  String toString() {
    return (StringBuffer('Bar(')
          ..write('id: $id')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => id.hashCode;
  @override
  bool operator ==(Object other) =>
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
  static Insertable<Bar> custom({
    Expression<int>? id,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
    });
  }

  BarsCompanion copyWith({Value<int>? id}) {
    return BarsCompanion(
      id: id ?? this.id,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BarsCompanion(')
          ..write('id: $id')
          ..write(')'))
        .toString();
  }
}

class $BarsTable extends Bars with TableInfo<$BarsTable, Bar> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BarsTable(this.attachedDatabase, [this._alias]);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int?> id = GeneratedColumn<int?>(
      'id', aliasedName, false,
      type: const IntType(),
      requiredDuringInsert: false,
      defaultConstraints: 'PRIMARY KEY AUTOINCREMENT');
  @override
  List<GeneratedColumn> get $columns => [id];
  @override
  String get aliasedName => _alias ?? 'bars';
  @override
  String get actualTableName => 'bars';
  @override
  VerificationContext validateIntegrity(Insertable<Bar> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Bar map(Map<String, dynamic> data, {String? tablePrefix}) {
    return Bar.fromData(data,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  $BarsTable createAlias(String alias) {
    return $BarsTable(attachedDatabase, alias);
  }
}

abstract class _$_FakeDb extends GeneratedDatabase {
  _$_FakeDb(QueryExecutor e) : super(SqlTypeSystem.defaultInstance, e);
  late final $FoosTable foos = $FoosTable(this);
  late final $BarsTable bars = $BarsTable(this);
  @override
  Iterable<TableInfo> get allTables => allSchemaEntities.whereType<TableInfo>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [foos, bars];
}
