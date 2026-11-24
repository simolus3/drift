// This is a generated file - do not edit.
//
// Generated from drift.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'drift.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'drift.pbenum.dart';

class Empty extends $pb.GeneratedMessage {
  factory Empty() => Empty._();

  Empty._();

  factory Empty.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Empty()..mergeFromBuffer(data, registry);
  factory Empty.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Empty()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Empty',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'driftremote'),
      createEmptyInstance: Empty.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Empty clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Empty copyWith(void Function(Empty) updates) =>
      super.copyWith((message) => updates(message as Empty)) as Empty;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Empty() / Empty.new instead')
  static Empty create() => Empty._();
  static $pb.GeneratedMessage $_createMessage() => Empty._();
  @$core.override
  Empty createEmptyInstance() => Empty._();
  @$core.pragma('dart2js:noInline')
  static Empty getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Empty>(Empty.$_createMessage);
  static Empty? _defaultInstance;
}

class ConnectRequest extends $pb.GeneratedMessage {
  factory ConnectRequest() => ConnectRequest._();

  ConnectRequest._();

  factory ConnectRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConnectRequest()..mergeFromBuffer(data, registry);
  factory ConnectRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConnectRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ConnectRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'driftremote'),
      createEmptyInstance: ConnectRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConnectRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConnectRequest copyWith(void Function(ConnectRequest) updates) =>
      super.copyWith((message) => updates(message as ConnectRequest))
          as ConnectRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ConnectRequest() / ConnectRequest.new instead')
  static ConnectRequest create() => ConnectRequest._();
  static $pb.GeneratedMessage $_createMessage() => ConnectRequest._();
  @$core.override
  ConnectRequest createEmptyInstance() => ConnectRequest._();
  @$core.pragma('dart2js:noInline')
  static ConnectRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ConnectRequest>(
          ConnectRequest.$_createMessage);
  static ConnectRequest? _defaultInstance;
}

/// A session opened on the server, along with its optional capabilities.
class CreatedSession extends $pb.GeneratedMessage {
  factory CreatedSession({
    $core.int? id,
    $core.bool? persistentSchemaVersion,
    $core.bool? transaction,
    $core.bool? transactionParent,
    $core.bool? locks,
  }) {
    final result = CreatedSession._();
    if (id != null) result.id = id;
    if (persistentSchemaVersion != null)
      result.persistentSchemaVersion = persistentSchemaVersion;
    if (transaction != null) result.transaction = transaction;
    if (transactionParent != null) result.transactionParent = transactionParent;
    if (locks != null) result.locks = locks;
    return result;
  }

  CreatedSession._();

  factory CreatedSession.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreatedSession()..mergeFromBuffer(data, registry);
  factory CreatedSession.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreatedSession()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreatedSession',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'driftremote'),
      createEmptyInstance: CreatedSession.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'id')
    ..aOB(2, _omitFieldNames ? '' : 'persistentSchemaVersion')
    ..aOB(3, _omitFieldNames ? '' : 'transaction')
    ..aOB(4, _omitFieldNames ? '' : 'transactionParent')
    ..aOB(5, _omitFieldNames ? '' : 'locks')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreatedSession clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreatedSession copyWith(void Function(CreatedSession) updates) =>
      super.copyWith((message) => updates(message as CreatedSession))
          as CreatedSession;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CreatedSession() / CreatedSession.new instead')
  static CreatedSession create() => CreatedSession._();
  static $pb.GeneratedMessage $_createMessage() => CreatedSession._();
  @$core.override
  CreatedSession createEmptyInstance() => CreatedSession._();
  @$core.pragma('dart2js:noInline')
  static CreatedSession getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CreatedSession>(
          CreatedSession.$_createMessage);
  static CreatedSession? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get id => $_getIZ(0);
  @$pb.TagNumber(1)
  set id($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// Whether `DriftSession.persistentSchemaVersion` is non-null.
  @$pb.TagNumber(2)
  $core.bool get persistentSchemaVersion => $_getBF(1);
  @$pb.TagNumber(2)
  set persistentSchemaVersion($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPersistentSchemaVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearPersistentSchemaVersion() => $_clearField(2);

  /// Whether `DriftSession.transaction` is non-null.
  @$pb.TagNumber(3)
  $core.bool get transaction => $_getBF(2);
  @$pb.TagNumber(3)
  set transaction($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTransaction() => $_has(2);
  @$pb.TagNumber(3)
  void clearTransaction() => $_clearField(3);

  /// Whether `DriftSession.transactionParent` is non-null.
  @$pb.TagNumber(4)
  $core.bool get transactionParent => $_getBF(3);
  @$pb.TagNumber(4)
  set transactionParent($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTransactionParent() => $_has(3);
  @$pb.TagNumber(4)
  void clearTransactionParent() => $_clearField(4);

  /// Whether `DriftSession.locks` is non-null.
  @$pb.TagNumber(5)
  $core.bool get locks => $_getBF(4);
  @$pb.TagNumber(5)
  set locks($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasLocks() => $_has(4);
  @$pb.TagNumber(5)
  void clearLocks() => $_clearField(5);
}

/// A request referring to a session without further arguments.
class SessionRequest extends $pb.GeneratedMessage {
  factory SessionRequest({
    $core.int? session,
  }) {
    final result = SessionRequest._();
    if (session != null) result.session = session;
    return result;
  }

  SessionRequest._();

  factory SessionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SessionRequest()..mergeFromBuffer(data, registry);
  factory SessionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SessionRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SessionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'driftremote'),
      createEmptyInstance: SessionRequest.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'session')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SessionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SessionRequest copyWith(void Function(SessionRequest) updates) =>
      super.copyWith((message) => updates(message as SessionRequest))
          as SessionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SessionRequest() / SessionRequest.new instead')
  static SessionRequest create() => SessionRequest._();
  static $pb.GeneratedMessage $_createMessage() => SessionRequest._();
  @$core.override
  SessionRequest createEmptyInstance() => SessionRequest._();
  @$core.pragma('dart2js:noInline')
  static SessionRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SessionRequest>(
          SessionRequest.$_createMessage);
  static SessionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get session => $_getIZ(0);
  @$pb.TagNumber(1)
  set session($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSession() => $_has(0);
  @$pb.TagNumber(1)
  void clearSession() => $_clearField(1);
}

class GetSchemaVersion extends $pb.GeneratedMessage {
  factory GetSchemaVersion({
    $core.int? session,
  }) {
    final result = GetSchemaVersion._();
    if (session != null) result.session = session;
    return result;
  }

  GetSchemaVersion._();

  factory GetSchemaVersion.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSchemaVersion()..mergeFromBuffer(data, registry);
  factory GetSchemaVersion.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSchemaVersion()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSchemaVersion',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'driftremote'),
      createEmptyInstance: GetSchemaVersion.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'session')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSchemaVersion clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSchemaVersion copyWith(void Function(GetSchemaVersion) updates) =>
      super.copyWith((message) => updates(message as GetSchemaVersion))
          as GetSchemaVersion;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetSchemaVersion() / GetSchemaVersion.new instead')
  static GetSchemaVersion create() => GetSchemaVersion._();
  static $pb.GeneratedMessage $_createMessage() => GetSchemaVersion._();
  @$core.override
  GetSchemaVersion createEmptyInstance() => GetSchemaVersion._();
  @$core.pragma('dart2js:noInline')
  static GetSchemaVersion getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetSchemaVersion>(
          GetSchemaVersion.$_createMessage);
  static GetSchemaVersion? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get session => $_getIZ(0);
  @$pb.TagNumber(1)
  set session($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSession() => $_has(0);
  @$pb.TagNumber(1)
  void clearSession() => $_clearField(1);
}

class GetSchemaVersionResult extends $pb.GeneratedMessage {
  factory GetSchemaVersionResult({
    $fixnum.Int64? schemaVersion,
  }) {
    final result = GetSchemaVersionResult._();
    if (schemaVersion != null) result.schemaVersion = schemaVersion;
    return result;
  }

  GetSchemaVersionResult._();

  factory GetSchemaVersionResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSchemaVersionResult()..mergeFromBuffer(data, registry);
  factory GetSchemaVersionResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSchemaVersionResult()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSchemaVersionResult',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'driftremote'),
      createEmptyInstance: GetSchemaVersionResult.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'schemaVersion')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSchemaVersionResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSchemaVersionResult copyWith(
          void Function(GetSchemaVersionResult) updates) =>
      super.copyWith((message) => updates(message as GetSchemaVersionResult))
          as GetSchemaVersionResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetSchemaVersionResult() / GetSchemaVersionResult.new instead')
  static GetSchemaVersionResult create() => GetSchemaVersionResult._();
  static $pb.GeneratedMessage $_createMessage() => GetSchemaVersionResult._();
  @$core.override
  GetSchemaVersionResult createEmptyInstance() => GetSchemaVersionResult._();
  @$core.pragma('dart2js:noInline')
  static GetSchemaVersionResult getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSchemaVersionResult>(
          GetSchemaVersionResult.$_createMessage);
  static GetSchemaVersionResult? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get schemaVersion => $_getI64(0);
  @$pb.TagNumber(1)
  set schemaVersion($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSchemaVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearSchemaVersion() => $_clearField(1);
}

class SetSchemaVersion extends $pb.GeneratedMessage {
  factory SetSchemaVersion({
    $core.int? session,
    $fixnum.Int64? schemaVersion,
  }) {
    final result = SetSchemaVersion._();
    if (session != null) result.session = session;
    if (schemaVersion != null) result.schemaVersion = schemaVersion;
    return result;
  }

  SetSchemaVersion._();

  factory SetSchemaVersion.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetSchemaVersion()..mergeFromBuffer(data, registry);
  factory SetSchemaVersion.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetSchemaVersion()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetSchemaVersion',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'driftremote'),
      createEmptyInstance: SetSchemaVersion.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'session')
    ..aInt64(2, _omitFieldNames ? '' : 'schemaVersion')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetSchemaVersion clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetSchemaVersion copyWith(void Function(SetSchemaVersion) updates) =>
      super.copyWith((message) => updates(message as SetSchemaVersion))
          as SetSchemaVersion;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SetSchemaVersion() / SetSchemaVersion.new instead')
  static SetSchemaVersion create() => SetSchemaVersion._();
  static $pb.GeneratedMessage $_createMessage() => SetSchemaVersion._();
  @$core.override
  SetSchemaVersion createEmptyInstance() => SetSchemaVersion._();
  @$core.pragma('dart2js:noInline')
  static SetSchemaVersion getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetSchemaVersion>(
          SetSchemaVersion.$_createMessage);
  static SetSchemaVersion? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get session => $_getIZ(0);
  @$pb.TagNumber(1)
  set session($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSession() => $_has(0);
  @$pb.TagNumber(1)
  void clearSession() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get schemaVersion => $_getI64(1);
  @$pb.TagNumber(2)
  set schemaVersion($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSchemaVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearSchemaVersion() => $_clearField(2);
}

class BeginRequest extends $pb.GeneratedMessage {
  factory BeginRequest({
    $core.int? session,
    TransactionOptions? options,
  }) {
    final result = BeginRequest._();
    if (session != null) result.session = session;
    if (options != null) result.options = options;
    return result;
  }

  BeginRequest._();

  factory BeginRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BeginRequest()..mergeFromBuffer(data, registry);
  factory BeginRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BeginRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BeginRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'driftremote'),
      createEmptyInstance: BeginRequest.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'session')
    ..aOM<TransactionOptions>(2, _omitFieldNames ? '' : 'options',
        subBuilder: TransactionOptions.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BeginRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BeginRequest copyWith(void Function(BeginRequest) updates) =>
      super.copyWith((message) => updates(message as BeginRequest))
          as BeginRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use BeginRequest() / BeginRequest.new instead')
  static BeginRequest create() => BeginRequest._();
  static $pb.GeneratedMessage $_createMessage() => BeginRequest._();
  @$core.override
  BeginRequest createEmptyInstance() => BeginRequest._();
  @$core.pragma('dart2js:noInline')
  static BeginRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BeginRequest>(
          BeginRequest.$_createMessage);
  static BeginRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get session => $_getIZ(0);
  @$pb.TagNumber(1)
  set session($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSession() => $_has(0);
  @$pb.TagNumber(1)
  void clearSession() => $_clearField(1);

  @$pb.TagNumber(2)
  TransactionOptions get options => $_getN(1);
  @$pb.TagNumber(2)
  set options(TransactionOptions value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasOptions() => $_has(1);
  @$pb.TagNumber(2)
  void clearOptions() => $_clearField(2);
  @$pb.TagNumber(2)
  TransactionOptions ensureOptions() => $_ensure(1);
}

class TransactionOptions extends $pb.GeneratedMessage {
  factory TransactionOptions({
    $core.bool? deferForeignKeys,
    $core.bool? readOnly,
  }) {
    final result = TransactionOptions._();
    if (deferForeignKeys != null) result.deferForeignKeys = deferForeignKeys;
    if (readOnly != null) result.readOnly = readOnly;
    return result;
  }

  TransactionOptions._();

  factory TransactionOptions.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TransactionOptions()..mergeFromBuffer(data, registry);
  factory TransactionOptions.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TransactionOptions()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TransactionOptions',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'driftremote'),
      createEmptyInstance: TransactionOptions.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'deferForeignKeys')
    ..aOB(2, _omitFieldNames ? '' : 'readOnly')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TransactionOptions clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TransactionOptions copyWith(void Function(TransactionOptions) updates) =>
      super.copyWith((message) => updates(message as TransactionOptions))
          as TransactionOptions;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TransactionOptions() / TransactionOptions.new instead')
  static TransactionOptions create() => TransactionOptions._();
  static $pb.GeneratedMessage $_createMessage() => TransactionOptions._();
  @$core.override
  TransactionOptions createEmptyInstance() => TransactionOptions._();
  @$core.pragma('dart2js:noInline')
  static TransactionOptions getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TransactionOptions>(
          TransactionOptions.$_createMessage);
  static TransactionOptions? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get deferForeignKeys => $_getBF(0);
  @$pb.TagNumber(1)
  set deferForeignKeys($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeferForeignKeys() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeferForeignKeys() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get readOnly => $_getBF(1);
  @$pb.TagNumber(2)
  set readOnly($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasReadOnly() => $_has(1);
  @$pb.TagNumber(2)
  void clearReadOnly() => $_clearField(2);
}

class ExecuteRequest extends $pb.GeneratedMessage {
  factory ExecuteRequest({
    $core.int? session,
    StatementInfo? statement,
  }) {
    final result = ExecuteRequest._();
    if (session != null) result.session = session;
    if (statement != null) result.statement = statement;
    return result;
  }

  ExecuteRequest._();

  factory ExecuteRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ExecuteRequest()..mergeFromBuffer(data, registry);
  factory ExecuteRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ExecuteRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExecuteRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'driftremote'),
      createEmptyInstance: ExecuteRequest.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'session')
    ..aOM<StatementInfo>(2, _omitFieldNames ? '' : 'statement',
        subBuilder: StatementInfo.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExecuteRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExecuteRequest copyWith(void Function(ExecuteRequest) updates) =>
      super.copyWith((message) => updates(message as ExecuteRequest))
          as ExecuteRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ExecuteRequest() / ExecuteRequest.new instead')
  static ExecuteRequest create() => ExecuteRequest._();
  static $pb.GeneratedMessage $_createMessage() => ExecuteRequest._();
  @$core.override
  ExecuteRequest createEmptyInstance() => ExecuteRequest._();
  @$core.pragma('dart2js:noInline')
  static ExecuteRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ExecuteRequest>(
          ExecuteRequest.$_createMessage);
  static ExecuteRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get session => $_getIZ(0);
  @$pb.TagNumber(1)
  set session($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSession() => $_has(0);
  @$pb.TagNumber(1)
  void clearSession() => $_clearField(1);

  @$pb.TagNumber(2)
  StatementInfo get statement => $_getN(1);
  @$pb.TagNumber(2)
  set statement(StatementInfo value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasStatement() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatement() => $_clearField(2);
  @$pb.TagNumber(2)
  StatementInfo ensureStatement() => $_ensure(1);
}

class ExecuteBatchRequest extends $pb.GeneratedMessage {
  factory ExecuteBatchRequest({
    $core.int? session,
    StatementBatch? batch,
  }) {
    final result = ExecuteBatchRequest._();
    if (session != null) result.session = session;
    if (batch != null) result.batch = batch;
    return result;
  }

  ExecuteBatchRequest._();

  factory ExecuteBatchRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ExecuteBatchRequest()..mergeFromBuffer(data, registry);
  factory ExecuteBatchRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ExecuteBatchRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExecuteBatchRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'driftremote'),
      createEmptyInstance: ExecuteBatchRequest.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'session')
    ..aOM<StatementBatch>(2, _omitFieldNames ? '' : 'batch',
        subBuilder: StatementBatch.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExecuteBatchRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExecuteBatchRequest copyWith(void Function(ExecuteBatchRequest) updates) =>
      super.copyWith((message) => updates(message as ExecuteBatchRequest))
          as ExecuteBatchRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use ExecuteBatchRequest() / ExecuteBatchRequest.new instead')
  static ExecuteBatchRequest create() => ExecuteBatchRequest._();
  static $pb.GeneratedMessage $_createMessage() => ExecuteBatchRequest._();
  @$core.override
  ExecuteBatchRequest createEmptyInstance() => ExecuteBatchRequest._();
  @$core.pragma('dart2js:noInline')
  static ExecuteBatchRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExecuteBatchRequest>(
          ExecuteBatchRequest.$_createMessage);
  static ExecuteBatchRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get session => $_getIZ(0);
  @$pb.TagNumber(1)
  set session($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSession() => $_has(0);
  @$pb.TagNumber(1)
  void clearSession() => $_clearField(1);

  @$pb.TagNumber(2)
  StatementBatch get batch => $_getN(1);
  @$pb.TagNumber(2)
  set batch(StatementBatch value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasBatch() => $_has(1);
  @$pb.TagNumber(2)
  void clearBatch() => $_clearField(2);
  @$pb.TagNumber(2)
  StatementBatch ensureBatch() => $_ensure(1);
}

class StatementBatch extends $pb.GeneratedMessage {
  factory StatementBatch({
    $core.Iterable<$core.String>? sql,
    $core.Iterable<StatementInBatch>? statements,
  }) {
    final result = StatementBatch._();
    if (sql != null) result.sql.addAll(sql);
    if (statements != null) result.statements.addAll(statements);
    return result;
  }

  StatementBatch._();

  factory StatementBatch.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StatementBatch()..mergeFromBuffer(data, registry);
  factory StatementBatch.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StatementBatch()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StatementBatch',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'driftremote'),
      createEmptyInstance: StatementBatch.$_createMessage)
    ..pPS(1, _omitFieldNames ? '' : 'sql')
    ..pPM<StatementInBatch>(2, _omitFieldNames ? '' : 'statements',
        subBuilder: StatementInBatch.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatementBatch clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatementBatch copyWith(void Function(StatementBatch) updates) =>
      super.copyWith((message) => updates(message as StatementBatch))
          as StatementBatch;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use StatementBatch() / StatementBatch.new instead')
  static StatementBatch create() => StatementBatch._();
  static $pb.GeneratedMessage $_createMessage() => StatementBatch._();
  @$core.override
  StatementBatch createEmptyInstance() => StatementBatch._();
  @$core.pragma('dart2js:noInline')
  static StatementBatch getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StatementBatch>(
          StatementBatch.$_createMessage);
  static StatementBatch? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get sql => $_getList(0);

  @$pb.TagNumber(2)
  $pb.PbList<StatementInBatch> get statements => $_getList(1);
}

class StatementInBatch extends $pb.GeneratedMessage {
  factory StatementInBatch({
    $core.int? sqlIndex,
    StatementInfo? info,
  }) {
    final result = StatementInBatch._();
    if (sqlIndex != null) result.sqlIndex = sqlIndex;
    if (info != null) result.info = info;
    return result;
  }

  StatementInBatch._();

  factory StatementInBatch.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StatementInBatch()..mergeFromBuffer(data, registry);
  factory StatementInBatch.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StatementInBatch()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StatementInBatch',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'driftremote'),
      createEmptyInstance: StatementInBatch.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'sqlIndex')
    ..aOM<StatementInfo>(2, _omitFieldNames ? '' : 'info',
        subBuilder: StatementInfo.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatementInBatch clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatementInBatch copyWith(void Function(StatementInBatch) updates) =>
      super.copyWith((message) => updates(message as StatementInBatch))
          as StatementInBatch;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use StatementInBatch() / StatementInBatch.new instead')
  static StatementInBatch create() => StatementInBatch._();
  static $pb.GeneratedMessage $_createMessage() => StatementInBatch._();
  @$core.override
  StatementInBatch createEmptyInstance() => StatementInBatch._();
  @$core.pragma('dart2js:noInline')
  static StatementInBatch getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StatementInBatch>(
          StatementInBatch.$_createMessage);
  static StatementInBatch? _defaultInstance;

  /// Index into `StatementBatch.sql`.
  @$pb.TagNumber(1)
  $core.int get sqlIndex => $_getIZ(0);
  @$pb.TagNumber(1)
  set sqlIndex($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSqlIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearSqlIndex() => $_clearField(1);

  @$pb.TagNumber(2)
  StatementInfo get info => $_getN(1);
  @$pb.TagNumber(2)
  set info(StatementInfo value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasInfo() => $_has(1);
  @$pb.TagNumber(2)
  void clearInfo() => $_clearField(2);
  @$pb.TagNumber(2)
  StatementInfo ensureInfo() => $_ensure(1);
}

class StatementInfo extends $pb.GeneratedMessage {
  factory StatementInfo({
    $core.String? sql,
    $core.bool? needsResultSet,
    $core.Iterable<SqlValue>? variables,
    $core.Iterable<$core.String>? watchedTables,
    $core.Iterable<TableUpdate>? expectedWrites,
    $core.bool? isReadOnly,
  }) {
    final result = StatementInfo._();
    if (sql != null) result.sql = sql;
    if (needsResultSet != null) result.needsResultSet = needsResultSet;
    if (variables != null) result.variables.addAll(variables);
    if (watchedTables != null) result.watchedTables.addAll(watchedTables);
    if (expectedWrites != null) result.expectedWrites.addAll(expectedWrites);
    if (isReadOnly != null) result.isReadOnly = isReadOnly;
    return result;
  }

  StatementInfo._();

  factory StatementInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StatementInfo()..mergeFromBuffer(data, registry);
  factory StatementInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StatementInfo()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StatementInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'driftremote'),
      createEmptyInstance: StatementInfo.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'sql')
    ..aOB(2, _omitFieldNames ? '' : 'needsResultSet')
    ..pPM<SqlValue>(3, _omitFieldNames ? '' : 'variables',
        subBuilder: SqlValue.$_createMessage)
    ..pPS(4, _omitFieldNames ? '' : 'watchedTables')
    ..pPM<TableUpdate>(5, _omitFieldNames ? '' : 'expectedWrites',
        subBuilder: TableUpdate.$_createMessage)
    ..aOB(6, _omitFieldNames ? '' : 'isReadOnly')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatementInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatementInfo copyWith(void Function(StatementInfo) updates) =>
      super.copyWith((message) => updates(message as StatementInfo))
          as StatementInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use StatementInfo() / StatementInfo.new instead')
  static StatementInfo create() => StatementInfo._();
  static $pb.GeneratedMessage $_createMessage() => StatementInfo._();
  @$core.override
  StatementInfo createEmptyInstance() => StatementInfo._();
  @$core.pragma('dart2js:noInline')
  static StatementInfo getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StatementInfo>(
          StatementInfo.$_createMessage);
  static StatementInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sql => $_getSZ(0);
  @$pb.TagNumber(1)
  set sql($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSql() => $_has(0);
  @$pb.TagNumber(1)
  void clearSql() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get needsResultSet => $_getBF(1);
  @$pb.TagNumber(2)
  set needsResultSet($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNeedsResultSet() => $_has(1);
  @$pb.TagNumber(2)
  void clearNeedsResultSet() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<SqlValue> get variables => $_getList(2);

  @$pb.TagNumber(4)
  $pb.PbList<$core.String> get watchedTables => $_getList(3);

  @$pb.TagNumber(5)
  $pb.PbList<TableUpdate> get expectedWrites => $_getList(4);

  @$pb.TagNumber(6)
  $core.bool get isReadOnly => $_getBF(5);
  @$pb.TagNumber(6)
  set isReadOnly($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasIsReadOnly() => $_has(5);
  @$pb.TagNumber(6)
  void clearIsReadOnly() => $_clearField(6);
}

enum SqlValue_Value { intValue, doubleValue, textValue, blobValue, notSet }

/// A value bound to a statement or returned in a result set.
///
/// This covers the values used by the SQLite dialect.
class SqlValue extends $pb.GeneratedMessage {
  factory SqlValue({
    $fixnum.Int64? intValue,
    $core.double? doubleValue,
    $core.String? textValue,
    $core.List<$core.int>? blobValue,
  }) {
    final result = SqlValue._();
    if (intValue != null) result.intValue = intValue;
    if (doubleValue != null) result.doubleValue = doubleValue;
    if (textValue != null) result.textValue = textValue;
    if (blobValue != null) result.blobValue = blobValue;
    return result;
  }

  SqlValue._();

  factory SqlValue.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SqlValue()..mergeFromBuffer(data, registry);
  factory SqlValue.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SqlValue()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, SqlValue_Value> _SqlValue_ValueByTag = {
    1: SqlValue_Value.intValue,
    2: SqlValue_Value.doubleValue,
    3: SqlValue_Value.textValue,
    4: SqlValue_Value.blobValue,
    0: SqlValue_Value.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SqlValue',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'driftremote'),
      createEmptyInstance: SqlValue.$_createMessage)
    ..oo(0, [1, 2, 3, 4])
    ..aInt64(1, _omitFieldNames ? '' : 'intValue')
    ..aD(2, _omitFieldNames ? '' : 'doubleValue')
    ..aOS(3, _omitFieldNames ? '' : 'textValue')
    ..a<$core.List<$core.int>>(
        4, _omitFieldNames ? '' : 'blobValue', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SqlValue clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SqlValue copyWith(void Function(SqlValue) updates) =>
      super.copyWith((message) => updates(message as SqlValue)) as SqlValue;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SqlValue() / SqlValue.new instead')
  static SqlValue create() => SqlValue._();
  static $pb.GeneratedMessage $_createMessage() => SqlValue._();
  @$core.override
  SqlValue createEmptyInstance() => SqlValue._();
  @$core.pragma('dart2js:noInline')
  static SqlValue getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SqlValue>(SqlValue.$_createMessage);
  static SqlValue? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  SqlValue_Value whichValue() => _SqlValue_ValueByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  void clearValue() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $fixnum.Int64 get intValue => $_getI64(0);
  @$pb.TagNumber(1)
  set intValue($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIntValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearIntValue() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get doubleValue => $_getN(1);
  @$pb.TagNumber(2)
  set doubleValue($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDoubleValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearDoubleValue() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get textValue => $_getSZ(2);
  @$pb.TagNumber(3)
  set textValue($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTextValue() => $_has(2);
  @$pb.TagNumber(3)
  void clearTextValue() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get blobValue => $_getN(3);
  @$pb.TagNumber(4)
  set blobValue($core.List<$core.int> value) => $_setBytes(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBlobValue() => $_has(3);
  @$pb.TagNumber(4)
  void clearBlobValue() => $_clearField(4);
}

class TableUpdate extends $pb.GeneratedMessage {
  factory TableUpdate({
    $core.String? table,
    UpdateKind? kind,
  }) {
    final result = TableUpdate._();
    if (table != null) result.table = table;
    if (kind != null) result.kind = kind;
    return result;
  }

  TableUpdate._();

  factory TableUpdate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TableUpdate()..mergeFromBuffer(data, registry);
  factory TableUpdate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TableUpdate()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TableUpdate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'driftremote'),
      createEmptyInstance: TableUpdate.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'table')
    ..aE<UpdateKind>(2, _omitFieldNames ? '' : 'kind',
        enumValues: UpdateKind.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TableUpdate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TableUpdate copyWith(void Function(TableUpdate) updates) =>
      super.copyWith((message) => updates(message as TableUpdate))
          as TableUpdate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TableUpdate() / TableUpdate.new instead')
  static TableUpdate create() => TableUpdate._();
  static $pb.GeneratedMessage $_createMessage() => TableUpdate._();
  @$core.override
  TableUpdate createEmptyInstance() => TableUpdate._();
  @$core.pragma('dart2js:noInline')
  static TableUpdate getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TableUpdate>(
          TableUpdate.$_createMessage);
  static TableUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get table => $_getSZ(0);
  @$pb.TagNumber(1)
  set table($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTable() => $_has(0);
  @$pb.TagNumber(1)
  void clearTable() => $_clearField(1);

  @$pb.TagNumber(2)
  UpdateKind get kind => $_getN(1);
  @$pb.TagNumber(2)
  set kind(UpdateKind value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearKind() => $_clearField(2);
}

/// A set of updates handled together, mirroring `Set<TableUpdate>`.
class TableUpdates extends $pb.GeneratedMessage {
  factory TableUpdates({
    $core.Iterable<TableUpdate>? updates,
  }) {
    final result = TableUpdates._();
    if (updates != null) result.updates.addAll(updates);
    return result;
  }

  TableUpdates._();

  factory TableUpdates.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TableUpdates()..mergeFromBuffer(data, registry);
  factory TableUpdates.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TableUpdates()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TableUpdates',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'driftremote'),
      createEmptyInstance: TableUpdates.$_createMessage)
    ..pPM<TableUpdate>(1, _omitFieldNames ? '' : 'updates',
        subBuilder: TableUpdate.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TableUpdates clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TableUpdates copyWith(void Function(TableUpdates) updates) =>
      super.copyWith((message) => updates(message as TableUpdates))
          as TableUpdates;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TableUpdates() / TableUpdates.new instead')
  static TableUpdates create() => TableUpdates._();
  static $pb.GeneratedMessage $_createMessage() => TableUpdates._();
  @$core.override
  TableUpdates createEmptyInstance() => TableUpdates._();
  @$core.pragma('dart2js:noInline')
  static TableUpdates getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TableUpdates>(
          TableUpdates.$_createMessage);
  static TableUpdates? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<TableUpdate> get updates => $_getList(0);
}

class QueryResult extends $pb.GeneratedMessage {
  factory QueryResult({
    $fixnum.Int64? affectedRows,
    $fixnum.Int64? lastInsertRowId,
    ResultSet? resultSet,
  }) {
    final result = QueryResult._();
    if (affectedRows != null) result.affectedRows = affectedRows;
    if (lastInsertRowId != null) result.lastInsertRowId = lastInsertRowId;
    if (resultSet != null) result.resultSet = resultSet;
    return result;
  }

  QueryResult._();

  factory QueryResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      QueryResult()..mergeFromBuffer(data, registry);
  factory QueryResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      QueryResult()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'QueryResult',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'driftremote'),
      createEmptyInstance: QueryResult.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'affectedRows')
    ..aInt64(2, _omitFieldNames ? '' : 'lastInsertRowId')
    ..aOM<ResultSet>(3, _omitFieldNames ? '' : 'resultSet',
        subBuilder: ResultSet.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QueryResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QueryResult copyWith(void Function(QueryResult) updates) =>
      super.copyWith((message) => updates(message as QueryResult))
          as QueryResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use QueryResult() / QueryResult.new instead')
  static QueryResult create() => QueryResult._();
  static $pb.GeneratedMessage $_createMessage() => QueryResult._();
  @$core.override
  QueryResult createEmptyInstance() => QueryResult._();
  @$core.pragma('dart2js:noInline')
  static QueryResult getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<QueryResult>(
          QueryResult.$_createMessage);
  static QueryResult? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get affectedRows => $_getI64(0);
  @$pb.TagNumber(1)
  set affectedRows($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAffectedRows() => $_has(0);
  @$pb.TagNumber(1)
  void clearAffectedRows() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get lastInsertRowId => $_getI64(1);
  @$pb.TagNumber(2)
  set lastInsertRowId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLastInsertRowId() => $_has(1);
  @$pb.TagNumber(2)
  void clearLastInsertRowId() => $_clearField(2);

  /// Only set if `StatementInfo.needs_result_set` was enabled.
  @$pb.TagNumber(3)
  ResultSet get resultSet => $_getN(2);
  @$pb.TagNumber(3)
  set resultSet(ResultSet value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasResultSet() => $_has(2);
  @$pb.TagNumber(3)
  void clearResultSet() => $_clearField(3);
  @$pb.TagNumber(3)
  ResultSet ensureResultSet() => $_ensure(2);
}

class BatchResult extends $pb.GeneratedMessage {
  factory BatchResult({
    $core.Iterable<QueryResult>? results,
  }) {
    final result = BatchResult._();
    if (results != null) result.results.addAll(results);
    return result;
  }

  BatchResult._();

  factory BatchResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BatchResult()..mergeFromBuffer(data, registry);
  factory BatchResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BatchResult()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BatchResult',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'driftremote'),
      createEmptyInstance: BatchResult.$_createMessage)
    ..pPM<QueryResult>(1, _omitFieldNames ? '' : 'results',
        subBuilder: QueryResult.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BatchResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BatchResult copyWith(void Function(BatchResult) updates) =>
      super.copyWith((message) => updates(message as BatchResult))
          as BatchResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use BatchResult() / BatchResult.new instead')
  static BatchResult create() => BatchResult._();
  static $pb.GeneratedMessage $_createMessage() => BatchResult._();
  @$core.override
  BatchResult createEmptyInstance() => BatchResult._();
  @$core.pragma('dart2js:noInline')
  static BatchResult getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BatchResult>(
          BatchResult.$_createMessage);
  static BatchResult? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<QueryResult> get results => $_getList(0);
}

class ResultSet extends $pb.GeneratedMessage {
  factory ResultSet({
    $core.Iterable<$core.String>? columnNames,
    $core.Iterable<Row>? rows,
  }) {
    final result = ResultSet._();
    if (columnNames != null) result.columnNames.addAll(columnNames);
    if (rows != null) result.rows.addAll(rows);
    return result;
  }

  ResultSet._();

  factory ResultSet.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResultSet()..mergeFromBuffer(data, registry);
  factory ResultSet.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResultSet()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResultSet',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'driftremote'),
      createEmptyInstance: ResultSet.$_createMessage)
    ..pPS(1, _omitFieldNames ? '' : 'columnNames')
    ..pPM<Row>(2, _omitFieldNames ? '' : 'rows',
        subBuilder: Row.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResultSet clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResultSet copyWith(void Function(ResultSet) updates) =>
      super.copyWith((message) => updates(message as ResultSet)) as ResultSet;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResultSet() / ResultSet.new instead')
  static ResultSet create() => ResultSet._();
  static $pb.GeneratedMessage $_createMessage() => ResultSet._();
  @$core.override
  ResultSet createEmptyInstance() => ResultSet._();
  @$core.pragma('dart2js:noInline')
  static ResultSet getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResultSet>(ResultSet.$_createMessage);
  static ResultSet? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get columnNames => $_getList(0);

  @$pb.TagNumber(2)
  $pb.PbList<Row> get rows => $_getList(1);
}

class Row extends $pb.GeneratedMessage {
  factory Row({
    $core.Iterable<SqlValue>? values,
  }) {
    final result = Row._();
    if (values != null) result.values.addAll(values);
    return result;
  }

  Row._();

  factory Row.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Row()..mergeFromBuffer(data, registry);
  factory Row.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Row()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Row',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'driftremote'),
      createEmptyInstance: Row.$_createMessage)
    ..pPM<SqlValue>(1, _omitFieldNames ? '' : 'values',
        subBuilder: SqlValue.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Row clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Row copyWith(void Function(Row) updates) =>
      super.copyWith((message) => updates(message as Row)) as Row;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Row() / Row.new instead')
  static Row create() => Row._();
  static $pb.GeneratedMessage $_createMessage() => Row._();
  @$core.override
  Row createEmptyInstance() => Row._();
  @$core.pragma('dart2js:noInline')
  static Row getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Row>(Row.$_createMessage);
  static Row? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<SqlValue> get values => $_getList(0);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
