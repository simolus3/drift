import 'dart:async';
import 'dart:convert';
import 'dart:io';

// ignore: implementation_imports
import 'package:drift/src/web/wasm_setup/types.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:web_wasm/initialization_mode.dart';
import 'driver.dart';

void main() {
  late TestAssetServer server;

  setUpAll(() async {
    server = await TestAssetServer.start();
  });
  tearDownAll(() => server.close());

  for (final browser in Browser.values) {
    group(browser.name, () {
      for (final wasm in [false, true]) {
        final compiler = wasm ? 'dart2wasm' : 'dart2js';

        group(compiler, () {
          final config = _TestConfiguration(browser, wasm);
          setUp(() {
            config.server = server;
          });

          config.declareTests();
        }, tags: [browser.name, compiler]);
      }
    });
  }
}

final class _TestConfiguration {
  final Browser browser;
  late TestAssetServer server;
  final bool isDart2wasm;

  _TestConfiguration(this.browser, this.isDart2wasm);

  Future<ConnectedClient> openBrowser({bool coep = true}) async {
    final (uri, client) = server.newClient(dart2wasm: isDart2wasm, coep: coep);
    final browserProcess = await browser.open(uri);
    addTearDown(browserProcess.close);

    return await client;
  }

  void declareTests() {
    test('compatibility check', () async {
      final client = await openBrowser();

      // Make sure we're not testing the same compiler twice due to e.g. bugs in
      // the loader script.
      expect(await client.isDart2wasm(), isDart2wasm);

      final result = await client.probeImplementations();

      expect(result.missingFeatures, browser.missingFeatures);
      expect(result.storages, browser.availableImplementations);
    });

    test('reports worker error for wrong URI', () async {
      final client = await openBrowser();
      final result = await client.probeImplementations(
        withWrongWorkerUri: true,
      );

      expect(
        result.missingFeatures,
        contains(MissingBrowserFeature.workerError),
      );
    });

    test('via regular open', () async {
      final client = await openBrowser();
      await client.openDatabase();
      expect(await client.amountOfRows, 0);

      await client.insertIntoDatabase();
      await client.waitForTableUpdate();
      expect(await client.amountOfRows, 1);
    });

    test('regular open with initializaton', () async {
      final client = await openBrowser();
      await client.enableInitialization(InitializationMode.loadAsset);
      await client.openDatabase();

      expect(await client.amountOfRows, 1);
    });

    test('disable migrations', () async {
      final client = await openBrowser();
      await client.enableInitialization(
        InitializationMode.noneAndDisableMigrations,
      );
      await client.openDatabase();

      expect(await client.hasTable, isFalse);
    });

    test('closes transactions when tab closes', () async {
      final client = await openBrowser();
      await client.openDatabase(
        implementation: WasmStorageImplementation.sharedIndexedDb,
      );

      final otherTab = await client.openWindow();
      await otherTab.openDatabase(
        implementation: WasmStorageImplementation.sharedIndexedDb,
      );
      await otherTab.lockForever();
      await client.closeWindow(otherTab);

      // We should be able to use the database in the first tab despite the
      // second tab locking it, as the second tab has now been closed.
      await client.insertInTransaction();
    });

    for (final entry in browser.availableImplementations) {
      group(entry.name, () {
        test('basic', () async {
          final client = await openBrowser();
          await client.openDatabase(implementation: entry);
          expect(await client.amountOfRows, 0);

          await client.insertIntoDatabase();
          await client.waitForTableUpdate();
          expect(await client.amountOfRows, 1);

          if (entry != WasmStorageImplementation.unsafeIndexedDb &&
              entry != WasmStorageImplementation.inMemory) {
            // Test stream query updates across tabs
            final otherTab = await client.openWindow();

            await otherTab.openDatabase(implementation: entry);
            expect(await otherTab.amountOfRows, 1);
            await otherTab.insertIntoDatabase();
            await client.closeWindow(otherTab);

            await client.waitForTableUpdate();
          }
        });

        if (entry != WasmStorageImplementation.inMemory) {
          test('export and delete', () async {
            var client = await openBrowser();
            final impl = await client.probeImplementations();
            expect(impl.existing, isEmpty);

            await client.openDatabase(implementation: entry);
            await client.insertIntoDatabase();
            await client.waitForTableUpdate();

            await client.closeDatabase();

            final newImpls = await client.probeImplementations();
            expect(newImpls.existing, hasLength(1));
            final existing = newImpls.existing[0];

            expect(
              await client.exportDatabase(existing.$1, existing.$2),
              isNotNull,
            );
            await client.deleteDatabase(existing.$1, existing.$2);

            client = await client.reload();

            final finalImpls = await client.probeImplementations();
            expect(finalImpls.existing, isEmpty);
          });

          test('migrations', () async {
            var client = await openBrowser();
            await client.openDatabase(implementation: entry);
            await client.insertIntoDatabase();
            await client.waitForTableUpdate();

            await client.closeDatabase();
            client = await client.reload();

            await client.setSchemaVersion(2);
            await client.openDatabase(implementation: entry);
            // The migration adds a row
            expect(await client.amountOfRows, 2);
          });

          test('disabling migrations', () async {
            final client = await openBrowser();
            await client.enableInitialization(
              InitializationMode.noneAndDisableMigrations,
            );
            await client.openDatabase();
            expect(await client.hasTable, isFalse);
          });

          test('persists writes from transactions and RETURNING', () async {
            var client = await openBrowser();
            await client.openDatabase(implementation: entry);
            await client.insertInTransaction();
            await client.insertReturning();
            expect(await client.amountOfRows, 2);

            // No delay before reloading: the writes must have been persisted
            // by the time they complete.
            client = await client.reload();

            await client.openDatabase(implementation: entry);
            expect(await client.amountOfRows, 2);
          });
        }

        group(
          'initialization from',
          () {
            test('static blob', () async {
              var client = await openBrowser();
              await client.enableInitialization(InitializationMode.loadAsset);
              await client.openDatabase(implementation: entry);

              expect(await client.amountOfRows, 1);
              await client.insertIntoDatabase();
              expect(await client.amountOfRows, 2);

              if (entry != WasmStorageImplementation.inMemory) {
                await Future.delayed(const Duration(seconds: 1));
                client = await client.reload();

                await client.enableInitialization(InitializationMode.loadAsset);
                await client.openDatabase();
                expect(await client.amountOfRows, 2);
              }
            });

            test('custom wasmdatabase', () async {
              final client = await openBrowser();
              await client.enableInitialization(
                InitializationMode.migrateCustomWasmDatabase,
              );
              await client.openDatabase(implementation: entry);

              expect(await client.amountOfRows, 1);
            });
          },
          skip:
              browser == Browser.firefox &&
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
          var client = await openBrowser();
          // Open an IndexedDB database first
          await client.openDatabase(
            implementation: WasmStorageImplementation.unsafeIndexedDb,
          );
          await client.insertIntoDatabase();
          await Future.delayed(const Duration(seconds: 2));
          client = await client.reload(); // Reset JS state

          // Open the database again, this time without specifying a fixed
          // implementation. Despite OPFS being available (and preferred),
          // the existing database should be used.
          await client.openDatabase();
          expect(await client.amountOfRows, 1);
        },
      );

      test('can migrate from IndexedDB to OPFS', () async {
        var client = await openBrowser();
        // Open an IndexedDB database first
        await client.openDatabase(
          implementation: WasmStorageImplementation.unsafeIndexedDb,
        );
        await client.insertIntoDatabase();
        await Future.delayed(const Duration(seconds: 2));
        client = await client.reload(); // Reset JS state

        // Open the database again, preferring a migration.
        await client.openDatabase(moveIndexedDbToOpfs: true);
        expect(await client.amountOfRows, 1);
        await Future.delayed(const Duration(seconds: 2));
        client = await client.reload(); // Reset JS state

        await client.openDatabase(
          implementation: WasmStorageImplementation.opfsLocks,
        );
        expect(await client.amountOfRows, 1);
      });

      if (!browser.supports(WasmStorageImplementation.opfsShared)) {
        test('uses indexeddb after OPFS becomes unavailable', () async {
          var client = await openBrowser();
          // This browser only supports OPFS with the right headers. If they
          // are ever removed, data is lost (nothing we could do about that),
          // but drift should continue to work.
          await client.openDatabase(
            implementation: WasmStorageImplementation.opfsLocks,
          );
          await client.insertIntoDatabase();
          expect(await client.amountOfRows, 1);
          await Future.delayed(const Duration(seconds: 2));

          client = await client.reload(coep: false);
          await client.openDatabase();
          expect(await client.amountOfRows, isZero);
        });
      }
    }

    test('supports exclusively API', () async {
      final client = await openBrowser();
      await client.openDatabase();
      expect(await client.amountOfRows, 0);

      await client.runExclusiveBlock();
      expect(await client.amountOfRows, 1);
    });
  }
}

enum Browser {
  manual(),
  firefox(),
  chrome(
    unsupportedImplementations: {WasmStorageImplementation.opfsShared},
    missingFeatures: {MissingBrowserFeature.dedicatedWorkersInSharedWorkers},
  ),
  safari(
    unsupportedImplementations: {WasmStorageImplementation.opfsShared},
    missingFeatures: {MissingBrowserFeature.dedicatedWorkersInSharedWorkers},
  );

  final Set<WasmStorageImplementation> unsupportedImplementations;
  final Set<MissingBrowserFeature> missingFeatures;

  const Browser({
    this.unsupportedImplementations = const {},
    this.missingFeatures = const {},
  });

  Set<WasmStorageImplementation> get availableImplementations {
    return WasmStorageImplementation.values.toSet()
      ..removeAll(unsupportedImplementations);
  }

  bool supports(WasmStorageImplementation impl) =>
      !unsupportedImplementations.contains(impl);

  /// Environment variable that can be set to override the path of the browser
  /// executable.
  String get _executableEnvironmentVariable => switch (this) {
    Browser.manual ||
    Browser.safari => throw StateError('No executable for $this'),
    Browser.firefox => 'FIREFOX_EXECUTABLE',
    Browser.chrome => 'CHROME_EXECUTABLE',
  };

  Future<String> _findExecutable() async {
    if (Platform.environment[_executableEnvironmentVariable] case final path?) {
      return path;
    }

    final candidates = switch ((this, Platform.operatingSystem)) {
      (Browser.firefox, 'macos') => [
        '/Applications/Firefox.app/Contents/MacOS/firefox',
      ],
      (Browser.chrome, 'macos') => [
        '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
        '/Applications/Chromium.app/Contents/MacOS/Chromium',
      ],
      (Browser.firefox, 'windows') => [
        r'C:\Program Files\Mozilla Firefox\firefox.exe',
      ],
      (Browser.chrome, 'windows') => [
        r'C:\Program Files\Google\Chrome\Application\chrome.exe',
        r'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe',
      ],
      _ => <String>[],
    };

    for (final candidate in candidates) {
      if (await File(candidate).exists()) {
        return candidate;
      }
    }

    // Fall back to resolving the executable from the PATH.
    return switch (this) {
      Browser.firefox => 'firefox',
      _ => 'google-chrome',
    };
  }

  Future<BrowserProcess> open(Uri uri) async {
    switch (this) {
      case Browser.manual:
        print('To run the test, open $uri');
        return BrowserProcess.manual();
      case Browser.firefox:
        final profile = await BrowserProcess.createProfileDirectory();
        // Avoid first-run pages and prompts in the fresh profile.
        await File(p.join(profile.path, 'user.js')).writeAsString('''
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("browser.aboutwelcome.enabled", false);
user_pref("browser.startup.homepage_override.mstone", "ignore");
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("toolkit.telemetry.reportingpolicy.firstRun", false);
user_pref("dom.disable_open_during_load", false);
user_pref("dom.allow_scripts_to_close_windows", true);
''');

        final process = await Process.start(await _findExecutable(), [
          '-headless',
          '-no-remote',
          '-profile',
          profile.path,
          uri.toString(),
        ]);
        return BrowserProcess(profile, process);
      case Browser.safari:
        return _openSafari(uri);
      case Browser.chrome:
        final profile = await BrowserProcess.createProfileDirectory();
        final process = await Process.start(await _findExecutable(), [
          '--headless=new',
          '--user-data-dir=${profile.path}',
          '--no-first-run',
          '--no-default-browser-check',
          '--disable-search-engine-choice-screen',
          // Tests open new windows without user interaction and expect
          // background tabs to keep running.
          '--disable-popup-blocking',
          '--disable-background-timer-throttling',
          '--disable-backgrounding-occluded-windows',
          '--disable-renderer-backgrounding',
          uri.toString(),
        ]);
        return BrowserProcess(profile, process);
    }
  }

  /// Starts an automation session in Safari and navigates it to [uri].
  ///
  /// Safari can't be started headless or with a custom profile, but automation
  /// sessions started through `safaridriver` use a fresh, ephemeral storage
  /// that is discarded when the session ends. We only use WebDriver to open the
  /// page, everything else goes through the regular test protocol.
  ///
  /// This requires running `safaridriver --enable` once.
  static Future<BrowserProcess> _openSafari(Uri uri) async {
    final port = await _unusedPort();
    final process = await Process.start('safaridriver', ['--port', '$port']);
    final session = _SafariSession(port);

    try {
      await session.create();
      await session.navigate(uri);
    } catch (_) {
      process.kill();
      session.close();
      rethrow;
    }

    return BrowserProcess.withDriver(process, session.delete);
  }
}

Future<int> _unusedPort() async {
  final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  await socket.close();
  return port;
}

/// A minimal client for the parts of the WebDriver protocol needed to launch
/// Safari.
///
/// Ported from https://github.com/dart-lang/test/blob/master/pkgs/test/lib/src/runner/browser/safari.dart.
final class _SafariSession {
  final int port;
  final http.Client _client = http.Client();
  String? _sessionId;

  _SafariSession(this.port);

  Future<Object?> _send(String method, String path, [Object? body]) async {
    final request = http.Request(method, Uri.http('127.0.0.1:$port', path));
    if (body != null) {
      request.headers['content-type'] = 'application/json';
      request.body = json.encode(body);
    }

    final response = await http.Response.fromStream(
      await _client.send(request),
    );
    final value = (json.decode(response.body) as Map)['value'];
    if (value case {'error': final error}) {
      throw 'safaridriver: $error: ${value['message']}';
    }

    return value;
  }

  Future<void> create() async {
    // safaridriver takes a moment to start listening.
    for (var i = 0; ; i++) {
      try {
        final value = await _send('POST', '/session', {
          'capabilities': {
            'alwaysMatch': {'browserName': 'safari'},
          },
        });
        _sessionId = (value as Map)['sessionId'] as String;
        return;
      } on http.ClientException {
        if (i == 20) rethrow;
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  Future<void> navigate(Uri uri) async {
    await _send('POST', '/session/$_sessionId/url', {'url': uri.toString()});
  }

  /// Ends the session, which closes all windows of the session.
  Future<void> delete() async {
    try {
      if (_sessionId != null) {
        await _send('DELETE', '/session/$_sessionId');
      }
    } finally {
      close();
    }
  }

  void close() => _client.close();
}

final class BrowserProcess {
  final Directory? profileDirectory;
  final Process? process;

  /// Invoked before killing the [process] to gracefully shut it down.
  final Future<void> Function()? _beforeKill;

  BrowserProcess.manual()
    : profileDirectory = null,
      process = null,
      _beforeKill = null;

  /// A browser controlled by a driver [process], which is shut down by calling
  /// [beforeKill] before stopping the driver.
  BrowserProcess.withDriver(Process process, Future<void> Function() beforeKill)
    : profileDirectory = null,
      process = process,
      _beforeKill = beforeKill {
    process.stdout.drain<void>();
    process.stderr.drain<void>();
  }

  BrowserProcess(Directory profileDirectory, Process process)
    : profileDirectory = profileDirectory,
      process = process,
      _beforeKill = null {
    // To avoid blocking the browser process when the buffer is full.
    process.stdout.drain<void>();
    process.stderr.drain<void>();

    process.exitCode.whenComplete(() async {
      try {
        await profileDirectory.delete(recursive: true);
      } on FileSystemException {
        // Helper processes may still be writing to the profile. It's only a
        // temporary directory, so failing to delete it is fine.
      }
    });
  }

  Future<void> get closed {
    return process?.exitCode ?? Completer().future;
  }

  Future<void> close() async {
    if (process case final process?) {
      try {
        await _beforeKill?.call();
      } finally {
        process.kill();
      }
      await process.exitCode;
    }
  }

  static Future<Directory> createProfileDirectory() async {
    return Directory.systemTemp.createTemp('drift-browser-test');
  }
}
