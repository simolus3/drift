/// A (very!) experimental web-compatible version of drift that doesn't depend
/// on external JavaScript sources.
///
/// This library is highly experimental and not production readdy at the moment.
/// It exists for development and testing purposes for interested users.
///
/// While this library is marked as [experimental], it is not subject to
/// semantic versioning. Future drift updates with a minor update might break
/// APIs defined in this package or change the way data is persisted in
/// backwards-incompatible ways.
///
/// To use drift on the web, use the `package:drift/web.dart` library as
/// described in the [documentation](https://drift.simonbinder.eu/web/).
@experimental
library drift.wasm;

import 'package:meta/meta.dart';
import 'package:sqlite3/common.dart';

import 'backends.dart';
import 'src/sqlite3/database.dart';

/// Signature of a function that can perform setup work on a [database] before
/// drift is fully ready.
///
/// This could be used to, for instance, set encryption keys for SQLCipher
/// implementations.
typedef WasmDatabaseSetup = void Function(CommonDatabase database);

/// An experimental, WebAssembly based implementation of a drift sqlite3
/// database.
///
/// Using this database requires adding a WebAssembly file for sqlite3 to your
/// app. Details for that are available [here](https://github.com/simolus3/sqlite3.dart/).
class WasmDatabase extends DelegatedDatabase {
  WasmDatabase._(DatabaseDelegate delegate, bool logStatements)
      : super(delegate, isSequential: true, logStatements: logStatements);

  /// Creates a wasm database at [path] in the virtual file system of the
  /// [sqlite3] module.
  factory WasmDatabase({
    required CommmonSqlite3 sqlite3,
    required String path,
    WasmDatabaseSetup? setup,
    bool logStatements = false,
  }) {
    return WasmDatabase._(_WasmDelegate(sqlite3, path, setup), logStatements);
  }

  /// Creates an in-memory database in the loaded [sqlite3] database.
  factory WasmDatabase.inMemory(
    CommmonSqlite3 sqlite3, {
    WasmDatabaseSetup? setup,
    bool logStatements = false,
  }) {
    return WasmDatabase._(_WasmDelegate(sqlite3, null, setup), logStatements);
  }

  @override
  bool get supportsBigInt => true;
}

class _WasmDelegate extends Sqlite3Delegate<CommonDatabase> {
  final CommmonSqlite3 _sqlite3;
  final String? _path;

  _WasmDelegate(this._sqlite3, this._path, WasmDatabaseSetup? setup)
      : super(setup);

  @override
  CommonDatabase openDatabase() {
    final path = _path;
    if (path == null) {
      return _sqlite3.openInMemory();
    } else {
      return _sqlite3.open(path);
    }
  }
}
