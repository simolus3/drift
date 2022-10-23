// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_tables.dart';

class NoIdsCompanion extends UpdateCompanion<NoIdRow> {
final Value<Uint8List> payload;
const NoIdsCompanion({this.payload = const Value.absent(),});
NoIdsCompanion.insert({required Uint8List payload,}): payload = Value(payload);
static Insertable<NoIdRow> custom({Expression<Uint8List>? payload, 
}) {
return RawValuesInsertable({if (payload != null)'payload': payload,});
}NoIdsCompanion copyWith({Value<Uint8List>? payload}) {
return NoIdsCompanion(payload: payload ?? this.payload,);
}
@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};if (payload.present) {map['payload'] = Variable<Uint8List>(payload.value);}return map; 
}
@override
String toString() {return (StringBuffer('NoIdsCompanion(')..write('payload: $payload')..write(')')).toString();}
}
class $NoIdsTable extends Table with TableInfo<$NoIdsTable, NoIdRow> {
@override final GeneratedDatabase attachedDatabase;
final String? _alias;
$NoIdsTable(this.attachedDatabase, [this._alias]);
final VerificationMeta _payloadMeta = const VerificationMeta('payload');
late final GeneratedColumn<Uint8List> payload = GeneratedColumn<Uint8List>('payload', aliasedName, false, type: DriftSqlType.blob, requiredDuringInsert: true);
@override
List<GeneratedColumn> get $columns => [payload];
@override
String get aliasedName => _alias ?? 'no_ids';
@override
 String get actualTableName => 'no_ids';
@override
VerificationContext validateIntegrity(Insertable<NoIdRow> instance, {bool isInserting = false}) {
final context = VerificationContext();
final data = instance.toColumns(true);
if (data.containsKey('payload')) {
context.handle(_payloadMeta, payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));} else if (isInserting) {
context.missing(_payloadMeta);
}
return context;
}
@override
Set<GeneratedColumn> get $primaryKey => const <GeneratedColumn>{};@override NoIdRow map(Map<String, dynamic> data, {String? tablePrefix})  {
final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';return NoIdRow(attachedDatabase.options.types.read(DriftSqlType.blob, data['${effectivePrefix}payload'])!, );
}
@override
$NoIdsTable createAlias(String alias) {
return $NoIdsTable(attachedDatabase, alias);}@override
bool get withoutRowId => true;
}class WithDefault extends DataClass implements Insertable<WithDefault> {
final String? a;
final int? b;
const WithDefault({this.a, this.b});@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};if (!nullToAbsent || a != null){map['a'] = Variable<String>(a);}if (!nullToAbsent || b != null){map['b'] = Variable<int>(b);}return map; 
}
WithDefaultsCompanion toCompanion(bool nullToAbsent) {
return WithDefaultsCompanion(a: a == null && nullToAbsent ? const Value.absent() : Value (a),b: b == null && nullToAbsent ? const Value.absent() : Value (b),);
}
factory WithDefault.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return WithDefault(a: serializer.fromJson<String?>(json['a']),b: serializer.fromJson<int?>(json['b']),);}
factory WithDefault.fromJsonString(String encodedJson, {ValueSerializer? serializer}) => WithDefault.fromJson(DataClass.parseJson(encodedJson) as Map<String, dynamic>, serializer: serializer);@override Map<String, dynamic> toJson({ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return <String, dynamic>{
'a': serializer.toJson<String?>(a),'b': serializer.toJson<int?>(b),};}WithDefault copyWith({Value<String?> a = const Value.absent(),Value<int?> b = const Value.absent()}) => WithDefault(a: a.present ? a.value : this.a,b: b.present ? b.value : this.b,);@override
String toString() {return (StringBuffer('WithDefault(')..write('a: $a, ')..write('b: $b')..write(')')).toString();}
@override
 int get hashCode => Object.hash(a, b);@override
bool operator ==(Object other) => identical(this, other) || (other is WithDefault && other.a == this.a && other.b == this.b);
}class WithDefaultsCompanion extends UpdateCompanion<WithDefault> {
final Value<String?> a;
final Value<int?> b;
const WithDefaultsCompanion({this.a = const Value.absent(),this.b = const Value.absent(),});
WithDefaultsCompanion.insert({this.a = const Value.absent(),this.b = const Value.absent(),});
static Insertable<WithDefault> custom({Expression<String>? a, 
Expression<int>? b, 
}) {
return RawValuesInsertable({if (a != null)'a': a,if (b != null)'b': b,});
}WithDefaultsCompanion copyWith({Value<String?>? a, Value<int?>? b}) {
return WithDefaultsCompanion(a: a ?? this.a,b: b ?? this.b,);
}
@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};if (a.present) {map['a'] = Variable<String>(a.value);}if (b.present) {map['b'] = Variable<int>(b.value);}return map; 
}
@override
String toString() {return (StringBuffer('WithDefaultsCompanion(')..write('a: $a, ')..write('b: $b')..write(')')).toString();}
}
class $WithDefaultsTable extends Table with TableInfo<$WithDefaultsTable, WithDefault> {
@override final GeneratedDatabase attachedDatabase;
final String? _alias;
$WithDefaultsTable(this.attachedDatabase, [this._alias]);
final VerificationMeta _aMeta = const VerificationMeta('a');
late final GeneratedColumn<String> a = GeneratedColumn<String>('a', aliasedName, true, type: DriftSqlType.string, requiredDuringInsert: false);
final VerificationMeta _bMeta = const VerificationMeta('b');
late final GeneratedColumn<int> b = GeneratedColumn<int>('b', aliasedName, true, type: DriftSqlType.int, requiredDuringInsert: false);
@override
List<GeneratedColumn> get $columns => [a, b];
@override
String get aliasedName => _alias ?? 'with_defaults';
@override
 String get actualTableName => 'with_defaults';
@override
VerificationContext validateIntegrity(Insertable<WithDefault> instance, {bool isInserting = false}) {
final context = VerificationContext();
final data = instance.toColumns(true);
if (data.containsKey('a')) {
context.handle(_aMeta, a.isAcceptableOrUnknown(data['a']!, _aMeta));}if (data.containsKey('b')) {
context.handle(_bMeta, b.isAcceptableOrUnknown(data['b']!, _bMeta));}return context;
}
@override
Set<GeneratedColumn> get $primaryKey => const <GeneratedColumn>{};@override WithDefault map(Map<String, dynamic> data, {String? tablePrefix})  {
final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';return WithDefault(a: attachedDatabase.options.types.read(DriftSqlType.string, data['${effectivePrefix}a']), b: attachedDatabase.options.types.read(DriftSqlType.int, data['${effectivePrefix}b']), );
}
@override
$WithDefaultsTable createAlias(String alias) {
return $WithDefaultsTable(attachedDatabase, alias);}}class WithConstraint extends DataClass implements Insertable<WithConstraint> {
final String? a;
final int b;
final double? c;
const WithConstraint({this.a, required this.b, this.c});@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};if (!nullToAbsent || a != null){map['a'] = Variable<String>(a);}map['b'] = Variable<int>(b);if (!nullToAbsent || c != null){map['c'] = Variable<double>(c);}return map; 
}
WithConstraintsCompanion toCompanion(bool nullToAbsent) {
return WithConstraintsCompanion(a: a == null && nullToAbsent ? const Value.absent() : Value (a),b: Value (b),c: c == null && nullToAbsent ? const Value.absent() : Value (c),);
}
factory WithConstraint.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return WithConstraint(a: serializer.fromJson<String?>(json['a']),b: serializer.fromJson<int>(json['b']),c: serializer.fromJson<double?>(json['c']),);}
factory WithConstraint.fromJsonString(String encodedJson, {ValueSerializer? serializer}) => WithConstraint.fromJson(DataClass.parseJson(encodedJson) as Map<String, dynamic>, serializer: serializer);@override Map<String, dynamic> toJson({ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return <String, dynamic>{
'a': serializer.toJson<String?>(a),'b': serializer.toJson<int>(b),'c': serializer.toJson<double?>(c),};}WithConstraint copyWith({Value<String?> a = const Value.absent(),int? b,Value<double?> c = const Value.absent()}) => WithConstraint(a: a.present ? a.value : this.a,b: b ?? this.b,c: c.present ? c.value : this.c,);@override
String toString() {return (StringBuffer('WithConstraint(')..write('a: $a, ')..write('b: $b, ')..write('c: $c')..write(')')).toString();}
@override
 int get hashCode => Object.hash(a, b, c);@override
bool operator ==(Object other) => identical(this, other) || (other is WithConstraint && other.a == this.a && other.b == this.b && other.c == this.c);
}class WithConstraintsCompanion extends UpdateCompanion<WithConstraint> {
final Value<String?> a;
final Value<int> b;
final Value<double?> c;
const WithConstraintsCompanion({this.a = const Value.absent(),this.b = const Value.absent(),this.c = const Value.absent(),});
WithConstraintsCompanion.insert({this.a = const Value.absent(),required int b,this.c = const Value.absent(),}): b = Value(b);
static Insertable<WithConstraint> custom({Expression<String>? a, 
Expression<int>? b, 
Expression<double>? c, 
}) {
return RawValuesInsertable({if (a != null)'a': a,if (b != null)'b': b,if (c != null)'c': c,});
}WithConstraintsCompanion copyWith({Value<String?>? a, Value<int>? b, Value<double?>? c}) {
return WithConstraintsCompanion(a: a ?? this.a,b: b ?? this.b,c: c ?? this.c,);
}
@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};if (a.present) {map['a'] = Variable<String>(a.value);}if (b.present) {map['b'] = Variable<int>(b.value);}if (c.present) {map['c'] = Variable<double>(c.value);}return map; 
}
@override
String toString() {return (StringBuffer('WithConstraintsCompanion(')..write('a: $a, ')..write('b: $b, ')..write('c: $c')..write(')')).toString();}
}
class $WithConstraintsTable extends Table with TableInfo<$WithConstraintsTable, WithConstraint> {
@override final GeneratedDatabase attachedDatabase;
final String? _alias;
$WithConstraintsTable(this.attachedDatabase, [this._alias]);
final VerificationMeta _aMeta = const VerificationMeta('a');
late final GeneratedColumn<String> a = GeneratedColumn<String>('a', aliasedName, true, type: DriftSqlType.string, requiredDuringInsert: false);
final VerificationMeta _bMeta = const VerificationMeta('b');
late final GeneratedColumn<int> b = GeneratedColumn<int>('b', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: true);
final VerificationMeta _cMeta = const VerificationMeta('c');
late final GeneratedColumn<double> c = GeneratedColumn<double>('c', aliasedName, true, type: DriftSqlType.double, requiredDuringInsert: false);
@override
List<GeneratedColumn> get $columns => [a, b, c];
@override
String get aliasedName => _alias ?? 'with_constraints';
@override
 String get actualTableName => 'with_constraints';
@override
VerificationContext validateIntegrity(Insertable<WithConstraint> instance, {bool isInserting = false}) {
final context = VerificationContext();
final data = instance.toColumns(true);
if (data.containsKey('a')) {
context.handle(_aMeta, a.isAcceptableOrUnknown(data['a']!, _aMeta));}if (data.containsKey('b')) {
context.handle(_bMeta, b.isAcceptableOrUnknown(data['b']!, _bMeta));} else if (isInserting) {
context.missing(_bMeta);
}
if (data.containsKey('c')) {
context.handle(_cMeta, c.isAcceptableOrUnknown(data['c']!, _cMeta));}return context;
}
@override
Set<GeneratedColumn> get $primaryKey => const <GeneratedColumn>{};@override WithConstraint map(Map<String, dynamic> data, {String? tablePrefix})  {
final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';return WithConstraint(a: attachedDatabase.options.types.read(DriftSqlType.string, data['${effectivePrefix}a']), b: attachedDatabase.options.types.read(DriftSqlType.int, data['${effectivePrefix}b'])!, c: attachedDatabase.options.types.read(DriftSqlType.double, data['${effectivePrefix}c']), );
}
@override
$WithConstraintsTable createAlias(String alias) {
return $WithConstraintsTable(attachedDatabase, alias);}}class Config extends DataClass implements Insertable<Config> {
final String configKey;
final String? configValue;
final int? syncState;
final int? syncStateImplicit;
const Config({required this.configKey, this.configValue, this.syncState, this.syncStateImplicit});@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};map['config_key'] = Variable<String>(configKey);if (!nullToAbsent || configValue != null){map['config_value'] = Variable<String>(configValue);}if (!nullToAbsent || syncState != null){map['sync_state'] = Variable<int>(syncState);}if (!nullToAbsent || syncStateImplicit != null){map['sync_state_implicit'] = Variable<int>(syncStateImplicit);}return map; 
}
ConfigCompanion toCompanion(bool nullToAbsent) {
return ConfigCompanion(configKey: Value (configKey),configValue: configValue == null && nullToAbsent ? const Value.absent() : Value (configValue),syncState: syncState == null && nullToAbsent ? const Value.absent() : Value (syncState),syncStateImplicit: syncStateImplicit == null && nullToAbsent ? const Value.absent() : Value (syncStateImplicit),);
}
factory Config.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return Config(configKey: serializer.fromJson<String>(json['config_key']),configValue: serializer.fromJson<String?>(json['config_value']),syncState: serializer.fromJson<int?>(json['sync_state']),syncStateImplicit: serializer.fromJson<int?>(json['sync_state_implicit']),);}
factory Config.fromJsonString(String encodedJson, {ValueSerializer? serializer}) => Config.fromJson(DataClass.parseJson(encodedJson) as Map<String, dynamic>, serializer: serializer);@override Map<String, dynamic> toJson({ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return <String, dynamic>{
'config_key': serializer.toJson<String>(configKey),'config_value': serializer.toJson<String?>(configValue),'sync_state': serializer.toJson<int?>(syncState),'sync_state_implicit': serializer.toJson<int?>(syncStateImplicit),};}Config copyWith({String? configKey,Value<String?> configValue = const Value.absent(),Value<int?> syncState = const Value.absent(),Value<int?> syncStateImplicit = const Value.absent()}) => Config(configKey: configKey ?? this.configKey,configValue: configValue.present ? configValue.value : this.configValue,syncState: syncState.present ? syncState.value : this.syncState,syncStateImplicit: syncStateImplicit.present ? syncStateImplicit.value : this.syncStateImplicit,);@override
String toString() {return (StringBuffer('Config(')..write('configKey: $configKey, ')..write('configValue: $configValue, ')..write('syncState: $syncState, ')..write('syncStateImplicit: $syncStateImplicit')..write(')')).toString();}
@override
 int get hashCode => Object.hash(configKey, configValue, syncState, syncStateImplicit);@override
bool operator ==(Object other) => identical(this, other) || (other is Config && other.configKey == this.configKey && other.configValue == this.configValue && other.syncState == this.syncState && other.syncStateImplicit == this.syncStateImplicit);
}class ConfigCompanion extends UpdateCompanion<Config> {
final Value<String> configKey;
final Value<String?> configValue;
final Value<int?> syncState;
final Value<int?> syncStateImplicit;
const ConfigCompanion({this.configKey = const Value.absent(),this.configValue = const Value.absent(),this.syncState = const Value.absent(),this.syncStateImplicit = const Value.absent(),});
ConfigCompanion.insert({required String configKey,this.configValue = const Value.absent(),this.syncState = const Value.absent(),this.syncStateImplicit = const Value.absent(),}): configKey = Value(configKey);
static Insertable<Config> custom({Expression<String>? configKey, 
Expression<String>? configValue, 
Expression<int>? syncState, 
Expression<int>? syncStateImplicit, 
}) {
return RawValuesInsertable({if (configKey != null)'config_key': configKey,if (configValue != null)'config_value': configValue,if (syncState != null)'sync_state': syncState,if (syncStateImplicit != null)'sync_state_implicit': syncStateImplicit,});
}ConfigCompanion copyWith({Value<String>? configKey, Value<String?>? configValue, Value<int?>? syncState, Value<int?>? syncStateImplicit}) {
return ConfigCompanion(configKey: configKey ?? this.configKey,configValue: configValue ?? this.configValue,syncState: syncState ?? this.syncState,syncStateImplicit: syncStateImplicit ?? this.syncStateImplicit,);
}
@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};if (configKey.present) {map['config_key'] = Variable<String>(configKey.value);}if (configValue.present) {map['config_value'] = Variable<String>(configValue.value);}if (syncState.present) {map['sync_state'] = Variable<int>(syncState.value);}if (syncStateImplicit.present) {map['sync_state_implicit'] = Variable<int>(syncStateImplicit.value);}return map; 
}
@override
String toString() {return (StringBuffer('ConfigCompanion(')..write('configKey: $configKey, ')..write('configValue: $configValue, ')..write('syncState: $syncState, ')..write('syncStateImplicit: $syncStateImplicit')..write(')')).toString();}
}
class $ConfigTable extends Table with TableInfo<$ConfigTable, Config> {
@override final GeneratedDatabase attachedDatabase;
final String? _alias;
$ConfigTable(this.attachedDatabase, [this._alias]);
final VerificationMeta _configKeyMeta = const VerificationMeta('configKey');
late final GeneratedColumn<String> configKey = GeneratedColumn<String>('config_key', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
final VerificationMeta _configValueMeta = const VerificationMeta('configValue');
late final GeneratedColumn<String> configValue = GeneratedColumn<String>('config_value', aliasedName, true, type: DriftSqlType.string, requiredDuringInsert: false);
final VerificationMeta _syncStateMeta = const VerificationMeta('syncState');
late final GeneratedColumn<int> syncState = GeneratedColumn<int>('sync_state', aliasedName, true, type: DriftSqlType.int, requiredDuringInsert: false);
final VerificationMeta _syncStateImplicitMeta = const VerificationMeta('syncStateImplicit');
late final GeneratedColumn<int> syncStateImplicit = GeneratedColumn<int>('sync_state_implicit', aliasedName, true, type: DriftSqlType.int, requiredDuringInsert: false);
@override
List<GeneratedColumn> get $columns => [configKey, configValue, syncState, syncStateImplicit];
@override
String get aliasedName => _alias ?? 'config';
@override
 String get actualTableName => 'config';
@override
VerificationContext validateIntegrity(Insertable<Config> instance, {bool isInserting = false}) {
final context = VerificationContext();
final data = instance.toColumns(true);
if (data.containsKey('config_key')) {
context.handle(_configKeyMeta, configKey.isAcceptableOrUnknown(data['config_key']!, _configKeyMeta));} else if (isInserting) {
context.missing(_configKeyMeta);
}
if (data.containsKey('config_value')) {
context.handle(_configValueMeta, configValue.isAcceptableOrUnknown(data['config_value']!, _configValueMeta));}if (data.containsKey('sync_state')) {
context.handle(_syncStateMeta, syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta));}if (data.containsKey('sync_state_implicit')) {
context.handle(_syncStateImplicitMeta, syncStateImplicit.isAcceptableOrUnknown(data['sync_state_implicit']!, _syncStateImplicitMeta));}return context;
}
@override
Set<GeneratedColumn> get $primaryKey => const <GeneratedColumn>{};@override Config map(Map<String, dynamic> data, {String? tablePrefix})  {
final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';return Config(configKey: attachedDatabase.options.types.read(DriftSqlType.string, data['${effectivePrefix}config_key'])!, configValue: attachedDatabase.options.types.read(DriftSqlType.string, data['${effectivePrefix}config_value']), syncState: attachedDatabase.options.types.read(DriftSqlType.int, data['${effectivePrefix}sync_state']), syncStateImplicit: attachedDatabase.options.types.read(DriftSqlType.int, data['${effectivePrefix}sync_state_implicit']), );
}
@override
$ConfigTable createAlias(String alias) {
return $ConfigTable(attachedDatabase, alias);}@override
bool get isStrict => true;
}class MytableData extends DataClass implements Insertable<MytableData> {
final int someid;
final String? sometext;
final bool? isInserting;
final DateTime? somedate;
const MytableData({required this.someid, this.sometext, this.isInserting, this.somedate});@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};map['someid'] = Variable<int>(someid);if (!nullToAbsent || sometext != null){map['sometext'] = Variable<String>(sometext);}if (!nullToAbsent || isInserting != null){map['is_inserting'] = Variable<bool>(isInserting);}if (!nullToAbsent || somedate != null){map['somedate'] = Variable<DateTime>(somedate);}return map; 
}
MytableCompanion toCompanion(bool nullToAbsent) {
return MytableCompanion(someid: Value (someid),sometext: sometext == null && nullToAbsent ? const Value.absent() : Value (sometext),isInserting: isInserting == null && nullToAbsent ? const Value.absent() : Value (isInserting),somedate: somedate == null && nullToAbsent ? const Value.absent() : Value (somedate),);
}
factory MytableData.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return MytableData(someid: serializer.fromJson<int>(json['someid']),sometext: serializer.fromJson<String?>(json['sometext']),isInserting: serializer.fromJson<bool?>(json['is_inserting']),somedate: serializer.fromJson<DateTime?>(json['somedate']),);}
factory MytableData.fromJsonString(String encodedJson, {ValueSerializer? serializer}) => MytableData.fromJson(DataClass.parseJson(encodedJson) as Map<String, dynamic>, serializer: serializer);@override Map<String, dynamic> toJson({ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return <String, dynamic>{
'someid': serializer.toJson<int>(someid),'sometext': serializer.toJson<String?>(sometext),'is_inserting': serializer.toJson<bool?>(isInserting),'somedate': serializer.toJson<DateTime?>(somedate),};}MytableData copyWith({int? someid,Value<String?> sometext = const Value.absent(),Value<bool?> isInserting = const Value.absent(),Value<DateTime?> somedate = const Value.absent()}) => MytableData(someid: someid ?? this.someid,sometext: sometext.present ? sometext.value : this.sometext,isInserting: isInserting.present ? isInserting.value : this.isInserting,somedate: somedate.present ? somedate.value : this.somedate,);@override
String toString() {return (StringBuffer('MytableData(')..write('someid: $someid, ')..write('sometext: $sometext, ')..write('isInserting: $isInserting, ')..write('somedate: $somedate')..write(')')).toString();}
@override
 int get hashCode => Object.hash(someid, sometext, isInserting, somedate);@override
bool operator ==(Object other) => identical(this, other) || (other is MytableData && other.someid == this.someid && other.sometext == this.sometext && other.isInserting == this.isInserting && other.somedate == this.somedate);
}class MytableCompanion extends UpdateCompanion<MytableData> {
final Value<int> someid;
final Value<String?> sometext;
final Value<bool?> isInserting;
final Value<DateTime?> somedate;
const MytableCompanion({this.someid = const Value.absent(),this.sometext = const Value.absent(),this.isInserting = const Value.absent(),this.somedate = const Value.absent(),});
MytableCompanion.insert({required int someid,this.sometext = const Value.absent(),this.isInserting = const Value.absent(),this.somedate = const Value.absent(),}): someid = Value(someid);
static Insertable<MytableData> custom({Expression<int>? someid, 
Expression<String>? sometext, 
Expression<bool>? isInserting, 
Expression<DateTime>? somedate, 
}) {
return RawValuesInsertable({if (someid != null)'someid': someid,if (sometext != null)'sometext': sometext,if (isInserting != null)'is_inserting': isInserting,if (somedate != null)'somedate': somedate,});
}MytableCompanion copyWith({Value<int>? someid, Value<String?>? sometext, Value<bool?>? isInserting, Value<DateTime?>? somedate}) {
return MytableCompanion(someid: someid ?? this.someid,sometext: sometext ?? this.sometext,isInserting: isInserting ?? this.isInserting,somedate: somedate ?? this.somedate,);
}
@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};if (someid.present) {map['someid'] = Variable<int>(someid.value);}if (sometext.present) {map['sometext'] = Variable<String>(sometext.value);}if (isInserting.present) {map['is_inserting'] = Variable<bool>(isInserting.value);}if (somedate.present) {map['somedate'] = Variable<DateTime>(somedate.value);}return map; 
}
@override
String toString() {return (StringBuffer('MytableCompanion(')..write('someid: $someid, ')..write('sometext: $sometext, ')..write('isInserting: $isInserting, ')..write('somedate: $somedate')..write(')')).toString();}
}
class $MytableTable extends Table with TableInfo<$MytableTable, MytableData> {
@override final GeneratedDatabase attachedDatabase;
final String? _alias;
$MytableTable(this.attachedDatabase, [this._alias]);
final VerificationMeta _someidMeta = const VerificationMeta('someid');
late final GeneratedColumn<int> someid = GeneratedColumn<int>('someid', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: true);
final VerificationMeta _sometextMeta = const VerificationMeta('sometext');
late final GeneratedColumn<String> sometext = GeneratedColumn<String>('sometext', aliasedName, true, type: DriftSqlType.string, requiredDuringInsert: false);
final VerificationMeta _isInsertingMeta = const VerificationMeta('isInserting');
late final GeneratedColumn<bool> isInserting = GeneratedColumn<bool>('is_inserting', aliasedName, true, type: DriftSqlType.bool, requiredDuringInsert: false, defaultConstraints: 'CHECK (is_inserting IN (0, 1))');
final VerificationMeta _somedateMeta = const VerificationMeta('somedate');
late final GeneratedColumn<DateTime> somedate = GeneratedColumn<DateTime>('somedate', aliasedName, true, type: DriftSqlType.dateTime, requiredDuringInsert: false);
@override
List<GeneratedColumn> get $columns => [someid, sometext, isInserting, somedate];
@override
String get aliasedName => _alias ?? 'mytable';
@override
 String get actualTableName => 'mytable';
@override
VerificationContext validateIntegrity(Insertable<MytableData> instance, {bool isInserting = false}) {
final context = VerificationContext();
final data = instance.toColumns(true);
if (data.containsKey('someid')) {
context.handle(_someidMeta, someid.isAcceptableOrUnknown(data['someid']!, _someidMeta));} else if (isInserting) {
context.missing(_someidMeta);
}
if (data.containsKey('sometext')) {
context.handle(_sometextMeta, sometext.isAcceptableOrUnknown(data['sometext']!, _sometextMeta));}if (data.containsKey('is_inserting')) {
context.handle(_isInsertingMeta, this.isInserting.isAcceptableOrUnknown(data['is_inserting']!, _isInsertingMeta));}if (data.containsKey('somedate')) {
context.handle(_somedateMeta, somedate.isAcceptableOrUnknown(data['somedate']!, _somedateMeta));}return context;
}
@override
Set<GeneratedColumn> get $primaryKey => const <GeneratedColumn>{};@override MytableData map(Map<String, dynamic> data, {String? tablePrefix})  {
final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';return MytableData(someid: attachedDatabase.options.types.read(DriftSqlType.int, data['${effectivePrefix}someid'])!, sometext: attachedDatabase.options.types.read(DriftSqlType.string, data['${effectivePrefix}sometext']), isInserting: attachedDatabase.options.types.read(DriftSqlType.bool, data['${effectivePrefix}is_inserting']), somedate: attachedDatabase.options.types.read(DriftSqlType.dateTime, data['${effectivePrefix}somedate']), );
}
@override
$MytableTable createAlias(String alias) {
return $MytableTable(attachedDatabase, alias);}}class EMail extends DataClass implements Insertable<EMail> {
final String sender;
final String title;
final String body;
const EMail({required this.sender, required this.title, required this.body});@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};map['sender'] = Variable<String>(sender);map['title'] = Variable<String>(title);map['body'] = Variable<String>(body);return map; 
}
EmailCompanion toCompanion(bool nullToAbsent) {
return EmailCompanion(sender: Value (sender),title: Value (title),body: Value (body),);
}
factory EMail.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return EMail(sender: serializer.fromJson<String>(json['sender']),title: serializer.fromJson<String>(json['title']),body: serializer.fromJson<String>(json['body']),);}
factory EMail.fromJsonString(String encodedJson, {ValueSerializer? serializer}) => EMail.fromJson(DataClass.parseJson(encodedJson) as Map<String, dynamic>, serializer: serializer);@override Map<String, dynamic> toJson({ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return <String, dynamic>{
'sender': serializer.toJson<String>(sender),'title': serializer.toJson<String>(title),'body': serializer.toJson<String>(body),};}EMail copyWith({String? sender,String? title,String? body}) => EMail(sender: sender ?? this.sender,title: title ?? this.title,body: body ?? this.body,);@override
String toString() {return (StringBuffer('EMail(')..write('sender: $sender, ')..write('title: $title, ')..write('body: $body')..write(')')).toString();}
@override
 int get hashCode => Object.hash(sender, title, body);@override
bool operator ==(Object other) => identical(this, other) || (other is EMail && other.sender == this.sender && other.title == this.title && other.body == this.body);
}class EmailCompanion extends UpdateCompanion<EMail> {
final Value<String> sender;
final Value<String> title;
final Value<String> body;
const EmailCompanion({this.sender = const Value.absent(),this.title = const Value.absent(),this.body = const Value.absent(),});
EmailCompanion.insert({required String sender,required String title,required String body,}): sender = Value(sender), title = Value(title), body = Value(body);
static Insertable<EMail> custom({Expression<String>? sender, 
Expression<String>? title, 
Expression<String>? body, 
}) {
return RawValuesInsertable({if (sender != null)'sender': sender,if (title != null)'title': title,if (body != null)'body': body,});
}EmailCompanion copyWith({Value<String>? sender, Value<String>? title, Value<String>? body}) {
return EmailCompanion(sender: sender ?? this.sender,title: title ?? this.title,body: body ?? this.body,);
}
@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};if (sender.present) {map['sender'] = Variable<String>(sender.value);}if (title.present) {map['title'] = Variable<String>(title.value);}if (body.present) {map['body'] = Variable<String>(body.value);}return map; 
}
@override
String toString() {return (StringBuffer('EmailCompanion(')..write('sender: $sender, ')..write('title: $title, ')..write('body: $body')..write(')')).toString();}
}
class $EmailTable extends Table with TableInfo<$EmailTable, EMail> , VirtualTableInfo<$EmailTable, EMail> {
@override final GeneratedDatabase attachedDatabase;
final String? _alias;
$EmailTable(this.attachedDatabase, [this._alias]);
final VerificationMeta _senderMeta = const VerificationMeta('sender');
late final GeneratedColumn<String> sender = GeneratedColumn<String>('sender', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
final VerificationMeta _titleMeta = const VerificationMeta('title');
late final GeneratedColumn<String> title = GeneratedColumn<String>('title', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
final VerificationMeta _bodyMeta = const VerificationMeta('body');
late final GeneratedColumn<String> body = GeneratedColumn<String>('body', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
@override
List<GeneratedColumn> get $columns => [sender, title, body];
@override
String get aliasedName => _alias ?? 'email';
@override
 String get actualTableName => 'email';
@override
VerificationContext validateIntegrity(Insertable<EMail> instance, {bool isInserting = false}) {
final context = VerificationContext();
final data = instance.toColumns(true);
if (data.containsKey('sender')) {
context.handle(_senderMeta, sender.isAcceptableOrUnknown(data['sender']!, _senderMeta));} else if (isInserting) {
context.missing(_senderMeta);
}
if (data.containsKey('title')) {
context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));} else if (isInserting) {
context.missing(_titleMeta);
}
if (data.containsKey('body')) {
context.handle(_bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));} else if (isInserting) {
context.missing(_bodyMeta);
}
return context;
}
@override
Set<GeneratedColumn> get $primaryKey => const <GeneratedColumn>{};@override EMail map(Map<String, dynamic> data, {String? tablePrefix})  {
final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';return EMail(sender: attachedDatabase.options.types.read(DriftSqlType.string, data['${effectivePrefix}sender'])!, title: attachedDatabase.options.types.read(DriftSqlType.string, data['${effectivePrefix}title'])!, body: attachedDatabase.options.types.read(DriftSqlType.string, data['${effectivePrefix}body'])!, );
}
@override
$EmailTable createAlias(String alias) {
return $EmailTable(attachedDatabase, alias);}@override
String get moduleAndArgs => 'fts5(sender, title, body)';
}class WeirdData extends DataClass implements Insertable<WeirdData> {
final int sqlClass;
final String textColumn;
const WeirdData({required this.sqlClass, required this.textColumn});@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};map['class'] = Variable<int>(sqlClass);map['text'] = Variable<String>(textColumn);return map; 
}
WeirdTableCompanion toCompanion(bool nullToAbsent) {
return WeirdTableCompanion(sqlClass: Value (sqlClass),textColumn: Value (textColumn),);
}
factory WeirdData.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return WeirdData(sqlClass: serializer.fromJson<int>(json['class']),textColumn: serializer.fromJson<String>(json['text']),);}
factory WeirdData.fromJsonString(String encodedJson, {ValueSerializer? serializer}) => WeirdData.fromJson(DataClass.parseJson(encodedJson) as Map<String, dynamic>, serializer: serializer);@override Map<String, dynamic> toJson({ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return <String, dynamic>{
'class': serializer.toJson<int>(sqlClass),'text': serializer.toJson<String>(textColumn),};}WeirdData copyWith({int? sqlClass,String? textColumn}) => WeirdData(sqlClass: sqlClass ?? this.sqlClass,textColumn: textColumn ?? this.textColumn,);@override
String toString() {return (StringBuffer('WeirdData(')..write('sqlClass: $sqlClass, ')..write('textColumn: $textColumn')..write(')')).toString();}
@override
 int get hashCode => Object.hash(sqlClass, textColumn);@override
bool operator ==(Object other) => identical(this, other) || (other is WeirdData && other.sqlClass == this.sqlClass && other.textColumn == this.textColumn);
}class WeirdTableCompanion extends UpdateCompanion<WeirdData> {
final Value<int> sqlClass;
final Value<String> textColumn;
const WeirdTableCompanion({this.sqlClass = const Value.absent(),this.textColumn = const Value.absent(),});
WeirdTableCompanion.insert({required int sqlClass,required String textColumn,}): sqlClass = Value(sqlClass), textColumn = Value(textColumn);
static Insertable<WeirdData> custom({Expression<int>? sqlClass, 
Expression<String>? textColumn, 
}) {
return RawValuesInsertable({if (sqlClass != null)'class': sqlClass,if (textColumn != null)'text': textColumn,});
}WeirdTableCompanion copyWith({Value<int>? sqlClass, Value<String>? textColumn}) {
return WeirdTableCompanion(sqlClass: sqlClass ?? this.sqlClass,textColumn: textColumn ?? this.textColumn,);
}
@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};if (sqlClass.present) {map['class'] = Variable<int>(sqlClass.value);}if (textColumn.present) {map['text'] = Variable<String>(textColumn.value);}return map; 
}
@override
String toString() {return (StringBuffer('WeirdTableCompanion(')..write('sqlClass: $sqlClass, ')..write('textColumn: $textColumn')..write(')')).toString();}
}
class $WeirdTableTable extends Table with TableInfo<$WeirdTableTable, WeirdData> {
@override final GeneratedDatabase attachedDatabase;
final String? _alias;
$WeirdTableTable(this.attachedDatabase, [this._alias]);
final VerificationMeta _sqlClassMeta = const VerificationMeta('sqlClass');
late final GeneratedColumn<int> sqlClass = GeneratedColumn<int>('class', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: true);
final VerificationMeta _textColumnMeta = const VerificationMeta('textColumn');
late final GeneratedColumn<String> textColumn = GeneratedColumn<String>('text', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
@override
List<GeneratedColumn> get $columns => [sqlClass, textColumn];
@override
String get aliasedName => _alias ?? 'Expression';
@override
 String get actualTableName => 'Expression';
@override
VerificationContext validateIntegrity(Insertable<WeirdData> instance, {bool isInserting = false}) {
final context = VerificationContext();
final data = instance.toColumns(true);
if (data.containsKey('class')) {
context.handle(_sqlClassMeta, sqlClass.isAcceptableOrUnknown(data['class']!, _sqlClassMeta));} else if (isInserting) {
context.missing(_sqlClassMeta);
}
if (data.containsKey('text')) {
context.handle(_textColumnMeta, textColumn.isAcceptableOrUnknown(data['text']!, _textColumnMeta));} else if (isInserting) {
context.missing(_textColumnMeta);
}
return context;
}
@override
Set<GeneratedColumn> get $primaryKey => const <GeneratedColumn>{};@override WeirdData map(Map<String, dynamic> data, {String? tablePrefix})  {
final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';return WeirdData(sqlClass: attachedDatabase.options.types.read(DriftSqlType.int, data['${effectivePrefix}class'])!, textColumn: attachedDatabase.options.types.read(DriftSqlType.string, data['${effectivePrefix}text'])!, );
}
@override
$WeirdTableTable createAlias(String alias) {
return $WeirdTableTable(attachedDatabase, alias);}}class MyViewData extends DataClass {
final String configKey;
final String configValue;
final int syncState;
final int syncStateImplicit;
const MyViewData({required this.configKey, required this.configValue, required this.syncState, required this.syncStateImplicit});factory MyViewData.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return MyViewData(configKey: serializer.fromJson<String>(json['config_key']),configValue: serializer.fromJson<String>(json['config_value']),syncState: serializer.fromJson<int>(json['sync_state']),syncStateImplicit: serializer.fromJson<int>(json['sync_state_implicit']),);}
factory MyViewData.fromJsonString(String encodedJson, {ValueSerializer? serializer}) => MyViewData.fromJson(DataClass.parseJson(encodedJson) as Map<String, dynamic>, serializer: serializer);@override Map<String, dynamic> toJson({ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return <String, dynamic>{
'config_key': serializer.toJson<String>(configKey),'config_value': serializer.toJson<String>(configValue),'sync_state': serializer.toJson<int>(syncState),'sync_state_implicit': serializer.toJson<int>(syncStateImplicit),};}MyViewData copyWith({String? configKey,String? configValue,int? syncState,int? syncStateImplicit}) => MyViewData(configKey: configKey ?? this.configKey,configValue: configValue ?? this.configValue,syncState: syncState ?? this.syncState,syncStateImplicit: syncStateImplicit ?? this.syncStateImplicit,);@override
String toString() {return (StringBuffer('MyViewData(')..write('configKey: $configKey, ')..write('configValue: $configValue, ')..write('syncState: $syncState, ')..write('syncStateImplicit: $syncStateImplicit')..write(')')).toString();}
@override
 int get hashCode => Object.hash(configKey, configValue, syncState, syncStateImplicit);@override
bool operator ==(Object other) => identical(this, other) || (other is MyViewData && other.configKey == this.configKey && other.configValue == this.configValue && other.syncState == this.syncState && other.syncStateImplicit == this.syncStateImplicit);
}class MyView extends ViewInfo<MyView, MyViewData> implements HasResultSet {
final String? _alias;
@override final _$CustomTablesDb attachedDatabase;
MyView(this.attachedDatabase, [this._alias]);
@override
List<GeneratedColumn> get $columns => [configKey, configValue, syncState, syncStateImplicit];
@override
String get aliasedName => _alias ?? entityName;
@override
 String get entityName=> 'my_view';
@override
String get createViewStmt =>'CREATE VIEW my_view AS SELECT * FROM config WHERE sync_state = 2'@override
MyView get asDslTable => this;
@override MyViewData map(Map<String, dynamic> data, {String? tablePrefix})  {
final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';return MyViewData(configKey: attachedDatabase.options.types.read(DriftSqlType.string, data['${effectivePrefix}config_key'])!, configValue: attachedDatabase.options.types.read(DriftSqlType.string, data['${effectivePrefix}config_value'])!, syncState: attachedDatabase.options.types.read(DriftSqlType.int, data['${effectivePrefix}sync_state'])!, syncStateImplicit: attachedDatabase.options.types.read(DriftSqlType.int, data['${effectivePrefix}sync_state_implicit'])!, );
}
late final GeneratedColumn<String> configKey = GeneratedColumn<String>('config_key', aliasedName, false, type: DriftSqlType.string);
late final GeneratedColumn<String> configValue = GeneratedColumn<String>('config_value', aliasedName, false, type: DriftSqlType.string);
late final GeneratedColumn<int> syncState = GeneratedColumn<int>('sync_state', aliasedName, false, type: DriftSqlType.int);
late final GeneratedColumn<int> syncStateImplicit = GeneratedColumn<int>('sync_state_implicit', aliasedName, false, type: DriftSqlType.int);
@override
MyView createAlias(String alias) {
return MyView(attachedDatabase, alias);}@override
Query? get query => null;
      @override
      Set<String> get readTables => const {'config'};
    
}
abstract class _$CustomTablesDb extends GeneratedDatabase{
_$CustomTablesDb(QueryExecutor e): super(e);
_$CustomTablesDb.connect(DatabaseConnection c): super.connect(c); 
late final $NoIdsTable noIds = $NoIdsTable(this);
late final $WithDefaultsTable withDefaults = $WithDefaultsTable(this);
late final $WithConstraintsTable withConstraints = $WithConstraintsTable(this);
late final $ConfigTable config = $ConfigTable(this);
late final Index valueIdx = Index('value_idx', 'CREATE INDEX IF NOT EXISTS value_idx ON config (config_value)');
late final $MytableTable mytable = $MytableTable(this);
late final $EmailTable email = $EmailTable(this);
late final $WeirdTableTable weirdTable = $WeirdTableTable(this);
late final Trigger myTrigger = Trigger('CREATE TRIGGER my_trigger AFTER INSERT ON config BEGIN INSERT INTO with_defaults VALUES (new.config_key, LENGTH(new.config_value));END', 'my_trigger');
late final MyView myView = MyView(this);
Future<int> writeConfig({required String key, required String value}) {
return customInsert('REPLACE INTO config (config_key, config_value) VALUES (?1, ?2)',variables: [Variable<String>(key), Variable<String>(value)],updates: {}, updateKind: UpdateKind.delete,);
}
Selectable<Config> readConfig(String var1) {
return customSelect('SELECT config_key AS ck, config_value AS cf, sync_state AS cs1, sync_state_implicit AS cs2 FROM config WHERE config_key = ?1', variables: [Variable<String>(var1)], readsFrom: {config,}).asyncMap((QueryRow row) => config.mapFromRowWithAlias(row, const {'ck': 'config_key', 'cf': 'config_value', 'cs1': 'sync_state', 'cs2': 'sync_state_implicit', }));
}
Selectable<ReadMultipleResult> readMultiple(String var1, {OrderBy clause =  const OrderBy.nothing()}) {
var $arrayStartIndex = 2;final generatedclause = $write(clause, startIndex: $arrayStartIndex);
$arrayStartIndex += generatedclause.amountOfVariables;
return customSelect('SELECT * FROM config WHERE config_key IN ?1 ${generatedclause.sql}', variables: [Variable<String>(var1), ...generatedclause.introducedVariables], readsFrom: {...generatedclause.watchedTables,}).map((QueryRow row) { return ReadMultipleResult(row: row,
);
});
}
Selectable<Config> readDynamic({ReadDynamic$predicate? predicate}) {
var $arrayStartIndex = 1;final generatedpredicate = $write(predicate?.call(this.config) ?? const CustomExpression('(TRUE)'), startIndex: $arrayStartIndex);
$arrayStartIndex += generatedpredicate.amountOfVariables;
return customSelect('SELECT * FROM config WHERE ${generatedpredicate.sql}', variables: [...generatedpredicate.introducedVariables], readsFrom: {config,...generatedpredicate.watchedTables,}).asyncMap(config.mapFromRow);
}
Selectable<String> typeConverterVar(int var1, List<int> var2, {TypeConverterVar$pred? pred}) {
var $arrayStartIndex = 2;final generatedpred = $write(pred?.call(this.config) ?? const CustomExpression('(TRUE)'), startIndex: $arrayStartIndex);
$arrayStartIndex += generatedpred.amountOfVariables;
final expandedvar2 = $expandVar($arrayStartIndex, var2.length);
$arrayStartIndex += var2.length;
return customSelect('SELECT config_key FROM config WHERE ${generatedpred.sql} AND(sync_state = ?1 OR sync_state_implicit IN ($expandedvar2))', variables: [Variable<int>(var1), ...generatedpred.introducedVariables, for (var $ in var2) Variable<int>($)], readsFrom: {config,...generatedpred.watchedTables,}).map((QueryRow row) => row.read<String>('config_key'));
}
Selectable<TableValuedResult> tableValued() {
return customSelect('SELECT "key", value FROM config,json_each(config.config_value)WHERE json_valid(config_value)', variables: [], readsFrom: {config,}).map((QueryRow row) { return TableValuedResult(row: row,
key: row.read<String>('key'),value: row.readNullable<String>('value'),);
});
}
Selectable<AnotherResult> another() {
return customSelect('SELECT \'one\' AS "key", NULLIF(\'two\', \'another\') AS value', variables: [], readsFrom: {}).map((QueryRow row) { return AnotherResult(row: row,
key: row.read<String>('key'),value: row.readNullable<String>('value'),);
});
}
Future<int> special:0() {
return customInsert('INSERT INTO config (config_key, config_value) VALUES (\'key\', \'values\')',variables: [],updates: {config},);
}
Selectable<MultipleResult> multiple({required Multiple$predicate predicate}) {
var $arrayStartIndex = 1;final generatedpredicate = $write(predicate(alias(this.withDefaults, 'd'), alias(this.withConstraints, 'c')), hasMultipleTables: true, startIndex: $arrayStartIndex);
$arrayStartIndex += generatedpredicate.amountOfVariables;
return customSelect('SELECT d.*,"c"."a" AS "nested_0.a", "c"."b" AS "nested_0.b", "c"."c" AS "nested_0.c" FROM with_defaults AS d LEFT OUTER JOIN with_constraints AS c ON d.a = c.a AND d.b = c.b WHERE ${generatedpredicate.sql}', variables: [...generatedpredicate.introducedVariables], readsFrom: {withDefaults,withConstraints,...generatedpredicate.watchedTables,}).asyncMap((QueryRow row) async { return MultipleResult(row: row,
a: row.read<String>('a'),b: row.read<int>('b'),c: await withConstraints.mapFromRowOrNull(row, tablePrefix: 'nested_0'),);
});
}
Selectable<EMail> searchEmails({required String? term}) {
return customSelect('SELECT * FROM email WHERE email MATCH ?1 ORDER BY rank', variables: [Variable<String>(term)], readsFrom: {email,}).asyncMap(email.mapFromRow);
}
Selectable<ReadRowIdResult> readRowId({required ReadRowId$expr expr}) {
var $arrayStartIndex = 1;final generatedexpr = $write(expr(this.config), startIndex: $arrayStartIndex);
$arrayStartIndex += generatedexpr.amountOfVariables;
return customSelect('SELECT oid, * FROM config WHERE _rowid_ = ${generatedexpr.sql}', variables: [...generatedexpr.introducedVariables], readsFrom: {config,...generatedexpr.watchedTables,}).map((QueryRow row) { return ReadRowIdResult(row: row,
rowid: row.read<int>('rowid'),configKey: row.read<String>('config_key'),configValue: row.read<String>('config_value'),syncState: row.read<int>('sync_state'),syncStateImplicit: row.read<int>('sync_state_implicit'),);
});
}
Selectable<ReadViewResult> readView() {
return customSelect('SELECT * FROM my_view', variables: [], readsFrom: {config,}).map((QueryRow row) { return ReadViewResult(row: row,
configKey: row.read<String>('config_key'),configValue: row.read<String>('config_value'),syncState: row.read<int>('sync_state'),syncStateImplicit: row.read<int>('sync_state_implicit'),);
});
}
Selectable<int> cfeTest() {
return customSelect('WITH RECURSIVE cnt(x) AS (SELECT 1 UNION ALL SELECT x + 1 FROM cnt LIMIT 1000000) SELECT x FROM cnt', variables: [], readsFrom: {}).map((QueryRow row) => row.read<int>('x'));
}
Selectable<int?> nullableQuery() {
return customSelect('SELECT MAX(oid) AS _c0 FROM config', variables: [], readsFrom: {config,}).map((QueryRow row) => row.readNullable<int>('_c0'));
}
Future<List<Config>> addConfig({required Insertable<Config> value}) {
var $arrayStartIndex = 1;final generatedvalue = $writeInsertable(this.config, value, startIndex: $arrayStartIndex);
$arrayStartIndex += generatedvalue.amountOfVariables;
return customWriteReturning('INSERT INTO config ${generatedvalue.sql} RETURNING *',variables: [...generatedvalue.introducedVariables],updates: {config}).then((rows) => Future.wait(rows.map(config.mapFromRow)));
}Selectable<NestedResult> nested(String var1) {
return customSelect('SELECT"defaults"."a" AS "nested_0.a", "defaults"."b" AS "nested_0.b", defaults.b AS "\$n_0" FROM with_defaults AS defaults WHERE a = ?1', variables: [Variable<String>(var1)], readsFrom: {withConstraints,withDefaults,}).asyncMap((QueryRow row) async { return NestedResult(row: row,
defaults: await withDefaults.mapFromRow(row, tablePrefix: 'nested_0'),nestedQuery0: await  customSelect('SELECT * FROM with_constraints AS c WHERE c.b = ?1', variables: [Variable<int>(row.read('\$n_0'))], readsFrom: {withConstraints,withDefaults,}).asyncMap(withConstraints.mapFromRow).get(),);
});
}
@override
Iterable<TableInfo<Table, dynamic>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
@override
List<DatabaseSchemaEntity> get allSchemaEntities => [];
@override
DriftDatabaseOptions get options => const DriftDatabaseOptions(storeDateTimeAsText: true);
}
typedef ReadDynamic$predicate = Expression<bool> Function($ConfigTable config);typedef TypeConverterVar$pred = Expression<bool> Function($ConfigTable config);class TableValuedResult extends CustomResultSet {
final String key
;final String? value
;TableValuedResult({required QueryRow row,required this.key,this.value,}): super(row);
@override int get hashCode => Object.hash(key, value);
@override
bool operator ==(Object other) => identical(this, other) || (other is TableValuedResult && other.key == this.key && other.value == this.value);
@override
String toString() {return (StringBuffer('TableValuedResult(')..write('key: $key, ')..write('value: $value')..write(')')).toString();}
}
class AnotherResult extends CustomResultSet {
final String key
;final String? value
;AnotherResult({required QueryRow row,required this.key,this.value,}): super(row);
@override int get hashCode => Object.hash(key, value);
@override
bool operator ==(Object other) => identical(this, other) || (other is AnotherResult && other.key == this.key && other.value == this.value);
@override
String toString() {return (StringBuffer('AnotherResult(')..write('key: $key, ')..write('value: $value')..write(')')).toString();}
}
class MultipleResult extends CustomResultSet {
final String a
;final int b
;final WithConstraint? c;
MultipleResult({required QueryRow row,required this.a,required this.b,this.c,}): super(row);
@override int get hashCode => Object.hash(a, b, c);
@override
bool operator ==(Object other) => identical(this, other) || (other is MultipleResult && other.a == this.a && other.b == this.b && other.c == this.c);
@override
String toString() {return (StringBuffer('MultipleResult(')..write('a: $a, ')..write('b: $b, ')..write('c: $c')..write(')')).toString();}
}
typedef Multiple$predicate = Expression<bool> Function($WithDefaultsTable d, $WithConstraintsTable c);class ReadRowIdResult extends CustomResultSet {
final int rowid
;final String configKey
;final String configValue
;final int syncState
;final int syncStateImplicit
;ReadRowIdResult({required QueryRow row,required this.rowid,required this.configKey,required this.configValue,required this.syncState,required this.syncStateImplicit,}): super(row);
@override int get hashCode => Object.hash(rowid, configKey, configValue, syncState, syncStateImplicit);
@override
bool operator ==(Object other) => identical(this, other) || (other is ReadRowIdResult && other.rowid == this.rowid && other.configKey == this.configKey && other.configValue == this.configValue && other.syncState == this.syncState && other.syncStateImplicit == this.syncStateImplicit);
@override
String toString() {return (StringBuffer('ReadRowIdResult(')..write('rowid: $rowid, ')..write('configKey: $configKey, ')..write('configValue: $configValue, ')..write('syncState: $syncState, ')..write('syncStateImplicit: $syncStateImplicit')..write(')')).toString();}
}
typedef ReadRowId$expr = Expression<int> Function($ConfigTable config);class ReadViewResult extends CustomResultSet {
final String configKey
;final String configValue
;final int syncState
;final int syncStateImplicit
;ReadViewResult({required QueryRow row,required this.configKey,required this.configValue,required this.syncState,required this.syncStateImplicit,}): super(row);
@override int get hashCode => Object.hash(configKey, configValue, syncState, syncStateImplicit);
@override
bool operator ==(Object other) => identical(this, other) || (other is ReadViewResult && other.configKey == this.configKey && other.configValue == this.configValue && other.syncState == this.syncState && other.syncStateImplicit == this.syncStateImplicit);
@override
String toString() {return (StringBuffer('ReadViewResult(')..write('configKey: $configKey, ')..write('configValue: $configValue, ')..write('syncState: $syncState, ')..write('syncStateImplicit: $syncStateImplicit')..write(')')).toString();}
}
class NestedResult extends CustomResultSet {
final WithDefault defaults;
finalList<WithConstraint>nestedQuery0;
NestedResult({required QueryRow row,required this.defaults,required this.nestedQuery0,}): super(row);
@override int get hashCode => Object.hash(defaults, nestedQuery0);
@override
bool operator ==(Object other) => identical(this, other) || (other is NestedResult && other.defaults == this.defaults && other.nestedQuery0 == this.nestedQuery0);
@override
String toString() {return (StringBuffer('NestedResult(')..write('defaults: $defaults, ')..write('nestedQuery0: $nestedQuery0')..write(')')).toString();}
}
