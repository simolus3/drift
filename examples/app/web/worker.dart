// ignore: avoid_web_libraries_in_flutter
import 'dart:html';

import 'package:app/database/connection/web.dart';
import 'package:drift/web.dart';
import 'package:drift/remote.dart';

void main() {
  final self = SharedWorkerGlobalScope.instance;
  final server = DriftServer(connect(isInWebWorker: true));

  self.onConnect.listen((event) {
    final msg = event as MessageEvent;
    server.serve(msg.ports.first.channel());
  });
}
