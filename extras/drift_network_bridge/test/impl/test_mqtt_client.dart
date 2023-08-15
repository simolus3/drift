import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/src/runtime/executor/executor.dart';
import 'package:drift/src/runtime/executor/helpers/delegates.dart';
import 'package:drift/src/runtime/executor/helpers/results.dart';
import 'package:drift/src/runtime/query_builder/query_builder.dart';
import 'package:drift_network_bridge/src/network/client_connection.dart';
import 'package:drift_network_bridge/src/network/serialization/network_batched_statement.dart';
import 'package:drift_network_bridge/src/network/serialization/network_statement.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import 'constants/constants.dart';

class TestMqttClient extends ClientConnection {
  // final client = MqttServerClient('test.mosquitto.org', 'drift_client');
  final client = MqttServerClient('127.0.0.1', 'drift_client');
  Completer<String> completer = Completer<String>();

  @override
  bool get isInTransaction => !completer.isCompleted;

  @override
  Future<bool> close() async {
    _send('close', [], kClientClose);
    return bool.parse(await _fetch(kServerClose));
  }


  @override
  Future<bool> open(QueryExecutorUser db) async {
    await super.open(db);
    _send('open', [], kClientOpen);
    return bool.parse(await _fetch(kServerOpen));
  }

  @override
  FutureOr<bool> connect() async {
    try {
      client.logging(on: true);
      client.keepAlivePeriod = 100;
      client.setProtocolV311();
      final connMess = MqttConnectMessage()
          // .withClientIdentifier('Mqtt_MyClientUniqueId')
          .withWillTopic('willtopic') // If you set this you must set a will message
          .withWillMessage('My Will message')
          .startClean() // Non persistent session for testing
          .withWillQos(MqttQos.atLeastOnce);
      print('EXAMPLE::Mosquitto client connecting....');
      client.connectionMessage = connMess;
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

  @override
  bool isConnect() => client.connectionStatus!.state == MqttConnectionState.connected;


  @override
  Future<bool> runBatched(BatchedStatements statements) async {
    final builder = MqttClientPayloadBuilder();
    builder.addString(NetworkBatchedStatement.fromDrift(statements).toJsonString());

    /// Publish it
    client.publishMessage(kClientRunBatched, MqttQos.exactlyOnce, builder.payload!);
    return bool.parse(await _fetch(kServerRunBatched));

  }

  @override
  Future<bool> runCustom(String statement, List<Object?> args) async {
    _send(statement, args, kClientRunCustom);
    return bool.parse(await _fetch(kServerRunCustom));
  }



  @override
  Future<int> runInsert(String statement, List<Object?> args) async {
    _send(statement, args, kClientRunInsert);
    return int.parse(await _fetch(kServerRunInsert));
  }

  @override
  Future<QueryResult> runSelect(String statement, List<Object?> args) async {
    _send(statement, args, kClientRunSelect);
    return QueryResult.fromRows(List.from(jsonDecode(await _fetch(kServerRunSelect))));
  }

  @override
  Future<int> runUpdate(String statement, List<Object?> args ) async {
    _send(statement, args, kClientRunUpdate);
    return int.parse(await _fetch(kServerRunUpdate));
  }



  @override
  // TODO: implement versionDelegate
  DbVersionDelegate get versionDelegate => NoVersionDelegate();

  void _send(String statement, List<Object?> args, String pubTopic) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(NetworkStatement(statement, args).toJsonString());

    /// Publish it
    client.publishMessage(pubTopic, MqttQos.exactlyOnce, builder.payload!);
  }

  static StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _fetchListener;
  Future<String> _fetch(String subTopic) {
    client.subscribe(subTopic, MqttQos.exactlyOnce);
    completer = Completer<String>();
    _fetchListener?.cancel();
    _fetchListener = client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final topic = SubscriptionTopic(subTopic);
      if(topic.matches(PublicationTopic(subTopic))){
        final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
        client.unsubscribe(subTopic);
        completer.complete(MqttPublishPayload.bytesToStringAsString(message.payload.message));
      }
    });
    Timer(const Duration(seconds: 100), () {
        completer.completeError(Exception('Timeout'));
    });
    return completer.future;
  }

  @override
  set isInTransaction(bool isInTransaction) {
    print(isInTransaction);
  }

  @override
  void notifyDatabaseOpened(OpeningDetails details) {
    // TODO: implement notifyDatabaseOpened
    print(details);
  }
}