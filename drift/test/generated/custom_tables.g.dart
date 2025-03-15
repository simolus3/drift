// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_tables.dart';

// ignore_for_file: type=lint
class NoIds extends Table
    with ResultSet<NoIdRow, NoIds>
    implements GeneratedTable<NoIdRow, NoIds> {
  @override
  final String? alias;
  NoIds([this.alias]);
  late final TableColumn<Uint8List> payload = TableColumn<Uint8List>(
      name: 'payload',
      type: BuiltinDriftType.byteArray,
      isNullable: false,
      requiredDuringInsert: true,
      constraints: [ColumnConstraint.customSql('NOT NULL PRIMARY KEY')])
    ..owningResultSet = this;
  @override
  List<TableColumn> get columns => [payload];
  @override
  String get entityName => $name;
  static const String $name = 'no_ids';
  @override
  NoIds asSelfType() => this;

  @override
  Set<TableColumn> get primaryKey => {payload};
  @override
  NoIdRow? Function(DriftRow) createMapperFromPositions(
      List<ColumnPosition> positions) {
    return (DriftRow row) {
      // Not part of row if non-nullable column "payload" is missing
      if (row.raw.rawValue(positions[0]) == null) {
        return null;
      }
      return NoIdRow(
        row.readWithType(positions[0], BuiltinDriftType.byteArray)!,
      );
    };
  }

  @override
  NoIds withAlias(String alias) {
    return NoIds(alias);
  }

  @override
  bool get withoutRowId => true;
  @override
  bool get isStrict => true;
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

class WithDefaults extends Table
    with ResultSet<WithDefault, WithDefaults>
    implements GeneratedTable<WithDefault, WithDefaults> {
  @override
  final String? alias;
  WithDefaults([this.alias]);
  late final TableColumn<String> a = TableColumn<String>(
      name: 'a',
      type: const CustomTextType(),
      isNullable: true,
      requiredDuringInsert: false,
      constraints: [ColumnConstraint.customSql('DEFAULT \'something\'')])
    ..owningResultSet = this;
  late final TableColumn<int> b = TableColumn<int>(
      name: 'b',
      type: BuiltinDriftType.int,
      isNullable: true,
      requiredDuringInsert: false,
      constraints: [ColumnConstraint.customSql('UNIQUE NULL')])
    ..owningResultSet = this;
  @override
  List<TableColumn> get columns => [a, b];
  @override
  String get entityName => $name;
  static const String $name = 'with_defaults';
  @override
  WithDefaults asSelfType() => this;

  @override
  Set<TableColumn> get primaryKey => const {};
  @override
  WithDefault? Function(DriftRow) createMapperFromPositions(
      List<ColumnPosition> positions) {
    return (DriftRow row) {
      return WithDefault(
        a: row.readWithType(positions[0], const CustomTextType()),
        b: row.readWithType(positions[1], BuiltinDriftType.int),
      );
    };
  }

  @override
  WithDefaults withAlias(String alias) {
    return WithDefaults(alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class WithDefault extends LegacyDataClass implements Insertable<WithDefault> {
  final String? a;
  final int? b;
  const WithDefault({this.a, this.b});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || a != null) {
      map['a'] = Variable<String>(a, (_) => const CustomTextType());
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
          LegacyDataClass.parseJson(encodedJson) as Map<String, dynamic>,
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
  WithDefault copyWithCompanion(WithDefaultsCompanion data) {
    return WithDefault(
      a: data.a.present ? data.a.value : this.a,
      b: data.b.present ? data.b.value : this.b,
    );
  }

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
      map['a'] = Variable<String>(a.value, (_) => const CustomTextType());
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
    with ResultSet<WithConstraint, WithConstraints>
    implements GeneratedTable<WithConstraint, WithConstraints> {
  @override
  final String? alias;
  WithConstraints([this.alias]);
  late final TableColumn<String> a = TableColumn<String>(
      name: 'a',
      type: BuiltinDriftType.text,
      isNullable: true,
      requiredDuringInsert: false,
      constraints: [ColumnConstraint.customSql('')])
    ..owningResultSet = this;
  late final TableColumn<int> b = TableColumn<int>(
      name: 'b',
      type: BuiltinDriftType.int,
      isNullable: false,
      requiredDuringInsert: true,
      constraints: [ColumnConstraint.customSql('NOT NULL')])
    ..owningResultSet = this;
  late final TableColumn<double> c = TableColumn<double>(
      name: 'c',
      type: BuiltinDriftType.double,
      isNullable: true,
      requiredDuringInsert: false,
      constraints: [ColumnConstraint.customSql('')])
    ..owningResultSet = this;
  @override
  List<TableColumn> get columns => [a, b, c];
  @override
  String get entityName => $name;
  static const String $name = 'with_constraints';
  @override
  WithConstraints asSelfType() => this;

  @override
  Set<TableColumn> get primaryKey => const {};
  @override
  WithConstraint? Function(DriftRow) createMapperFromPositions(
      List<ColumnPosition> positions) {
    return (DriftRow row) {
      // Not part of row if non-nullable column "b" is missing
      if (row.raw.rawValue(positions[1]) == null) {
        return null;
      }
      return WithConstraint(
        a: row.readWithType(positions[0], BuiltinDriftType.text),
        b: row.readWithType(positions[1], BuiltinDriftType.int)!,
        c: row.readWithType(positions[2], BuiltinDriftType.double),
      );
    };
  }

  @override
  WithConstraints withAlias(String alias) {
    return WithConstraints(alias);
  }

  @override
  List<String> get customConstraints =>
      const ['FOREIGN KEY(a, b)REFERENCES with_defaults(a, b)'];
  @override
  bool get dontWriteConstraints => true;
}

class WithConstraint extends LegacyDataClass
    implements Insertable<WithConstraint> {
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
          LegacyDataClass.parseJson(encodedJson) as Map<String, dynamic>,
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
  WithConstraint copyWithCompanion(WithConstraintsCompanion data) {
    return WithConstraint(
      a: data.a.present ? data.a.value : this.a,
      b: data.b.present ? data.b.value : this.b,
      c: data.c.present ? data.c.value : this.c,
    );
  }

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

class ConfigTable extends Table
    with ResultSet<Config, ConfigTable>
    implements GeneratedTable<Config, ConfigTable> {
  @override
  final String? alias;
  ConfigTable([this.alias]);
  late final TableColumn<String> configKey = TableColumn<String>(
      name: 'config_key',
      type: BuiltinDriftType.text,
      isNullable: false,
      requiredDuringInsert: true,
      constraints: [ColumnConstraint.customSql('NOT NULL PRIMARY KEY')])
    ..owningResultSet = this;
  late final TableColumn<DriftAny> configValue = TableColumn<DriftAny>(
      name: 'config_value',
      type: SqliteDialect,
      isNullable: true,
      requiredDuringInsert: false,
      constraints: [ColumnConstraint.customSql('')])
    ..owningResultSet = this;
  late final TableColumnWithTypeConverter<SyncType?, int> syncState =
      TableColumn<int>(
              name: 'sync_state',
              type: BuiltinDriftType.int,
              isNullable: true,
              requiredDuringInsert: false,
              constraints: [ColumnConstraint.customSql('')])
          .withConverter<SyncType?>(ConfigTable.$convertersyncStaten)
        ..owningResultSet = this;
  late final TableColumnWithTypeConverter<SyncType?, int> syncStateImplicit =
      TableColumn<int>(
              name: 'sync_state_implicit',
              type: BuiltinDriftType.int,
              isNullable: true,
              requiredDuringInsert: false,
              constraints: [ColumnConstraint.customSql('')])
          .withConverter<SyncType?>(ConfigTable.$convertersyncStateImplicitn)
        ..owningResultSet = this;
  @override
  List<TableColumn> get columns =>
      [configKey, configValue, syncState, syncStateImplicit];
  @override
  String get entityName => $name;
  static const String $name = 'config';
  @override
  ConfigTable asSelfType() => this;

  @override
  Set<TableColumn> get primaryKey => {configKey};
  @override
  Config? Function(DriftRow) createMapperFromPositions(
      List<ColumnPosition> positions) {
    return (DriftRow row) {
      // Not part of row if non-nullable column "configKey" is missing
      if (row.raw.rawValue(positions[0]) == null) {
        return null;
      }
      return Config(
        configKey: row.readWithType(positions[0], BuiltinDriftType.text)!,
        configValue: row.readWithType(positions[1], SqliteDialect),
        syncState: ConfigTable.$convertersyncStaten
            .fromSql(row.readWithType(positions[2], BuiltinDriftType.int)),
        syncStateImplicit: ConfigTable.$convertersyncStateImplicitn
            .fromSql(row.readWithType(positions[3], BuiltinDriftType.int)),
      );
    };
  }

  @override
  ConfigTable withAlias(String alias) {
    return ConfigTable(alias);
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

class Config extends LegacyDataClass implements Insertable<Config> {
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
      map['config_value'] =
          Variable<DriftAny>(configValue, (_) => SqliteDialect);
    }
    if (!nullToAbsent || syncState != null) {
      map['sync_state'] =
          Variable<int>(ConfigTable.$convertersyncStaten.toSql(syncState));
    }
    if (!nullToAbsent || syncStateImplicit != null) {
      map['sync_state_implicit'] = Variable<int>(
          ConfigTable.$convertersyncStateImplicitn.toSql(syncStateImplicit));
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
      Config.fromJson(
          LegacyDataClass.parseJson(encodedJson) as Map<String, dynamic>,
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
  Config copyWithCompanion(ConfigCompanion data) {
    return Config(
      configKey: data.configKey.present ? data.configKey.value : this.configKey,
      configValue:
          data.configValue.present ? data.configValue.value : this.configValue,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      syncStateImplicit: data.syncStateImplicit.present
          ? data.syncStateImplicit.value
          : this.syncStateImplicit,
    );
  }

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
      map['config_value'] =
          Variable<DriftAny>(configValue.value, (_) => SqliteDialect);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<int>(
          ConfigTable.$convertersyncStaten.toSql(syncState.value));
    }
    if (syncStateImplicit.present) {
      map['sync_state_implicit'] = Variable<int>(ConfigTable
          .$convertersyncStateImplicitn
          .toSql(syncStateImplicit.value));
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

class Mytable extends Table
    with ResultSet<MytableData, Mytable>
    implements GeneratedTable<MytableData, Mytable> {
  @override
  final String? alias;
  Mytable([this.alias]);
  late final TableColumn<int> someid = TableColumn<int>(
      name: 'someid',
      type: BuiltinDriftType.int,
      isNullable: false,
      requiredDuringInsert: false,
      constraints: [ColumnConstraint.customSql('NOT NULL')])
    ..owningResultSet = this;
  late final TableColumn<String> sometext = TableColumn<String>(
      name: 'sometext',
      type: BuiltinDriftType.text,
      isNullable: true,
      requiredDuringInsert: false,
      constraints: [ColumnConstraint.customSql('')])
    ..owningResultSet = this;
  late final TableColumn<bool> isInserting = TableColumn<bool>(
      name: 'is_inserting',
      type: BuiltinDriftType.bool,
      isNullable: true,
      requiredDuringInsert: false,
      constraints: [ColumnConstraint.customSql('')])
    ..owningResultSet = this;
  late final TableColumn<DateTime> somedate = TableColumn<DateTime>(
      name: 'somedate',
      type: BuiltinDriftType.dateTime,
      isNullable: true,
      requiredDuringInsert: false,
      constraints: [ColumnConstraint.customSql('')])
    ..owningResultSet = this;
  @override
  List<TableColumn> get columns => [someid, sometext, isInserting, somedate];
  @override
  String get entityName => $name;
  static const String $name = 'mytable';
  @override
  Mytable asSelfType() => this;

  @override
  Set<TableColumn> get primaryKey => {someid};
  @override
  List<Set<TableColumn>> get uniqueKeys => [
        {sometext, isInserting},
      ];
  @override
  MytableData? Function(DriftRow) createMapperFromPositions(
      List<ColumnPosition> positions) {
    return (DriftRow row) {
      // Not part of row if non-nullable column "someid" is missing
      if (row.raw.rawValue(positions[0]) == null) {
        return null;
      }
      return MytableData(
        someid: row.readWithType(positions[0], BuiltinDriftType.int)!,
        sometext: row.readWithType(positions[1], BuiltinDriftType.text),
        isInserting: row.readWithType(positions[2], BuiltinDriftType.bool),
        somedate: row.readWithType(positions[3], BuiltinDriftType.dateTime),
      );
    };
  }

  @override
  Mytable withAlias(String alias) {
    return Mytable(alias);
  }

  @override
  List<String> get customConstraints =>
      const ['PRIMARY KEY(someid DESC)', 'UNIQUE(sometext, is_inserting)'];
  @override
  bool get dontWriteConstraints => true;
}

class MytableData extends LegacyDataClass implements Insertable<MytableData> {
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
          LegacyDataClass.parseJson(encodedJson) as Map<String, dynamic>,
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
  MytableData copyWithCompanion(MytableCompanion data) {
    return MytableData(
      someid: data.someid.present ? data.someid.value : this.someid,
      sometext: data.sometext.present ? data.sometext.value : this.sometext,
      isInserting:
          data.isInserting.present ? data.isInserting.value : this.isInserting,
      somedate: data.somedate.present ? data.somedate.value : this.somedate,
    );
  }

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
    with ResultSet<EMail, Email>
    implements GeneratedTable<EMail, Email>, VirtualTableInfo<EMail, Email> {
  @override
  final String? alias;
  Email([this.alias]);
  late final TableColumn<String> sender = TableColumn<String>(
      name: 'sender',
      type: BuiltinDriftType.text,
      isNullable: false,
      requiredDuringInsert: true,
      constraints: [ColumnConstraint.customSql('')])
    ..owningResultSet = this;
  late final TableColumn<String> title = TableColumn<String>(
      name: 'title',
      type: BuiltinDriftType.text,
      isNullable: false,
      requiredDuringInsert: true,
      constraints: [ColumnConstraint.customSql('')])
    ..owningResultSet = this;
  late final TableColumn<String> body = TableColumn<String>(
      name: 'body',
      type: BuiltinDriftType.text,
      isNullable: false,
      requiredDuringInsert: true,
      constraints: [ColumnConstraint.customSql('')])
    ..owningResultSet = this;
  @override
  List<TableColumn> get columns => [sender, title, body];
  @override
  String get entityName => $name;
  static const String $name = 'email';
  @override
  Email asSelfType() => this;

  @override
  Set<TableColumn> get primaryKey => const {};
  @override
  EMail? Function(DriftRow) createMapperFromPositions(
      List<ColumnPosition> positions) {
    return (DriftRow row) {
      // Not part of row if non-nullable column "sender" is missing
      if (row.raw.rawValue(positions[0]) == null) {
        return null;
      }
      return EMail(
        sender: row.readWithType(positions[0], BuiltinDriftType.text)!,
        title: row.readWithType(positions[1], BuiltinDriftType.text)!,
        body: row.readWithType(positions[2], BuiltinDriftType.text)!,
      );
    };
  }

  @override
  Email withAlias(String alias) {
    return Email(alias);
  }

  @override
  bool get dontWriteConstraints => true;
  @override
  String get moduleAndArgs => 'fts5(sender, title, body)';
}

class EMail extends LegacyDataClass implements Insertable<EMail> {
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
      EMail.fromJson(
          LegacyDataClass.parseJson(encodedJson) as Map<String, dynamic>,
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
  EMail copyWithCompanion(EmailCompanion data) {
    return EMail(
      sender: data.sender.present ? data.sender.value : this.sender,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
    );
  }

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

class WeirdTable extends Table
    with ResultSet<WeirdData, WeirdTable>
    implements GeneratedTable<WeirdData, WeirdTable> {
  @override
  final String? alias;
  WeirdTable([this.alias]);
  late final TableColumn<int> sqlClass = TableColumn<int>(
      name: 'class',
      type: BuiltinDriftType.int,
      isNullable: false,
      requiredDuringInsert: true,
      constraints: [ColumnConstraint.customSql('NOT NULL')])
    ..owningResultSet = this;
  late final TableColumn<String> textColumn = TableColumn<String>(
      name: 'text',
      type: BuiltinDriftType.text,
      isNullable: false,
      requiredDuringInsert: true,
      constraints: [ColumnConstraint.customSql('NOT NULL')])
    ..owningResultSet = this;
  @override
  List<TableColumn> get columns => [sqlClass, textColumn];
  @override
  String get entityName => $name;
  static const String $name = 'Expression';
  @override
  WeirdTable asSelfType() => this;

  @override
  Set<TableColumn> get primaryKey => const {};
  @override
  WeirdData? Function(DriftRow) createMapperFromPositions(
      List<ColumnPosition> positions) {
    return (DriftRow row) {
      // Not part of row if non-nullable column "sqlClass" is missing
      if (row.raw.rawValue(positions[0]) == null) {
        return null;
      }
      return WeirdData(
        sqlClass: row.readWithType(positions[0], BuiltinDriftType.int)!,
        textColumn: row.readWithType(positions[1], BuiltinDriftType.text)!,
      );
    };
  }

  @override
  WeirdTable withAlias(String alias) {
    return WeirdTable(alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class WeirdData extends LegacyDataClass implements Insertable<WeirdData> {
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
          LegacyDataClass.parseJson(encodedJson) as Map<String, dynamic>,
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
  WeirdData copyWithCompanion(WeirdTableCompanion data) {
    return WeirdData(
      sqlClass: data.sqlClass.present ? data.sqlClass.value : this.sqlClass,
      textColumn:
          data.textColumn.present ? data.textColumn.value : this.textColumn,
    );
  }

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

class MyViewData extends LegacyDataClass {
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
          LegacyDataClass.parseJson(encodedJson) as Map<String, dynamic>,
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

class MyView extends View
    with ResultSet<MyViewData, MyView>
    implements GeneratedView<MyViewData, MyView> {
  @override
  final String? alias;
  final _$CustomTablesDb _attachedDatabase;
  MyView(this._attachedDatabase, [this.alias]);
  @override
  List<SchemaColumn> get columns =>
      [configKey, configValue, syncState, syncStateImplicit];
  @override
  String get entityName => 'my_view';
  @override
  MyView asSelfType() => this;

  @override
  MyViewData? Function(DriftRow) createMapperFromPositions(
      List<ColumnPosition> positions) {
    return (DriftRow row) {
      // Not part of row if non-nullable column "configKey" is missing
      if (row.raw.rawValue(positions[0]) == null) {
        return null;
      }
      return MyViewData(
        configKey: row.readWithType(positions[0], BuiltinDriftType.text)!,
        configValue: row.readWithType(positions[1], SqliteDialect),
        syncState: ConfigTable.$convertersyncStaten
            .fromSql(row.readWithType(positions[2], BuiltinDriftType.int)),
        syncStateImplicit: ConfigTable.$convertersyncStateImplicitn
            .fromSql(row.readWithType(positions[3], BuiltinDriftType.int)),
      );
    };
  }

  late final ViewColumn<String> configKey = ViewColumn<String>(
      name: 'config_key', type: BuiltinDriftType.text, isNullable: false)
    ..owningResultSet = this;
  late final ViewColumn<DriftAny> configValue = ViewColumn<DriftAny>(
      name: 'config_value', type: SqliteDialect, isNullable: true)
    ..owningResultSet = this;
  late final ViewColumnWithTypeConverter<SyncType?, int> syncState =
      ViewColumn<int>(
              name: 'sync_state', type: BuiltinDriftType.int, isNullable: true)
          .withConverter<SyncType?>(ConfigTable.$convertersyncStaten)
        ..owningResultSet = this;
  late final ViewColumnWithTypeConverter<SyncType?, int> syncStateImplicit =
      ViewColumn<int>(
              name: 'sync_state_implicit',
              type: BuiltinDriftType.int,
              isNullable: true)
          .withConverter<SyncType?>(ConfigTable.$convertersyncStateImplicitn)
        ..owningResultSet = this;
  @override
  MyView withAlias(String alias) {
    return MyView(_attachedDatabase, alias);
  }

  @override
  SelectStatement? get query => null;
  @override
  Set<String> get readTables => const {'config'};
}

abstract base class _$CustomTablesDb extends GeneratedDatabase {
  _$CustomTablesDb(super.implementation);
  late final NoIds noIds = NoIds();
  late final WithDefaults withDefaults = WithDefaults();
  late final WithConstraints withConstraints = WithConstraints();
  late final ConfigTable config = ConfigTable();
  late final Index valueIdx = Index.byDialect('value_idx', {
    SqlDialect.sqlite:
        'CREATE INDEX IF NOT EXISTS value_idx ON config (config_value)',
  });
  late final Mytable mytable = Mytable();
  late final Email email = Email();
  late final WeirdTable weirdTable = WeirdTable();
  late final Trigger myTrigger = Trigger.byDialect('my_trigger', {
    SqlDialect.sqlite:
        'CREATE TRIGGER my_trigger AFTER INSERT ON config BEGIN INSERT INTO with_defaults VALUES (new.config_key, LENGTH(new.config_value));END',
  });
  late final MyView myView = MyView(this);
  Future<int> writeConfig({required String key, DriftAny? value}) {
    return customInsert(
      'REPLACE INTO config (config_key, config_value) VALUES (?1, ?2)',
      variables: [
        Variable<String>(key),
        Variable<DriftAny>(value, (_) => SqliteDialect)
      ],
      updates: {config},
    );
  }

  Selectable<Config> readConfig(String var1) {
    return customSelectMapped<Config>(
        query:
            'SELECT config_key AS ck, config_value AS cf, sync_state AS cs1, sync_state_implicit AS cs2 FROM config WHERE config_key = ?1',
        variables: [Variable<String>(var1)],
        readsFrom: {
          config,
        },
        createMapper: (DriftResultSet resultSet) {
          final map_0 = config.createMapperFromPositions(const [
            (index: 0, name: 'ck'),
            (index: 1, name: 'cf'),
            (index: 2, name: 'cs1'),
            (index: 3, name: 'cs2'),
          ]);

          return (DriftRow row) => map_0(row)!;
        });
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
    return customSelectMapped<Config>(
        query:
            'SELECT config_key AS _c0, config_value AS _c1, sync_state AS _c2, sync_state_implicit AS _c3 FROM config WHERE config_key IN ($expandedvar1) ${generatedclause.sql}',
        variables: [
          for (var $ in var1) Variable<String>($),
          ...generatedclause.introducedVariables
        ],
        readsFrom: {
          config,
          ...generatedclause.watchedTables,
        },
        createMapper: (DriftResultSet resultSet) {
          final map_0 = config.createMapperFromPositions(const [
            (index: 0, name: '_c0'),
            (index: 1, name: '_c1'),
            (index: 2, name: '_c2'),
            (index: 3, name: '_c3'),
          ]);

          return (DriftRow row) => map_0(row)!;
        });
  }

  Selectable<Config> readDynamic({ReadDynamic$predicate? predicate}) {
    var $arrayStartIndex = 1;
    final generatedpredicate = $write(
        predicate?.call(this.config) ??
            const CustomExpression.dialectSpecific({
              SqlDialect.sqlite: '(TRUE)',
            }),
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedpredicate.amountOfVariables;
    return customSelectMapped<Config>(
        query:
            'SELECT config_key AS _c0, config_value AS _c1, sync_state AS _c2, sync_state_implicit AS _c3 FROM config WHERE ${generatedpredicate.sql}',
        variables: [...generatedpredicate.introducedVariables],
        readsFrom: {
          config,
          ...generatedpredicate.watchedTables,
        },
        createMapper: (DriftResultSet resultSet) {
          final map_0 = config.createMapperFromPositions(const [
            (index: 0, name: '_c0'),
            (index: 1, name: '_c1'),
            (index: 2, name: '_c2'),
            (index: 3, name: '_c3'),
          ]);

          return (DriftRow row) => map_0(row)!;
        });
  }

  Selectable<String> typeConverterVar(SyncType? var1, List<SyncType?> var2,
      {TypeConverterVar$pred? pred}) {
    var $arrayStartIndex = 2;
    final generatedpred = $write(
        pred?.call(this.config) ??
            const CustomExpression.dialectSpecific({
              SqlDialect.sqlite: '(TRUE)',
            }),
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedpred.amountOfVariables;
    final expandedvar2 = $expandVar($arrayStartIndex, var2.length);
    $arrayStartIndex += var2.length;
    return customSelectMapped<String>(
        query:
            'SELECT config_key FROM config WHERE ${generatedpred.sql} AND(sync_state = ?1 OR sync_state_implicit IN ($expandedvar2))',
        variables: [
          Variable<int>(ConfigTable.$convertersyncStaten.toSql(var1)),
          ...generatedpred.introducedVariables,
          for (var $ in var2)
            Variable<int>(ConfigTable.$convertersyncStateImplicitn.toSql($))
        ],
        readsFrom: {
          config,
          ...generatedpred.watchedTables,
        },
        createMapper: (DriftResultSet resultSet) {
          final type$text = dialect.textType;

          return (DriftRow row) => row
              .readWithType(const (index: 0, name: 'config_key'), type$text)!;
        });
  }

  Selectable<JsonResult> tableValued() {
    return customSelectMapped<JsonResult>(
        query:
            'SELECT "key", value FROM config,json_each(config.config_value)WHERE json_valid(config_value)',
        variables: [],
        readsFrom: {
          config,
        },
        createMapper: (DriftResultSet resultSet) {
          final type$text = dialect.textType;

          return (DriftRow row) => JsonResult(
                row: row,
                key:
                    row.readWithType(const (index: 0, name: 'key'), type$text)!,
                value: row
                    .readWithType(const (index: 1, name: 'value'), type$text),
              );
        });
  }

  Selectable<JsonResult> another() {
    return customSelectMapped<JsonResult>(
        query: 'SELECT \'one\' AS "key", NULLIF(\'two\', \'another\') AS value',
        variables: [],
        readsFrom: {},
        createMapper: (DriftResultSet resultSet) {
          final type$text = dialect.textType;

          return (DriftRow row) => JsonResult(
                row: row,
                key:
                    row.readWithType(const (index: 0, name: 'key'), type$text)!,
                value: row
                    .readWithType(const (index: 1, name: 'value'), type$text),
              );
        });
  }

  Selectable<MultipleResult> multiple({required Multiple$predicate predicate}) {
    var $arrayStartIndex = 1;
    final generatedpredicate = $write(
        predicate(
            alias(this.withDefaults, 'd'), alias(this.withConstraints, 'c')),
        hasMultipleTables: true,
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedpredicate.amountOfVariables;
    return customSelectMapped<MultipleResult>(
        query:
            'SELECT d.a AS _c0, d.b AS _c1,"c"."a" AS "nested_0.a", "c"."b" AS "nested_0.b", "c"."c" AS "nested_0.c" FROM with_defaults AS d LEFT OUTER JOIN with_constraints AS c ON d.a = c.a AND d.b = c.b WHERE ${generatedpredicate.sql}',
        variables: [...generatedpredicate.introducedVariables],
        readsFrom: {
          withDefaults,
          withConstraints,
          ...generatedpredicate.watchedTables,
        },
        createMapper: (DriftResultSet resultSet) {
          final type$0 = const CustomTextType();
          final type$int = dialect.intType;
          final map_0 = withConstraints.createMapperFromPositions(const [
            (index: 0, name: 'a'),
            (index: 1, name: 'b'),
            (index: 2, name: 'c'),
          ]);

          return (DriftRow row) => MultipleResult(
                row: row,
                a: row.readWithType(const (index: 0, name: '_c0'), type$0),
                b: row.readWithType(const (index: 1, name: '_c1'), type$int),
                c: map_0(row),
              );
        });
  }

  Selectable<EMail> searchEmails({required String? term}) {
    return customSelectMapped<EMail>(
        query:
            'SELECT sender AS _c0, title AS _c1, body AS _c2 FROM email WHERE email MATCH ?1 ORDER BY rank',
        variables: [Variable<String>(term)],
        readsFrom: {
          email,
        },
        createMapper: (DriftResultSet resultSet) {
          final map_0 = email.createMapperFromPositions(const [
            (index: 0, name: '_c0'),
            (index: 1, name: '_c1'),
            (index: 2, name: '_c2'),
          ]);

          return (DriftRow row) => map_0(row)!;
        });
  }

  Selectable<ReadRowIdResult> readRowId({required ReadRowId$expr expr}) {
    var $arrayStartIndex = 1;
    final generatedexpr =
        $write(expr(this.config), startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedexpr.amountOfVariables;
    return customSelectMapped<ReadRowIdResult>(
        query:
            'SELECT oid, config_key AS _c0, config_value AS _c1, sync_state AS _c2, sync_state_implicit AS _c3 FROM config WHERE _rowid_ = ${generatedexpr.sql}',
        variables: [...generatedexpr.introducedVariables],
        readsFrom: {
          config,
          ...generatedexpr.watchedTables,
        },
        createMapper: (DriftResultSet resultSet) {
          final type$int = dialect.intType;
          final type$text = dialect.textType;
          final type$2 = SqliteDialect;

          return (DriftRow row) => ReadRowIdResult(
                row: row,
                rowid: row
                    .readWithType(const (index: 0, name: 'rowid'), type$int)!,
                configKey:
                    row.readWithType(const (index: 1, name: '_c0'), type$text)!,
                configValue:
                    row.readWithType(const (index: 2, name: '_c1'), type$2),
                syncState: NullAwareTypeConverter.wrapFromSql(
                    ConfigTable.$convertersyncState,
                    row.readWithType(const (index: 3, name: '_c2'), type$int)),
                syncStateImplicit: NullAwareTypeConverter.wrapFromSql(
                    ConfigTable.$convertersyncStateImplicit,
                    row.readWithType(const (index: 4, name: '_c3'), type$int)),
              );
        });
  }

  Selectable<MyViewData> readView({ReadView$where? where}) {
    var $arrayStartIndex = 1;
    final generatedwhere = $write(
        where?.call(this.myView) ??
            const CustomExpression.dialectSpecific({
              SqlDialect.sqlite: '(TRUE)',
            }),
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedwhere.amountOfVariables;
    return customSelectMapped<MyViewData>(
        query:
            'SELECT config_key AS _c0, config_value AS _c1, sync_state AS _c2, sync_state_implicit AS _c3 FROM my_view WHERE ${generatedwhere.sql}',
        variables: [...generatedwhere.introducedVariables],
        readsFrom: {
          config,
          ...generatedwhere.watchedTables,
        },
        createMapper: (DriftResultSet resultSet) {
          final map_0 = myView.createMapperFromPositions(const [
            (index: 0, name: '_c0'),
            (index: 1, name: '_c1'),
            (index: 2, name: '_c2'),
            (index: 3, name: '_c3'),
          ]);

          return (DriftRow row) => map_0(row)!;
        });
  }

  Selectable<int> cfeTest() {
    return customSelectMapped<int>(
        query:
            'WITH RECURSIVE cnt (x) AS (SELECT 1 UNION ALL SELECT x + 1 FROM cnt LIMIT 1000000) SELECT x FROM cnt',
        variables: [],
        readsFrom: {},
        createMapper: (DriftResultSet resultSet) {
          final type$int = dialect.intType;

          return (DriftRow row) =>
              row.readWithType(const (index: 0, name: 'x'), type$int)!;
        });
  }

  Selectable<int?> nullableQuery() {
    return customSelectMapped<int?>(
        query: 'SELECT MAX(oid) AS _c0 FROM config',
        variables: [],
        readsFrom: {
          config,
        },
        createMapper: (DriftResultSet resultSet) {
          final type$int = dialect.intType;

          return (DriftRow row) =>
              row.readWithType(const (index: 0, name: '_c0'), type$int);
        });
  }

  Future<List<Config>> addConfig({required Insertable<Config> value}) {
    var $arrayStartIndex = 1;
    final generatedvalue =
        $writeInsertable(this.config, value, startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedvalue.amountOfVariables;
    return customWriteReturning('INSERT INTO config ${generatedvalue.sql} RETURNING *',
        variables: [
          ...generatedvalue.introducedVariables
        ],
        updates: {
          config
        }).then((rows) => rows.map((DriftResultSet resultSet) {
          final map_0 = config.createMapperFromPositions(const [
            (index: 0, name: 'config_key'),
            (index: 1, name: 'config_value'),
            (index: 2, name: 'sync_state'),
            (index: 3, name: 'sync_state_implicit'),
          ]);

          return (DriftRow row) => map_0(row)!;
        }).toList());
  }

  Selectable<NestedResult> nested(String? var1) {
    return customSelectMapped<NestedResult>(
        query:
            'SELECT"defaults"."a" AS "nested_0.a", "defaults"."b" AS "nested_0.b", defaults.b AS "\$n_0" FROM with_defaults AS defaults WHERE a = ?1',
        variables: [Variable<String>(var1, (_) => const CustomTextType())],
        readsFrom: {
          withConstraints,
          withDefaults,
        },
        createMapper: (DriftResultSet resultSet) {
          final map_0 = withDefaults.createMapperFromPositions(const [
            (index: 0, name: 'a'),
            (index: 1, name: 'b'),
          ]);

          return (DriftRow row) => NestedResult(
                row: row,
                defaults: map_0(row)!,
                nestedQuery1: throw 'todo',
              );
        });
  }

  Selectable<MyCustomResultClass> customResult() {
    return customSelectMapped<MyCustomResultClass>(
        query:
            'SELECT with_constraints.b, config.sync_state,"config"."config_key" AS "nested_0.config_key", "config"."config_value" AS "nested_0.config_value", "config"."sync_state" AS "nested_0.sync_state", "config"."sync_state_implicit" AS "nested_0.sync_state_implicit","no_ids"."payload" AS "nested_1.payload" FROM with_constraints INNER JOIN config ON config_key = with_constraints.a CROSS JOIN no_ids',
        variables: [],
        readsFrom: {
          withConstraints,
          config,
          noIds,
        },
        createMapper: (DriftResultSet resultSet) {
          final type$int = dialect.intType;
          final map_0 = config.createMapperFromPositions(const [
            (index: 0, name: 'config_key'),
            (index: 1, name: 'config_value'),
            (index: 2, name: 'sync_state'),
            (index: 3, name: 'sync_state_implicit'),
          ]);
          final map_1 = noIds.createMapperFromPositions(const [
            (index: 0, name: 'payload'),
          ]);

          return (DriftRow row) => MyCustomResultClass(
                row.readWithType(const (index: 0, name: 'b'), type$int)!,
                syncState: NullAwareTypeConverter.wrapFromSql(
                    ConfigTable.$convertersyncState,
                    row.readWithType(
                        const (index: 1, name: 'sync_state'), type$int)),
                config: map_0(row)!,
                noIds: map_1(row)!,
                nested: throw 'todo',
              );
        });
  }

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
        OnCreateQuery.byDialect({
          SqlDialect.sqlite:
              'INSERT INTO config (config_key, config_value) VALUES (\'key\', \'values\')',
        })
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
}

typedef ReadMultiple$clause = OrderBy Function(ConfigTable config);
typedef ReadDynamic$predicate = Expression<bool> Function(ConfigTable config);
typedef TypeConverterVar$pred = Expression<bool> Function(ConfigTable config);

class JsonResult extends CustomResultSet {
  final String key;
  final String? value;
  JsonResult({
    required DriftRow row,
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
    required DriftRow row,
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
    required DriftRow row,
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
    required DriftRow row,
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
