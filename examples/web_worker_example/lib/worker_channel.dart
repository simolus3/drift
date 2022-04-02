import 'dart:html';

import 'package:drift/web.dart';
import 'package:stream_channel/stream_channel.dart';

StreamChannel<Object?> startWorker(String script) {
  final worker = SharedWorker(script);
  worker.onError.forEach(print);

  return worker.port!.channel();
}
