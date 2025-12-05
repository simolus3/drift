// ignore: implementation_imports
import 'dart:async';
import 'dart:io';

import 'package:drift/src/web/wasm_setup/types.dart';
import 'package:test/test.dart';
import 'package:web_wasm/driver.dart';
import 'package:web_wasm/initialization_mode.dart';
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

  bool supports(WasmStorageImplementation impl) =>
      !unsupportedImplementations.contains(impl);

  Future<Process> spawnDriver() async {
    return switch (this) {
      firefox => Process.start('geckodriver', []).then((result) async {
          // geckodriver seems to take a while to initialize
          await Future.delayed(const Duration(seconds: 1));
          return result;
        }),
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
      var isStoppingProcess = false;
      final processStopped = Completer<void>();

      setUpAll(() async {
        final process = driverProcess = await browser.spawnDriver();
        // geckodriver becomes unresponsive when no one is listening on stdout.
        unawaited(process.stdout.drain());

        process.exitCode.then((code) {
          if (!isStoppingProcess) {
            throw 'Webdriver stopped (code $code) before tearing down tests.';
          }

          processStopped.complete();
        });
      });
      tearDownAll(() {
        isStoppingProcess = true;
        driverProcess.kill();
        return processStopped.future;
      });

      for (final wasm in [false, true]) {
        final compiler = wasm ? 'dart2wasm' : 'dart2js';

        group(compiler, () {
          final config = _TestConfiguration(browser, () => server, wasm);

          setUp(() async {
            await config.setUp();
          });
          tearDown(() => config.tearDown());

          config.declareTests();
        }, tags: [browser.name, compiler]);
      }
    });
  }
}

final class _TestConfiguration {
  final Browser browser;
  final TestAssetServer Function() _server;
  final bool isDart2Wasm;

  late DriftWebDriver driver;

  _TestConfiguration(this.browser, this._server, this.isDart2Wasm);

  TestAssetServer get server => _server();

  Future<void> setUp() async {
    late WebDriver rawDriver;
    for (var i = 0; i < 3; i++) {
      try {
        rawDriver = await createDriver(
          spec: browser.isChromium ? WebDriverSpec.JsonWire : WebDriverSpec.W3c,
          uri: browser.driverUri,
          desired: {
            'goog:chromeOptions': {
              'args': [
                '--headless=new',
                '--disable-search-engine-choice-screen',
              ],
            },
            'moz:firefoxOptions': {
              'args': ['-headless']
            },
          },
        );
        break;
      } on SocketException {
        // webdriver server taking a bit longer to start up...
        if (i == 2) {
          rethrow;
        }

        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    // logs.get() isn't supported on Firefox
    if (browser != Browser.firefox) {
      rawDriver.logs.get(LogType.browser).listen((entry) {
        print('[console]: ${entry.message}');
      });
    }

    driver = DriftWebDriver(server, rawDriver);
    final port = server.server.port;
    await driver.driver.get(isDart2Wasm
        ? 'http://localhost:$port/?wasm=1'
        : 'http://localhost:$port/');
    await driver.waitReady();
  }

  Future<void> tearDown() async {
    await driver.driver.quit();
  }

  void declareTests() {
    test('compatibility check', () async {
      // Make sure we're not testing the same compiler twice due to e.g. bugs in
      // the loader script.
      expect(await driver.isDart2wasm(), isDart2Wasm);

      final result = await driver.probeImplementations();

      final expectedImplementations = WasmStorageImplementation.values.toSet()
        ..removeAll(browser.unsupportedImplementations);

      expect(result.missingFeatures, browser.missingFeatures);
      expect(result.storages, expectedImplementations);
    });

    test('reports worker error for wrong URI', () async {
      final result =
          await driver.probeImplementations(withWrongWorkerUri: true);

      expect(
          result.missingFeatures, contains(MissingBrowserFeature.workerError));
    });

    test('via regular open', () async {
      await driver.openDatabase();
      expect(await driver.amountOfRows, 0);

      await driver.insertIntoDatabase();
      await driver.waitForTableUpdate();
      expect(await driver.amountOfRows, 1);
    });

    test('regular open with initializaton', () async {
      await driver.enableInitialization(InitializationMode.loadAsset);
      await driver.openDatabase();

      expect(await driver.amountOfRows, 1);
    });

    test('disable migrations', () async {
      await driver
          .enableInitialization(InitializationMode.noneAndDisableMigrations);
      await driver.openDatabase();

      expect(await driver.hasTable, isFalse);
    });

    for (final entry in browser.availableImplementations) {
      group(entry.name, () {
        test('basic', () async {
          await driver.openDatabase(implementation: entry);
          expect(await driver.amountOfRows, 0);

          await driver.insertIntoDatabase();
          await driver.waitForTableUpdate();
          expect(await driver.amountOfRows, 1);

          if (entry != WasmStorageImplementation.unsafeIndexedDb &&
              entry != WasmStorageImplementation.inMemory) {
            // Test stream query updates across tabs
            final newTabLink = await driver.driver.findElement(By.id('newtab'));
            await newTabLink.click();

            final windows = await driver.driver.windows.toList();
            expect(windows, hasLength(2));
            // Firefox does crazy things when setAsActive is called without
            // this delay. I don't really understand why, Chrome works...
            await Future.delayed(const Duration(seconds: 1));
            await windows.last.setAsActive();

            await driver.openDatabase(implementation: entry);
            expect(await driver.amountOfRows, 1);
            await driver.insertIntoDatabase();
            await windows.last.close();

            await windows.first.setAsActive();
            await driver.waitForTableUpdate();
          }
        });

        if (entry != WasmStorageImplementation.inMemory) {
          test('export and delete', () async {
            final impl = await driver.probeImplementations();
            expect(impl.existing, isEmpty);

            await driver.openDatabase(implementation: entry);
            await driver.insertIntoDatabase();
            await driver.waitForTableUpdate();

            await driver.closeDatabase();

            final newImpls = await driver.probeImplementations();
            expect(newImpls.existing, hasLength(1));
            final existing = newImpls.existing[0];

            expect(await driver.exportDatabase(existing.$1, existing.$2),
                isNotNull);
            await driver.deleteDatabase(existing.$1, existing.$2);

            await driver.driver.refresh();
            await driver.waitReady();

            final finalImpls = await driver.probeImplementations();
            expect(finalImpls.existing, isEmpty);
          });

          test('migrations', () async {
            await driver.openDatabase(implementation: entry);
            await driver.insertIntoDatabase();
            await driver.waitForTableUpdate();

            await driver.closeDatabase();
            await driver.driver.refresh();
            await driver.waitReady();

            await driver.setSchemaVersion(2);
            await driver.openDatabase(implementation: entry);
            // The migration adds a row
            expect(await driver.amountOfRows, 2);
          });

          test('disabling migrations', () async {
            await driver.enableInitialization(
                InitializationMode.noneAndDisableMigrations);
            await driver.openDatabase();
            expect(await driver.hasTable, isFalse);
          });
        }

        group(
          'initialization from',
          () {
            test('static blob', () async {
              await driver.enableInitialization(InitializationMode.loadAsset);
              await driver.openDatabase(implementation: entry);

              expect(await driver.amountOfRows, 1);
              await driver.insertIntoDatabase();
              expect(await driver.amountOfRows, 2);

              if (entry != WasmStorageImplementation.inMemory) {
                await Future.delayed(const Duration(seconds: 1));
                await driver.driver.refresh();
                await driver.waitReady();

                await driver.enableInitialization(InitializationMode.loadAsset);
                await driver.openDatabase();
                expect(await driver.amountOfRows, 2);
              }
            });

            test('custom wasmdatabase', () async {
              await driver.enableInitialization(
                  InitializationMode.migrateCustomWasmDatabase);
              await driver.openDatabase(implementation: entry);

              expect(await driver.amountOfRows, 1);
            });
          },
          skip: browser == Browser.firefox &&
                  entry == WasmStorageImplementation.opfsLocks
              ? "This configuration fails, but the failure can't be "
                  'reproduced by manually running the steps of this test.'
              : null,
        );
      });
    }

    if (browser.supports(WasmStorageImplementation.unsafeIndexedDb) &&
        browser.supports(WasmStorageImplementation.opfsLocks)) {
      test(
        'keep existing IndexedDB database after OPFS becomes available',
        () async {
          // Open an IndexedDB database first
          await driver.openDatabase(
              implementation: WasmStorageImplementation.unsafeIndexedDb);
          await driver.insertIntoDatabase();
          await Future.delayed(const Duration(seconds: 2));
          await driver.driver.refresh(); // Reset JS state
          await driver.waitReady();

          // Open the database again, this time without specifying a fixed
          // implementation. Despite OPFS being available (and preferred),
          // the existing database should be used.
          await driver.openDatabase();
          expect(await driver.amountOfRows, 1);
        },
      );

      test(
        'can migrate from IndexedDB to OPFS',
        () async {
          // Open an IndexedDB database first
          await driver.openDatabase(
              implementation: WasmStorageImplementation.unsafeIndexedDb);
          await driver.insertIntoDatabase();
          await Future.delayed(const Duration(seconds: 2));
          await driver.driver.refresh(); // Reset JS state
          await driver.waitReady();

          // Open the database again, preferring a migration.
          await driver.openDatabase(moveIndexedDbToOpfs: true);
          expect(await driver.amountOfRows, 1);
          await Future.delayed(const Duration(seconds: 2));
          await driver.driver.refresh(); // Reset JS state
          await driver.waitReady();

          await driver.openDatabase(
              implementation: WasmStorageImplementation.opfsLocks);
          expect(await driver.amountOfRows, 1);
        },
      );

      if (!browser.supports(WasmStorageImplementation.opfsShared)) {
        test('uses indexeddb after OPFS becomes unavailable', () async {
          // This browser only supports OPFS with the right headers. If they
          // are ever removed, data is lost (nothing we could do about that),
          // but drift should continue to work.
          await driver.openDatabase(
              implementation: WasmStorageImplementation.opfsLocks);
          await driver.insertIntoDatabase();
          expect(await driver.amountOfRows, 1);
          await Future.delayed(const Duration(seconds: 2));

          await driver.driver
              .get('http://localhost:${server.server.port}/no-coep');
          await driver.openDatabase();
          expect(await driver.amountOfRows, isZero);
        });
      }
    }

    test('supports exclusively API', () async {
      await driver.openDatabase();
      expect(await driver.amountOfRows, 0);

      await driver.runExclusiveBlock();
      expect(await driver.amountOfRows, 1);
    });
  }
}
