// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// **************************************************************************
// MoorGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps, unnecessary_this
class KeyValue extends DataClass implements Insertable<KeyValue> {
  final String key;
  final String value;
  KeyValue({@required this.key, @required this.value});
  factory KeyValue.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    return KeyValue(
      key: stringType.mapFromDatabaseResponse(data['${effectivePrefix}key']),
      value:
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}value']),
    );
  }
  factory KeyValue.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return KeyValue(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  @override
  KeyValuesCompanion createCompanion(bool nullToAbsent) {
    return KeyValuesCompanion(
      key: key == null && nullToAbsent ? const Value.absent() : Value(key),
      value:
          value == null && nullToAbsent ? const Value.absent() : Value(value),
    );
  }

  KeyValue copyWith({String key, String value}) => KeyValue(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  @override
  String toString() {
    return (StringBuffer('KeyValue(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(key.hashCode, value.hashCode));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is KeyValue && other.key == this.key && other.value == this.value);
}

class KeyValuesCompanion extends UpdateCompanion<KeyValue> {
  final Value<String> key;
  final Value<String> value;
  const KeyValuesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
  });
  KeyValuesCompanion.insert({
    @required String key,
    @required String value,
  })  : key = Value(key),
        value = Value(value);
  KeyValuesCompanion copyWith({Value<String> key, Value<String> value}) {
    return KeyValuesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
    );
  }
}

class $KeyValuesTable extends KeyValues
    with TableInfo<$KeyValuesTable, KeyValue> {
  final GeneratedDatabase _db;
  final String _alias;
  $KeyValuesTable(this._db, [this._alias]);
  final VerificationMeta _keyMeta = const VerificationMeta('key');
  GeneratedTextColumn _key;
  @override
  GeneratedTextColumn get key => _key ??= _constructKey();
  GeneratedTextColumn _constructKey() {
    return GeneratedTextColumn(
      'key',
      $tableName,
      false,
    );
  }

  final VerificationMeta _valueMeta = const VerificationMeta('value');
  GeneratedTextColumn _value;
  @override
  GeneratedTextColumn get value => _value ??= _constructValue();
  GeneratedTextColumn _constructValue() {
    return GeneratedTextColumn(
      'value',
      $tableName,
      false,
    );
  }

  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  $KeyValuesTable get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'key_values';
  @override
  final String actualTableName = 'key_values';
  @override
  VerificationContext validateIntegrity(KeyValuesCompanion d,
      {bool isInserting = false}) {
    final context = VerificationContext();
    if (d.key.present) {
      context.handle(_keyMeta, key.isAcceptableValue(d.key.value, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (d.value.present) {
      context.handle(
          _valueMeta, value.isAcceptableValue(d.value.value, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  KeyValue map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return KeyValue.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Map<String, Variable> entityToSql(KeyValuesCompanion d) {
    final map = <String, Variable>{};
    if (d.key.present) {
      map['key'] = Variable<String>(d.key.value);
    }
    if (d.value.present) {
      map['value'] = Variable<String>(d.value.value);
    }
    return map;
  }

  @override
  $KeyValuesTable createAlias(String alias) {
    return $KeyValuesTable(_db, alias);
  }
}

abstract class _$Database extends GeneratedDatabase {
  _$Database(QueryExecutor e) : super(SqlTypeSystem.defaultInstance, e);
  $KeyValuesTable _keyValues;
  $KeyValuesTable get keyValues => _keyValues ??= $KeyValuesTable(this);
  @override
  Iterable<TableInfo> get allTables => allSchemaEntities.whereType<TableInfo>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [keyValues];
}
