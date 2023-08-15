
import 'dart:async';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:stream_channel/stream_channel.dart';

import 'mqtt_stream.dart';

class MqttStreamController extends StreamChannelController<Object?> {

  Completer<bool> readyCompl = Completer<bool>();

  Future<bool> isReady() => readyCompl.future;

  /// The local channel.
  ///
  /// This channel should be used directly by the creator of this
  /// [StreamChannelController] to send and receive events.
  @override
  StreamChannel<Object?>  get local => _local;
  late final  StreamChannel<Object?>  _local;

  /// The foreign channel.
  ///
  /// This channel should be returned to external users so they can communicate
  /// with [local].
  @override
  StreamChannel<Object?>  get foreign => _foreign;
  late final  StreamChannel<Object?>  _foreign;

  MqttStreamController({bool allowForeignErrors = true, bool sync = false}){
    final foreign = MqttServerClient('127.0.0.1', 'drift_client');
    final local = MqttServerClient('127.0.0.1', 'drift_server');
    final localconnMess = MqttConnectMessage()
        .withWillTopic('server') // If you set this you must set a will message
        .withWillMessage('My Will message')
        .startClean() // Non persistent session for testing
        .withWillQos(MqttQos.atLeastOnce);

    final foreignconnMess = MqttConnectMessage()
        .withWillTopic('client') // If you set this you must set a will message
        .withWillMessage('My Will message')
        .startClean() // Non persistent session for testing
        .withWillQos(MqttQos.atLeastOnce);

    foreign.logging(on: false);
    foreign.keepAlivePeriod = 100;
    foreign.setProtocolV311();

    local.logging(on: false);
    local.keepAlivePeriod = 100;
    local.setProtocolV311();

    foreign.connectionMessage = foreignconnMess;
    local.connectionMessage = localconnMess;

    var localToForeignController = MqttStream(local, 'local', 'foreign',sync : sync);
    var foreignToLocalController = MqttStream(foreign,'foreign' ,'local',sync : sync);

    // _local = MqttStream.withGuarantees(
    //     foreignToLocalController.stream, localToForeignController.sink);
    // _foreign = MqttStream.withGuarantees(
    //     localToForeignController.stream, foreignToLocalController.sink,
    //     allowSinkErrors: allowForeignErrors);

    _local = StreamChannel<Object?>.withGuarantees(
        foreignToLocalController.stream, localToForeignController.sink);
    _foreign = StreamChannel<Object?>.withGuarantees(
        localToForeignController.stream, foreignToLocalController.sink,
        allowSinkErrors: allowForeignErrors);

    Future.delayed(Duration(seconds: 5),(){
      readyCompl.complete(true);
    });
  }

}

