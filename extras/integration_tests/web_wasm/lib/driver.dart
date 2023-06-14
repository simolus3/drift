import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:build_daemon/client.dart';
import 'package:build_daemon/constants.dart';
import 'package:build_daemon/data/build_status.dart';
import 'package:build_daemon/data/build_target.dart';
import 'package:collection/collection.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf_io.dart';
import 'package:shelf_proxy/shelf_proxy.dart';
import 'package:web_wasm/initialization_mode.dart';
import 'package:webdriver/async_io.dart';
// ignore: implementation_imports
import 'package:drift/src/web/wasm_setup/types.dart';

class TestAssetServer {
  final BuildDaemonClient buildRunner;
  late final HttpServer server;

  bool addCoopAndCoepHeaders = true;

  TestAssetServer(this.buildRunner);

  Future<void> close() async {
    await server.close(force: true);
    await buildRunner.close();
  }

  static Future<TestAssetServer> start() async {
    final packageConfig =
        await loadPackageConfigUri((await Isolate.packageConfig)!);
    final ownPackage = packageConfig['web_wasm']!.root;
    var packageDir = ownPackage.toFilePath(windows: Platform.isWindows);
    if (packageDir.endsWith('/')) {
      packageDir = packageDir.substring(0, packageDir.length - 1);
    }

    final buildRunner = await BuildDaemonClient.connect(
      packageDir,
      [
        Platform.executable, // dart
        'run',
        'build_runner',
        'daemon',
      ],
      logHandler: (log) => print(log.message),
    );

    buildRunner
      ..registerBuildTarget(DefaultBuildTarget((b) => b.target = 'web'))
      ..startBuild();

    // Wait for the build to complete, so that the server we return is ready to
    // go.
    await buildRunner.buildResults.firstWhere((b) {
      final buildResult = b.results.firstWhereOrNull((r) => r.target == 'web');
      return buildResult != null && buildResult.status != BuildStatus.started;
    });

    final assetServerPortFile =
        File(p.join(daemonWorkspace(packageDir), '.asset_server_port'));
    final assetServerPort = int.parse(await assetServerPortFile.readAsString());

    final server = TestAssetServer(buildRunner);

    final proxy = proxyHandler('http://localhost:$assetServerPort/web/');
    server.server = await serve(
      (request) async {
        final response = await proxy(request);

        if (server.addCoopAndCoepHeaders) {
          return response.change(headers: {
            // Needed for shared array buffers to work
            'Cross-Origin-Opener-Policy': 'same-origin',
            'Cross-Origin-Embedder-Policy': 'require-corp'
          });
        }

        return response;
      },
      'localhost',
      8080,
    );

    return server;
  }
}

class DriftWebDriver {
  final TestAssetServer server;
  final WebDriver driver;

  DriftWebDriver(this.server, this.driver);

  Future<
      ({
        Set<WasmStorageImplementation> storages,
        Set<MissingBrowserFeature> missingFeatures,
      })> probeImplementations() async {
    final rawResult = await driver
        .executeAsync('detectImplementations("", arguments[0])', []);
    final result = json.decode(rawResult);

    return (
      storages: {
        for (final entry in result['impls'])
          WasmStorageImplementation.values.byName(entry)
      },
      missingFeatures: {
        for (final entry in result['missing'])
          MissingBrowserFeature.values.byName(entry)
      },
    );
  }

  Future<void> openDatabase([WasmStorageImplementation? implementation]) async {
    await driver.executeAsync(
        'open(arguments[0], arguments[1])', [implementation?.name]);
  }

  Future<void> insertIntoDatabase() async {
    await driver.executeAsync('insert("", arguments[0])', []);
  }

  Future<int> get amountOfRows async {
    return await driver.executeAsync('get_rows("", arguments[0])', []);
  }

  Future<void> waitForTableUpdate() async {
    await driver.executeAsync('wait_for_update("", arguments[0])', []);
  }

  Future<void> enableInitialization(InitializationMode mode) async {
    final result = await driver.executeAsync(
      'enable_initialization(arguments[0], arguments[1])',
      [mode.name],
    );

    if (result != true) {
      throw 'Could not set initialization mode';
    }
  }
}
