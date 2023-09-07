import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/remote.dart';
import 'package:drift_network_bridge/dev/logging.dart';
import 'package:drift_network_bridge/src/network_stream_channel/database_gateway.dart';
import 'package:drift_network_bridge/src/network_stream_channel/network_stream_channel.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import 'mqtt_stream_channel.dart';

class MqttDatabaseGateway extends DatabaseGateway {
  final String _topic;
  late MqttServerClient _client;

  SubscriptionTopic get sClientRequests =>
      SubscriptionTopic('$_topic/+/request');

  Future<DatabaseConnection> createRemoteConnection() async {
    final remoteConnection = createConnection();
    await remoteConnection.connect();
    return await connectToRemoteAndInitialize(remoteConnection);
  }

  MqttDatabaseGateway(broker, String clientId, this._topic,
      {bool allowRemoteShutdown = false})
      : super(() => _buildStreamChannel(broker, clientId, _topic),
            allowRemoteShutdown: allowRemoteShutdown) {
    _initialize(broker, clientId);
  }

  static MqttStreamChannel _buildStreamChannel(
      broker, String clientId, String topic) {
    final newClientId = '$clientId-${DateTime.now().millisecondsSinceEpoch}';
    return MqttStreamChannel.clientWithGuarantees(
        broker, newClientId, '$topic/$newClientId');
  }

  void _initialize(broker, String clientId) {
    _client = MqttServerClient(broker, '$clientId-gateway');
    _client.connectionMessage ??= MqttConnectMessage();
    _client.connectionMessage = _client.connectionMessage!.startClean();
    _client.logging(on: false);
    _client.keepAlivePeriod = 30;
    _client.setProtocolV311();
  }

  @override
  Future<void> completeChannel(
      Future Function(NetworkStreamChannel channel)
          hostFactoryWithGuarantee) async {
    _client.onConnected = () {
      kDebugPrint('${_client.clientIdentifier} connected');
      _client.subscribe(sClientRequests.rawTopic, MqttQos.exactlyOnce);
      _client.updates
          ?.listen((List<MqttReceivedMessage<MqttMessage>> messages) async {
        for (var message in messages) {
          final pubTopic = PublicationTopic(message.topic);
          if (sClientRequests.matches(pubTopic)) {
            pubTopic.topicFragments.removeLast();
            /// Reply to client that connection is established
            await hostFactoryWithGuarantee(MqttStreamChannel.hostWithGuarantees(
                _client.server, pubTopic.topicFragments.last, (pubTopic.topicFragments).join('/')));
            _client.publishMessage(
                '${(pubTopic.topicFragments).join('/')}/stream',
                MqttQos.exactlyOnce,
                MqttClientPayloadBuilder().addString('ok').payload!);
          }
        }
      });
    };
    await _client.connect();
  }

  @override
  Future<void> shutdown() async {
    super.shutdown();
    _client.disconnect();
  }


  Future disconnect() async {
    return _client.disconnect();
  }
}
