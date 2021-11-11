// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// **************************************************************************
// MoorGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps, unnecessary_this
class Entrie extends DataClass implements Insertable<Entrie> {
  final int id;
  final String value;
  Entrie({required this.id, required this.value});
  factory Entrie.fromData(Map<String, dynamic> data, {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return Entrie(
      id: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}id'])!,
      value: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}text'])!,
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['text'] = Variable<String>(value);
    return map;
  }

  EntriesCompanion toCompanion(bool nullToAbsent) {
    return EntriesCompanion(
      id: Value(id),
      value: Value(value),
    );
  }

  factory Entrie.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Entrie(
      id: serializer.fromJson<int>(json['id']),
      value: serializer.fromJson<String>(json['text']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'text': serializer.toJson<String>(value),
    };
  }

  Entrie copyWith({int? id, String? value}) => Entrie(
        id: id ?? this.id,
        value: value ?? this.value,
      );
  @override
  String toString() {
    return (StringBuffer('Entrie(')
          ..write('id: $id, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Entrie && other.id == this.id && other.value == this.value);
}

class EntriesCompanion extends UpdateCompanion<Entrie> {
  final Value<int> id;
  final Value<String> value;
  const EntriesCompanion({
    this.id = const Value.absent(),
    this.value = const Value.absent(),
  });
  EntriesCompanion.insert({
    this.id = const Value.absent(),
    required String value,
  }) : value = Value(value);
  static Insertable<Entrie> custom({
    Expression<int>? id,
    Expression<String>? value,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (value != null) 'text': value,
    });
  }

  EntriesCompanion copyWith({Value<int>? id, Value<String>? value}) {
    return EntriesCompanion(
      id: id ?? this.id,
      value: value ?? this.value,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (value.present) {
      map['text'] = Variable<String>(value.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntriesCompanion(')
          ..write('id: $id, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }
}

class Entries extends Table with TableInfo<Entries, Entrie> {
  final GeneratedDatabase _db;
  final String? _alias;
  Entries(this._db, [this._alias]);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int?> id = GeneratedColumn<int?>(
      'id', aliasedName, false,
      type: const IntType(),
      requiredDuringInsert: false,
      $customConstraints: 'PRIMARY KEY');
  final VerificationMeta _valueMeta = const VerificationMeta('value');
  late final GeneratedColumn<String?> value = GeneratedColumn<String?>(
      'text', aliasedName, false,
      type: const StringType(),
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  @override
  List<GeneratedColumn> get $columns => [id, value];
  @override
  String get aliasedName => _alias ?? 'entries';
  @override
  String get actualTableName => 'entries';
  @override
  VerificationContext validateIntegrity(Insertable<Entrie> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('text')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['text']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Entrie map(Map<String, dynamic> data, {String? tablePrefix}) {
    return Entrie.fromData(data,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  Entries createAlias(String alias) {
    return Entries(_db, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

abstract class _$MyDatabase extends GeneratedDatabase {
  _$MyDatabase(QueryExecutor e) : super(SqlTypeSystem.defaultInstance, e);
  late final Entries entries = Entries(this);
  Selectable<Entrie> allEntries() {
    return customSelect('SELECT * FROM entries', variables: [], readsFrom: {
      entries,
    }).map(entries.mapFromRow);
  }

  Future<int> addEntry(String var1) {
    return customInsert(
      'INSERT INTO entries (text) VALUES (?1)',
      variables: [Variable<String>(var1)],
      updates: {entries},
    );
  }

  Future<int> clearEntries() {
    return customUpdate(
      'DELETE FROM entries',
      variables: [],
      updates: {entries},
      updateKind: UpdateKind.delete,
    );
  }

  @override
  Iterable<TableInfo> get allTables => allSchemaEntities.whereType<TableInfo>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [entries];
}
