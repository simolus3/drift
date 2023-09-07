import 'dart:async';
import 'package:drift_network_bridge/dev/logging.dart';
import 'package:drift_network_bridge/src/network_stream_channel/network_stream_channel.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
extension on MqttClient {
  int publishString(String topic, String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    // Publish the event to the MQTT broker
    return _client.publishMessage(topic, MqttQos.exactlyOnce, builder.payload!);
  }
}

extension on SubscriptionTopic {
  bool safeMatch(PublicationTopic matcheeTopic) {
    if(matcheeTopic.topicFragments.length != topicFragments.length) {
      return false;
    }
    return matches(matcheeTopic);
  }
}

//1. The stream is single-subscription, and must follow all the guarantees of single-subscription streams.
//   StreamController is single-subscription by default.
//2. Closing the sink causes the stream to close before it emits any more events.
//   close() of sink calls disconnect() of client which triggers the will message
//   .withWillTopic('$topic/close')
//   .withWillMessage('close')
//3. After the stream closes, the sink is automatically closed. If this happens, sink methods should silently drop their arguments until sink.close is called.
//   StreamSinkWrapper close() calls _onClose which calls _controller.close()
//4. If the stream closes before it has a listener, the sink should silently drop events if possible.
//   _controller.hasListener?_controller.add(decoded):print('No listener');
//5. Canceling the stream's subscription has no effect on the sink. The channel must still be able to respond to the other endpoint closing the channel even after the subscription has been canceled.
//   sounds like we should not do anything on unSubscription and we are
//6. The sink either forwards errors to the other endpoint or closes as soon as an error is added and forwards that error to the sink.done future.
//     void addError(Object error, [StackTrace? stackTrace]) if (allowSinkErrors) forward it, else controller add error
//           if (!allowSinkErrors && sCloseTopic.matches(pubTopic)) {
//           _controller.close();
//         }
//         if (allowSinkErrors && sErrorTopic.matches(pubTopic)) {
//           final payload = jsonDecode(message.payload.toString());
//           _controller.addError(payload['error'], payload['stackTrace']);
//         }
class MqttClient extends NetworkClient{
  late MqttServerClient _client;

  final String _topic;
  late String _counterpartTopic;

  SubscriptionTopic get sTopic => SubscriptionTopic(_counterpartTopic);
  SubscriptionTopic get sCloseTopic => SubscriptionTopic('$_counterpartTopic/close');
  SubscriptionTopic get sErrorTopic => SubscriptionTopic('$_counterpartTopic/error');


  PublicationTopic get pTopic => PublicationTopic(_topic);
  PublicationTopic get pCloseTopic => PublicationTopic('$_topic/close');
  PublicationTopic get pErrorTopic => PublicationTopic('$_topic/error');

  MqttClient(String broker, String clientId, this._topic, String counterTopic) {
    _client = MqttServerClient(broker, clientId);
    _commonInit();
    _setupWillMessage();
    _subscribeToCounterpart(counterTopic);
  }

  void _commonInit() {
    _client.logging(on: false);
    _client.keepAlivePeriod = 30;
    _client.setProtocolV311();
    _client.autoReconnect = true;
    _client.resubscribeOnAutoReconnect = true;
  }

  void _setupWillMessage() {
    _client.connectionMessage ??= MqttConnectMessage();
    _client.connectionMessage = _client.connectionMessage!
        .withWillTopic(pCloseTopic.rawTopic)
        .withWillMessage('close')
        .startClean()
        .withWillQos(MqttQos.exactlyOnce);
  }

  void _subscribeToCounterpart(String counterpartTopic) {
    _counterpartTopic = counterpartTopic;
    _client.onConnected = () {
      _client.subscribe(sTopic.rawTopic, MqttQos.exactlyOnce);
      _client.subscribe(sCloseTopic.rawTopic, MqttQos.exactlyOnce);
      _client.subscribe(sErrorTopic.rawTopic, MqttQos.exactlyOnce);
      _client.subscribe(pCloseTopic.rawTopic, MqttQos.exactlyOnce);
      onConnected();
    };
  }

  @override
  void add(String event) {
    kDebugPrint(
        '${_client.clientIdentifier} is sending to $_topic with $event');
    publishString(_topic, event);
  }

  @override
  void addError(String serializedError) {
    publishString('$_topic/error',serializedError);
  }

  @override
  void close() {
    publishString(pCloseTopic.rawTopic, 'close');
  }

  @override
  void channelRequestStrategy([dynamic s]){
    final pClientRequests = PublicationTopic(s);
    publishString(pClientRequests.rawTopic, _client.clientIdentifier);
  }

  @override
  void disconnect() {
    _client.disconnect();
  }

  @override
  Future<void> connect() {
    return _client.connect();
  }

  @override
  void startListening() {
    _client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      for (var message in messages) {
        final pubTopic = PublicationTopic(message.topic);
        final payload =
        MqttPublishPayload.bytesToStringAsString(((message.payload) as MqttPublishMessage).payload.message);
        if (sTopic.safeMatch(pubTopic)) {
          kDebugPrint(
              '${_client.clientIdentifier} received from $pubTopic with $payload');
          streamChannel.handleDriftMessage(payload);
          return;
        }
        if(sCloseTopic.safeMatch(pubTopic)){
          kDebugPrint(
              '${_client.clientIdentifier} received from $pubTopic with close');
          streamChannel.handleCloseMessage(payload);
          return;
        }
        if(sErrorTopic.safeMatch(pubTopic)){
          kDebugPrint(
              '${_client.clientIdentifier} received from $pubTopic with error');
          streamChannel.handleError(payload);
          return;
        }
        if(SubscriptionTopic(pCloseTopic.rawTopic).safeMatch(pubTopic)){
          streamChannel.closeCompleted();
          return;
        }
      }
    });
  }

  @override
  bool get isConnected => _client.connectionStatus?.state == MqttConnectionState.connected;

  @override
  Future<bool> reconnect() async {
    await _client.connect();
    if(isConnected){
      _client.resubscribe();
    }
    return isConnected;
  }
}

class MqttStreamChannel extends NetworkStreamChannel {
  // Common initialization code
  MqttStreamChannel(String broker, String clientId, String topic, String counterTopic,{bool allowSinkErrors = true}) :
        super(MqttClient(broker, clientId, topic, counterTopic),allowSinkErrors: allowSinkErrors);

  @override
  factory MqttStreamChannel.hostWithGuarantees(String broker, String clientId, String topic) {
    final hostChannel = MqttStreamChannel(broker, '${clientId}_server', '$topic/server','$topic/remote',allowSinkErrors: false);
    return hostChannel;
  }

  factory MqttStreamChannel.clientWithGuarantees(String broker, String clientId, String topic) {
    final clientChannel = MqttStreamChannel(broker, '${clientId}_remote', '$topic/remote', '$topic/server',allowSinkErrors: true);
    clientChannel.onConnected = (mqttClient){
      clientChannel.channelRequestStrategy('$topic/request');
    };
    return clientChannel;
  }

}
