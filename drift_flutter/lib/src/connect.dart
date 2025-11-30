/// @docimport `package:sqlite3/sqlite3.dart`
library;

export 'unsupported.dart'
    if (dart.library.js_interop) 'web.dart'
    if (dart.library.ffi) 'native.dart';

export 'package:drift/src/web/wasm_setup/types.dart';
import 'dart:async';
import 'dart:typed_data';

// ignore: implementation_imports
import 'package:drift/src/web/wasm_setup/types.dart';
import 'package:sqlite3/common.dart';

/// Web-specific options used to open drift databases.
///
/// These options are ignored when drift is opened on native platforms.
final class DriftWebOptions {
  /// A uri pointing to the compiled sqlite3 WebAssembly module.
  ///
  /// If you have placed the module into your `web/` folder, you can simply use
  /// a relative url: `Uri.parse('sqlite3.wasm')`
  final Uri sqlite3Wasm;

  /// A uri pointing to the compiled drift worker.
  ///
  /// If you have placed the worker into your `web/` folder, you can simply use
  /// a relative url: `Uri.parse('drift_worker.js')`
  final Uri driftWorker;

  /// A method invoked when opening a database on the web, giving you access to
  /// the [WasmDatabaseResult] obtained before opening the database.
  ///
  /// The result provides insights about available browser features and how they
  /// impacted the database implementation (e.g. OPFS, IndexedDB) chosen.
  final void Function(WasmDatabaseResult)? onResult;

  final FutureOr<Uint8List?> Function()? initializeDatabase;

  /// Create web-specific drift options.
  DriftWebOptions({
    required this.sqlite3Wasm,
    required this.driftWorker,
    this.onResult,
    this.initializeDatabase,
  });
}

/// Options used to open drift databases on native platforms (outside of the
/// web).
final class DriftNativeOptions {
  /// Whether two isolates opening a drift database with the name should be
  /// connected to a shared database instance.
  ///
  /// When using a shared instance, stream queries synchronize across the two
  /// isolates. Also, drift then manages concurrent access to the database,
  /// preventing "database is locked" errors due to concurrent transactions.
  /// Note that this uses an `IsolateNameServer` to discover drift databases, so
  /// this feature does not work across databases opened by independent Flutter
  /// engines.
  ///
  /// A downside is a minor performance overhead caused by sending table updates
  /// across isolates.
  ///
  /// This option is not enabled by default, but recommended if a drift database
  /// may be used on multiple isolates.
  final bool shareAcrossIsolates;

  /// Setting the [isolateDebugLog] is only helpful when debugging drift itself.
  /// It will print messages exchanged between the drift isolate server and the
  /// client.
  final bool isolateDebugLog;

  /// An optional callback returning a custom database path to be used by drift.
  ///
  /// By default, drift uses the `getApplicationDocumentsDirectory()` function
  /// from `package:path_provider` as a base directory and uses a file named
  /// `$name.sqlite` to store the database.
  ///
  /// This function, which can be asynchronous for convenience, allows using
  /// a custom database path in another directory.
  ///
  /// At most one of [databasePath] or [databaseDirectory] may be used. Using
  /// [databasePath] allows more control over the file name, while
  /// [databaseDirectory] can be used to select another directory from
  /// `path_provider` more easily.
  final Future<String> Function()? databasePath;

  /// An optional function returning either a string or a `Directory` that will
  /// be used as a directory to store the database.
  ///
  /// By default, drift will use `getApplicationDocumentsDirectory()` function
  /// from `package:path_provider` as a directory an `$name.sqlite` as a file
  /// name in that directory.
  ///
  /// At most one of [databasePath] or [databaseDirectory] may be used. Using
  /// [databasePath] allows more control over the file name, while
  /// [databaseDirectory] can be used to select another directory from
  /// `path_provider` more easily.
  final Future<Object> Function()? databaseDirectory;

  /// An optional callback returning a temporary directory.
  ///
  /// For larger queries, sqlite3 might store intermediate results in memory.
  /// By default, sqlite3 will attempt to store these results in `/tmp/`. On
  /// some platforms, the global `/tmp/` directory is inaccessible to sandboxed
  /// application, which then causes issues with sqlite3.
  /// For this reason, `drift_flutter` will configure sqlite3 to store these
  /// results in an application-defined temporary directory.
  ///
  /// When not set, `drift_flutter` defaults to `getTemporaryDirectory()` from
  /// `package:path_provider`.
  ///
  /// If the function returns `null`, the temporary directory for sqlite3 will
  /// not be changed by `drift_flutter`.
  final Future<String?> Function()? tempDirectoryPath;

  /// An optional callback to be invoked when opening an underlying database
  /// connection.
  ///
  /// Because the connection options are cross-platform, the function is
  /// declared to get invoked with a [CommonDatabase] instance, but at runtime
  /// will only get called with native [Database] instances. If you need to
  /// access functionality not available on the common interface, cast as
  /// necessary.
  ///
  /// This function is sent across isolates because that's where connections are
  /// actually opened, so this function must not capture closed variables that
  /// can't be sent over isolates.
  final void Function(CommonDatabase db)? setup;

  /// An optional callback to be invoked when `drift_flutter` spawns a
  /// background isolate to host database connections.
  ///
  /// This could be used to configure how `libsqlite3` is loaded, or setup state
  /// that needs to be accessible in the background isolate.
  final void Function()? isolateSetup;

  /// Create drift options effective when opening drift databases on native
  /// platforms.
  const DriftNativeOptions({
    this.shareAcrossIsolates = false,
    this.isolateDebugLog = false,
    this.databasePath,
    this.databaseDirectory,
    this.tempDirectoryPath,
    this.isolateSetup,
    this.setup,
  }) : assert(
          databasePath == null || databaseDirectory == null,
          'databasePath and databaseDirectory must not both be set.',
        );
}
