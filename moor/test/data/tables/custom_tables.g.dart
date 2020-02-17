// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_tables.dart';

// **************************************************************************
// MoorGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps, unnecessary_this
class Config extends DataClass implements Insertable<Config> {
  final String configKey;
  final String configValue;
  final SyncType syncState;
  Config({@required this.configKey, this.configValue, this.syncState});
  factory Config.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    final intType = db.typeSystem.forDartType<int>();
    return Config(
      configKey: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}config_key']),
      configValue: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}config_value']),
      syncState: ConfigTable.$converter0.mapToDart(intType
          .mapFromDatabaseResponse(data['${effectivePrefix}sync_state'])),
    );
  }
  factory Config.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return Config(
      configKey: serializer.fromJson<String>(json['config_key']),
      configValue: serializer.fromJson<String>(json['config_value']),
      syncState: serializer.fromJson<SyncType>(json['sync_state']),
    );
  }
  factory Config.fromJsonString(String encodedJson,
          {ValueSerializer serializer}) =>
      Config.fromJson(DataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'config_key': serializer.toJson<String>(configKey),
      'config_value': serializer.toJson<String>(configValue),
      'sync_state': serializer.toJson<SyncType>(syncState),
    };
  }

  @override
  ConfigCompanion createCompanion(bool nullToAbsent) {
    return ConfigCompanion(
      configKey: configKey == null && nullToAbsent
          ? const Value.absent()
          : Value(configKey),
      configValue: configValue == null && nullToAbsent
          ? const Value.absent()
          : Value(configValue),
      syncState: syncState == null && nullToAbsent
          ? const Value.absent()
          : Value(syncState),
    );
  }

  Config copyWith({String configKey, String configValue, SyncType syncState}) =>
      Config(
        configKey: configKey ?? this.configKey,
        configValue: configValue ?? this.configValue,
        syncState: syncState ?? this.syncState,
      );
  @override
  String toString() {
    return (StringBuffer('Config(')
          ..write('configKey: $configKey, ')
          ..write('configValue: $configValue, ')
          ..write('syncState: $syncState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(
      configKey.hashCode, $mrjc(configValue.hashCode, syncState.hashCode)));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is Config &&
          other.configKey == this.configKey &&
          other.configValue == this.configValue &&
          other.syncState == this.syncState);
}

class ConfigCompanion extends UpdateCompanion<Config> {
  final Value<String> configKey;
  final Value<String> configValue;
  final Value<SyncType> syncState;
  const ConfigCompanion({
    this.configKey = const Value.absent(),
    this.configValue = const Value.absent(),
    this.syncState = const Value.absent(),
  });
  ConfigCompanion.insert({
    @required String configKey,
    this.configValue = const Value.absent(),
    this.syncState = const Value.absent(),
  }) : configKey = Value(configKey);
  ConfigCompanion copyWith(
      {Value<String> configKey,
      Value<String> configValue,
      Value<SyncType> syncState}) {
    return ConfigCompanion(
      configKey: configKey ?? this.configKey,
      configValue: configValue ?? this.configValue,
      syncState: syncState ?? this.syncState,
    );
  }
}

class ConfigTable extends Table with TableInfo<ConfigTable, Config> {
  final GeneratedDatabase _db;
  final String _alias;
  ConfigTable(this._db, [this._alias]);
  final VerificationMeta _configKeyMeta = const VerificationMeta('configKey');
  GeneratedTextColumn _configKey;
  GeneratedTextColumn get configKey => _configKey ??= _constructConfigKey();
  GeneratedTextColumn _constructConfigKey() {
    return GeneratedTextColumn('config_key', $tableName, false,
        $customConstraints: 'not null primary key');
  }

  final VerificationMeta _configValueMeta =
      const VerificationMeta('configValue');
  GeneratedTextColumn _configValue;
  GeneratedTextColumn get configValue =>
      _configValue ??= _constructConfigValue();
  GeneratedTextColumn _constructConfigValue() {
    return GeneratedTextColumn('config_value', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _syncStateMeta = const VerificationMeta('syncState');
  GeneratedIntColumn _syncState;
  GeneratedIntColumn get syncState => _syncState ??= _constructSyncState();
  GeneratedIntColumn _constructSyncState() {
    return GeneratedIntColumn('sync_state', $tableName, true,
        $customConstraints: '');
  }

  @override
  List<GeneratedColumn> get $columns => [configKey, configValue, syncState];
  @override
  ConfigTable get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'config';
  @override
  final String actualTableName = 'config';
  @override
  VerificationContext validateIntegrity(ConfigCompanion d,
      {bool isInserting = false}) {
    final context = VerificationContext();
    if (d.configKey.present) {
      context.handle(_configKeyMeta,
          configKey.isAcceptableValue(d.configKey.value, _configKeyMeta));
    } else if (isInserting) {
      context.missing(_configKeyMeta);
    }
    if (d.configValue.present) {
      context.handle(_configValueMeta,
          configValue.isAcceptableValue(d.configValue.value, _configValueMeta));
    }
    context.handle(_syncStateMeta, const VerificationResult.success());
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {configKey};
  @override
  Config map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return Config.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Map<String, Variable> entityToSql(ConfigCompanion d) {
    final map = <String, Variable>{};
    if (d.configKey.present) {
      map['config_key'] = Variable<String>(d.configKey.value);
    }
    if (d.configValue.present) {
      map['config_value'] = Variable<String>(d.configValue.value);
    }
    if (d.syncState.present) {
      final converter = ConfigTable.$converter0;
      map['sync_state'] = Variable<int>(converter.mapToSql(d.syncState.value));
    }
    return map;
  }

  @override
  ConfigTable createAlias(String alias) {
    return ConfigTable(_db, alias);
  }

  static TypeConverter<SyncType, int> $converter0 = const SyncTypeConverter();
  @override
  bool get dontWriteConstraints => true;
}

class WithDefault extends DataClass implements Insertable<WithDefault> {
  final String a;
  final int b;
  WithDefault({this.a, this.b});
  factory WithDefault.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    final intType = db.typeSystem.forDartType<int>();
    return WithDefault(
      a: stringType.mapFromDatabaseResponse(data['${effectivePrefix}a']),
      b: intType.mapFromDatabaseResponse(data['${effectivePrefix}b']),
    );
  }
  factory WithDefault.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return WithDefault(
      a: serializer.fromJson<String>(json['a']),
      b: serializer.fromJson<int>(json['b']),
    );
  }
  factory WithDefault.fromJsonString(String encodedJson,
          {ValueSerializer serializer}) =>
      WithDefault.fromJson(
          DataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'a': serializer.toJson<String>(a),
      'b': serializer.toJson<int>(b),
    };
  }

  @override
  WithDefaultsCompanion createCompanion(bool nullToAbsent) {
    return WithDefaultsCompanion(
      a: a == null && nullToAbsent ? const Value.absent() : Value(a),
      b: b == null && nullToAbsent ? const Value.absent() : Value(b),
    );
  }

  WithDefault copyWith({String a, int b}) => WithDefault(
        a: a ?? this.a,
        b: b ?? this.b,
      );
  @override
  String toString() {
    return (StringBuffer('WithDefault(')
          ..write('a: $a, ')
          ..write('b: $b')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(a.hashCode, b.hashCode));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is WithDefault && other.a == this.a && other.b == this.b);
}

class WithDefaultsCompanion extends UpdateCompanion<WithDefault> {
  final Value<String> a;
  final Value<int> b;
  const WithDefaultsCompanion({
    this.a = const Value.absent(),
    this.b = const Value.absent(),
  });
  WithDefaultsCompanion.insert({
    this.a = const Value.absent(),
    this.b = const Value.absent(),
  });
  WithDefaultsCompanion copyWith({Value<String> a, Value<int> b}) {
    return WithDefaultsCompanion(
      a: a ?? this.a,
      b: b ?? this.b,
    );
  }
}

class WithDefaults extends Table with TableInfo<WithDefaults, WithDefault> {
  final GeneratedDatabase _db;
  final String _alias;
  WithDefaults(this._db, [this._alias]);
  final VerificationMeta _aMeta = const VerificationMeta('a');
  GeneratedTextColumn _a;
  GeneratedTextColumn get a => _a ??= _constructA();
  GeneratedTextColumn _constructA() {
    return GeneratedTextColumn('a', $tableName, true,
        $customConstraints: 'DEFAULT \'something\'',
        defaultValue: const CustomExpression<String>('\'something\''));
  }

  final VerificationMeta _bMeta = const VerificationMeta('b');
  GeneratedIntColumn _b;
  GeneratedIntColumn get b => _b ??= _constructB();
  GeneratedIntColumn _constructB() {
    return GeneratedIntColumn('b', $tableName, true,
        $customConstraints: 'UNIQUE');
  }

  @override
  List<GeneratedColumn> get $columns => [a, b];
  @override
  WithDefaults get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'with_defaults';
  @override
  final String actualTableName = 'with_defaults';
  @override
  VerificationContext validateIntegrity(WithDefaultsCompanion d,
      {bool isInserting = false}) {
    final context = VerificationContext();
    if (d.a.present) {
      context.handle(_aMeta, a.isAcceptableValue(d.a.value, _aMeta));
    }
    if (d.b.present) {
      context.handle(_bMeta, b.isAcceptableValue(d.b.value, _bMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => <GeneratedColumn>{};
  @override
  WithDefault map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return WithDefault.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Map<String, Variable> entityToSql(WithDefaultsCompanion d) {
    final map = <String, Variable>{};
    if (d.a.present) {
      map['a'] = Variable<String>(d.a.value);
    }
    if (d.b.present) {
      map['b'] = Variable<int>(d.b.value);
    }
    return map;
  }

  @override
  WithDefaults createAlias(String alias) {
    return WithDefaults(_db, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class NoId extends DataClass implements Insertable<NoId> {
  final Uint8List payload;
  NoId({@required this.payload});
  factory NoId.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final uint8ListType = db.typeSystem.forDartType<Uint8List>();
    return NoId(
      payload: uint8ListType
          .mapFromDatabaseResponse(data['${effectivePrefix}payload']),
    );
  }
  factory NoId.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return NoId(
      payload: serializer.fromJson<Uint8List>(json['payload']),
    );
  }
  factory NoId.fromJsonString(String encodedJson,
          {ValueSerializer serializer}) =>
      NoId.fromJson(DataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'payload': serializer.toJson<Uint8List>(payload),
    };
  }

  @override
  NoIdsCompanion createCompanion(bool nullToAbsent) {
    return NoIdsCompanion(
      payload: payload == null && nullToAbsent
          ? const Value.absent()
          : Value(payload),
    );
  }

  NoId copyWith({Uint8List payload}) => NoId(
        payload: payload ?? this.payload,
      );
  @override
  String toString() {
    return (StringBuffer('NoId(')..write('payload: $payload')..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf(payload.hashCode);
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is NoId && other.payload == this.payload);
}

class NoIdsCompanion extends UpdateCompanion<NoId> {
  final Value<Uint8List> payload;
  const NoIdsCompanion({
    this.payload = const Value.absent(),
  });
  NoIdsCompanion.insert({
    @required Uint8List payload,
  }) : payload = Value(payload);
  NoIdsCompanion copyWith({Value<Uint8List> payload}) {
    return NoIdsCompanion(
      payload: payload ?? this.payload,
    );
  }
}

class NoIds extends Table with TableInfo<NoIds, NoId> {
  final GeneratedDatabase _db;
  final String _alias;
  NoIds(this._db, [this._alias]);
  final VerificationMeta _payloadMeta = const VerificationMeta('payload');
  GeneratedBlobColumn _payload;
  GeneratedBlobColumn get payload => _payload ??= _constructPayload();
  GeneratedBlobColumn _constructPayload() {
    return GeneratedBlobColumn('payload', $tableName, false,
        $customConstraints: 'NOT NULL PRIMARY KEY');
  }

  @override
  List<GeneratedColumn> get $columns => [payload];
  @override
  NoIds get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'no_ids';
  @override
  final String actualTableName = 'no_ids';
  @override
  VerificationContext validateIntegrity(NoIdsCompanion d,
      {bool isInserting = false}) {
    final context = VerificationContext();
    if (d.payload.present) {
      context.handle(_payloadMeta,
          payload.isAcceptableValue(d.payload.value, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {payload};
  @override
  NoId map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return NoId.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Map<String, Variable> entityToSql(NoIdsCompanion d) {
    final map = <String, Variable>{};
    if (d.payload.present) {
      map['payload'] = Variable<Uint8List>(d.payload.value);
    }
    return map;
  }

  @override
  NoIds createAlias(String alias) {
    return NoIds(_db, alias);
  }

  @override
  bool get withoutRowId => true;
  @override
  bool get dontWriteConstraints => true;
}

class WithConstraint extends DataClass implements Insertable<WithConstraint> {
  final String a;
  final int b;
  final double c;
  WithConstraint({this.a, @required this.b, this.c});
  factory WithConstraint.fromData(
      Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    final intType = db.typeSystem.forDartType<int>();
    final doubleType = db.typeSystem.forDartType<double>();
    return WithConstraint(
      a: stringType.mapFromDatabaseResponse(data['${effectivePrefix}a']),
      b: intType.mapFromDatabaseResponse(data['${effectivePrefix}b']),
      c: doubleType.mapFromDatabaseResponse(data['${effectivePrefix}c']),
    );
  }
  factory WithConstraint.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return WithConstraint(
      a: serializer.fromJson<String>(json['a']),
      b: serializer.fromJson<int>(json['b']),
      c: serializer.fromJson<double>(json['c']),
    );
  }
  factory WithConstraint.fromJsonString(String encodedJson,
          {ValueSerializer serializer}) =>
      WithConstraint.fromJson(
          DataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'a': serializer.toJson<String>(a),
      'b': serializer.toJson<int>(b),
      'c': serializer.toJson<double>(c),
    };
  }

  @override
  WithConstraintsCompanion createCompanion(bool nullToAbsent) {
    return WithConstraintsCompanion(
      a: a == null && nullToAbsent ? const Value.absent() : Value(a),
      b: b == null && nullToAbsent ? const Value.absent() : Value(b),
      c: c == null && nullToAbsent ? const Value.absent() : Value(c),
    );
  }

  WithConstraint copyWith({String a, int b, double c}) => WithConstraint(
        a: a ?? this.a,
        b: b ?? this.b,
        c: c ?? this.c,
      );
  @override
  String toString() {
    return (StringBuffer('WithConstraint(')
          ..write('a: $a, ')
          ..write('b: $b, ')
          ..write('c: $c')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(a.hashCode, $mrjc(b.hashCode, c.hashCode)));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is WithConstraint &&
          other.a == this.a &&
          other.b == this.b &&
          other.c == this.c);
}

class WithConstraintsCompanion extends UpdateCompanion<WithConstraint> {
  final Value<String> a;
  final Value<int> b;
  final Value<double> c;
  const WithConstraintsCompanion({
    this.a = const Value.absent(),
    this.b = const Value.absent(),
    this.c = const Value.absent(),
  });
  WithConstraintsCompanion.insert({
    this.a = const Value.absent(),
    @required int b,
    this.c = const Value.absent(),
  }) : b = Value(b);
  WithConstraintsCompanion copyWith(
      {Value<String> a, Value<int> b, Value<double> c}) {
    return WithConstraintsCompanion(
      a: a ?? this.a,
      b: b ?? this.b,
      c: c ?? this.c,
    );
  }
}

class WithConstraints extends Table
    with TableInfo<WithConstraints, WithConstraint> {
  final GeneratedDatabase _db;
  final String _alias;
  WithConstraints(this._db, [this._alias]);
  final VerificationMeta _aMeta = const VerificationMeta('a');
  GeneratedTextColumn _a;
  GeneratedTextColumn get a => _a ??= _constructA();
  GeneratedTextColumn _constructA() {
    return GeneratedTextColumn('a', $tableName, true, $customConstraints: '');
  }

  final VerificationMeta _bMeta = const VerificationMeta('b');
  GeneratedIntColumn _b;
  GeneratedIntColumn get b => _b ??= _constructB();
  GeneratedIntColumn _constructB() {
    return GeneratedIntColumn('b', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  final VerificationMeta _cMeta = const VerificationMeta('c');
  GeneratedRealColumn _c;
  GeneratedRealColumn get c => _c ??= _constructC();
  GeneratedRealColumn _constructC() {
    return GeneratedRealColumn('c', $tableName, true, $customConstraints: '');
  }

  @override
  List<GeneratedColumn> get $columns => [a, b, c];
  @override
  WithConstraints get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'with_constraints';
  @override
  final String actualTableName = 'with_constraints';
  @override
  VerificationContext validateIntegrity(WithConstraintsCompanion d,
      {bool isInserting = false}) {
    final context = VerificationContext();
    if (d.a.present) {
      context.handle(_aMeta, a.isAcceptableValue(d.a.value, _aMeta));
    }
    if (d.b.present) {
      context.handle(_bMeta, b.isAcceptableValue(d.b.value, _bMeta));
    } else if (isInserting) {
      context.missing(_bMeta);
    }
    if (d.c.present) {
      context.handle(_cMeta, c.isAcceptableValue(d.c.value, _cMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => <GeneratedColumn>{};
  @override
  WithConstraint map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return WithConstraint.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Map<String, Variable> entityToSql(WithConstraintsCompanion d) {
    final map = <String, Variable>{};
    if (d.a.present) {
      map['a'] = Variable<String>(d.a.value);
    }
    if (d.b.present) {
      map['b'] = Variable<int>(d.b.value);
    }
    if (d.c.present) {
      map['c'] = Variable<double>(d.c.value);
    }
    return map;
  }

  @override
  WithConstraints createAlias(String alias) {
    return WithConstraints(_db, alias);
  }

  @override
  List<String> get customConstraints =>
      const ['FOREIGN KEY (a, b) REFERENCES with_defaults (a, b)'];
  @override
  bool get dontWriteConstraints => true;
}

class MytableData extends DataClass implements Insertable<MytableData> {
  final int someid;
  final String sometext;
  final bool somebool;
  final DateTime somedate;
  MytableData(
      {@required this.someid, this.sometext, this.somebool, this.somedate});
  factory MytableData.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final intType = db.typeSystem.forDartType<int>();
    final stringType = db.typeSystem.forDartType<String>();
    final boolType = db.typeSystem.forDartType<bool>();
    final dateTimeType = db.typeSystem.forDartType<DateTime>();
    return MytableData(
      someid: intType.mapFromDatabaseResponse(data['${effectivePrefix}someid']),
      sometext: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}sometext']),
      somebool:
          boolType.mapFromDatabaseResponse(data['${effectivePrefix}somebool']),
      somedate: dateTimeType
          .mapFromDatabaseResponse(data['${effectivePrefix}somedate']),
    );
  }
  factory MytableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return MytableData(
      someid: serializer.fromJson<int>(json['someid']),
      sometext: serializer.fromJson<String>(json['sometext']),
      somebool: serializer.fromJson<bool>(json['somebool']),
      somedate: serializer.fromJson<DateTime>(json['somedate']),
    );
  }
  factory MytableData.fromJsonString(String encodedJson,
          {ValueSerializer serializer}) =>
      MytableData.fromJson(
          DataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'someid': serializer.toJson<int>(someid),
      'sometext': serializer.toJson<String>(sometext),
      'somebool': serializer.toJson<bool>(somebool),
      'somedate': serializer.toJson<DateTime>(somedate),
    };
  }

  @override
  MytableCompanion createCompanion(bool nullToAbsent) {
    return MytableCompanion(
      someid:
          someid == null && nullToAbsent ? const Value.absent() : Value(someid),
      sometext: sometext == null && nullToAbsent
          ? const Value.absent()
          : Value(sometext),
      somebool: somebool == null && nullToAbsent
          ? const Value.absent()
          : Value(somebool),
      somedate: somedate == null && nullToAbsent
          ? const Value.absent()
          : Value(somedate),
    );
  }

  MytableData copyWith(
          {int someid, String sometext, bool somebool, DateTime somedate}) =>
      MytableData(
        someid: someid ?? this.someid,
        sometext: sometext ?? this.sometext,
        somebool: somebool ?? this.somebool,
        somedate: somedate ?? this.somedate,
      );
  @override
  String toString() {
    return (StringBuffer('MytableData(')
          ..write('someid: $someid, ')
          ..write('sometext: $sometext, ')
          ..write('somebool: $somebool, ')
          ..write('somedate: $somedate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(someid.hashCode,
      $mrjc(sometext.hashCode, $mrjc(somebool.hashCode, somedate.hashCode))));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is MytableData &&
          other.someid == this.someid &&
          other.sometext == this.sometext &&
          other.somebool == this.somebool &&
          other.somedate == this.somedate);
}

class MytableCompanion extends UpdateCompanion<MytableData> {
  final Value<int> someid;
  final Value<String> sometext;
  final Value<bool> somebool;
  final Value<DateTime> somedate;
  const MytableCompanion({
    this.someid = const Value.absent(),
    this.sometext = const Value.absent(),
    this.somebool = const Value.absent(),
    this.somedate = const Value.absent(),
  });
  MytableCompanion.insert({
    this.someid = const Value.absent(),
    this.sometext = const Value.absent(),
    this.somebool = const Value.absent(),
    this.somedate = const Value.absent(),
  });
  MytableCompanion copyWith(
      {Value<int> someid,
      Value<String> sometext,
      Value<bool> somebool,
      Value<DateTime> somedate}) {
    return MytableCompanion(
      someid: someid ?? this.someid,
      sometext: sometext ?? this.sometext,
      somebool: somebool ?? this.somebool,
      somedate: somedate ?? this.somedate,
    );
  }
}

class Mytable extends Table with TableInfo<Mytable, MytableData> {
  final GeneratedDatabase _db;
  final String _alias;
  Mytable(this._db, [this._alias]);
  final VerificationMeta _someidMeta = const VerificationMeta('someid');
  GeneratedIntColumn _someid;
  GeneratedIntColumn get someid => _someid ??= _constructSomeid();
  GeneratedIntColumn _constructSomeid() {
    return GeneratedIntColumn('someid', $tableName, false,
        declaredAsPrimaryKey: true, $customConstraints: 'NOT NULL PRIMARY KEY');
  }

  final VerificationMeta _sometextMeta = const VerificationMeta('sometext');
  GeneratedTextColumn _sometext;
  GeneratedTextColumn get sometext => _sometext ??= _constructSometext();
  GeneratedTextColumn _constructSometext() {
    return GeneratedTextColumn('sometext', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _someboolMeta = const VerificationMeta('somebool');
  GeneratedBoolColumn _somebool;
  GeneratedBoolColumn get somebool => _somebool ??= _constructSomebool();
  GeneratedBoolColumn _constructSomebool() {
    return GeneratedBoolColumn('somebool', $tableName, true,
        $customConstraints: '');
  }

  final VerificationMeta _somedateMeta = const VerificationMeta('somedate');
  GeneratedDateTimeColumn _somedate;
  GeneratedDateTimeColumn get somedate => _somedate ??= _constructSomedate();
  GeneratedDateTimeColumn _constructSomedate() {
    return GeneratedDateTimeColumn('somedate', $tableName, true,
        $customConstraints: '');
  }

  @override
  List<GeneratedColumn> get $columns => [someid, sometext, somebool, somedate];
  @override
  Mytable get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'mytable';
  @override
  final String actualTableName = 'mytable';
  @override
  VerificationContext validateIntegrity(MytableCompanion d,
      {bool isInserting = false}) {
    final context = VerificationContext();
    if (d.someid.present) {
      context.handle(
          _someidMeta, someid.isAcceptableValue(d.someid.value, _someidMeta));
    }
    if (d.sometext.present) {
      context.handle(_sometextMeta,
          sometext.isAcceptableValue(d.sometext.value, _sometextMeta));
    }
    if (d.somebool.present) {
      context.handle(_someboolMeta,
          somebool.isAcceptableValue(d.somebool.value, _someboolMeta));
    }
    if (d.somedate.present) {
      context.handle(_somedateMeta,
          somedate.isAcceptableValue(d.somedate.value, _somedateMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {someid};
  @override
  MytableData map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return MytableData.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Map<String, Variable> entityToSql(MytableCompanion d) {
    final map = <String, Variable>{};
    if (d.someid.present) {
      map['someid'] = Variable<int>(d.someid.value);
    }
    if (d.sometext.present) {
      map['sometext'] = Variable<String>(d.sometext.value);
    }
    if (d.somebool.present) {
      map['somebool'] = Variable<bool>(d.somebool.value);
    }
    if (d.somedate.present) {
      map['somedate'] = Variable<DateTime>(d.somedate.value);
    }
    return map;
  }

  @override
  Mytable createAlias(String alias) {
    return Mytable(_db, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class EMail extends DataClass implements Insertable<EMail> {
  final String sender;
  final String title;
  final String body;
  EMail({@required this.sender, @required this.title, @required this.body});
  factory EMail.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    return EMail(
      sender:
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}sender']),
      title:
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}title']),
      body: stringType.mapFromDatabaseResponse(data['${effectivePrefix}body']),
    );
  }
  factory EMail.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return EMail(
      sender: serializer.fromJson<String>(json['sender']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
    );
  }
  factory EMail.fromJsonString(String encodedJson,
          {ValueSerializer serializer}) =>
      EMail.fromJson(DataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sender': serializer.toJson<String>(sender),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
    };
  }

  @override
  EmailCompanion createCompanion(bool nullToAbsent) {
    return EmailCompanion(
      sender:
          sender == null && nullToAbsent ? const Value.absent() : Value(sender),
      title:
          title == null && nullToAbsent ? const Value.absent() : Value(title),
      body: body == null && nullToAbsent ? const Value.absent() : Value(body),
    );
  }

  EMail copyWith({String sender, String title, String body}) => EMail(
        sender: sender ?? this.sender,
        title: title ?? this.title,
        body: body ?? this.body,
      );
  @override
  String toString() {
    return (StringBuffer('EMail(')
          ..write('sender: $sender, ')
          ..write('title: $title, ')
          ..write('body: $body')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      $mrjf($mrjc(sender.hashCode, $mrjc(title.hashCode, body.hashCode)));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is EMail &&
          other.sender == this.sender &&
          other.title == this.title &&
          other.body == this.body);
}

class EmailCompanion extends UpdateCompanion<EMail> {
  final Value<String> sender;
  final Value<String> title;
  final Value<String> body;
  const EmailCompanion({
    this.sender = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
  });
  EmailCompanion.insert({
    @required String sender,
    @required String title,
    @required String body,
  })  : sender = Value(sender),
        title = Value(title),
        body = Value(body);
  EmailCompanion copyWith(
      {Value<String> sender, Value<String> title, Value<String> body}) {
    return EmailCompanion(
      sender: sender ?? this.sender,
      title: title ?? this.title,
      body: body ?? this.body,
    );
  }
}

class Email extends Table
    with TableInfo<Email, EMail>, VirtualTableInfo<Email, EMail> {
  final GeneratedDatabase _db;
  final String _alias;
  Email(this._db, [this._alias]);
  final VerificationMeta _senderMeta = const VerificationMeta('sender');
  GeneratedTextColumn _sender;
  GeneratedTextColumn get sender => _sender ??= _constructSender();
  GeneratedTextColumn _constructSender() {
    return GeneratedTextColumn('sender', $tableName, false,
        $customConstraints: '');
  }

  final VerificationMeta _titleMeta = const VerificationMeta('title');
  GeneratedTextColumn _title;
  GeneratedTextColumn get title => _title ??= _constructTitle();
  GeneratedTextColumn _constructTitle() {
    return GeneratedTextColumn('title', $tableName, false,
        $customConstraints: '');
  }

  final VerificationMeta _bodyMeta = const VerificationMeta('body');
  GeneratedTextColumn _body;
  GeneratedTextColumn get body => _body ??= _constructBody();
  GeneratedTextColumn _constructBody() {
    return GeneratedTextColumn('body', $tableName, false,
        $customConstraints: '');
  }

  @override
  List<GeneratedColumn> get $columns => [sender, title, body];
  @override
  Email get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'email';
  @override
  final String actualTableName = 'email';
  @override
  VerificationContext validateIntegrity(EmailCompanion d,
      {bool isInserting = false}) {
    final context = VerificationContext();
    if (d.sender.present) {
      context.handle(
          _senderMeta, sender.isAcceptableValue(d.sender.value, _senderMeta));
    } else if (isInserting) {
      context.missing(_senderMeta);
    }
    if (d.title.present) {
      context.handle(
          _titleMeta, title.isAcceptableValue(d.title.value, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (d.body.present) {
      context.handle(
          _bodyMeta, body.isAcceptableValue(d.body.value, _bodyMeta));
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => <GeneratedColumn>{};
  @override
  EMail map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return EMail.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Map<String, Variable> entityToSql(EmailCompanion d) {
    final map = <String, Variable>{};
    if (d.sender.present) {
      map['sender'] = Variable<String>(d.sender.value);
    }
    if (d.title.present) {
      map['title'] = Variable<String>(d.title.value);
    }
    if (d.body.present) {
      map['body'] = Variable<String>(d.body.value);
    }
    return map;
  }

  @override
  Email createAlias(String alias) {
    return Email(_db, alias);
  }

  @override
  bool get dontWriteConstraints => true;
  @override
  String get moduleAndArgs => 'fts5(sender, title, body)';
}

abstract class _$CustomTablesDb extends GeneratedDatabase {
  _$CustomTablesDb(QueryExecutor e) : super(SqlTypeSystem.defaultInstance, e);
  _$CustomTablesDb.connect(DatabaseConnection c) : super.connect(c);
  ConfigTable _config;
  ConfigTable get config => _config ??= ConfigTable(this);
  Index _valueIdx;
  Index get valueIdx => _valueIdx ??= Index('value_idx',
      'CREATE INDEX IF NOT EXISTS value_idx ON config (config_value);');
  WithDefaults _withDefaults;
  WithDefaults get withDefaults => _withDefaults ??= WithDefaults(this);
  Trigger _myTrigger;
  Trigger get myTrigger => _myTrigger ??= Trigger(
      'CREATE TRIGGER my_trigger AFTER INSERT ON config BEGIN\n  INSERT INTO with_defaults VALUES (new.config_key, LENGTH(new.config_value));\nEND;',
      'my_trigger');
  NoIds _noIds;
  NoIds get noIds => _noIds ??= NoIds(this);
  WithConstraints _withConstraints;
  WithConstraints get withConstraints =>
      _withConstraints ??= WithConstraints(this);
  Mytable _mytable;
  Mytable get mytable => _mytable ??= Mytable(this);
  Email _email;
  Email get email => _email ??= Email(this);
  Config _rowToConfig(QueryRow row) {
    return Config(
      configKey: row.readString('config_key'),
      configValue: row.readString('config_value'),
      syncState: ConfigTable.$converter0.mapToDart(row.readInt('sync_state')),
    );
  }

  Selectable<Config> readConfig(String var1) {
    return customSelect('SELECT * FROM config WHERE config_key = ?',
        variables: [Variable.withString(var1)],
        readsFrom: {config}).map(_rowToConfig);
  }

  Selectable<Config> readMultiple(List<String> var1, OrderBy clause) {
    var $arrayStartIndex = 1;
    final expandedvar1 = $expandVar($arrayStartIndex, var1.length);
    $arrayStartIndex += var1.length;
    final generatedclause = $write(clause);
    $arrayStartIndex += generatedclause.amountOfVariables;
    return customSelect(
        'SELECT * FROM config WHERE config_key IN ($expandedvar1) ORDER BY ${generatedclause.sql}',
        variables: [
          for (var $ in var1) Variable.withString($),
          ...generatedclause.introducedVariables
        ],
        readsFrom: {
          config
        }).map(_rowToConfig);
  }

  Selectable<Config> readDynamic(Expression<bool> predicate) {
    final generatedpredicate = $write(predicate);
    return customSelect('SELECT * FROM config WHERE ${generatedpredicate.sql}',
        variables: [...generatedpredicate.introducedVariables],
        readsFrom: {config}).map(_rowToConfig);
  }

  TableValuedResult _rowToTableValuedResult(QueryRow row) {
    return TableValuedResult(
      key: row.readString('key'),
      value: row.readString('value'),
    );
  }

  Selectable<TableValuedResult> tableValued() {
    return customSelect(
        'SELECT "key", "value"\n  FROM config, json_each(config.config_value)\n  WHERE json_valid(config_value)',
        variables: [],
        readsFrom: {config}).map(_rowToTableValuedResult);
  }

  MultipleResult _rowToMultipleResult(QueryRow row) {
    return MultipleResult(
      a: row.readString('a'),
      b: row.readInt('b'),
      c: row.readDouble('c'),
      a1: row.readString('a'),
      b1: row.readInt('b'),
    );
  }

  Selectable<MultipleResult> multiple(Expression<bool> predicate) {
    final generatedpredicate = $write(predicate, hasMultipleTables: true);
    return customSelect(
        'SELECT * FROM with_constraints c\n INNER JOIN with_defaults d\n   ON d.a = c.a AND d.b = c.b\n WHERE ${generatedpredicate.sql}',
        variables: [...generatedpredicate.introducedVariables],
        readsFrom: {withConstraints, withDefaults}).map(_rowToMultipleResult);
  }

  EMail _rowToEMail(QueryRow row) {
    return EMail(
      sender: row.readString('sender'),
      title: row.readString('title'),
      body: row.readString('body'),
    );
  }

  Selectable<EMail> searchEmails(String term) {
    return customSelect(
        'SELECT * FROM email WHERE email MATCH :term ORDER BY rank',
        variables: [Variable.withString(term)],
        readsFrom: {email}).map(_rowToEMail);
  }

  ReadRowIdResult _rowToReadRowIdResult(QueryRow row) {
    return ReadRowIdResult(
      rowid: row.readInt('rowid'),
      configKey: row.readString('config_key'),
      configValue: row.readString('config_value'),
      syncState: ConfigTable.$converter0.mapToDart(row.readInt('sync_state')),
    );
  }

  Selectable<ReadRowIdResult> readRowId(Expression<int> expr) {
    final generatedexpr = $write(expr);
    return customSelect(
        'SELECT oid, * FROM config WHERE _rowid_ = ${generatedexpr.sql}',
        variables: [...generatedexpr.introducedVariables],
        readsFrom: {config}).map(_rowToReadRowIdResult);
  }

  Selectable<int> cfeTest() {
    return customSelect(
        'WITH RECURSIVE\n  cnt(x) AS (\n    SELECT 1\n      UNION ALL\n      SELECT x+1 FROM cnt\n      LIMIT 1000000\n    )\n  SELECT x FROM cnt',
        variables: [],
        readsFrom: {}).map((QueryRow row) => row.readInt('x'));
  }

  Future<int> writeConfig(String key, String value) {
    return customInsert(
      'REPLACE INTO config (config_key, config_value) VALUES (:key, :value)',
      variables: [Variable.withString(key), Variable.withString(value)],
      updates: {config},
    );
  }

  @override
  Iterable<TableInfo> get allTables => allSchemaEntities.whereType<TableInfo>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        config,
        valueIdx,
        withDefaults,
        myTrigger,
        OnCreateQuery(
            'INSERT INTO config (config_key, config_value) VALUES (\'key\', \'values\')'),
        noIds,
        withConstraints,
        mytable,
        email
      ];
}

class TableValuedResult {
  final String key;
  final String value;
  TableValuedResult({
    this.key,
    this.value,
  });
  @override
  int get hashCode => $mrjf($mrjc(key.hashCode, value.hashCode));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is TableValuedResult &&
          other.key == this.key &&
          other.value == this.value);
}

class MultipleResult {
  final String a;
  final int b;
  final double c;
  final String a1;
  final int b1;
  MultipleResult({
    this.a,
    this.b,
    this.c,
    this.a1,
    this.b1,
  });
  @override
  int get hashCode => $mrjf($mrjc(a.hashCode,
      $mrjc(b.hashCode, $mrjc(c.hashCode, $mrjc(a1.hashCode, b1.hashCode)))));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is MultipleResult &&
          other.a == this.a &&
          other.b == this.b &&
          other.c == this.c &&
          other.a1 == this.a1 &&
          other.b1 == this.b1);
}

class ReadRowIdResult {
  final int rowid;
  final String configKey;
  final String configValue;
  final SyncType syncState;
  ReadRowIdResult({
    this.rowid,
    this.configKey,
    this.configValue,
    this.syncState,
  });
  @override
  int get hashCode => $mrjf($mrjc(
      rowid.hashCode,
      $mrjc(configKey.hashCode,
          $mrjc(configValue.hashCode, syncState.hashCode))));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is ReadRowIdResult &&
          other.rowid == this.rowid &&
          other.configKey == this.configKey &&
          other.configValue == this.configValue &&
          other.syncState == this.syncState);
}
