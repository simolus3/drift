import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/src/runtime/executor/executor.dart';
import 'package:drift/src/runtime/executor/helpers/delegates.dart';
import 'package:drift/src/runtime/executor/helpers/engines.dart';
import 'package:drift/src/runtime/executor/helpers/results.dart';
import 'package:drift/src/runtime/query_builder/query_builder.dart';
import 'package:drift_network_bridge/src/network/host_connection.dart';
import 'package:drift_network_bridge/src/network/serialization/network_batched_statement.dart';
import 'package:drift_network_bridge/src/network/serialization/network_statement.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import 'constants/constants.dart';

class TestMqttHost extends HostConnection {
  // final client = MqttServerClient('test.mosquitto.org', 'drift_client');
  final client = MqttServerClient('127.0.0.1', 'drift_host');
  QueryExecutorUser? user;
  TestMqttHost(DelegatedDatabase db) : super(db);

  @override
  FutureOr<bool> get isOpen => parentDelegate.isOpen;

  @override
  TransactionDelegate get transactionDelegate => parentDelegate.transactionDelegate;

  @override
  Future<Function> open(QueryExecutorUser db) async {
    user ??= db;
    await parentDelegate.open(db);
    await connect();
    return Future.value((){});
  }

  @override
  bool get isInTransaction => parentDelegate.isInTransaction;

  @override
  bool isConnect() => client.connectionStatus!.state == MqttConnectionState.connected;

  @override
  Future<void> close() => parentDelegate.close();

  @override
  Future<void> runBatched(BatchedStatements statements) => parentDelegate.runBatched(statements);

  @override
  Future<void> runCustom(String statement, List<Object?> args) => parentDelegate.runCustom(statement,args);



  @override
  Future<int> runInsert(String statement, List<Object?> args) =>  parentDelegate.runInsert(statement, args);

  @override
  Future<QueryResult> runSelect(String statement, List<Object?> args) async => parentDelegate.runSelect(statement, args);

  @override
  Future<int> runUpdate(String statement, List<Object?> args ) => parentDelegate.runUpdate(statement, args);

  @override
  DbVersionDelegate get versionDelegate => parentDelegate.versionDelegate;

  @override
  set isInTransaction(bool isInTransaction) => parentDelegate.isInTransaction = isInTransaction;

  @override
  void notifyDatabaseOpened(OpeningDetails details) => parentDelegate.notifyDatabaseOpened(details);

  @override
  FutureOr<bool> connect() async {
    try {
      client.logging(on: true);
      client.keepAlivePeriod = 100;
      client.setProtocolV311();
      final connMess = MqttConnectMessage()
          .withWillTopic('server') // If you set this you must set a will message
          .withWillMessage('My Will message')
          .startClean() // Non persistent session for testing
          .withWillQos(MqttQos.atLeastOnce);
      print('EXAMPLE::Mosquitto client connecting....');
      client.connectionMessage = connMess;
      client.onConnected = _onConnected;
      client.resubscribeOnAutoReconnect = true;
      await client.connect();
      return true;
    } on NoConnectionException catch (e) {
      // Raised by the client when connection fails.
      print('EXAMPLE::client exception - $e');
      client.disconnect();
    } on SocketException catch (e) {
      // Raised by the socket layer
      print('EXAMPLE::socket exception - $e');
      client.disconnect();
    }
    return false;
  }
  void _onConnected() {
    _registerCallbacks();
    client.updates!.listen(_onData);
  }
  void _registerCallbacks(){
    client.subscribe(kClientOpen, MqttQos.exactlyOnce);
    client.subscribe(kClientClose, MqttQos.exactlyOnce);
    client.subscribe(kClientRunBatched, MqttQos.exactlyOnce);
    client.subscribe(kClientRunCustom, MqttQos.exactlyOnce);
    client.subscribe(kClientRunInsert, MqttQos.exactlyOnce);
    client.subscribe(kClientRunSelect, MqttQos.exactlyOnce);
    client.subscribe(kClientRunUpdate, MqttQos.exactlyOnce);
  }

  Future<void> _onData(List<MqttReceivedMessage<MqttMessage>> c) async {
    for (var msg in c) {
      try {
        final topic = SubscriptionTopic(msg.topic);
        final String json = MqttPublishPayload.bytesToStringAsString(
            (msg.payload as MqttPublishMessage).payload.message);

        if (topic.matches(PublicationTopic(kClientOpen))) {
          if(user == null) throw Exception("User is null");
          open(user!).then(
                  (value) => _send(true.toString(), kServerOpen)
          ).catchError((e) => _sendError(e.toString()));
        }

        if (topic.matches(PublicationTopic(kClientClose))) {
          close().then(
                  (value) => _send(true.toString(), kServerClose)
          ).catchError((e) => _sendError(e.toString()));
        }

        if (topic.matches(PublicationTopic(kClientRunBatched))) {
          final nbs = NetworkBatchedStatement.fromJsonString(json);
          runBatched(nbs.toDrift()).then(
                  (value) => _send(true.toString(), kServerRunBatched)
          ).catchError((e) => _sendError(e.toString()));
        }

        if (topic.matches(PublicationTopic(kClientRunCustom))) {
          final ns = NetworkStatement.fromJsonString(json);
          runCustom(ns.statement, ns.args).then(
                  (value) => _send(true.toString(), kServerRunCustom)
          ).catchError((e) => _sendError(e.toString()));
        }

        if (topic.matches(PublicationTopic(kClientRunInsert))) {
          final ns = NetworkStatement.fromJsonString(json);
          runInsert(ns.statement, ns.args).then(
                  (value) => _send(value.toString(), kServerRunInsert)
          ).catchError((e) => _sendError(e.toString()));
        }

        if (topic.matches(PublicationTopic(kClientRunSelect))) {
          final ns = NetworkStatement.fromJsonString(json);
          runSelect(ns.statement, ns.args).then(
                  (value) => _send(jsonEncode(value.asMap.toList()), kServerRunSelect)
          ).catchError((e) => _sendError(e.toString()));
        }

        if (topic.matches(PublicationTopic(kClientRunUpdate))) {
          final ns = NetworkStatement.fromJsonString(json);
          runUpdate(ns.statement, ns.args).then(
                  (value) => _send(value.toString(), kServerRunUpdate)
          ).catchError((e) => _sendError(e.toString()));
        }
      }
      catch (e) {
        _sendError(e.toString());
      }
    }
  }

  void _send(String payload, String pubTopic) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);
    /// Publish it
    client.publishMessage(pubTopic, MqttQos.exactlyOnce, builder.payload!);
  }

  void _sendError(String payload) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);
    /// Publish it
    client.publishMessage(kServerError, MqttQos.exactlyOnce, builder.payload!);
  }


}