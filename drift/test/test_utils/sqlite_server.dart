import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:stream_channel/stream_channel.dart';

/// Spawns an HTTP server serving the sqlite WebAssembly module to use in web
/// tests.
Future<void> hybridMain(StreamChannel channel) async {
  final wasmFile = File(p.join('..', 'extras', 'assets', 'sqlite3.wasm'));
  if (!await wasmFile.exists()) {
    throw UnsupportedError('Could not find sqlite3 WebAssembly module at '
        '${wasmFile.absolute.path}!');
  }

  final server = await HttpServer.bind('localhost', 0);
  final handler =
      const Pipeline().addMiddleware(_cors()).addHandler(_serveFile(wasmFile));
  io.serveRequests(server, handler);

  channel.sink.add(server.port);
  await channel.stream
      .listen(null)
      .asFuture<void>()
      .then<void>((_) => server.close());
}

const _corsHeaders = {'Access-Control-Allow-Origin': '*'};

Middleware _cors() {
  Response? handleOptionsRequest(Request request) {
    if (request.method == 'OPTIONS') {
      return Response.ok(null, headers: _corsHeaders);
    } else {
      // Returning null will run the regular request handler
      return null;
    }
  }

  Response addCorsHeaders(Response response) {
    return response.change(headers: _corsHeaders);
  }

  return createMiddleware(
      requestHandler: handleOptionsRequest, responseHandler: addCorsHeaders);
}

Handler _serveFile(File file) {
  return (request) {
    return Response(
      200,
      body: file.openRead(),
      headers: {'Content-Type': 'application/wasm'},
    );
  };
}
