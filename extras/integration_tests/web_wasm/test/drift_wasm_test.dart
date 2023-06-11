// ignore: implementation_imports
import 'dart:io';

import 'package:drift/src/web/wasm_setup/types.dart';
import 'package:test/test.dart';
import 'package:web_wasm/driver.dart';
import 'package:webdriver/async_io.dart';

enum Browser {
  chrome(
    driverUriString: 'http://localhost:4444/wd/hub/',
    isChromium: true,
    unsupportedImplementations: {WasmStorageImplementation.opfsShared},
    missingFeatures: {MissingBrowserFeature.dedicatedWorkersInSharedWorkers},
  ),
  firefox(driverUriString: 'http://localhost:4444/');

  final bool isChromium;
  final String driverUriString;
  final Set<WasmStorageImplementation> unsupportedImplementations;
  final Set<MissingBrowserFeature> missingFeatures;

  const Browser({
    required this.driverUriString,
    this.isChromium = false,
    this.unsupportedImplementations = const {},
    this.missingFeatures = const {},
  });

  Uri get driverUri => Uri.parse(driverUriString);

  Set<WasmStorageImplementation> get availableImplementations {
    return WasmStorageImplementation.values.toSet()
      ..removeAll(unsupportedImplementations);
  }

  Future<Process> spawnDriver() async {
    return switch (this) {
      firefox => Process.start('geckodriver', []),
      chrome =>
        Process.start('chromedriver', ['--port=4444', '--url-base=/wd/hub']),
    };
  }
}

void main() {
  late TestAssetServer server;

  setUpAll(() async {
    server = await TestAssetServer.start();
  });
  tearDownAll(() => server.close());

  for (final browser in Browser.values) {
    group(browser.name, () {
      late Process driverProcess;
      late DriftWebDriver driver;

      setUpAll(() async => driverProcess = await browser.spawnDriver());
      tearDownAll(() => driverProcess.kill());

      setUp(() async {
        final rawDriver = await createDriver(
          spec: browser.isChromium ? WebDriverSpec.JsonWire : WebDriverSpec.W3c,
          uri: browser.driverUri,
        );

        driver = DriftWebDriver(server, rawDriver);

        await driver.driver.get('http://localhost:8080/');
      });

      tearDown(() => driver.driver.quit());

      test('compatibility check', () async {
        final result = await driver.probeImplementations();

        final expectedImplementations = WasmStorageImplementation.values.toSet()
          ..removeAll(browser.unsupportedImplementations);

        expect(result.missingFeatures, browser.missingFeatures);
        expect(result.storages, expectedImplementations);
      });

      group('supports', () {
        for (final entry in browser.availableImplementations) {
          test(entry.name, () async {
            await driver.openDatabase();
          });
        }
      });
    });
  }
}
