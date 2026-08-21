/// @docimport `package:sqlite3/sqlite3.dart`
library;

export 'unsupported.dart'
    if (dart.library.js_interop) 'web.dart'
    if (dart.library.ffi) 'native.dart';

import 'dart:async';
import 'dart:typed_data';

import 'package:drift3_preview/drift.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlite3_web/types.dart';

/// Web-specific options used to open drift databases.
///
/// These options are ignored when drift is opened on native platforms.
final class DriftWebOptions {
  /// A uri pointing to the compiled sqlite3 WebAssembly module.
  ///
  /// If you have placed the module into your `web/` folder, you can simply use
  /// a relative url: `sqlite3.wasm`.
  final String sqlite3Wasm;

  /// A uri pointing to the compiled drift worker.
  ///
  /// If you have placed the worker into your `web/` folder, you can simply use
  /// a relative url: `drift_worker.js`.
  final String driftWorker;

  /// A method invoked when opening a database on the web, giving you access to
  /// the [WasmDatabaseResult] obtained before opening the database.
  ///
  /// The result provides insights about available browser features and how they
  /// impacted the database implementation (e.g. OPFS, IndexedDB) chosen.
  final void Function(WasmDatabaseResult)? onResult;

  /// A function providing initial database bytes if the database does not
  /// exist.
  final FutureOr<Uint8List?> Function()? initializeDatabase;

  /// Create web-specific drift options.
  const DriftWebOptions({
    required this.sqlite3Wasm,
    required this.driftWorker,
    this.onResult,
    this.initializeDatabase,
  });
}

/// The result of opening a WebAssembly-based SQLite database on the web.
final class WasmDatabaseResult {
  /// The opened [DriftSession] that will be used to run queries on the drift
  /// database.
  final DriftSession resolvedSession;

  /// An enumeration of missing browser features probed by drift.
  ///
  /// The lack of support of features listed here contributed to the
  /// [databaseImplementation] for the virtual file system used to store
  /// databases.
  final FeatureDetectionResult features;

  /// For your reference, the chosen storage implementation.
  ///
  /// Depending on the features available in the browser your app runs on, drift
  /// will use the most reliable implementation in [DatabaseImplementation].
  ///
  /// If the implementation can't store data reliably ([DatabaseImplementation.indexedDbUnsafeLocal])
  /// or not at all ([DatabaseImplementation.inMemoryLocal]), you may want to show
  /// a warning to the user if persistence is important in your app.
  final DatabaseImplementation databaseImplementation;

  /// @nodoc
  WasmDatabaseResult({
    required this.resolvedSession,
    required this.features,
    required this.databaseImplementation,
  });
}

/// Options used to open drift databases on native platforms (outside of the
/// web).
final class DriftNativeOptions {
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
  final void Function(CommonDatabase, {required bool isWriter})? setup;

  /// Create drift options effective when opening drift databases on native
  /// platforms.
  const DriftNativeOptions({
    this.databasePath,
    this.databaseDirectory,
    this.tempDirectoryPath,
    this.setup,
  }) : assert(
         databasePath == null || databaseDirectory == null,
         'databasePath and databaseDirectory must not both be set.',
       );
}
