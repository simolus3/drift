// This is a generated file - do not edit.
//
// Generated from drift.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'drift.pb.dart' as $0;

export 'drift.pb.dart';

@$pb.GrpcServiceName('driftremote.DatabaseService')
class DatabaseServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  DatabaseServiceClient(super.channel, {super.options, super.interceptors});

  /// Opens the outermost session.
  $grpc.ResponseFuture<$0.CreatedSession> connect(
    $0.ConnectRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$connect, request, options: options);
  }

  $grpc.ResponseFuture<$0.QueryResult> execute(
    $0.ExecuteRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$execute, request, options: options);
  }

  $grpc.ResponseFuture<$0.BatchResult> executeBatch(
    $0.ExecuteBatchRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$executeBatch, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> close(
    $0.SessionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$close, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> awaitClosed(
    $0.SessionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$awaitClosed, request, options: options);
  }

  $grpc.ResponseFuture<$0.GetSchemaVersionResult> schemaVersionGet(
    $0.GetSchemaVersion request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$schemaVersionGet, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> schemaVersionSet(
    $0.SetSchemaVersion request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$schemaVersionSet, request, options: options);
  }

  $grpc.ResponseFuture<$0.CreatedSession> begin(
    $0.BeginRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$begin, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> commit(
    $0.SessionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$commit, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> rollback(
    $0.SessionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$rollback, request, options: options);
  }

  $grpc.ResponseFuture<$0.CreatedSession> exclusive(
    $0.SessionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$exclusive, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> dispatchTableUpdates(
    $0.TableUpdates request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$dispatchTableUpdates, request, options: options);
  }

  $grpc.ResponseStream<$0.TableUpdates> tableUpdateNotifications(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$tableUpdateNotifications, $async.Stream.fromIterable([request]),
        options: options);
  }

  // method descriptors

  static final _$connect =
      $grpc.ClientMethod<$0.ConnectRequest, $0.CreatedSession>(
          '/driftremote.DatabaseService/Connect',
          ($0.ConnectRequest value) => value.writeToBuffer(),
          $0.CreatedSession.fromBuffer);
  static final _$execute =
      $grpc.ClientMethod<$0.ExecuteRequest, $0.QueryResult>(
          '/driftremote.DatabaseService/Execute',
          ($0.ExecuteRequest value) => value.writeToBuffer(),
          $0.QueryResult.fromBuffer);
  static final _$executeBatch =
      $grpc.ClientMethod<$0.ExecuteBatchRequest, $0.BatchResult>(
          '/driftremote.DatabaseService/ExecuteBatch',
          ($0.ExecuteBatchRequest value) => value.writeToBuffer(),
          $0.BatchResult.fromBuffer);
  static final _$close = $grpc.ClientMethod<$0.SessionRequest, $0.Empty>(
      '/driftremote.DatabaseService/Close',
      ($0.SessionRequest value) => value.writeToBuffer(),
      $0.Empty.fromBuffer);
  static final _$awaitClosed = $grpc.ClientMethod<$0.SessionRequest, $0.Empty>(
      '/driftremote.DatabaseService/AwaitClosed',
      ($0.SessionRequest value) => value.writeToBuffer(),
      $0.Empty.fromBuffer);
  static final _$schemaVersionGet =
      $grpc.ClientMethod<$0.GetSchemaVersion, $0.GetSchemaVersionResult>(
          '/driftremote.DatabaseService/SchemaVersionGet',
          ($0.GetSchemaVersion value) => value.writeToBuffer(),
          $0.GetSchemaVersionResult.fromBuffer);
  static final _$schemaVersionSet =
      $grpc.ClientMethod<$0.SetSchemaVersion, $0.Empty>(
          '/driftremote.DatabaseService/SchemaVersionSet',
          ($0.SetSchemaVersion value) => value.writeToBuffer(),
          $0.Empty.fromBuffer);
  static final _$begin = $grpc.ClientMethod<$0.BeginRequest, $0.CreatedSession>(
      '/driftremote.DatabaseService/Begin',
      ($0.BeginRequest value) => value.writeToBuffer(),
      $0.CreatedSession.fromBuffer);
  static final _$commit = $grpc.ClientMethod<$0.SessionRequest, $0.Empty>(
      '/driftremote.DatabaseService/Commit',
      ($0.SessionRequest value) => value.writeToBuffer(),
      $0.Empty.fromBuffer);
  static final _$rollback = $grpc.ClientMethod<$0.SessionRequest, $0.Empty>(
      '/driftremote.DatabaseService/Rollback',
      ($0.SessionRequest value) => value.writeToBuffer(),
      $0.Empty.fromBuffer);
  static final _$exclusive =
      $grpc.ClientMethod<$0.SessionRequest, $0.CreatedSession>(
          '/driftremote.DatabaseService/Exclusive',
          ($0.SessionRequest value) => value.writeToBuffer(),
          $0.CreatedSession.fromBuffer);
  static final _$dispatchTableUpdates =
      $grpc.ClientMethod<$0.TableUpdates, $0.Empty>(
          '/driftremote.DatabaseService/DispatchTableUpdates',
          ($0.TableUpdates value) => value.writeToBuffer(),
          $0.Empty.fromBuffer);
  static final _$tableUpdateNotifications =
      $grpc.ClientMethod<$0.Empty, $0.TableUpdates>(
          '/driftremote.DatabaseService/TableUpdateNotifications',
          ($0.Empty value) => value.writeToBuffer(),
          $0.TableUpdates.fromBuffer);
}

@$pb.GrpcServiceName('driftremote.DatabaseService')
abstract class DatabaseServiceBase extends $grpc.Service {
  $core.String get $name => 'driftremote.DatabaseService';

  DatabaseServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.ConnectRequest, $0.CreatedSession>(
        'Connect',
        connect_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ConnectRequest.fromBuffer(value),
        ($0.CreatedSession value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ExecuteRequest, $0.QueryResult>(
        'Execute',
        execute_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ExecuteRequest.fromBuffer(value),
        ($0.QueryResult value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ExecuteBatchRequest, $0.BatchResult>(
        'ExecuteBatch',
        executeBatch_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ExecuteBatchRequest.fromBuffer(value),
        ($0.BatchResult value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SessionRequest, $0.Empty>(
        'Close',
        close_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SessionRequest.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SessionRequest, $0.Empty>(
        'AwaitClosed',
        awaitClosed_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SessionRequest.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.GetSchemaVersion, $0.GetSchemaVersionResult>(
            'SchemaVersionGet',
            schemaVersionGet_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.GetSchemaVersion.fromBuffer(value),
            ($0.GetSchemaVersionResult value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SetSchemaVersion, $0.Empty>(
        'SchemaVersionSet',
        schemaVersionSet_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SetSchemaVersion.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.BeginRequest, $0.CreatedSession>(
        'Begin',
        begin_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.BeginRequest.fromBuffer(value),
        ($0.CreatedSession value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SessionRequest, $0.Empty>(
        'Commit',
        commit_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SessionRequest.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SessionRequest, $0.Empty>(
        'Rollback',
        rollback_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SessionRequest.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SessionRequest, $0.CreatedSession>(
        'Exclusive',
        exclusive_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SessionRequest.fromBuffer(value),
        ($0.CreatedSession value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.TableUpdates, $0.Empty>(
        'DispatchTableUpdates',
        dispatchTableUpdates_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.TableUpdates.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.TableUpdates>(
        'TableUpdateNotifications',
        tableUpdateNotifications_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.TableUpdates value) => value.writeToBuffer()));
  }

  $async.Future<$0.CreatedSession> connect_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ConnectRequest> $request) async {
    return connect($call, await $request);
  }

  $async.Future<$0.CreatedSession> connect(
      $grpc.ServiceCall call, $0.ConnectRequest request);

  $async.Future<$0.QueryResult> execute_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ExecuteRequest> $request) async {
    return execute($call, await $request);
  }

  $async.Future<$0.QueryResult> execute(
      $grpc.ServiceCall call, $0.ExecuteRequest request);

  $async.Future<$0.BatchResult> executeBatch_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ExecuteBatchRequest> $request) async {
    return executeBatch($call, await $request);
  }

  $async.Future<$0.BatchResult> executeBatch(
      $grpc.ServiceCall call, $0.ExecuteBatchRequest request);

  $async.Future<$0.Empty> close_Pre($grpc.ServiceCall $call,
      $async.Future<$0.SessionRequest> $request) async {
    return close($call, await $request);
  }

  $async.Future<$0.Empty> close(
      $grpc.ServiceCall call, $0.SessionRequest request);

  $async.Future<$0.Empty> awaitClosed_Pre($grpc.ServiceCall $call,
      $async.Future<$0.SessionRequest> $request) async {
    return awaitClosed($call, await $request);
  }

  $async.Future<$0.Empty> awaitClosed(
      $grpc.ServiceCall call, $0.SessionRequest request);

  $async.Future<$0.GetSchemaVersionResult> schemaVersionGet_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetSchemaVersion> $request) async {
    return schemaVersionGet($call, await $request);
  }

  $async.Future<$0.GetSchemaVersionResult> schemaVersionGet(
      $grpc.ServiceCall call, $0.GetSchemaVersion request);

  $async.Future<$0.Empty> schemaVersionSet_Pre($grpc.ServiceCall $call,
      $async.Future<$0.SetSchemaVersion> $request) async {
    return schemaVersionSet($call, await $request);
  }

  $async.Future<$0.Empty> schemaVersionSet(
      $grpc.ServiceCall call, $0.SetSchemaVersion request);

  $async.Future<$0.CreatedSession> begin_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.BeginRequest> $request) async {
    return begin($call, await $request);
  }

  $async.Future<$0.CreatedSession> begin(
      $grpc.ServiceCall call, $0.BeginRequest request);

  $async.Future<$0.Empty> commit_Pre($grpc.ServiceCall $call,
      $async.Future<$0.SessionRequest> $request) async {
    return commit($call, await $request);
  }

  $async.Future<$0.Empty> commit(
      $grpc.ServiceCall call, $0.SessionRequest request);

  $async.Future<$0.Empty> rollback_Pre($grpc.ServiceCall $call,
      $async.Future<$0.SessionRequest> $request) async {
    return rollback($call, await $request);
  }

  $async.Future<$0.Empty> rollback(
      $grpc.ServiceCall call, $0.SessionRequest request);

  $async.Future<$0.CreatedSession> exclusive_Pre($grpc.ServiceCall $call,
      $async.Future<$0.SessionRequest> $request) async {
    return exclusive($call, await $request);
  }

  $async.Future<$0.CreatedSession> exclusive(
      $grpc.ServiceCall call, $0.SessionRequest request);

  $async.Future<$0.Empty> dispatchTableUpdates_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.TableUpdates> $request) async {
    return dispatchTableUpdates($call, await $request);
  }

  $async.Future<$0.Empty> dispatchTableUpdates(
      $grpc.ServiceCall call, $0.TableUpdates request);

  $async.Stream<$0.TableUpdates> tableUpdateNotifications_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async* {
    yield* tableUpdateNotifications($call, await $request);
  }

  $async.Stream<$0.TableUpdates> tableUpdateNotifications(
      $grpc.ServiceCall call, $0.Empty request);
}
