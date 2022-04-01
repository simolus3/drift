import 'dart:html';

import 'package:stream_channel/stream_channel.dart';

StreamChannel<Object?> startWorker(String script) {
  final worker = SharedWorker(script);
  worker.onError.forEach(print);

  return worker.port!.channel();
}

extension PortToChannel on MessagePort {
  StreamChannel<Object?> channel() {
    final controller = StreamChannelController();
    onMessage.map((event) => event.data).pipe(controller.local.sink);
    controller.local.stream.listen(postMessage, onDone: close);

    return controller.foreign;
  }
}
