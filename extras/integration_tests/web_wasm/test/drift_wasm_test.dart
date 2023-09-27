// ignore: implementation_imports
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

      for (final entry in browser.availableImplementations) {
        group(entry.name, () {
          test('basic', () async {
            await driver.openDatabase(entry);

            await driver.insertIntoDatabase();
            await driver.waitForTableUpdate();
            expect(await driver.amountOfRows, 1);

            if (entry != WasmStorageImplementation.unsafeIndexedDb &&
                entry != WasmStorageImplementation.inMemory) {
              // Test stream query updates across tabs
              final newTabLink =
                  await driver.driver.findElement(By.id('newtab'));
              await newTabLink.click();

              final windows = await driver.driver.windows.toList();
              expect(windows, hasLength(2));
              // Firefox does crazy things when setAsActive is called without
              // this delay. I don't really understand why, Chrome works...
              await Future.delayed(const Duration(seconds: 1));
              await windows.last.setAsActive();

              await driver.openDatabase(entry);
              expect(await driver.amountOfRows, 1);
              await driver.insertIntoDatabase();
              await windows.last.close();

              await windows.first.setAsActive();
              await driver.waitForTableUpdate();
            }
          });

          if (entry != WasmStorageImplementation.inMemory) {
            test('delete', () async {
              final impl = await driver.probeImplementations();
              expect(impl.existing, isEmpty);

              await driver.openDatabase(entry);
              await driver.insertIntoDatabase();
              await driver.waitForTableUpdate();

              await driver.driver.refresh(); // Reset JS state

              final newImpls = await driver.probeImplementations();
              expect(newImpls.existing, hasLength(1));
              final existing = newImpls.existing[0];
              await driver.deleteDatabase(existing.$1, existing.$2);

              await driver.driver.refresh();

              final finalImpls = await driver.probeImplementations();
              expect(finalImpls.existing, isEmpty);
            });
          }

          group(
            'initialization from',
            () {
              test('static blob', () async {
                await driver.enableInitialization(InitializationMode.loadAsset);
                await driver.openDatabase(entry);

                expect(await driver.amountOfRows, 1);
                await driver.insertIntoDatabase();
                expect(await driver.amountOfRows, 2);

                if (entry != WasmStorageImplementation.inMemory) {
                  await Future.delayed(const Duration(seconds: 1));
                  await driver.driver.refresh();

                  await driver
                      .enableInitialization(InitializationMode.loadAsset);
                  await driver.openDatabase();
                  expect(await driver.amountOfRows, 2);
                }
              });

              test('custom wasmdatabase', () async {
                await driver.enableInitialization(
                    InitializationMode.migrateCustomWasmDatabase);
                await driver.openDatabase(entry);

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
            await driver
                .openDatabase(WasmStorageImplementation.unsafeIndexedDb);
            await driver.insertIntoDatabase();
            await Future.delayed(const Duration(seconds: 2));
            await driver.driver.refresh(); // Reset JS state

            // Open the database again, this time without specifying a fixed
            // implementation. Despite OPFS being available (and preferred),
            // the existing database should be used.
            await driver.openDatabase();
            expect(await driver.amountOfRows, 1);
          },
        );

        if (!browser.supports(WasmStorageImplementation.opfsShared)) {
          test('uses indexeddb after OPFS becomes unavailable', () async {
            // This browser only supports OPFS with the right headers. If they
            // are ever removed, data is lost (nothing we could do about that),
            // but drift should continue to work.
            await driver.openDatabase(WasmStorageImplementation.opfsLocks);
            await driver.insertIntoDatabase();
            expect(await driver.amountOfRows, 1);
            await Future.delayed(const Duration(seconds: 2));

            await driver.driver.get('http://localhost:8080/no-coep');
            await driver.openDatabase();
            expect(await driver.amountOfRows, isZero);
          });
        }
      }
    });
  }
}
