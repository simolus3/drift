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
    sqlType: BuiltinDriftType.byteArray,
    requiredDuringInsert: true,
    constraints: () => [ColumnConstraint.customSql('NOT NULL PRIMARY KEY')],
  )..owningResultSet = this;
  @override
  List<TableColumn> get columns => [payload];
  @override
  String get entityName => $name;
  static const String $name = 'no_ids';
  @override
  NoIds asSelfType() => this;

  @override
  NoIdRow? Function(RawRow) createMapperFromPositions(
    DriftDialect dialect,
    List<ColumnPosition> positions,
  ) {
    final pos$payload = positions[0].index;
    final type$0 = BuiltinDriftType.byteArray.resolveIn(dialect);
    return (RawRow row) {
      // Not part of row if non-nullable column "payload" is missing
      if (row[pos$payload] == null) {
        return null;
      }
      return NoIdRow(type$0.dartValue(row[pos$payload]!));
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
  const NoIdsCompanion({this.payload = const Value.absent()});
  NoIdsCompanion.insert({required Uint8List payload})
    : payload = Value(payload);
  static Insertable<NoIdRow> custom({Expression<Uint8List>? payload}) {
    return RawValuesInsertable({if (payload != null) 'payload': payload});
  }

  NoIdsCompanion copyWith({Value<Uint8List>? payload}) {
    return NoIdsCompanion(payload: payload ?? this.payload);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (payload.present) {
      map['payload'] = Variable<Uint8List>(
        payload.value,
        BuiltinDriftType.byteArray,
      );
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
    sqlType: const CustomTextType(),
    requiredDuringInsert: false,
    constraints: () => [ColumnConstraint.customSql('DEFAULT \'something\'')],
  )..owningResultSet = this;
  late final TableColumn<int> b = TableColumn<int>(
    name: 'b',
    sqlType: BuiltinDriftType.int,
    requiredDuringInsert: false,
    constraints: () => [ColumnConstraint.customSql('UNIQUE NULL')],
  )..owningResultSet = this;
  @override
  List<TableColumn> get columns => [a, b];
  @override
  String get entityName => $name;
  static const String $name = 'with_defaults';
  @override
  WithDefaults asSelfType() => this;

  @override
  WithDefault? Function(RawRow) createMapperFromPositions(
    DriftDialect dialect,
    List<ColumnPosition> positions,
  ) {
    final pos$a = positions[0].index;
    final type$0 = const CustomTextType().resolveIn(dialect);
    final pos$b = positions[1].index;
    final type$1 = BuiltinDriftType.int.resolveIn(dialect);
    return (RawRow row) {
      return WithDefault(
        a: type$0.nullableDartValue(row[pos$a]),
        b: type$1.nullableDartValue(row[pos$b]),
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
      map['a'] = Variable<String>(a, const CustomTextType());
    }
    if (!nullToAbsent || b != null) {
      map['b'] = Variable<int>(b, BuiltinDriftType.int);
    }
    return map;
  }

  WithDefaultsCompanion toCompanion(bool nullToAbsent) {
    return WithDefaultsCompanion(
      a: a == null && nullToAbsent ? const Value.absent() : Value(a),
      b: b == null && nullToAbsent ? const Value.absent() : Value(b),
    );
  }

  factory WithDefault.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WithDefault(
      a: serializer.fromJson<String?>(json['customJsonName']),
      b: serializer.fromJson<int?>(json['b']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'customJsonName': serializer.toJson<String?>(a),
      'b': serializer.toJson<int?>(b),
    };
  }

  WithDefault copyWith({
    Value<String?> a = const Value.absent(),
    Value<int?> b = const Value.absent(),
  }) => WithDefault(
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

  WithDefaultsCompanion copyWith({
    Value<String?>? a,
    Value<int?>? b,
    Value<int>? rowid,
  }) {
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
      map['a'] = Variable<String>(a.value, const CustomTextType());
    }
    if (b.present) {
      map['b'] = Variable<int>(b.value, BuiltinDriftType.int);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value, BuiltinDriftType.int);
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
    sqlType: BuiltinDriftType.text,
    requiredDuringInsert: false,
  )..owningResultSet = this;
  late final TableColumn<int> b = TableColumn<int>(
    name: 'b',
    sqlType: BuiltinDriftType.int,
    requiredDuringInsert: true,
    constraints: () => [ColumnConstraint.customSql('NOT NULL')],
  )..owningResultSet = this;
  late final TableColumn<double> c = TableColumn<double>(
    name: 'c',
    sqlType: BuiltinDriftType.double,
    requiredDuringInsert: false,
  )..owningResultSet = this;
  @override
  List<TableColumn> get columns => [a, b, c];
  @override
  String get entityName => $name;
  static const String $name = 'with_constraints';
  @override
  WithConstraints asSelfType() => this;

  @override
  WithConstraint? Function(RawRow) createMapperFromPositions(
    DriftDialect dialect,
    List<ColumnPosition> positions,
  ) {
    final pos$a = positions[0].index;
    final type$0 = BuiltinDriftType.text.resolveIn(dialect);
    final pos$b = positions[1].index;
    final type$1 = BuiltinDriftType.int.resolveIn(dialect);
    final pos$c = positions[2].index;
    final type$2 = BuiltinDriftType.double.resolveIn(dialect);
    return (RawRow row) {
      // Not part of row if non-nullable column "b" is missing
      if (row[pos$b] == null) {
        return null;
      }
      return WithConstraint(
        a: type$0.nullableDartValue(row[pos$a]),
        b: type$1.dartValue(row[pos$b]!),
        c: type$2.nullableDartValue(row[pos$c]),
      );
    };
  }

  @override
  WithConstraints withAlias(String alias) {
    return WithConstraints(alias);
  }

  @override
  List<String> get customConstraints => const [
    'FOREIGN KEY(a, b)REFERENCES with_defaults(a, b)',
  ];
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
      map['a'] = Variable<String>(a, BuiltinDriftType.text);
    }
    map['b'] = Variable<int>(b, BuiltinDriftType.int);
    if (!nullToAbsent || c != null) {
      map['c'] = Variable<double>(c, BuiltinDriftType.double);
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

  factory WithConstraint.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WithConstraint(
      a: serializer.fromJson<String?>(json['a']),
      b: serializer.fromJson<int>(json['b']),
      c: serializer.fromJson<double?>(json['c']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'a': serializer.toJson<String?>(a),
      'b': serializer.toJson<int>(b),
      'c': serializer.toJson<double?>(c),
    };
  }

  WithConstraint copyWith({
    Value<String?> a = const Value.absent(),
    int? b,
    Value<double?> c = const Value.absent(),
  }) => WithConstraint(
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

  WithConstraintsCompanion copyWith({
    Value<String?>? a,
    Value<int>? b,
    Value<double?>? c,
    Value<int>? rowid,
  }) {
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
      map['a'] = Variable<String>(a.value, BuiltinDriftType.text);
    }
    if (b.present) {
      map['b'] = Variable<int>(b.value, BuiltinDriftType.int);
    }
    if (c.present) {
      map['c'] = Variable<double>(c.value, BuiltinDriftType.double);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value, BuiltinDriftType.int);
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
    sqlType: BuiltinDriftType.text,
    requiredDuringInsert: true,
    constraints: () => [ColumnConstraint.customSql('NOT NULL PRIMARY KEY')],
  )..owningResultSet = this;
  late final TableColumn<DriftAny> configValue = TableColumn<DriftAny>(
    name: 'config_value',
    sqlType: const AnyType(),
    requiredDuringInsert: false,
  )..owningResultSet = this;
  late final TableColumnWithTypeConverter<SyncType?, int> syncState =
      TableColumn<int>(
          name: 'sync_state',
          sqlType: BuiltinDriftType.int,
          requiredDuringInsert: false,
        ).withConverter<SyncType?>(ConfigTable.$convertersyncStaten)
        ..owningResultSet = this;
  late final TableColumnWithTypeConverter<SyncType?, int> syncStateImplicit =
      TableColumn<int>(
          name: 'sync_state_implicit',
          sqlType: BuiltinDriftType.int,
          requiredDuringInsert: false,
        ).withConverter<SyncType?>(ConfigTable.$convertersyncStateImplicitn)
        ..owningResultSet = this;
  @override
  List<TableColumn> get columns => [
    configKey,
    configValue,
    syncState,
    syncStateImplicit,
  ];
  @override
  String get entityName => $name;
  static const String $name = 'config';
  @override
  ConfigTable asSelfType() => this;

  @override
  Config? Function(RawRow) createMapperFromPositions(
    DriftDialect dialect,
    List<ColumnPosition> positions,
  ) {
    final pos$configKey = positions[0].index;
    final type$0 = BuiltinDriftType.text.resolveIn(dialect);
    final pos$configValue = positions[1].index;
    final type$1 = const AnyType().resolveIn(dialect);
    final pos$syncState = positions[2].index;
    final type$2 = BuiltinDriftType.int.resolveIn(dialect);
    final pos$syncStateImplicit = positions[3].index;
    return (RawRow row) {
      // Not part of row if non-nullable column "configKey" is missing
      if (row[pos$configKey] == null) {
        return null;
      }
      return Config(
        configKey: type$0.dartValue(row[pos$configKey]!),
        configValue: type$1.nullableDartValue(row[pos$configValue]),
        syncState: ConfigTable.$convertersyncStaten.fromSql(
          type$2.nullableDartValue(row[pos$syncState]),
        ),
        syncStateImplicit: ConfigTable.$convertersyncStateImplicitn.fromSql(
          type$2.nullableDartValue(row[pos$syncStateImplicit]),
        ),
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
  $convertersyncStateImplicitn = JsonTypeConverter2.asNullable(
    $convertersyncStateImplicit,
  );
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
  const Config({
    required this.configKey,
    this.configValue,
    this.syncState,
    this.syncStateImplicit,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['config_key'] = Variable<String>(configKey, BuiltinDriftType.text);
    if (!nullToAbsent || configValue != null) {
      map['config_value'] = Variable<DriftAny>(configValue, const AnyType());
    }
    if (!nullToAbsent || syncState != null) {
      map['sync_state'] = Variable<int>(
        ConfigTable.$convertersyncStaten.toSql(syncState),
        BuiltinDriftType.int,
      );
    }
    if (!nullToAbsent || syncStateImplicit != null) {
      map['sync_state_implicit'] = Variable<int>(
        ConfigTable.$convertersyncStateImplicitn.toSql(syncStateImplicit),
        BuiltinDriftType.int,
      );
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

  factory Config.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Config(
      configKey: serializer.fromJson<String>(json['config_key']),
      configValue: serializer.fromJson<DriftAny?>(json['config_value']),
      syncState: serializer.fromJson<SyncType?>(json['sync_state']),
      syncStateImplicit: ConfigTable.$convertersyncStateImplicitn.fromJson(
        serializer.fromJson<int?>(json['sync_state_implicit']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'config_key': serializer.toJson<String>(configKey),
      'config_value': serializer.toJson<DriftAny?>(configValue),
      'sync_state': serializer.toJson<SyncType?>(syncState),
      'sync_state_implicit': serializer.toJson<int?>(
        ConfigTable.$convertersyncStateImplicitn.toJson(syncStateImplicit),
      ),
    };
  }

  Config copyWith({
    String? configKey,
    Value<DriftAny?> configValue = const Value.absent(),
    Value<SyncType?> syncState = const Value.absent(),
    Value<SyncType?> syncStateImplicit = const Value.absent(),
  }) => Config(
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
      configValue: data.configValue.present
          ? data.configValue.value
          : this.configValue,
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

  ConfigCompanion copyWith({
    Value<String>? configKey,
    Value<DriftAny?>? configValue,
    Value<SyncType?>? syncState,
    Value<SyncType?>? syncStateImplicit,
    Value<int>? rowid,
  }) {
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
      map['config_key'] = Variable<String>(
        configKey.value,
        BuiltinDriftType.text,
      );
    }
    if (configValue.present) {
      map['config_value'] = Variable<DriftAny>(
        configValue.value,
        const AnyType(),
      );
    }
    if (syncState.present) {
      map['sync_state'] = Variable<int>(
        ConfigTable.$convertersyncStaten.toSql(syncState.value),
        BuiltinDriftType.int,
      );
    }
    if (syncStateImplicit.present) {
      map['sync_state_implicit'] = Variable<int>(
        ConfigTable.$convertersyncStateImplicitn.toSql(syncStateImplicit.value),
        BuiltinDriftType.int,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value, BuiltinDriftType.int);
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
    sqlType: BuiltinDriftType.int,
    requiredDuringInsert: false,
    constraints: () => [ColumnConstraint.customSql('NOT NULL')],
  )..owningResultSet = this;
  late final TableColumn<String> sometext = TableColumn<String>(
    name: 'sometext',
    sqlType: BuiltinDriftType.text,
    requiredDuringInsert: false,
  )..owningResultSet = this;
  late final TableColumn<bool> isInserting = TableColumn<bool>(
    name: 'is_inserting',
    sqlType: BuiltinDriftType.bool,
    requiredDuringInsert: false,
  )..owningResultSet = this;
  late final TableColumn<DateTime> somedate = TableColumn<DateTime>(
    name: 'somedate',
    sqlType: BuiltinDriftType.dateTime,
    requiredDuringInsert: false,
  )..owningResultSet = this;
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
  MytableData? Function(RawRow) createMapperFromPositions(
    DriftDialect dialect,
    List<ColumnPosition> positions,
  ) {
    final pos$someid = positions[0].index;
    final type$0 = BuiltinDriftType.int.resolveIn(dialect);
    final pos$sometext = positions[1].index;
    final type$1 = BuiltinDriftType.text.resolveIn(dialect);
    final pos$isInserting = positions[2].index;
    final type$2 = BuiltinDriftType.bool.resolveIn(dialect);
    final pos$somedate = positions[3].index;
    final type$3 = BuiltinDriftType.dateTime.resolveIn(dialect);
    return (RawRow row) {
      // Not part of row if non-nullable column "someid" is missing
      if (row[pos$someid] == null) {
        return null;
      }
      return MytableData(
        someid: type$0.dartValue(row[pos$someid]!),
        sometext: type$1.nullableDartValue(row[pos$sometext]),
        isInserting: type$2.nullableDartValue(row[pos$isInserting]),
        somedate: type$3.nullableDartValue(row[pos$somedate]),
      );
    };
  }

  @override
  Mytable withAlias(String alias) {
    return Mytable(alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(someid DESC)',
    'UNIQUE(sometext, is_inserting)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class MytableData extends LegacyDataClass implements Insertable<MytableData> {
  final int someid;
  final String? sometext;
  final bool? isInserting;
  final DateTime? somedate;
  const MytableData({
    required this.someid,
    this.sometext,
    this.isInserting,
    this.somedate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['someid'] = Variable<int>(someid, BuiltinDriftType.int);
    if (!nullToAbsent || sometext != null) {
      map['sometext'] = Variable<String>(sometext, BuiltinDriftType.text);
    }
    if (!nullToAbsent || isInserting != null) {
      map['is_inserting'] = Variable<bool>(isInserting, BuiltinDriftType.bool);
    }
    if (!nullToAbsent || somedate != null) {
      map['somedate'] = Variable<DateTime>(somedate, BuiltinDriftType.dateTime);
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

  factory MytableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MytableData(
      someid: serializer.fromJson<int>(json['someid']),
      sometext: serializer.fromJson<String?>(json['sometext']),
      isInserting: serializer.fromJson<bool?>(json['is_inserting']),
      somedate: serializer.fromJson<DateTime?>(json['somedate']),
    );
  }
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

  MytableData copyWith({
    int? someid,
    Value<String?> sometext = const Value.absent(),
    Value<bool?> isInserting = const Value.absent(),
    Value<DateTime?> somedate = const Value.absent(),
  }) => MytableData(
    someid: someid ?? this.someid,
    sometext: sometext.present ? sometext.value : this.sometext,
    isInserting: isInserting.present ? isInserting.value : this.isInserting,
    somedate: somedate.present ? somedate.value : this.somedate,
  );
  MytableData copyWithCompanion(MytableCompanion data) {
    return MytableData(
      someid: data.someid.present ? data.someid.value : this.someid,
      sometext: data.sometext.present ? data.sometext.value : this.sometext,
      isInserting: data.isInserting.present
          ? data.isInserting.value
          : this.isInserting,
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

  MytableCompanion copyWith({
    Value<int>? someid,
    Value<String?>? sometext,
    Value<bool?>? isInserting,
    Value<DateTime?>? somedate,
  }) {
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
      map['someid'] = Variable<int>(someid.value, BuiltinDriftType.int);
    }
    if (sometext.present) {
      map['sometext'] = Variable<String>(sometext.value, BuiltinDriftType.text);
    }
    if (isInserting.present) {
      map['is_inserting'] = Variable<bool>(
        isInserting.value,
        BuiltinDriftType.bool,
      );
    }
    if (somedate.present) {
      map['somedate'] = Variable<DateTime>(
        somedate.value,
        BuiltinDriftType.dateTime,
      );
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
    sqlType: BuiltinDriftType.text,
    requiredDuringInsert: true,
    constraints: () => [const ColumnNotNullConstraint()],
  )..owningResultSet = this;
  late final TableColumn<String> title = TableColumn<String>(
    name: 'title',
    sqlType: BuiltinDriftType.text,
    requiredDuringInsert: true,
    constraints: () => [const ColumnNotNullConstraint()],
  )..owningResultSet = this;
  late final TableColumn<String> body = TableColumn<String>(
    name: 'body',
    sqlType: BuiltinDriftType.text,
    requiredDuringInsert: true,
    constraints: () => [const ColumnNotNullConstraint()],
  )..owningResultSet = this;
  @override
  List<TableColumn> get columns => [sender, title, body];
  @override
  String get entityName => $name;
  static const String $name = 'email';
  @override
  Email asSelfType() => this;

  @override
  EMail? Function(RawRow) createMapperFromPositions(
    DriftDialect dialect,
    List<ColumnPosition> positions,
  ) {
    final pos$sender = positions[0].index;
    final type$0 = BuiltinDriftType.text.resolveIn(dialect);
    final pos$title = positions[1].index;
    final pos$body = positions[2].index;
    return (RawRow row) {
      // Not part of row if non-nullable column "sender" is missing
      if (row[pos$sender] == null) {
        return null;
      }
      return EMail(
        sender: type$0.dartValue(row[pos$sender]!),
        title: type$0.dartValue(row[pos$title]!),
        body: type$0.dartValue(row[pos$body]!),
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
    map['sender'] = Variable<String>(sender, BuiltinDriftType.text);
    map['title'] = Variable<String>(title, BuiltinDriftType.text);
    map['body'] = Variable<String>(body, BuiltinDriftType.text);
    return map;
  }

  EmailCompanion toCompanion(bool nullToAbsent) {
    return EmailCompanion(
      sender: Value(sender),
      title: Value(title),
      body: Value(body),
    );
  }

  factory EMail.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EMail(
      sender: serializer.fromJson<String>(json['sender']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
    );
  }
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
  }) : sender = Value(sender),
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

  EmailCompanion copyWith({
    Value<String>? sender,
    Value<String>? title,
    Value<String>? body,
    Value<int>? rowid,
  }) {
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
      map['sender'] = Variable<String>(sender.value, BuiltinDriftType.text);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value, BuiltinDriftType.text);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value, BuiltinDriftType.text);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value, BuiltinDriftType.int);
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
    sqlType: BuiltinDriftType.int,
    requiredDuringInsert: true,
    constraints: () => [ColumnConstraint.customSql('NOT NULL')],
  )..owningResultSet = this;
  late final TableColumn<String> textColumn = TableColumn<String>(
    name: 'text',
    sqlType: BuiltinDriftType.text,
    requiredDuringInsert: true,
    constraints: () => [ColumnConstraint.customSql('NOT NULL')],
  )..owningResultSet = this;
  @override
  List<TableColumn> get columns => [sqlClass, textColumn];
  @override
  String get entityName => $name;
  static const String $name = 'Expression';
  @override
  WeirdTable asSelfType() => this;

  @override
  WeirdData? Function(RawRow) createMapperFromPositions(
    DriftDialect dialect,
    List<ColumnPosition> positions,
  ) {
    final pos$sqlClass = positions[0].index;
    final type$0 = BuiltinDriftType.int.resolveIn(dialect);
    final pos$textColumn = positions[1].index;
    final type$1 = BuiltinDriftType.text.resolveIn(dialect);
    return (RawRow row) {
      // Not part of row if non-nullable column "sqlClass" is missing
      if (row[pos$sqlClass] == null) {
        return null;
      }
      return WeirdData(
        sqlClass: type$0.dartValue(row[pos$sqlClass]!),
        textColumn: type$1.dartValue(row[pos$textColumn]!),
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
    map['class'] = Variable<int>(sqlClass, BuiltinDriftType.int);
    map['text'] = Variable<String>(textColumn, BuiltinDriftType.text);
    return map;
  }

  WeirdTableCompanion toCompanion(bool nullToAbsent) {
    return WeirdTableCompanion(
      sqlClass: Value(sqlClass),
      textColumn: Value(textColumn),
    );
  }

  factory WeirdData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeirdData(
      sqlClass: serializer.fromJson<int>(json['class']),
      textColumn: serializer.fromJson<String>(json['text']),
    );
  }
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
      textColumn: data.textColumn.present
          ? data.textColumn.value
          : this.textColumn,
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
  }) : sqlClass = Value(sqlClass),
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

  WeirdTableCompanion copyWith({
    Value<int>? sqlClass,
    Value<String>? textColumn,
    Value<int>? rowid,
  }) {
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
      map['class'] = Variable<int>(sqlClass.value, BuiltinDriftType.int);
    }
    if (textColumn.present) {
      map['text'] = Variable<String>(textColumn.value, BuiltinDriftType.text);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value, BuiltinDriftType.int);
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
  const MyViewData({
    required this.configKey,
    this.configValue,
    this.syncState,
    this.syncStateImplicit,
  });
  factory MyViewData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MyViewData(
      configKey: serializer.fromJson<String>(json['config_key']),
      configValue: serializer.fromJson<DriftAny?>(json['config_value']),
      syncState: serializer.fromJson<SyncType?>(json['sync_state']),
      syncStateImplicit: ConfigTable.$convertersyncStateImplicitn.fromJson(
        serializer.fromJson<int?>(json['sync_state_implicit']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'config_key': serializer.toJson<String>(configKey),
      'config_value': serializer.toJson<DriftAny?>(configValue),
      'sync_state': serializer.toJson<SyncType?>(syncState),
      'sync_state_implicit': serializer.toJson<int?>(
        ConfigTable.$convertersyncStateImplicitn.toJson(syncStateImplicit),
      ),
    };
  }

  MyViewData copyWith({
    String? configKey,
    Value<DriftAny?> configValue = const Value.absent(),
    Value<SyncType?> syncState = const Value.absent(),
    Value<SyncType?> syncStateImplicit = const Value.absent(),
  }) => MyViewData(
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

class MyView
    with ResultSet<MyViewData, MyView>
    implements GeneratedView<MyViewData, MyView> {
  @override
  final String? alias;
  MyView([this.alias]);
  @override
  List<SchemaColumn> get columns => [
    configKey,
    configValue,
    syncState,
    syncStateImplicit,
  ];
  @override
  String get entityName => 'my_view';
  @override
  CustomComponent? get sqlDefinition => CustomComponent(
    'CREATE VIEW my_view AS SELECT * FROM config WHERE sync_state = 2',
    dialectSpecificSql: {},
  );
  @override
  MyView asSelfType() => this;

  @override
  MyViewData? Function(RawRow) createMapperFromPositions(
    DriftDialect dialect,
    List<ColumnPosition> positions,
  ) {
    final pos$configKey = positions[0].index;
    final type$0 = BuiltinDriftType.text.resolveIn(dialect);
    final pos$configValue = positions[1].index;
    final type$1 = const AnyType().resolveIn(dialect);
    final pos$syncState = positions[2].index;
    final type$2 = BuiltinDriftType.int.resolveIn(dialect);
    final pos$syncStateImplicit = positions[3].index;
    return (RawRow row) {
      // Not part of row if non-nullable column "configKey" is missing
      if (row[pos$configKey] == null) {
        return null;
      }
      return MyViewData(
        configKey: type$0.dartValue(row[pos$configKey]!),
        configValue: type$1.nullableDartValue(row[pos$configValue]),
        syncState: ConfigTable.$convertersyncStaten.fromSql(
          type$2.nullableDartValue(row[pos$syncState]),
        ),
        syncStateImplicit: ConfigTable.$convertersyncStateImplicitn.fromSql(
          type$2.nullableDartValue(row[pos$syncStateImplicit]),
        ),
      );
    };
  }

  late final ViewColumn<String> configKey = ViewColumn<String>.forDriftFile(
    name: 'config_key',
    sqlType: BuiltinDriftType.text,
  )..owningResultSet = this;
  late final ViewColumn<DriftAny> configValue =
      ViewColumn<DriftAny>.forDriftFile(
        name: 'config_value',
        sqlType: const AnyType(),
      )..owningResultSet = this;
  late final ViewColumnWithTypeConverter<SyncType?, int> syncState =
      ViewColumn<int>.forDriftFile(
          name: 'sync_state',
          sqlType: BuiltinDriftType.int,
        ).withConverter<SyncType?>(ConfigTable.$convertersyncStaten)
        ..owningResultSet = this;
  late final ViewColumnWithTypeConverter<SyncType?, int> syncStateImplicit =
      ViewColumn<int>.forDriftFile(
          name: 'sync_state_implicit',
          sqlType: BuiltinDriftType.int,
        ).withConverter<SyncType?>(ConfigTable.$convertersyncStateImplicitn)
        ..owningResultSet = this;
  @override
  MyView withAlias(String alias) {
    return MyView(alias);
  }

  @override
  SelectStatement? get query => null;
  @override
  Set<String> get readsFrom => const {'config'};
}

abstract base class _$CustomTablesDb extends GeneratedDatabase {
  _$CustomTablesDb(super.implementation);
  NoIds get noIds => NoIds();
  WithDefaults get withDefaults => WithDefaults();
  WithConstraints get withConstraints => WithConstraints();
  ConfigTable get config => ConfigTable();
  Index get valueIdx => _$valueIdx;
  Mytable get mytable => Mytable();
  Email get email => Email();
  WeirdTable get weirdTable => WeirdTable();
  Trigger get myTrigger => _$myTrigger;
  MyView get myView => MyView();
  @override
  Map<KnownSqlDialect, Object> get dialectOptions => {
    KnownSqlDialect.sqlite: const SqliteOptions(
      strictTablesByDefault: true,
      storeDateTimesAsText: true,
      useBinaryJsonRepresentation: true,
    ),
  };
  Future<int> writeConfig({required String key, DriftAny? value}) {
    return customInsert(
      switch (dialect.known) {
        KnownSqlDialect.sqlite =>
          'REPLACE INTO config (config_key, config_value) VALUES (?1, ?2)',
        KnownSqlDialect.postgres ||
        _ => 'REPLACE INTO config (config_key, config_value) VALUES (\$1, \$2)',
      },
      variables: [
        mapValue(BuiltinDriftType.text, key),
        mapValue(const AnyType(), value),
      ],
      updates: {ConfigTable()},
    );
  }

  Selectable<Config> readConfig(String var1) {
    return customSelectMapped<Config>(
      query: switch (dialect.known) {
        KnownSqlDialect.sqlite =>
          'SELECT config_key AS ck, config_value AS cf, sync_state AS cs1, sync_state_implicit AS cs2 FROM config WHERE config_key = ?1',
        KnownSqlDialect.postgres || _ =>
          'SELECT config_key AS ck, config_value AS cf, sync_state AS cs1, sync_state_implicit AS cs2 FROM config WHERE config_key = \$1',
      },
      variables: [mapValue(BuiltinDriftType.text, var1)],
      readsFrom: {ConfigTable()},
      createMapper: (RawResultSet _) {
        final map_0 = ConfigTable().createMapperFromPositions(dialect, const [
          ColumnPosition(0),
          ColumnPosition(1),
          ColumnPosition(2),
          ColumnPosition(3),
        ]);

        return (RawRow row) => map_0(row)!;
      },
    );
  }

  Selectable<Config> readMultiple(
    List<String> var1, {
    ReadMultiple$clause? clause,
  }) {
    var $arrayStartIndex = 0;
    final expandedvar1 = $expandVar($arrayStartIndex, var1.length);
    $arrayStartIndex += var1.length;
    final generatedclause = $write(
      clause?.call(ConfigTable()) ?? const OrderBy.nothing(),
      startIndex: $arrayStartIndex,
    );
    $arrayStartIndex += generatedclause.variables.length;
    return customSelectMapped<Config>(
      query:
          'SELECT "_s:0".config_key, "_s:0".config_value, "_s:0".sync_state, "_s:0".sync_state_implicit FROM config AS "_s:0" WHERE "_s:0".config_key IN ($expandedvar1) ${generatedclause.buffer}',
      variables: [
        for (var $ in var1) mapValue(BuiltinDriftType.text, $),
        ...generatedclause.variables,
      ],
      readsFrom: {ConfigTable(), ...generatedclause.watchedTables},
      createMapper: (RawResultSet _) {
        final map_0 = ConfigTable().createMapperFromPositions(dialect, const [
          ColumnPosition(0),
          ColumnPosition(1),
          ColumnPosition(2),
          ColumnPosition(3),
        ]);

        return (RawRow row) => map_0(row)!;
      },
    );
  }

  Selectable<Config> readDynamic({ReadDynamic$predicate? predicate}) {
    var $arrayStartIndex = 0;
    final generatedpredicate = $write(
      predicate?.call(ConfigTable()) ??
          const Expression.customComponent(
            CustomComponent('(TRUE)', dialectSpecificSql: {}),
          ),
      startIndex: $arrayStartIndex,
    );
    $arrayStartIndex += generatedpredicate.variables.length;
    return customSelectMapped<Config>(
      query:
          'SELECT "_s:0".config_key, "_s:0".config_value, "_s:0".sync_state, "_s:0".sync_state_implicit FROM config AS "_s:0" WHERE ${generatedpredicate.buffer}',
      variables: [...generatedpredicate.variables],
      readsFrom: {ConfigTable(), ...generatedpredicate.watchedTables},
      createMapper: (RawResultSet _) {
        final map_0 = ConfigTable().createMapperFromPositions(dialect, const [
          ColumnPosition(0),
          ColumnPosition(1),
          ColumnPosition(2),
          ColumnPosition(3),
        ]);

        return (RawRow row) => map_0(row)!;
      },
    );
  }

  Selectable<String> typeConverterVar(
    SyncType? var1,
    List<SyncType?> var2, {
    TypeConverterVar$pred? pred,
  }) {
    var $arrayStartIndex = 1;
    final generatedpred = $write(
      pred?.call(ConfigTable()) ??
          const Expression.customComponent(
            CustomComponent('(TRUE)', dialectSpecificSql: {}),
          ),
      startIndex: $arrayStartIndex,
    );
    $arrayStartIndex += generatedpred.variables.length;
    final expandedvar2 = $expandVar($arrayStartIndex, var2.length);
    $arrayStartIndex += var2.length;
    return customSelectMapped<String>(
      query: switch (dialect.known) {
        KnownSqlDialect.sqlite =>
          'SELECT config_key FROM config WHERE ${generatedpred.buffer} AND(sync_state = ?1 OR sync_state_implicit IN ($expandedvar2))',
        KnownSqlDialect.postgres || _ =>
          'SELECT config_key FROM config WHERE ${generatedpred.buffer} AND(sync_state = \$1 OR sync_state_implicit IN ($expandedvar2))',
      },
      variables: [
        mapValue(
          BuiltinDriftType.int,
          ConfigTable.$convertersyncStaten.toSql(var1),
        ),
        ...generatedpred.variables,
        for (var $ in var2)
          mapValue(
            BuiltinDriftType.int,
            ConfigTable.$convertersyncStateImplicitn.toSql($),
          ),
      ],
      readsFrom: {ConfigTable(), ...generatedpred.watchedTables},
      createMapper: (RawResultSet _) {
        final type$0 = BuiltinDriftType.text.resolveIn(dialect);

        return (RawRow row) => type$0.dartValue(row[0]!);
      },
    );
  }

  Selectable<JsonResult> tableValued() {
    return customSelectMapped<JsonResult>(
      query:
          'SELECT "key", value FROM config,json_each(config.config_value)WHERE json_valid(config_value)',
      variables: [],
      readsFrom: {ConfigTable()},
      createMapper: (RawResultSet _) {
        final type$0 = BuiltinDriftType.text.resolveIn(dialect);

        return (RawRow row) => JsonResult(
          row: row,
          key: type$0.dartValue(row[0]!),
          value: type$0.nullableDartValue(row[1]),
        );
      },
    );
  }

  Selectable<JsonResult> another() {
    return customSelectMapped<JsonResult>(
      query: 'SELECT \'one\' AS "key", NULLIF(\'two\', \'another\') AS value',
      variables: [],
      readsFrom: {},
      createMapper: (RawResultSet _) {
        final type$0 = BuiltinDriftType.text.resolveIn(dialect);

        return (RawRow row) => JsonResult(
          row: row,
          key: type$0.dartValue(row[0]!),
          value: type$0.nullableDartValue(row[1]),
        );
      },
    );
  }

  Selectable<MultipleResult> multiple({required Multiple$predicate predicate}) {
    var $arrayStartIndex = 0;
    final generatedpredicate = $write(
      predicate(alias(WithDefaults(), 'd'), alias(WithConstraints(), 'c')),
      hasMultipleTables: true,
      startIndex: $arrayStartIndex,
    );
    $arrayStartIndex += generatedpredicate.variables.length;
    return customSelectMapped<MultipleResult>(
      query:
          'SELECT d.a, d.b,"c"."a", "c"."b", "c"."c" FROM with_defaults AS d LEFT OUTER JOIN with_constraints AS c ON d.a = c.a AND d.b = c.b WHERE ${generatedpredicate.buffer}',
      variables: [...generatedpredicate.variables],
      readsFrom: {
        WithDefaults(),
        WithConstraints(),
        ...generatedpredicate.watchedTables,
      },
      createMapper: (RawResultSet _) {
        final type$0 = const CustomTextType().resolveIn(dialect);
        final type$1 = BuiltinDriftType.int.resolveIn(dialect);
        final map_0 = WithConstraints().createMapperFromPositions(
          dialect,
          const [ColumnPosition(2), ColumnPosition(3), ColumnPosition(4)],
        );

        return (RawRow row) => MultipleResult(
          row: row,
          a: type$0.nullableDartValue(row[0]),
          b: type$1.nullableDartValue(row[1]),
          c: map_0(row),
        );
      },
    );
  }

  Selectable<EMail> searchEmails({required String? term}) {
    return customSelectMapped<EMail>(
      query: switch (dialect.known) {
        KnownSqlDialect.sqlite =>
          'SELECT "_s:0".sender, "_s:0".title, "_s:0".body FROM email AS "_s:0" WHERE "_s:0".email MATCH ?1 ORDER BY "_s:0".rank',
        KnownSqlDialect.postgres || _ =>
          'SELECT "_s:0".sender, "_s:0".title, "_s:0".body FROM email AS "_s:0" WHERE "_s:0".email MATCH \$1 ORDER BY "_s:0".rank',
      },
      variables: [mapValue(BuiltinDriftType.text, term)],
      readsFrom: {Email()},
      createMapper: (RawResultSet _) {
        final map_0 = Email().createMapperFromPositions(dialect, const [
          ColumnPosition(0),
          ColumnPosition(1),
          ColumnPosition(2),
        ]);

        return (RawRow row) => map_0(row)!;
      },
    );
  }

  Selectable<ReadRowIdResult> readRowId({required ReadRowId$expr expr}) {
    var $arrayStartIndex = 0;
    final generatedexpr = $write(
      expr(ConfigTable()),
      startIndex: $arrayStartIndex,
    );
    $arrayStartIndex += generatedexpr.variables.length;
    return customSelectMapped<ReadRowIdResult>(
      query:
          'SELECT oid, "_s:0".config_key, "_s:0".config_value, "_s:0".sync_state, "_s:0".sync_state_implicit FROM config AS "_s:0" WHERE _rowid_ = ${generatedexpr.buffer}',
      variables: [...generatedexpr.variables],
      readsFrom: {ConfigTable(), ...generatedexpr.watchedTables},
      createMapper: (RawResultSet _) {
        final type$0 = BuiltinDriftType.int.resolveIn(dialect);
        final type$1 = BuiltinDriftType.text.resolveIn(dialect);
        final type$2 = const AnyType().resolveIn(dialect);

        return (RawRow row) => ReadRowIdResult(
          row: row,
          rowid: type$0.dartValue(row[0]!),
          configKey: type$1.dartValue(row[1]!),
          configValue: type$2.nullableDartValue(row[2]),
          syncState: NullAwareTypeConverter.wrapFromSql(
            ConfigTable.$convertersyncState,
            type$0.nullableDartValue(row[3]),
          ),
          syncStateImplicit: NullAwareTypeConverter.wrapFromSql(
            ConfigTable.$convertersyncStateImplicit,
            type$0.nullableDartValue(row[4]),
          ),
        );
      },
    );
  }

  Selectable<MyViewData> readView({ReadView$where? where}) {
    var $arrayStartIndex = 0;
    final generatedwhere = $write(
      where?.call(MyView()) ??
          const Expression.customComponent(
            CustomComponent('(TRUE)', dialectSpecificSql: {}),
          ),
      startIndex: $arrayStartIndex,
    );
    $arrayStartIndex += generatedwhere.variables.length;
    return customSelectMapped<MyViewData>(
      query:
          'SELECT "_s:0".config_key, "_s:0".config_value, "_s:0".sync_state, "_s:0".sync_state_implicit FROM my_view AS "_s:0" WHERE ${generatedwhere.buffer}',
      variables: [...generatedwhere.variables],
      readsFrom: {ConfigTable(), ...generatedwhere.watchedTables},
      createMapper: (RawResultSet _) {
        final map_0 = MyView().createMapperFromPositions(dialect, const [
          ColumnPosition(0),
          ColumnPosition(1),
          ColumnPosition(2),
          ColumnPosition(3),
        ]);

        return (RawRow row) => map_0(row)!;
      },
    );
  }

  Selectable<int> cfeTest() {
    return customSelectMapped<int>(
      query:
          'WITH RECURSIVE cnt (x) AS (SELECT 1 UNION ALL SELECT x + 1 FROM cnt LIMIT 1000000) SELECT x FROM cnt',
      variables: [],
      readsFrom: {},
      createMapper: (RawResultSet _) {
        final type$0 = BuiltinDriftType.int.resolveIn(dialect);

        return (RawRow row) => type$0.dartValue(row[0]!);
      },
    );
  }

  Selectable<int?> nullableQuery() {
    return customSelectMapped<int?>(
      query: 'SELECT MAX(oid) FROM config',
      variables: [],
      readsFrom: {ConfigTable()},
      createMapper: (RawResultSet _) {
        final type$0 = BuiltinDriftType.int.resolveIn(dialect);

        return (RawRow row) => type$0.nullableDartValue(row[0]);
      },
    );
  }

  Future<List<Config>> addConfig({required Insertable<Config> value}) {
    var $arrayStartIndex = 0;
    final generatedvalue = $writeInsertable(
      this.config,
      value,
      startIndex: $arrayStartIndex,
    );
    $arrayStartIndex += generatedvalue.variables.length;
    return customWriteReturning(
      'INSERT INTO config ${generatedvalue.buffer} RETURNING *',
      variables: [...generatedvalue.variables],
      updates: {ConfigTable()},
    ).then((rows) {
      final map_0 = ConfigTable().createMapperFromPositions(dialect, const [
        ColumnPosition(0),
        ColumnPosition(1),
        ColumnPosition(2),
        ColumnPosition(3),
      ]);

      return rows.map((row) => map_0(row)!).toList();
    });
  }

  Future<int> updateAll({
    required Insertable<Config> all,
    required UpdateAll$key key,
  }) {
    var $arrayStartIndex = 0;
    final generatedall = $writeUpdateInsertable(
      this.config,
      all,
      startIndex: $arrayStartIndex,
    );
    $arrayStartIndex += generatedall.variables.length;
    final generatedkey = $write(
      key(ConfigTable()),
      startIndex: $arrayStartIndex,
    );
    $arrayStartIndex += generatedkey.variables.length;
    return customUpdate(
      'UPDATE config SET ${generatedall.buffer} WHERE ${generatedkey.buffer}',
      variables: [...generatedall.variables, ...generatedkey.variables],
      updates: {ConfigTable()},
      updateKind: UpdateKind.update,
    );
  }

  Selectable<NestedResult> nested(String? var1) {
    return customSelectMappedAsync<NestedResult>(
      query: switch (dialect.known) {
        KnownSqlDialect.sqlite =>
          'SELECT"defaults"."a", "defaults"."b", defaults.b AS "\$n_0" FROM with_defaults AS defaults WHERE a = ?1',
        KnownSqlDialect.postgres || _ =>
          'SELECT"defaults"."a", "defaults"."b", defaults.b AS "\$n_0" FROM with_defaults AS defaults WHERE a = \$1',
      },
      variables: [mapValue(const CustomTextType(), var1)],
      readsFrom: {WithConstraints(), WithDefaults()},
      createMapper: (RawResultSet _) {
        final map_0 = WithDefaults().createMapperFromPositions(dialect, const [
          ColumnPosition(0),
          ColumnPosition(1),
        ]);
        final type$0 = BuiltinDriftType.int.resolveIn(dialect);

        return (RawRow row) async => NestedResult(
          row: row,
          defaults: map_0(row)!,
          nestedQuery1: await customSelectMapped<WithConstraint>(
            query: switch (dialect.known) {
              KnownSqlDialect.sqlite =>
                'SELECT * FROM with_constraints AS c WHERE c.b = ?1',
              KnownSqlDialect.postgres ||
              _ => 'SELECT * FROM with_constraints AS c WHERE c.b = \$1',
            },
            variables: [MappedValue.raw(type$0, row[2])],
            readsFrom: {WithConstraints(), WithDefaults()},
            createMapper: (RawResultSet _) {
              final map_0 = WithConstraints().createMapperFromPositions(
                dialect,
                const [ColumnPosition(0), ColumnPosition(1), ColumnPosition(2)],
              );

              return (RawRow row) => map_0(row)!;
            },
          ).get(),
        );
      },
    );
  }

  Selectable<MyCustomResultClass> customResult() {
    return customSelectMappedAsync<MyCustomResultClass>(
      query:
          'SELECT with_constraints.b, config.sync_state,"config"."config_key", "config"."config_value", "config"."sync_state", "config"."sync_state_implicit","no_ids"."payload" FROM with_constraints INNER JOIN config ON config_key = with_constraints.a CROSS JOIN no_ids',
      variables: [],
      readsFrom: {WithConstraints(), ConfigTable(), NoIds()},
      createMapper: (RawResultSet _) {
        final type$0 = BuiltinDriftType.int.resolveIn(dialect);
        final map_0 = ConfigTable().createMapperFromPositions(dialect, const [
          ColumnPosition(2),
          ColumnPosition(3),
          ColumnPosition(4),
          ColumnPosition(5),
        ]);
        final map_1 = NoIds().createMapperFromPositions(dialect, const [
          ColumnPosition(6),
        ]);

        return (RawRow row) async => MyCustomResultClass(
          type$0.dartValue(row[0]!),
          syncState: NullAwareTypeConverter.wrapFromSql(
            ConfigTable.$convertersyncState,
            type$0.nullableDartValue(row[1]),
          ),
          config: map_0(row)!,
          noIds: map_1(row)!,
          nested: await customSelectMapped<Buffer>(
            query: 'SELECT * FROM no_ids',
            variables: [],
            readsFrom: {NoIds()},
            createMapper: (RawResultSet _) {
              final type$0 = BuiltinDriftType.byteArray.resolveIn(dialect);

              return (RawRow row) => Buffer(type$0.dartValue(row[0]!));
            },
          ).get(),
        );
      },
    );
  }

  @override
  DatabaseSchema get schema => _$schema;
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'config',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [TableUpdate('with_defaults', kind: UpdateKind.insert)],
    ),
  ]);
  static final _$valueIdx = Index(
    'value_idx',
    CustomComponent(
      'CREATE INDEX IF NOT EXISTS value_idx ON config (config_value)',
      dialectSpecificSql: {},
    ),
  );
  static final _$myTrigger = Trigger(
    'my_trigger',
    CustomComponent(
      'CREATE TRIGGER my_trigger AFTER INSERT ON config BEGIN INSERT INTO with_defaults VALUES (new.config_key, LENGTH(new.config_value));END',
      dialectSpecificSql: {},
    ),
  );
  static final DatabaseSchema _$schema = DatabaseSchema([
    NoIds(),
    WithDefaults(),
    WithConstraints(),
    ConfigTable(),
    _$valueIdx,
    Mytable(),
    Email(),
    WeirdTable(),
    _$myTrigger,
    MyView(),
    OnCreateQuery(
      CustomComponent(
        'INSERT INTO config (config_key, config_value) VALUES (\'key\', \'values\')',
        dialectSpecificSql: {
          KnownSqlDialect.sqlite:
              'INSERT INTO config (config_key, config_value) VALUES (\'key\', \'values\')',
          KnownSqlDialect.postgres:
              'INSERT INTO config (config_key, config_value) VALUES (\'key\', \'values\')',
        },
      ),
    ),
  ]);
}

typedef ReadMultiple$clause = OrderBy Function(ConfigTable config);
typedef ReadDynamic$predicate = Expression<bool> Function(ConfigTable config);
typedef TypeConverterVar$pred = Expression<bool> Function(ConfigTable config);

final class JsonResult extends CustomResultSet {
  final String key;
  final String? value;
  JsonResult({required RawRow row, required this.key, this.value}) : super(row);
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

final class MultipleResult extends CustomResultSet {
  final String? a;
  final int? b;
  final WithConstraint? c;
  MultipleResult({required RawRow row, this.a, this.b, this.c}) : super(row);
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

typedef Multiple$predicate =
    Expression<bool> Function(WithDefaults d, WithConstraints c);

final class ReadRowIdResult extends CustomResultSet {
  final int rowid;
  final String configKey;
  final DriftAny? configValue;
  final SyncType? syncState;
  final SyncType? syncStateImplicit;
  ReadRowIdResult({
    required RawRow row,
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
typedef UpdateAll$key = Expression<bool> Function(ConfigTable config);

final class NestedResult extends CustomResultSet {
  final WithDefault defaults;
  final List<WithConstraint> nestedQuery1;
  NestedResult({
    required RawRow row,
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
