/// A version of moor that runs on the web by using [sql.js](https://github.com/sql-js/sql.js)
/// You manually need to include that library into your website to use the
/// web version of moor. See [the documentation](https://moor.simonbinder.eu/web)
/// for a more detailed instruction.
@experimental
library moor_web;

import 'dart:async';
import 'dart:html';
import 'dart:indexed_db';
import 'dart:js';

import 'package:meta/meta.dart';
import 'package:stream_channel/stream_channel.dart';

import 'backends.dart';
import 'moor.dart';
import 'src/web/binary_string_conversion.dart';
import 'src/web/sql_js.dart';

part 'src/web/storage.dart';
part 'src/web/web_db.dart';

/// Extension to transform a raw [MessagePort] from web workers into a Dart
/// [StreamChannel].
extension PortToChannel on MessagePort {
  /// Converts this port to a two-way communication channel, exposed as a
  /// [StreamChannel].
  ///
  /// This can be used to implement
  StreamChannel<Object?> channel() {
    final controller = StreamChannelController();
    onMessage.map((event) => event.data).pipe(controller.local.sink);
    controller.local.stream.listen(postMessage, onDone: close);

    return controller.foreign;
  }
}
