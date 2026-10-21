import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:build_daemon/client.dart';
import 'package:build_daemon/constants.dart';
import 'package:build_daemon/data/build_status.dart';
import 'package:build_daemon/data/build_target.dart';
import 'package:collection/collection.dart';
// ignore: implementation_imports
import 'package:drift/src/web/wasm_setup/types.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_proxy/shelf_proxy.dart';
import 'package:web_wasm/initialization_mode.dart';
import 'package:web_wasm/src/driver/protocol.dart';

class TestAssetServer {
  final BuildDaemonClient buildRunner;
  late final HttpServer server;

  final Map<int, ConnectedClient> _clients = {};
  final Map<int, (ConnectedClient, Completer<Object?>)>
  _outstandingInstructions = {};
  int _nextClientId = 0;
  int _nextInstructionId = 0;

  TestAssetServer(this.buildRunner);

  (Uri, Future<ConnectedClient>) newClient({
    bool coep = true,
    bool dart2wasm = false,
  }) {
    final id = _nextClientId++;
    final uri = Uri.http('localhost:${server.port}', coep ? '/' : '/no-coep/', {
      'client': '$id',
      'wasm': dart2wasm ? '1' : '0',
    });
    final client = ConnectedClient(this, uri, coep: coep, dart2wasm: dart2wasm);
    _clients[id] = client;

    return (uri, client._hasConnection.future.then((_) => client));
  }

  Future<Response> _instructions(Request request) async {
    final clientId = int.parse(request.url.queryParameters['client']!);
    final client = _clients[clientId]!;

    final body = client._instructions.stream
        .map((line) => '${json.encode(line)}\n')
        .transform(utf8.encoder);
    return Response(
      200,
      body: body,
      context: {'shelf.io.buffer_output': false},
    );
  }

  Future<Response> _complete(Request request) async {
    final body = InstructionComplete.fromJson(
      json.decode(await request.readAsString()),
    );

    if (_outstandingInstructions.remove(body.id) case (
      final client,
      final completer,
    )) {
      client._pendingInstructions.remove(body.id);
      completer.complete(body.result);
    }

    return Response(200);
  }

  Future<Response> _error(Request request) async {
    final body = ClientError.fromJson(
      json.decode(await request.readAsString()),
    );
    print('Received error from client: ${body.message} at ${body.trace}');

    if (body.id case final id?) {
      if (_outstandingInstructions.remove(id) case (
        final client,
        final completer,
      )) {
        client._pendingInstructions.remove(id);
        completer.completeError(body.message);
      }
    }

    return Response(200);
  }

  Future<Response> _print(Request request) async {
    final body = ClientPrint.fromJson(
      json.decode(await request.readAsString()),
    );
    print('[tab #${body.clientId}]: ${body.message}');

    return Response(200);
  }

  void markBrowserClosed() {
    for (final client in _clients.values) {
      if (!client._hasConnection.isCompleted) {
        client._hasConnection.completeError('browser closed');
      }
    }

    for (final (_, completer) in _outstandingInstructions.values) {
      completer.completeError('browser closed');
    }
  }

  Future<void> close() async {
    markBrowserClosed();

    await server.close(force: true);
    await buildRunner.close();
  }

  static Future<TestAssetServer> start({
    bool debug = false,
    int? fixedPort,
  }) async {
    final packageConfig = await loadPackageConfigUri(
      (await Isolate.packageConfig)!,
    );
    final ownPackage = packageConfig['web_wasm']!.root;
    var packageDir = ownPackage.toFilePath(windows: Platform.isWindows);
    if (packageDir.endsWith('/') || packageDir.endsWith('\\')) {
      packageDir = packageDir.substring(0, packageDir.length - 1);
    }

    final buildRunner = await BuildDaemonClient.connect(packageDir, [
      Platform.executable, // dart
      'run',
      'build_runner',
      'daemon',
      if (debug)
        '--define=build_web_compilers:entrypoint=dart2js_args=["-Dsqlite3.wasm.worker.debug=true"]',
    ], logHandler: (log) => print(log.message));

    buildRunner
      ..registerBuildTarget(DefaultBuildTarget((b) => b.target = 'web'))
      ..startBuild();

    // Wait for the build to complete, so that the server we return is ready to
    // go.
    await buildRunner.buildResults.firstWhere((b) {
      final buildResult = b.results.firstWhereOrNull((r) => r.target == 'web');
      return buildResult != null && buildResult.status != BuildStatus.started;
    });

    final assetServerPortFile = File(
      p.join(daemonWorkspace(packageDir), '.asset_server_port'),
    );
    final assetServerPort = int.parse(await assetServerPortFile.readAsString());

    final server = TestAssetServer(buildRunner);

    final proxy = proxyHandler('http://localhost:$assetServerPort/web/');
    server.server = await serve(
      (request) async {
        final pathSegments = request.url.pathSegments;

        switch (pathSegments) {
          case ['instructions']:
            return await server._instructions(request);
          case ['complete']:
            return await server._complete(request);
          case ['error']:
            return await server._error(request);
          case ['print']:
            return await server._print(request);
          case ['no-coep', ...]:
            // Serve stuff under /no-coep like the regular website, but without
            // adding the security headers.
            return await proxy(request.change(path: 'no-coep'));
          default:
            final response = await proxy(request);

            if (!request.url.path.startsWith('/no-coep')) {
              return response.change(
                headers: {
                  // Needed for shared array buffers to work
                  'Cross-Origin-Opener-Policy': 'same-origin',
                  'Cross-Origin-Embedder-Policy': 'require-corp',
                },
              );
            }

            return response;
        }
      },
      'localhost',
      fixedPort ?? 0,
    );

    return server;
  }
}

final class ConnectedClient {
  final TestAssetServer _server;
  final StreamController<Instruction> _instructions = StreamController();
  final Set<int> _pendingInstructions = {};

  final Completer<void> _hasConnection = Completer();

  /// The URI the page for this client has been opened with.
  final Uri uri;
  final bool coep;
  final bool dart2wasm;

  ConnectedClient(
    this._server,
    this.uri, {
    required this.coep,
    required this.dart2wasm,
  }) {
    _instructions.onListen = () {
      _hasConnection.complete();
    };
  }

  (int, Future<Object?>) _newInstruction() {
    final completer = Completer<Object?>();
    final id = _server._nextInstructionId++;
    _server._outstandingInstructions[id] = (this, completer);
    _pendingInstructions.add(id);

    return (id, completer.future);
  }

  Future<Object?> _sendInstruction(String method, Object? arguments) {
    final (id, future) = _newInstruction();
    _instructions.add(
      Instruction(id: id, method: method, arguments: arguments),
    );
    return future;
  }

  Future<bool> isDart2wasm() async {
    return (await _sendInstruction('isDart2wasm', null)) as bool;
  }

  /// Opens a new window (in the same browser) from this page, returning the
  /// client connected to that window.
  ///
  /// The window can be closed with [closeWindow].
  Future<ConnectedClient> openWindow() async {
    final (uri, client) = _server.newClient(coep: coep, dart2wasm: dart2wasm);
    await _sendInstruction('openWindow', uri.toString());
    return await client;
  }

  /// Closes a [window] previously opened with [openWindow] on this client.
  Future<void> closeWindow(ConnectedClient window) async {
    await _sendInstruction('closeWindow', window.uri.toString());
  }

  /// Navigates this page to a fresh instance of the test page, resetting all
  /// JavaScript state.
  ///
  /// This client is no longer usable afterwards, the returned client
  /// represents the reloaded page.
  Future<ConnectedClient> reload({bool? coep}) async {
    final (uri, client) = _server.newClient(
      coep: coep ?? this.coep,
      dart2wasm: dart2wasm,
    );
    // The page navigates away, so we might never get a response for this.
    _sendInstruction('navigate', uri.toString()).ignore();
    return await client;
  }

  Future<
    ({
      Set<WasmStorageImplementation> storages,
      Set<MissingBrowserFeature> missingFeatures,
      List<ExistingDatabase> existing,
    })
  >
  probeImplementations({bool withWrongWorkerUri = false}) async {
    final method = withWrongWorkerUri
        ? 'detectImplementationsWrongUri'
        : 'detectImplementations';
    final result = (await _sendInstruction(method, null)) as Map;

    return (
      storages: {
        for (final entry in result['impls'])
          WasmStorageImplementation.values.byName(entry),
      },
      missingFeatures: {
        for (final entry in result['missing'])
          MissingBrowserFeature.values.byName(entry),
      },
      existing: <ExistingDatabase>[
        for (final entry in result['existing'])
          (WebStorageApi.byName[entry[0] as String]!, entry[1] as String),
      ],
    );
  }

  Future<void> openDatabase({
    WasmStorageImplementation? implementation,
    bool moveIndexedDbToOpfs = false,
  }) async {
    await _sendInstruction('open', {
      'implementation': implementation?.name,
      'moveToOpfs': moveIndexedDbToOpfs,
    });
  }

  Future<void> closeDatabase() async {
    await _sendInstruction('close', null);
  }

  Future<void> insertIntoDatabase() async {
    await _sendInstruction('insert', null);
  }

  Future<void> insertInTransaction() async {
    await _sendInstruction('insertInTransaction', null);
  }

  Future<void> insertReturning() async {
    await _sendInstruction('insertReturning', null);
  }

  Future<void> runExclusiveBlock() async {
    await _sendInstruction('doExclusive', null);
  }

  Future<void> lockForever() async {
    await _sendInstruction('lockForever', null);
  }

  Future<int> get amountOfRows async {
    return (await _sendInstruction('getRows', null)) as int;
  }

  Future<bool> get hasTable async {
    return (await _sendInstruction('hasTable', null)) as bool;
  }

  Future<void> waitForTableUpdate() async {
    await _sendInstruction('waitForUpdate', null);
  }

  Future<void> enableInitialization(InitializationMode mode) async {
    await _sendInstruction('enableInitialization', mode.name);
  }

  Future<void> setSchemaVersion(int version) async {
    await _sendInstruction('setSchemaVersion', version);
  }

  Future<void> deleteDatabase(WebStorageApi storageApi, String name) async {
    await _sendInstruction('deleteDatabase', [storageApi.name, name]);
  }

  Future<bool> exportDatabase(WebStorageApi storageApi, String name) async {
    return (await _sendInstruction('exportDatabase', [storageApi.name, name]))
        as bool;
  }
}
