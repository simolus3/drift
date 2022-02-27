/// A version of drift that runs on the web by using [sql.js](https://github.com/sql-js/sql.js)
/// You manually need to include that library into your website to use the
/// web version of drift. See [the documentation](https://drift.simonbinder.eu/web)
/// for a more detailed instruction.
@experimental
library drift.web;

import 'dart:html';

import 'package:meta/meta.dart';
import 'package:stream_channel/stream_channel.dart';

export 'src/web/sql_js.dart';
export 'src/web/storage.dart' hide CustomSchemaVersionSave;
export 'src/web/web_db.dart';

/// Extension to transform a raw [MessagePort] from web workers into a Dart
/// [StreamChannel].
extension PortToChannel on MessagePort {
  /// Converts this port to a two-way communication channel, exposed as a
  /// [StreamChannel].
  ///
  /// This can be used to implement a remote database connection over service
  /// workers.
  StreamChannel<Object?> channel() {
    final controller = StreamChannelController();
    onMessage.map((event) => event.data).pipe(controller.local.sink);
    controller.local.stream.listen(postMessage, onDone: close);

    return controller.foreign;
  }
}
