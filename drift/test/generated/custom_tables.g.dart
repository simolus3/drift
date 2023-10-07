// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_tables.dart';

// ignore_for_file: type=lint
class NoIds extends Table with TableInfo<NoIds, NoIdRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  NoIds(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  late final GeneratedColumn<Uint8List> payload = GeneratedColumn<Uint8List>(
      'payload', aliasedName, false,
      type: DriftSqlType.blob,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL PRIMARY KEY');
  @override
  List<GeneratedColumn> get $columns => [payload];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'no_ids';
  @override
  VerificationContext validateIntegrity(Insertable<NoIdRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {payload};
  @override
  NoIdRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoIdRow(
      attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}payload'])!,
    );
  }

  @override
  NoIds createAlias(String alias) {
    return NoIds(attachedDatabase, alias);
  }

  @override
  bool get withoutRowId => true;
  @override
  bool get dontWriteConstraints => true;
}

class NoIdsCompanion extends UpdateCompanion<NoIdRow> {
  final Value<Uint8List> payload;
  const NoIdsCompanion({
    this.payload = const Value.absent(),
  });
  NoIdsCompanion.insert({
    required Uint8List payload,
  }) : payload = Value(payload);
  static Insertable<NoIdRow> custom({
    Expression<Uint8List>? payload,
  }) {
    return RawValuesInsertable({
      if (payload != null) 'payload': payload,
    });
  }

  NoIdsCompanion copyWith({Value<Uint8List>? payload}) {
    return NoIdsCompanion(
      payload: payload ?? this.payload,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (payload.present) {
      map['payload'] = Variable<Uint8List>(payload.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NoIdsCompanion(')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }
}

class WithDefaults extends Table with TableInfo<WithDefaults, WithDefault> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  WithDefaults(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _aMeta = const VerificationMeta('a');
  late final GeneratedColumn<String> a = GeneratedColumn<String>(
      'a', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: 'DEFAULT \'something\'',
      defaultValue: const CustomExpression('\'something\''));
  static const VerificationMeta _bMeta = const VerificationMeta('b');
  late final GeneratedColumn<int> b = GeneratedColumn<int>(
      'b', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'UNIQUE');
  @override
  List<GeneratedColumn> get $columns => [a, b];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'with_defaults';
  @override
  VerificationContext validateIntegrity(Insertable<WithDefault> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('a')) {
      context.handle(_aMeta, a.isAcceptableOrUnknown(data['a']!, _aMeta));
    }
    if (data.containsKey('b')) {
      context.handle(_bMeta, b.isAcceptableOrUnknown(data['b']!, _bMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  WithDefault map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WithDefault(
      a: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}a']),
      b: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}b']),
    );
  }

  @override
  WithDefaults createAlias(String alias) {
    return WithDefaults(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class WithDefault extends DataClass implements Insertable<WithDefault> {
  final String? a;
  final int? b;
  const WithDefault({this.a, this.b});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || a != null) {
      map['a'] = Variable<String>(a);
    }
    if (!nullToAbsent || b != null) {
      map['b'] = Variable<int>(b);
    }
    return map;
  }

  WithDefaultsCompanion toCompanion(bool nullToAbsent) {
    return WithDefaultsCompanion(
      a: a == null && nullToAbsent ? const Value.absent() : Value(a),
      b: b == null && nullToAbsent ? const Value.absent() : Value(b),
    );
  }

  factory WithDefault.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WithDefault(
      a: serializer.fromJson<String?>(json['customJsonName']),
      b: serializer.fromJson<int?>(json['b']),
    );
  }
  factory WithDefault.fromJsonString(String encodedJson,
          {ValueSerializer? serializer}) =>
      WithDefault.fromJson(
          DataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'customJsonName': serializer.toJson<String?>(a),
      'b': serializer.toJson<int?>(b),
    };
  }

  WithDefault copyWith(
          {Value<String?> a = const Value.absent(),
          Value<int?> b = const Value.absent()}) =>
      WithDefault(
        a: a.present ? a.value : this.a,
        b: b.present ? b.value : this.b,
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
  int get hashCode => Object.hash(a, b);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WithDefault && other.a == this.a && other.b == this.b);
}

class WithDefaultsCompanion extends UpdateCompanion<WithDefault> {
  final Value<String?> a;
  final Value<int?> b;
  final Value<int> rowid;
  const WithDefaultsCompanion({
    this.a = const Value.absent(),
    this.b = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WithDefaultsCompanion.insert({
    this.a = const Value.absent(),
    this.b = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  static Insertable<WithDefault> custom({
    Expression<String>? a,
    Expression<int>? b,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (a != null) 'a': a,
      if (b != null) 'b': b,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WithDefaultsCompanion copyWith(
      {Value<String?>? a, Value<int?>? b, Value<int>? rowid}) {
    return WithDefaultsCompanion(
      a: a ?? this.a,
      b: b ?? this.b,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (a.present) {
      map['a'] = Variable<String>(a.value);
    }
    if (b.present) {
      map['b'] = Variable<int>(b.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WithDefaultsCompanion(')
          ..write('a: $a, ')
          ..write('b: $b, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class WithConstraints extends Table
    with TableInfo<WithConstraints, WithConstraint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  WithConstraints(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _aMeta = const VerificationMeta('a');
  late final GeneratedColumn<String> a = GeneratedColumn<String>(
      'a', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _bMeta = const VerificationMeta('b');
  late final GeneratedColumn<int> b = GeneratedColumn<int>(
      'b', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _cMeta = const VerificationMeta('c');
  late final GeneratedColumn<double> c = GeneratedColumn<double>(
      'c', aliasedName, true,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      $customConstraints: '');
  @override
  List<GeneratedColumn> get $columns => [a, b, c];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'with_constraints';
  @override
  VerificationContext validateIntegrity(Insertable<WithConstraint> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('a')) {
      context.handle(_aMeta, a.isAcceptableOrUnknown(data['a']!, _aMeta));
    }
    if (data.containsKey('b')) {
      context.handle(_bMeta, b.isAcceptableOrUnknown(data['b']!, _bMeta));
    } else if (isInserting) {
      context.missing(_bMeta);
    }
    if (data.containsKey('c')) {
      context.handle(_cMeta, c.isAcceptableOrUnknown(data['c']!, _cMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  WithConstraint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WithConstraint(
      a: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}a']),
      b: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}b'])!,
      c: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}c']),
    );
  }

  @override
  WithConstraints createAlias(String alias) {
    return WithConstraints(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints =>
      const ['FOREIGN KEY(a, b)REFERENCES with_defaults(a, b)'];
  @override
  bool get dontWriteConstraints => true;
}

class WithConstraint extends DataClass implements Insertable<WithConstraint> {
  final String? a;
  final int b;
  final double? c;
  const WithConstraint({this.a, required this.b, this.c});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || a != null) {
      map['a'] = Variable<String>(a);
    }
    map['b'] = Variable<int>(b);
    if (!nullToAbsent || c != null) {
      map['c'] = Variable<double>(c);
    }
    return map;
  }

  WithConstraintsCompanion toCompanion(bool nullToAbsent) {
    return WithConstraintsCompanion(
      a: a == null && nullToAbsent ? const Value.absent() : Value(a),
      b: Value(b),
      c: c == null && nullToAbsent ? const Value.absent() : Value(c),
    );
  }

  factory WithConstraint.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WithConstraint(
      a: serializer.fromJson<String?>(json['a']),
      b: serializer.fromJson<int>(json['b']),
      c: serializer.fromJson<double?>(json['c']),
    );
  }
  factory WithConstraint.fromJsonString(String encodedJson,
          {ValueSerializer? serializer}) =>
      WithConstraint.fromJson(
          DataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'a': serializer.toJson<String?>(a),
      'b': serializer.toJson<int>(b),
      'c': serializer.toJson<double?>(c),
    };
  }

  WithConstraint copyWith(
          {Value<String?> a = const Value.absent(),
          int? b,
          Value<double?> c = const Value.absent()}) =>
      WithConstraint(
        a: a.present ? a.value : this.a,
        b: b ?? this.b,
        c: c.present ? c.value : this.c,
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
  int get hashCode => Object.hash(a, b, c);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WithConstraint &&
          other.a == this.a &&
          other.b == this.b &&
          other.c == this.c);
}

class WithConstraintsCompanion extends UpdateCompanion<WithConstraint> {
  final Value<String?> a;
  final Value<int> b;
  final Value<double?> c;
  final Value<int> rowid;
  const WithConstraintsCompanion({
    this.a = const Value.absent(),
    this.b = const Value.absent(),
    this.c = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WithConstraintsCompanion.insert({
    this.a = const Value.absent(),
    required int b,
    this.c = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : b = Value(b);
  static Insertable<WithConstraint> custom({
    Expression<String>? a,
    Expression<int>? b,
    Expression<double>? c,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (a != null) 'a': a,
      if (b != null) 'b': b,
      if (c != null) 'c': c,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WithConstraintsCompanion copyWith(
      {Value<String?>? a,
      Value<int>? b,
      Value<double?>? c,
      Value<int>? rowid}) {
    return WithConstraintsCompanion(
      a: a ?? this.a,
      b: b ?? this.b,
      c: c ?? this.c,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (a.present) {
      map['a'] = Variable<String>(a.value);
    }
    if (b.present) {
      map['b'] = Variable<int>(b.value);
    }
    if (c.present) {
      map['c'] = Variable<double>(c.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WithConstraintsCompanion(')
          ..write('a: $a, ')
          ..write('b: $b, ')
          ..write('c: $c, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ConfigTable extends Table with TableInfo<ConfigTable, Config> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ConfigTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _configKeyMeta =
      const VerificationMeta('configKey');
  late final GeneratedColumn<String> configKey = GeneratedColumn<String>(
      'config_key', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL PRIMARY KEY');
  static const VerificationMeta _configValueMeta =
      const VerificationMeta('configValue');
  late final GeneratedColumn<DriftAny> configValue = GeneratedColumn<DriftAny>(
      'config_value', aliasedName, true,
      type: DriftSqlType.any,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _syncStateMeta =
      const VerificationMeta('syncState');
  late final GeneratedColumnWithTypeConverter<SyncType?, int> syncState =
      GeneratedColumn<int>('sync_state', aliasedName, true,
              type: DriftSqlType.int,
              requiredDuringInsert: false,
              $customConstraints: '')
          .withConverter<SyncType?>(ConfigTable.$convertersyncStaten);
  static const VerificationMeta _syncStateImplicitMeta =
      const VerificationMeta('syncStateImplicit');
  late final GeneratedColumnWithTypeConverter<SyncType?, int>
      syncStateImplicit = GeneratedColumn<int>(
              'sync_state_implicit', aliasedName, true,
              type: DriftSqlType.int,
              requiredDuringInsert: false,
              $customConstraints: '')
          .withConverter<SyncType?>(ConfigTable.$convertersyncStateImplicitn);
  @override
  List<GeneratedColumn> get $columns =>
      [configKey, configValue, syncState, syncStateImplicit];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'config';
  @override
  VerificationContext validateIntegrity(Insertable<Config> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('config_key')) {
      context.handle(_configKeyMeta,
          configKey.isAcceptableOrUnknown(data['config_key']!, _configKeyMeta));
    } else if (isInserting) {
      context.missing(_configKeyMeta);
    }
    if (data.containsKey('config_value')) {
      context.handle(
          _configValueMeta,
          configValue.isAcceptableOrUnknown(
              data['config_value']!, _configValueMeta));
    }
    context.handle(_syncStateMeta, const VerificationResult.success());
    context.handle(_syncStateImplicitMeta, const VerificationResult.success());
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {configKey};
  @override
  Config map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Config(
      configKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}config_key'])!,
      configValue: attachedDatabase.typeMapping
          .read(DriftSqlType.any, data['${effectivePrefix}config_value']),
      syncState: ConfigTable.$convertersyncStaten.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sync_state'])),
      syncStateImplicit: ConfigTable.$convertersyncStateImplicitn.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.int, data['${effectivePrefix}sync_state_implicit'])),
    );
  }

  @override
  ConfigTable createAlias(String alias) {
    return ConfigTable(attachedDatabase, alias);
  }

  static TypeConverter<SyncType, int> $convertersyncState =
      const SyncTypeConverter();
  static TypeConverter<SyncType?, int?> $convertersyncStaten =
      NullAwareTypeConverter.wrap($convertersyncState);
  static JsonTypeConverter2<SyncType, int, int> $convertersyncStateImplicit =
      const EnumIndexConverter<SyncType>(SyncType.values);
  static JsonTypeConverter2<SyncType?, int?, int?>
      $convertersyncStateImplicitn =
      JsonTypeConverter2.asNullable($convertersyncStateImplicit);
  @override
  bool get isStrict => true;
  @override
  bool get dontWriteConstraints => true;
}

class Config extends DataClass implements Insertable<Config> {
  final String configKey;

  /// The current value associated with the [configKey]
  final DriftAny? configValue;
  final SyncType? syncState;
  final SyncType? syncStateImplicit;
  const Config(
      {required this.configKey,
      this.configValue,
      this.syncState,
      this.syncStateImplicit});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['config_key'] = Variable<String>(configKey);
    if (!nullToAbsent || configValue != null) {
      map['config_value'] = Variable<DriftAny>(configValue);
    }
    if (!nullToAbsent || syncState != null) {
      final converter = ConfigTable.$convertersyncStaten;
      map['sync_state'] = Variable<int>(converter.toSql(syncState));
    }
    if (!nullToAbsent || syncStateImplicit != null) {
      final converter = ConfigTable.$convertersyncStateImplicitn;
      map['sync_state_implicit'] =
          Variable<int>(converter.toSql(syncStateImplicit));
    }
    return map;
  }

  ConfigCompanion toCompanion(bool nullToAbsent) {
    return ConfigCompanion(
      configKey: Value(configKey),
      configValue: configValue == null && nullToAbsent
          ? const Value.absent()
          : Value(configValue),
      syncState: syncState == null && nullToAbsent
          ? const Value.absent()
          : Value(syncState),
      syncStateImplicit: syncStateImplicit == null && nullToAbsent
          ? const Value.absent()
          : Value(syncStateImplicit),
    );
  }

  factory Config.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Config(
      configKey: serializer.fromJson<String>(json['config_key']),
      configValue: serializer.fromJson<DriftAny?>(json['config_value']),
      syncState: serializer.fromJson<SyncType?>(json['sync_state']),
      syncStateImplicit: ConfigTable.$convertersyncStateImplicitn
          .fromJson(serializer.fromJson<int?>(json['sync_state_implicit'])),
    );
  }
  factory Config.fromJsonString(String encodedJson,
          {ValueSerializer? serializer}) =>
      Config.fromJson(DataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'config_key': serializer.toJson<String>(configKey),
      'config_value': serializer.toJson<DriftAny?>(configValue),
      'sync_state': serializer.toJson<SyncType?>(syncState),
      'sync_state_implicit': serializer.toJson<int?>(
          ConfigTable.$convertersyncStateImplicitn.toJson(syncStateImplicit)),
    };
  }

  Config copyWith(
          {String? configKey,
          Value<DriftAny?> configValue = const Value.absent(),
          Value<SyncType?> syncState = const Value.absent(),
          Value<SyncType?> syncStateImplicit = const Value.absent()}) =>
      Config(
        configKey: configKey ?? this.configKey,
        configValue: configValue.present ? configValue.value : this.configValue,
        syncState: syncState.present ? syncState.value : this.syncState,
        syncStateImplicit: syncStateImplicit.present
            ? syncStateImplicit.value
            : this.syncStateImplicit,
      );
  @override
  String toString() {
    return (StringBuffer('Config(')
          ..write('configKey: $configKey, ')
          ..write('configValue: $configValue, ')
          ..write('syncState: $syncState, ')
          ..write('syncStateImplicit: $syncStateImplicit')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(configKey, configValue, syncState, syncStateImplicit);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Config &&
          other.configKey == this.configKey &&
          other.configValue == this.configValue &&
          other.syncState == this.syncState &&
          other.syncStateImplicit == this.syncStateImplicit);
}

class ConfigCompanion extends UpdateCompanion<Config> {
  final Value<String> configKey;
  final Value<DriftAny?> configValue;
  final Value<SyncType?> syncState;
  final Value<SyncType?> syncStateImplicit;
  final Value<int> rowid;
  const ConfigCompanion({
    this.configKey = const Value.absent(),
    this.configValue = const Value.absent(),
    this.syncState = const Value.absent(),
    this.syncStateImplicit = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConfigCompanion.insert({
    required String configKey,
    this.configValue = const Value.absent(),
    this.syncState = const Value.absent(),
    this.syncStateImplicit = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : configKey = Value(configKey);
  static Insertable<Config> custom({
    Expression<String>? configKey,
    Expression<DriftAny>? configValue,
    Expression<int>? syncState,
    Expression<int>? syncStateImplicit,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (configKey != null) 'config_key': configKey,
      if (configValue != null) 'config_value': configValue,
      if (syncState != null) 'sync_state': syncState,
      if (syncStateImplicit != null) 'sync_state_implicit': syncStateImplicit,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConfigCompanion copyWith(
      {Value<String>? configKey,
      Value<DriftAny?>? configValue,
      Value<SyncType?>? syncState,
      Value<SyncType?>? syncStateImplicit,
      Value<int>? rowid}) {
    return ConfigCompanion(
      configKey: configKey ?? this.configKey,
      configValue: configValue ?? this.configValue,
      syncState: syncState ?? this.syncState,
      syncStateImplicit: syncStateImplicit ?? this.syncStateImplicit,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (configKey.present) {
      map['config_key'] = Variable<String>(configKey.value);
    }
    if (configValue.present) {
      map['config_value'] = Variable<DriftAny>(configValue.value);
    }
    if (syncState.present) {
      final converter = ConfigTable.$convertersyncStaten;

      map['sync_state'] = Variable<int>(converter.toSql(syncState.value));
    }
    if (syncStateImplicit.present) {
      final converter = ConfigTable.$convertersyncStateImplicitn;

      map['sync_state_implicit'] =
          Variable<int>(converter.toSql(syncStateImplicit.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConfigCompanion(')
          ..write('configKey: $configKey, ')
          ..write('configValue: $configValue, ')
          ..write('syncState: $syncState, ')
          ..write('syncStateImplicit: $syncStateImplicit, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Mytable extends Table with TableInfo<Mytable, MytableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Mytable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _someidMeta = const VerificationMeta('someid');
  late final GeneratedColumn<int> someid = GeneratedColumn<int>(
      'someid', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _sometextMeta =
      const VerificationMeta('sometext');
  late final GeneratedColumn<String> sometext = GeneratedColumn<String>(
      'sometext', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _isInsertingMeta =
      const VerificationMeta('isInserting');
  late final GeneratedColumn<bool> isInserting = GeneratedColumn<bool>(
      'is_inserting', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _somedateMeta =
      const VerificationMeta('somedate');
  late final GeneratedColumn<DateTime> somedate = GeneratedColumn<DateTime>(
      'somedate', aliasedName, true,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      $customConstraints: '');
  @override
  List<GeneratedColumn> get $columns =>
      [someid, sometext, isInserting, somedate];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mytable';
  @override
  VerificationContext validateIntegrity(Insertable<MytableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('someid')) {
      context.handle(_someidMeta,
          someid.isAcceptableOrUnknown(data['someid']!, _someidMeta));
    }
    if (data.containsKey('sometext')) {
      context.handle(_sometextMeta,
          sometext.isAcceptableOrUnknown(data['sometext']!, _sometextMeta));
    }
    if (data.containsKey('is_inserting')) {
      context.handle(
          _isInsertingMeta,
          this
              .isInserting
              .isAcceptableOrUnknown(data['is_inserting']!, _isInsertingMeta));
    }
    if (data.containsKey('somedate')) {
      context.handle(_somedateMeta,
          somedate.isAcceptableOrUnknown(data['somedate']!, _somedateMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {someid};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {sometext, isInserting},
      ];
  @override
  MytableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MytableData(
      someid: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}someid'])!,
      sometext: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sometext']),
      isInserting: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_inserting']),
      somedate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}somedate']),
    );
  }

  @override
  Mytable createAlias(String alias) {
    return Mytable(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints =>
      const ['PRIMARY KEY(someid DESC)', 'UNIQUE(sometext, is_inserting)'];
  @override
  bool get dontWriteConstraints => true;
}

class MytableData extends DataClass implements Insertable<MytableData> {
  final int someid;
  final String? sometext;
  final bool? isInserting;
  final DateTime? somedate;
  const MytableData(
      {required this.someid, this.sometext, this.isInserting, this.somedate});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['someid'] = Variable<int>(someid);
    if (!nullToAbsent || sometext != null) {
      map['sometext'] = Variable<String>(sometext);
    }
    if (!nullToAbsent || isInserting != null) {
      map['is_inserting'] = Variable<bool>(isInserting);
    }
    if (!nullToAbsent || somedate != null) {
      map['somedate'] = Variable<DateTime>(somedate);
    }
    return map;
  }

  MytableCompanion toCompanion(bool nullToAbsent) {
    return MytableCompanion(
      someid: Value(someid),
      sometext: sometext == null && nullToAbsent
          ? const Value.absent()
          : Value(sometext),
      isInserting: isInserting == null && nullToAbsent
          ? const Value.absent()
          : Value(isInserting),
      somedate: somedate == null && nullToAbsent
          ? const Value.absent()
          : Value(somedate),
    );
  }

  factory MytableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MytableData(
      someid: serializer.fromJson<int>(json['someid']),
      sometext: serializer.fromJson<String?>(json['sometext']),
      isInserting: serializer.fromJson<bool?>(json['is_inserting']),
      somedate: serializer.fromJson<DateTime?>(json['somedate']),
    );
  }
  factory MytableData.fromJsonString(String encodedJson,
          {ValueSerializer? serializer}) =>
      MytableData.fromJson(
          DataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'someid': serializer.toJson<int>(someid),
      'sometext': serializer.toJson<String?>(sometext),
      'is_inserting': serializer.toJson<bool?>(isInserting),
      'somedate': serializer.toJson<DateTime?>(somedate),
    };
  }

  MytableData copyWith(
          {int? someid,
          Value<String?> sometext = const Value.absent(),
          Value<bool?> isInserting = const Value.absent(),
          Value<DateTime?> somedate = const Value.absent()}) =>
      MytableData(
        someid: someid ?? this.someid,
        sometext: sometext.present ? sometext.value : this.sometext,
        isInserting: isInserting.present ? isInserting.value : this.isInserting,
        somedate: somedate.present ? somedate.value : this.somedate,
      );
  @override
  String toString() {
    return (StringBuffer('MytableData(')
          ..write('someid: $someid, ')
          ..write('sometext: $sometext, ')
          ..write('isInserting: $isInserting, ')
          ..write('somedate: $somedate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(someid, sometext, isInserting, somedate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MytableData &&
          other.someid == this.someid &&
          other.sometext == this.sometext &&
          other.isInserting == this.isInserting &&
          other.somedate == this.somedate);
}

class MytableCompanion extends UpdateCompanion<MytableData> {
  final Value<int> someid;
  final Value<String?> sometext;
  final Value<bool?> isInserting;
  final Value<DateTime?> somedate;
  const MytableCompanion({
    this.someid = const Value.absent(),
    this.sometext = const Value.absent(),
    this.isInserting = const Value.absent(),
    this.somedate = const Value.absent(),
  });
  MytableCompanion.insert({
    this.someid = const Value.absent(),
    this.sometext = const Value.absent(),
    this.isInserting = const Value.absent(),
    this.somedate = const Value.absent(),
  });
  static Insertable<MytableData> custom({
    Expression<int>? someid,
    Expression<String>? sometext,
    Expression<bool>? isInserting,
    Expression<DateTime>? somedate,
  }) {
    return RawValuesInsertable({
      if (someid != null) 'someid': someid,
      if (sometext != null) 'sometext': sometext,
      if (isInserting != null) 'is_inserting': isInserting,
      if (somedate != null) 'somedate': somedate,
    });
  }

  MytableCompanion copyWith(
      {Value<int>? someid,
      Value<String?>? sometext,
      Value<bool?>? isInserting,
      Value<DateTime?>? somedate}) {
    return MytableCompanion(
      someid: someid ?? this.someid,
      sometext: sometext ?? this.sometext,
      isInserting: isInserting ?? this.isInserting,
      somedate: somedate ?? this.somedate,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (someid.present) {
      map['someid'] = Variable<int>(someid.value);
    }
    if (sometext.present) {
      map['sometext'] = Variable<String>(sometext.value);
    }
    if (isInserting.present) {
      map['is_inserting'] = Variable<bool>(isInserting.value);
    }
    if (somedate.present) {
      map['somedate'] = Variable<DateTime>(somedate.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MytableCompanion(')
          ..write('someid: $someid, ')
          ..write('sometext: $sometext, ')
          ..write('isInserting: $isInserting, ')
          ..write('somedate: $somedate')
          ..write(')'))
        .toString();
  }
}

class Email extends Table
    with TableInfo<Email, EMail>, VirtualTableInfo<Email, EMail> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Email(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _senderMeta = const VerificationMeta('sender');
  late final GeneratedColumn<String> sender = GeneratedColumn<String>(
      'sender', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: '');
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: '');
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
      'body', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: '');
  @override
  List<GeneratedColumn> get $columns => [sender, title, body];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'email';
  @override
  VerificationContext validateIntegrity(Insertable<EMail> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('sender')) {
      context.handle(_senderMeta,
          sender.isAcceptableOrUnknown(data['sender']!, _senderMeta));
    } else if (isInserting) {
      context.missing(_senderMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
          _bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  EMail map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EMail(
      sender: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sender'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      body: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body'])!,
    );
  }

  @override
  Email createAlias(String alias) {
    return Email(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
  @override
  String get moduleAndArgs => 'fts5(sender, title, body)';
}

class EMail extends DataClass implements Insertable<EMail> {
  final String sender;
  final String title;
  final String body;
  const EMail({required this.sender, required this.title, required this.body});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['sender'] = Variable<String>(sender);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    return map;
  }

  EmailCompanion toCompanion(bool nullToAbsent) {
    return EmailCompanion(
      sender: Value(sender),
      title: Value(title),
      body: Value(body),
    );
  }

  factory EMail.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EMail(
      sender: serializer.fromJson<String>(json['sender']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
    );
  }
  factory EMail.fromJsonString(String encodedJson,
          {ValueSerializer? serializer}) =>
      EMail.fromJson(DataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sender': serializer.toJson<String>(sender),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
    };
  }

  EMail copyWith({String? sender, String? title, String? body}) => EMail(
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
  int get hashCode => Object.hash(sender, title, body);
  @override
  bool operator ==(Object other) =>
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
  final Value<int> rowid;
  const EmailCompanion({
    this.sender = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EmailCompanion.insert({
    required String sender,
    required String title,
    required String body,
    this.rowid = const Value.absent(),
  })  : sender = Value(sender),
        title = Value(title),
        body = Value(body);
  static Insertable<EMail> custom({
    Expression<String>? sender,
    Expression<String>? title,
    Expression<String>? body,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sender != null) 'sender': sender,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EmailCompanion copyWith(
      {Value<String>? sender,
      Value<String>? title,
      Value<String>? body,
      Value<int>? rowid}) {
    return EmailCompanion(
      sender: sender ?? this.sender,
      title: title ?? this.title,
      body: body ?? this.body,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sender.present) {
      map['sender'] = Variable<String>(sender.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EmailCompanion(')
          ..write('sender: $sender, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class WeirdTable extends Table with TableInfo<WeirdTable, WeirdData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  WeirdTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sqlClassMeta =
      const VerificationMeta('sqlClass');
  late final GeneratedColumn<int> sqlClass = GeneratedColumn<int>(
      'class', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _textColumnMeta =
      const VerificationMeta('textColumn');
  late final GeneratedColumn<String> textColumn = GeneratedColumn<String>(
      'text', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  @override
  List<GeneratedColumn> get $columns => [sqlClass, textColumn];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'Expression';
  @override
  VerificationContext validateIntegrity(Insertable<WeirdData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('class')) {
      context.handle(_sqlClassMeta,
          sqlClass.isAcceptableOrUnknown(data['class']!, _sqlClassMeta));
    } else if (isInserting) {
      context.missing(_sqlClassMeta);
    }
    if (data.containsKey('text')) {
      context.handle(_textColumnMeta,
          textColumn.isAcceptableOrUnknown(data['text']!, _textColumnMeta));
    } else if (isInserting) {
      context.missing(_textColumnMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  WeirdData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeirdData(
      sqlClass: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}class'])!,
      textColumn: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}text'])!,
    );
  }

  @override
  WeirdTable createAlias(String alias) {
    return WeirdTable(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class WeirdData extends DataClass implements Insertable<WeirdData> {
  final int sqlClass;
  final String textColumn;
  const WeirdData({required this.sqlClass, required this.textColumn});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['class'] = Variable<int>(sqlClass);
    map['text'] = Variable<String>(textColumn);
    return map;
  }

  WeirdTableCompanion toCompanion(bool nullToAbsent) {
    return WeirdTableCompanion(
      sqlClass: Value(sqlClass),
      textColumn: Value(textColumn),
    );
  }

  factory WeirdData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeirdData(
      sqlClass: serializer.fromJson<int>(json['class']),
      textColumn: serializer.fromJson<String>(json['text']),
    );
  }
  factory WeirdData.fromJsonString(String encodedJson,
          {ValueSerializer? serializer}) =>
      WeirdData.fromJson(
          DataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'class': serializer.toJson<int>(sqlClass),
      'text': serializer.toJson<String>(textColumn),
    };
  }

  WeirdData copyWith({int? sqlClass, String? textColumn}) => WeirdData(
        sqlClass: sqlClass ?? this.sqlClass,
        textColumn: textColumn ?? this.textColumn,
      );
  @override
  String toString() {
    return (StringBuffer('WeirdData(')
          ..write('sqlClass: $sqlClass, ')
          ..write('textColumn: $textColumn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sqlClass, textColumn);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeirdData &&
          other.sqlClass == this.sqlClass &&
          other.textColumn == this.textColumn);
}

class WeirdTableCompanion extends UpdateCompanion<WeirdData> {
  final Value<int> sqlClass;
  final Value<String> textColumn;
  final Value<int> rowid;
  const WeirdTableCompanion({
    this.sqlClass = const Value.absent(),
    this.textColumn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WeirdTableCompanion.insert({
    required int sqlClass,
    required String textColumn,
    this.rowid = const Value.absent(),
  })  : sqlClass = Value(sqlClass),
        textColumn = Value(textColumn);
  static Insertable<WeirdData> custom({
    Expression<int>? sqlClass,
    Expression<String>? textColumn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sqlClass != null) 'class': sqlClass,
      if (textColumn != null) 'text': textColumn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WeirdTableCompanion copyWith(
      {Value<int>? sqlClass, Value<String>? textColumn, Value<int>? rowid}) {
    return WeirdTableCompanion(
      sqlClass: sqlClass ?? this.sqlClass,
      textColumn: textColumn ?? this.textColumn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sqlClass.present) {
      map['class'] = Variable<int>(sqlClass.value);
    }
    if (textColumn.present) {
      map['text'] = Variable<String>(textColumn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeirdTableCompanion(')
          ..write('sqlClass: $sqlClass, ')
          ..write('textColumn: $textColumn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class MyViewData extends DataClass {
  final String configKey;
  final DriftAny? configValue;
  final SyncType? syncState;
  final SyncType? syncStateImplicit;
  const MyViewData(
      {required this.configKey,
      this.configValue,
      this.syncState,
      this.syncStateImplicit});
  factory MyViewData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MyViewData(
      configKey: serializer.fromJson<String>(json['config_key']),
      configValue: serializer.fromJson<DriftAny?>(json['config_value']),
      syncState: serializer.fromJson<SyncType?>(json['sync_state']),
      syncStateImplicit: ConfigTable.$convertersyncStateImplicitn
          .fromJson(serializer.fromJson<int?>(json['sync_state_implicit'])),
    );
  }
  factory MyViewData.fromJsonString(String encodedJson,
          {ValueSerializer? serializer}) =>
      MyViewData.fromJson(
          DataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'config_key': serializer.toJson<String>(configKey),
      'config_value': serializer.toJson<DriftAny?>(configValue),
      'sync_state': serializer.toJson<SyncType?>(syncState),
      'sync_state_implicit': serializer.toJson<int?>(
          ConfigTable.$convertersyncStateImplicitn.toJson(syncStateImplicit)),
    };
  }

  MyViewData copyWith(
          {String? configKey,
          Value<DriftAny?> configValue = const Value.absent(),
          Value<SyncType?> syncState = const Value.absent(),
          Value<SyncType?> syncStateImplicit = const Value.absent()}) =>
      MyViewData(
        configKey: configKey ?? this.configKey,
        configValue: configValue.present ? configValue.value : this.configValue,
        syncState: syncState.present ? syncState.value : this.syncState,
        syncStateImplicit: syncStateImplicit.present
            ? syncStateImplicit.value
            : this.syncStateImplicit,
      );
  @override
  String toString() {
    return (StringBuffer('MyViewData(')
          ..write('configKey: $configKey, ')
          ..write('configValue: $configValue, ')
          ..write('syncState: $syncState, ')
          ..write('syncStateImplicit: $syncStateImplicit')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(configKey, configValue, syncState, syncStateImplicit);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MyViewData &&
          other.configKey == this.configKey &&
          other.configValue == this.configValue &&
          other.syncState == this.syncState &&
          other.syncStateImplicit == this.syncStateImplicit);
}

class MyView extends ViewInfo<MyView, MyViewData> implements HasResultSet {
  final String? _alias;
  @override
  final _$CustomTablesDb attachedDatabase;
  MyView(this.attachedDatabase, [this._alias]);
  @override
  List<GeneratedColumn> get $columns =>
      [configKey, configValue, syncState, syncStateImplicit];
  @override
  String get aliasedName => _alias ?? entityName;
  @override
  String get entityName => 'my_view';
  @override
  Map<SqlDialect, String> get createViewStatements => {
        SqlDialect.sqlite:
            'CREATE VIEW my_view AS SELECT * FROM config WHERE sync_state = 2',
      };
  @override
  MyView get asDslTable => this;
  @override
  MyViewData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MyViewData(
      configKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}config_key'])!,
      configValue: attachedDatabase.typeMapping
          .read(DriftSqlType.any, data['${effectivePrefix}config_value']),
      syncState: ConfigTable.$convertersyncStaten.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sync_state'])),
      syncStateImplicit: ConfigTable.$convertersyncStateImplicitn.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.int, data['${effectivePrefix}sync_state_implicit'])),
    );
  }

  late final GeneratedColumn<String> configKey = GeneratedColumn<String>(
      'config_key', aliasedName, false,
      type: DriftSqlType.string);
  late final GeneratedColumn<DriftAny> configValue = GeneratedColumn<DriftAny>(
      'config_value', aliasedName, true,
      type: DriftSqlType.any);
  late final GeneratedColumnWithTypeConverter<SyncType?, int> syncState =
      GeneratedColumn<int>('sync_state', aliasedName, true,
              type: DriftSqlType.int)
          .withConverter<SyncType?>(ConfigTable.$convertersyncStaten);
  late final GeneratedColumnWithTypeConverter<SyncType?, int>
      syncStateImplicit = GeneratedColumn<int>(
              'sync_state_implicit', aliasedName, true,
              type: DriftSqlType.int)
          .withConverter<SyncType?>(ConfigTable.$convertersyncStateImplicitn);
  @override
  MyView createAlias(String alias) {
    return MyView(attachedDatabase, alias);
  }

  @override
  Query? get query => null;
  @override
  Set<String> get readTables => const {'config'};
}

abstract class _$CustomTablesDb extends GeneratedDatabase {
  _$CustomTablesDb(QueryExecutor e) : super(e);
  late final NoIds noIds = NoIds(this);
  late final WithDefaults withDefaults = WithDefaults(this);
  late final WithConstraints withConstraints = WithConstraints(this);
  late final ConfigTable config = ConfigTable(this);
  late final Index valueIdx = Index('value_idx',
      'CREATE INDEX IF NOT EXISTS value_idx ON config (config_value)');
  late final Mytable mytable = Mytable(this);
  late final Email email = Email(this);
  late final WeirdTable weirdTable = WeirdTable(this);
  late final Trigger myTrigger = Trigger(
      'CREATE TRIGGER my_trigger AFTER INSERT ON config BEGIN INSERT INTO with_defaults VALUES (new.config_key, LENGTH(new.config_value));END',
      'my_trigger');
  late final MyView myView = MyView(this);
  Future<int> writeConfig({required String key, DriftAny? value}) {
    return customInsert(
      'REPLACE INTO config (config_key, config_value) VALUES (?1, ?2)',
      variables: [Variable<String>(key), Variable<DriftAny>(value)],
      updates: {config},
    );
  }

  Selectable<Config> readConfig(String var1) {
    return customSelect(
        'SELECT config_key AS ck, config_value AS cf, sync_state AS cs1, sync_state_implicit AS cs2 FROM config WHERE config_key = ?1',
        variables: [
          Variable<String>(var1)
        ],
        readsFrom: {
          config,
        }).asyncMap(
        (QueryRow row) async => config.mapFromRowWithAlias(row, const {
              'ck': 'config_key',
              'cf': 'config_value',
              'cs1': 'sync_state',
              'cs2': 'sync_state_implicit',
            }));
  }

  Selectable<Config> readMultiple(List<String> var1,
      {ReadMultiple$clause? clause}) {
    var $arrayStartIndex = 1;
    final expandedvar1 = $expandVar($arrayStartIndex, var1.length);
    $arrayStartIndex += var1.length;
    final generatedclause = $write(
        clause?.call(this.config) ?? const OrderBy.nothing(),
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedclause.amountOfVariables;
    return customSelect(
        'SELECT * FROM config WHERE config_key IN ($expandedvar1) ${generatedclause.sql}',
        variables: [
          for (var $ in var1) Variable<String>($),
          ...generatedclause.introducedVariables
        ],
        readsFrom: {
          config,
          ...generatedclause.watchedTables,
        }).asyncMap(config.mapFromRow);
  }

  Selectable<Config> readDynamic({ReadDynamic$predicate? predicate}) {
    var $arrayStartIndex = 1;
    final generatedpredicate = $write(
        predicate?.call(this.config) ?? const CustomExpression('(TRUE)'),
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedpredicate.amountOfVariables;
    return customSelect('SELECT * FROM config WHERE ${generatedpredicate.sql}',
        variables: [
          ...generatedpredicate.introducedVariables
        ],
        readsFrom: {
          config,
          ...generatedpredicate.watchedTables,
        }).asyncMap(config.mapFromRow);
  }

  Selectable<String> typeConverterVar(SyncType? var1, List<SyncType?> var2,
      {TypeConverterVar$pred? pred}) {
    var $arrayStartIndex = 2;
    final generatedpred = $write(
        pred?.call(this.config) ?? const CustomExpression('(TRUE)'),
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedpred.amountOfVariables;
    final expandedvar2 = $expandVar($arrayStartIndex, var2.length);
    $arrayStartIndex += var2.length;
    return customSelect(
        'SELECT config_key FROM config WHERE ${generatedpred.sql} AND(sync_state = ?1 OR sync_state_implicit IN ($expandedvar2))',
        variables: [
          Variable<int>(NullAwareTypeConverter.wrapToSql(
              ConfigTable.$convertersyncState, var1)),
          ...generatedpred.introducedVariables,
          for (var $ in var2)
            Variable<int>(NullAwareTypeConverter.wrapToSql(
                ConfigTable.$convertersyncStateImplicit, $))
        ],
        readsFrom: {
          config,
          ...generatedpred.watchedTables,
        }).map((QueryRow row) => row.read<String>('config_key'));
  }

  Selectable<JsonResult> tableValued() {
    return customSelect(
        'SELECT "key", value FROM config,json_each(config.config_value)WHERE json_valid(config_value)',
        variables: [],
        readsFrom: {
          config,
        }).map((QueryRow row) => JsonResult(
          row: row,
          key: row.read<String>('key'),
          value: row.readNullable<String>('value'),
        ));
  }

  Selectable<JsonResult> another() {
    return customSelect('SELECT \'one\' AS "key", NULLIF(\'two\', \'another\') AS value', variables: [], readsFrom: {})
        .map((QueryRow row) => JsonResult(
              row: row,
              key: row.read<String>('key'),
              value: row.readNullable<String>('value'),
            ));
  }

  Selectable<MultipleResult> multiple({required Multiple$predicate predicate}) {
    var $arrayStartIndex = 1;
    final generatedpredicate = $write(
        predicate(
            alias(this.withDefaults, 'd'), alias(this.withConstraints, 'c')),
        hasMultipleTables: true,
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedpredicate.amountOfVariables;
    return customSelect(
        'SELECT d.*,"c"."a" AS "nested_0.a", "c"."b" AS "nested_0.b", "c"."c" AS "nested_0.c" FROM with_defaults AS d LEFT OUTER JOIN with_constraints AS c ON d.a = c.a AND d.b = c.b WHERE ${generatedpredicate.sql}',
        variables: [
          ...generatedpredicate.introducedVariables
        ],
        readsFrom: {
          withDefaults,
          withConstraints,
          ...generatedpredicate.watchedTables,
        }).asyncMap((QueryRow row) async => MultipleResult(
          row: row,
          a: row.readNullable<String>('a'),
          b: row.readNullable<int>('b'),
          c: await withConstraints.mapFromRowOrNull(row,
              tablePrefix: 'nested_0'),
        ));
  }

  Selectable<EMail> searchEmails({required String? term}) {
    return customSelect(
        'SELECT * FROM email WHERE email MATCH ?1 ORDER BY rank',
        variables: [
          Variable<String>(term)
        ],
        readsFrom: {
          email,
        }).asyncMap(email.mapFromRow);
  }

  Selectable<ReadRowIdResult> readRowId({required ReadRowId$expr expr}) {
    var $arrayStartIndex = 1;
    final generatedexpr =
        $write(expr(this.config), startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedexpr.amountOfVariables;
    return customSelect(
        'SELECT oid, * FROM config WHERE _rowid_ = ${generatedexpr.sql}',
        variables: [
          ...generatedexpr.introducedVariables
        ],
        readsFrom: {
          config,
          ...generatedexpr.watchedTables,
        }).map((QueryRow row) => ReadRowIdResult(
          row: row,
          rowid: row.read<int>('rowid'),
          configKey: row.read<String>('config_key'),
          configValue: row.readNullable<DriftAny>('config_value'),
          syncState: NullAwareTypeConverter.wrapFromSql(
              ConfigTable.$convertersyncState,
              row.readNullable<int>('sync_state')),
          syncStateImplicit: NullAwareTypeConverter.wrapFromSql(
              ConfigTable.$convertersyncStateImplicit,
              row.readNullable<int>('sync_state_implicit')),
        ));
  }

  Selectable<MyViewData> readView({ReadView$where? where}) {
    var $arrayStartIndex = 1;
    final generatedwhere = $write(
        where?.call(this.myView) ?? const CustomExpression('(TRUE)'),
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedwhere.amountOfVariables;
    return customSelect('SELECT * FROM my_view WHERE ${generatedwhere.sql}',
        variables: [
          ...generatedwhere.introducedVariables
        ],
        readsFrom: {
          config,
          ...generatedwhere.watchedTables,
        }).asyncMap(myView.mapFromRow);
  }

  Selectable<int> cfeTest() {
    return customSelect(
        'WITH RECURSIVE cnt (x) AS (SELECT 1 UNION ALL SELECT x + 1 FROM cnt LIMIT 1000000) SELECT x FROM cnt',
        variables: [],
        readsFrom: {}).map((QueryRow row) => row.read<int>('x'));
  }

  Selectable<int?> nullableQuery() {
    return customSelect('SELECT MAX(oid) AS _c0 FROM config',
        variables: [],
        readsFrom: {
          config,
        }).map((QueryRow row) => row.readNullable<int>('_c0'));
  }

  Future<List<Config>> addConfig({required Insertable<Config> value}) {
    var $arrayStartIndex = 1;
    final generatedvalue =
        $writeInsertable(this.config, value, startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedvalue.amountOfVariables;
    return customWriteReturning(
            'INSERT INTO config ${generatedvalue.sql} RETURNING *',
            variables: [...generatedvalue.introducedVariables],
            updates: {config})
        .then((rows) => Future.wait(rows.map(config.mapFromRow)));
  }

  Selectable<NestedResult> nested(String? var1) {
    return customSelect(
        'SELECT"defaults"."a" AS "nested_0.a", "defaults"."b" AS "nested_0.b", defaults.b AS "\$n_0" FROM with_defaults AS defaults WHERE a = ?1',
        variables: [
          Variable<String>(var1)
        ],
        readsFrom: {
          withConstraints,
          withDefaults,
        }).asyncMap((QueryRow row) async => NestedResult(
          row: row,
          defaults: await withDefaults.mapFromRow(row, tablePrefix: 'nested_0'),
          nestedQuery1: await customSelect(
              'SELECT * FROM with_constraints AS c WHERE c.b = ?1',
              variables: [
                Variable<int>(row.read('\$n_0'))
              ],
              readsFrom: {
                withConstraints,
                withDefaults,
              }).asyncMap(withConstraints.mapFromRow).get(),
        ));
  }

  Selectable<MyCustomResultClass> customResult() {
    return customSelect(
        'SELECT with_constraints.b, config.sync_state,"config"."config_key" AS "nested_0.config_key", "config"."config_value" AS "nested_0.config_value", "config"."sync_state" AS "nested_0.sync_state", "config"."sync_state_implicit" AS "nested_0.sync_state_implicit","no_ids"."payload" AS "nested_1.payload" FROM with_constraints INNER JOIN config ON config_key = with_constraints.a CROSS JOIN no_ids',
        variables: [],
        readsFrom: {
          withConstraints,
          config,
          noIds,
        }).asyncMap((QueryRow row) async => MyCustomResultClass(
          row.read<int>('b'),
          syncState: NullAwareTypeConverter.wrapFromSql(
              ConfigTable.$convertersyncState,
              row.readNullable<int>('sync_state')),
          config: await config.mapFromRow(row, tablePrefix: 'nested_0'),
          noIds: await noIds.mapFromRow(row, tablePrefix: 'nested_1'),
          nested: await customSelect('SELECT * FROM no_ids',
                  variables: [],
                  readsFrom: {
                noIds,
              })
              .map((QueryRow row) => Buffer(
                    row.read<Uint8List>('payload'),
                  ))
              .get(),
        ));
  }

  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        noIds,
        withDefaults,
        withConstraints,
        config,
        valueIdx,
        mytable,
        email,
        weirdTable,
        myTrigger,
        myView,
        OnCreateQuery(
            'INSERT INTO config (config_key, config_value) VALUES (\'key\', \'values\')')
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('config',
                limitUpdateKind: UpdateKind.insert),
            result: [
              TableUpdate('with_defaults', kind: UpdateKind.insert),
            ],
          ),
        ],
      );
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef ReadMultiple$clause = OrderBy Function(ConfigTable config);
typedef ReadDynamic$predicate = Expression<bool> Function(ConfigTable config);
typedef TypeConverterVar$pred = Expression<bool> Function(ConfigTable config);

class JsonResult extends CustomResultSet {
  final String key;
  final String? value;
  JsonResult({
    required QueryRow row,
    required this.key,
    this.value,
  }) : super(row);
  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JsonResult &&
          other.key == this.key &&
          other.value == this.value);
  @override
  String toString() {
    return (StringBuffer('JsonResult(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }
}

class MultipleResult extends CustomResultSet {
  final String? a;
  final int? b;
  final WithConstraint? c;
  MultipleResult({
    required QueryRow row,
    this.a,
    this.b,
    this.c,
  }) : super(row);
  @override
  int get hashCode => Object.hash(a, b, c);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MultipleResult &&
          other.a == this.a &&
          other.b == this.b &&
          other.c == this.c);
  @override
  String toString() {
    return (StringBuffer('MultipleResult(')
          ..write('a: $a, ')
          ..write('b: $b, ')
          ..write('c: $c')
          ..write(')'))
        .toString();
  }
}

typedef Multiple$predicate = Expression<bool> Function(
    WithDefaults d, WithConstraints c);

class ReadRowIdResult extends CustomResultSet {
  final int rowid;
  final String configKey;
  final DriftAny? configValue;
  final SyncType? syncState;
  final SyncType? syncStateImplicit;
  ReadRowIdResult({
    required QueryRow row,
    required this.rowid,
    required this.configKey,
    this.configValue,
    this.syncState,
    this.syncStateImplicit,
  }) : super(row);
  @override
  int get hashCode =>
      Object.hash(rowid, configKey, configValue, syncState, syncStateImplicit);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadRowIdResult &&
          other.rowid == this.rowid &&
          other.configKey == this.configKey &&
          other.configValue == this.configValue &&
          other.syncState == this.syncState &&
          other.syncStateImplicit == this.syncStateImplicit);
  @override
  String toString() {
    return (StringBuffer('ReadRowIdResult(')
          ..write('rowid: $rowid, ')
          ..write('configKey: $configKey, ')
          ..write('configValue: $configValue, ')
          ..write('syncState: $syncState, ')
          ..write('syncStateImplicit: $syncStateImplicit')
          ..write(')'))
        .toString();
  }
}

typedef ReadRowId$expr = Expression<int> Function(ConfigTable config);
typedef ReadView$where = Expression<bool> Function(MyView my_view);

class NestedResult extends CustomResultSet {
  final WithDefault defaults;
  final List<WithConstraint> nestedQuery1;
  NestedResult({
    required QueryRow row,
    required this.defaults,
    required this.nestedQuery1,
  }) : super(row);
  @override
  int get hashCode => Object.hash(defaults, nestedQuery1);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NestedResult &&
          other.defaults == this.defaults &&
          other.nestedQuery1 == this.nestedQuery1);
  @override
  String toString() {
    return (StringBuffer('NestedResult(')
          ..write('defaults: $defaults, ')
          ..write('nestedQuery1: $nestedQuery1')
          ..write(')'))
        .toString();
  }
}
