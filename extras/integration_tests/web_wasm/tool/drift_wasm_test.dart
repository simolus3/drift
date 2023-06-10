// ignore: implementation_imports
import 'package:drift/src/web/wasm_setup/types.dart';
import 'package:test/test.dart';
import 'package:web_wasm/driver.dart';
import 'package:webdriver/async_io.dart';

enum Browser {
  chrome(
    isChromium: true,
    unsupportedImplementations: {WasmStorageImplementation.opfsShared},
    missingFeatures: {MissingBrowserFeature.dedicatedWorkersInSharedWorkers},
  ),
  firefox();

  final bool isChromium;
  final Set<WasmStorageImplementation> unsupportedImplementations;
  final Set<MissingBrowserFeature> missingFeatures;

  const Browser({
    this.isChromium = false,
    this.unsupportedImplementations = const {},
    this.missingFeatures = const {},
  });
}

void main(List<String> args) {
  final browser = Browser.values.byName(args[0]);
  final webDriverUri = Uri.parse(args[1]);

  late TestAssetServer server;
  late DriftWebDriver driver;

  setUpAll(() async {
    server = await TestAssetServer.start();
  });
  tearDownAll(() => server.close());

  setUp(() async {
    final rawDriver = await createDriver(
      spec: browser.isChromium ? WebDriverSpec.JsonWire : WebDriverSpec.W3c,
      uri: webDriverUri,
    );

    driver = DriftWebDriver(server, rawDriver);

    await driver.driver.get('http://localhost:8080/');
  });

  tearDown(() => driver.driver.quit());

  group('compatibility check', () {
    test('can enumerate', () async {
      final result = await driver.probeImplementations();

      final expectedImplementations = WasmStorageImplementation.values.toSet()
        ..removeAll(browser.unsupportedImplementations);

      expect(result.missingFeatures, browser.missingFeatures);
      expect(result.storages, expectedImplementations);
    });
  });
}
