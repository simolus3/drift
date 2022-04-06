import 'package:async/async.dart';
import 'package:drift/remote.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

import 'test_utils/database_vm.dart';

void main() {
  test('closes channel in shutdown', () async {
    final controller = StreamChannelController();
    final server =
        DriftServer(testInMemoryDatabase(), allowRemoteShutdown: true);
    server.serve(controller.foreign);

    final transformed = controller.local.transformSink(
      StreamSinkTransformer.fromHandlers(
        handleDone: expectAsync1((inner) => inner.close()),
      ),
    );

    await shutdown(transformed);
  });
}
