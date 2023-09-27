/// Shared types describing different file system implementations on the web.
///
/// This library must not import web-specific APIs, as it is also imported in
/// integration tests on a Dart VM (`extras/integration_tests/web_wasm`).
library;

import 'dart:async';

import 'package:drift/drift.dart';
import 'package:sqlite3/common.dart';

/// Signature of a function that can perform setup work on a [database] before
/// drift is fully ready.
///
/// This could be used to, for instance, register custom user-defined functions
/// on the database.
typedef WasmDatabaseSetup = void Function(CommonDatabase database);

/// The storage implementation used by the `drift` and `sqlite3` packages to
/// emulate a synchronous file system on the web, used by the sqlite3 C library
/// to store databases.
///
/// As persistence APIs exposed by Browsers are usually asynchronous, faking
/// a synchronous file system
enum WasmStorageImplementation {
  /// Uses the [Origin private file system APIs][OPFS] provided my modern
  /// browsers to persist data.
  ///
  /// In this storage mode, drift will host a single shared worker between tabs.
  /// As the file system API is only available in dedicated workers, the shared
  /// worker will spawn an internal dedicated worker which is thus shared between
  /// tabs as well.
  ///
  /// The OPFS API allows synchronous access to files, but only after they have
  /// been opened asynchronously. Since sqlite3 only needs access to two files
  /// for a database files, we can just open them once and keep them open while
  /// the database is in use.
  ///
  /// This mode is a very reliable and efficient approach to access sqlite3
  /// on the web, and the preferred mode used by drift.
  ///
  /// While the relevant specifications allow shared workers to spawn nested
  /// workers, this is only implemented in Firefox at the time of writing.
  /// Chrome (https://crbug.com/1088481) and Safari don't support this yet.
  ///
  /// [OPFS]: https://developer.mozilla.org/en-US/docs/Web/API/File_System_Access_API#origin_private_file_system
  opfsShared,

  /// Uses the [Origin private file system APIs][OPFS] provided my modern
  /// browsers to persist data.
  ///
  /// Unlike [opfsShared], this storage implementation does not use a shared
  /// worker (either because it is not available or because the current browser
  /// doesn't allow shared workers to spawn dedicated workers). Instead, each
  /// tab spawns two dedicated workers that use `Atomics.wait` and `Atomics.notify`
  /// to turn the asynchronous OPFS API into a synchronous file system
  /// implementation.
  ///
  /// While being less efficient than [opfsShared], this mode is also very
  /// reliably and used by the official WASM builds of the sqlite3 project as
  /// well.
  ///
  /// It requires [cross-origin isolation], which needs to be enabled by serving
  /// your app with special headers:
  ///
  /// ```
  /// Cross-Origin-Opener-Policy: same-origin
  /// Cross-Origin-Embedder-Policy: require-corp
  /// ```
  ///
  /// [OPFS]: https://developer.mozilla.org/en-US/docs/Web/API/File_System_Access_API#origin_private_file_system´
  /// [cross-origin isolation]: https://developer.mozilla.org/en-US/docs/Web/API/crossOriginIsolated
  opfsLocks,

  /// Emulates a file system over `IndexedDB` in a shared worker.
  sharedIndexedDb,

  /// Uses the asynchronous IndexedDB API outside of any worker to persist data.
  ///
  /// Unlike [opfsShared], [opfsLocks] or [sharedIndexedDb], this storage
  /// implementation can't prevent data races if your app is opened in multiple
  /// tabs at the same time, which is why it's declared as as unsafe.
  unsafeIndexedDb,

  /// A fallback storage implementation that doesn't store anything.
  ///
  /// This implementation is chosen when none of the features needed for other
  /// storage implementations are supported by the current browser. In this case,
  /// [WasmDatabaseResult.missingFeatures] enumerates missing browser features.
  inMemory,
}

/// The storage API used by drift to store a database.
enum WebStorageApi {
  /// The database is stored in the origin-private section of the user's file
  /// system via the FileSystem Access API.
  opfs,

  /// The database is stored in IndexedDb.
  indexedDb;

  /// Cached [EnumByName.asNameMap] for [values].
  static final byName = WebStorageApi.values.asNameMap();
}

/// An enumeration of features not supported by the current browsers.
///
/// While this information may not be useful to end users, it can be used to
/// understand why drift has chosen a particular storage implementation in
/// [WasmDatabaseResult].
enum MissingBrowserFeature {
  /// The browser is missing support for [shared workers].
  ///
  /// [shared workers]: https://developer.mozilla.org/en-US/docs/Web/API/SharedWorker
  sharedWorkers,

  /// The browser is missing support for [web workers] in general.
  ///
  /// [web workers]: https://developer.mozilla.org/en-US/docs/Web/API/Worker
  dedicatedWorkers,

  /// The browser doesn't allow shared workers to spawn dedicated workers in
  /// their context.
  ///
  /// While the specification for web workers explicitly allows this, this
  /// feature is only implemented by Firefox at the time of writing.
  dedicatedWorkersInSharedWorkers,

  /// The browser does not support a synchronous version of the [File System API]
  ///
  /// [File System API]: https://developer.mozilla.org/en-US/docs/Web/API/File_System_Access_API
  fileSystemAccess,

  /// The browser does not support IndexedDB.
  indexedDb,

  /// The browser does not support shared array buffers and `Atomics.wait`.
  ///
  /// To enable this feature in most browsers, you need to serve your app with
  /// two [special headers](https://web.dev/coop-coep/).
  sharedArrayBuffers,
}

/// Information about an existing web database, consisting of its
/// storage API ([WebStorageApi]) and its name.
typedef ExistingDatabase = (WebStorageApi, String);

/// The result of probing the current browser for wasm compatibility.
///
/// This reports available storage implementations ([availableStorages]) and
/// [missingFeatures] that contributed to some storage implementations not being
/// available.
///
/// In addition, [existingDatabases] reports a list of existing databases. Note
/// that databases stored in IndexedDb can't be listed reliably. Only databases
/// with the name given in [WasmDatabase.probe] are listed. Databases stored in
/// OPFS are always listed.
abstract interface class WasmProbeResult {
  /// All available [WasmStorageImplementation]s supported by the current
  /// browsing context.
  ///
  /// Depending on the features available in the browser your app runs on and
  /// whether your app is served with the required headers for shared array
  /// buffers, different implementations might be available.
  ///
  /// You can see the [WasmStorageImplementation]s and
  /// [the web documentation](https://drift.simonbinder.eu/web/#storages) to
  /// learn more about which implementations drift can use.
  List<WasmStorageImplementation> get availableStorages;

  /// For every storage found, drift also reports existing drift databases.
  List<ExistingDatabase> get existingDatabases;

  /// An enumeration of missing browser features probed by drift.
  ///
  /// Missing browser features limit the available storage implementations.
  Set<MissingBrowserFeature> get missingFeatures;

  /// Opens a connection to a database via the chosen [implementation].
  ///
  /// When this database doesn't exist, [initializeDatabase] is invoked to
  /// optionally return the initial bytes of the database.
  Future<DatabaseConnection> open(
    WasmStorageImplementation implementation,
    String name, {
    FutureOr<Uint8List?> Function()? initializeDatabase,
    WasmDatabaseSetup? localSetup,
  });

  /// Deletes an [ExistingDatabase] from storage.
  ///
  /// This method should not be called while a connection to the database is
  /// opened.
  ///
  /// This method is only supported when using the drift worker shipped with the
  /// drift 2.11 release or later. This method will not work when using an older
  /// worker.
  Future<void> deleteDatabase(ExistingDatabase database);
}

/// The result of opening a WASM database with default options.
final class WasmDatabaseResult {
  /// The drift database connection to pass to the [GeneratedDatabase.new]
  /// constructor of your database class to use the opened database.
  final DatabaseConnection resolvedExecutor;

  /// For your reference, the chosen storage implementation.
  ///
  /// Depending on the features available in the browser your app runs on, drift
  /// will use the most reliable implementation in [WasmStorageImplementation].
  ///
  /// If the implementation can't store data reliably ([WasmStorageImplementation.unsafeIndexedDb])
  /// or not at all ([WasmStorageImplementation.inMemory]), you may want to show
  /// a warning to the user if persistence is important in your app.
  final WasmStorageImplementation chosenImplementation;

  /// An enumeration of missing browser features probed by drift.
  ///
  /// The lack of support of features listed here contributed to the
  /// [chosenImplementation] for the virtual file system used to store databases.
  final Set<MissingBrowserFeature> missingFeatures;

  /// Default constructor from the invidiual fields.
  const WasmDatabaseResult(
      this.resolvedExecutor, this.chosenImplementation, this.missingFeatures);
}
