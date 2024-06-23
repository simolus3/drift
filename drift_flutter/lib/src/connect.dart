export 'unsupported.dart'
    if (dart.library.js) 'web.dart'
    if (dart.library.ffi) 'native.dart';

export 'package:drift/src/web/wasm_setup/types.dart';
// ignore: implementation_imports
import 'package:drift/src/web/wasm_setup/types.dart';

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

  /// Create web-specific drift options.
  DriftWebOptions({
    required this.sqlite3Wasm,
    required this.driftWorker,
    this.onResult,
  });
}
