import 'dart:async';
import 'dart:html';
import 'dart:indexed_db';
import 'dart:js';
import 'dart:js_util' as js_util;
import 'dart:typed_data';

import 'package:meta/meta.dart';

import 'binary_string_conversion.dart';

/// Interface to control how drift should store data on the web.
abstract class DriftWebStorage {
  /// Opens the storage implementation.
  Future<void> open();

  /// Closes the storage implementation.
  ///
  /// No further requests may be sent after [close] was called.
  Future<void> close();

  /// Restore the last database version that was saved with [store].
  ///
  /// If no saved data was found, returns null.
  Future<Uint8List?> restore();

  /// Store the entire database.
  Future<void> store(Uint8List data);

  /// Creates the default storage implementation that uses the local storage
  /// apis.
  ///
  /// The [name] parameter is used as a key to store the database blob in local
  /// storage. It can be used to store multiple databases.
  const factory DriftWebStorage(String name) = _LocalStorageImpl;

  /// Creates an in-memory storage that doesn't persist data.
  ///
  /// This means that your database will be recreated at each page reload.
  factory DriftWebStorage.volatile() = _VolatileStorage;

  /// An experimental storage implementation that uses IndexedDB.
  ///
  /// This implementation is significantly faster than the default
  /// implementation in local storage. Browsers also tend to allow more data
  /// to be saved in IndexedDB.
  ///
  /// When the [migrateFromLocalStorage] parameter (defaults to `true`) is set,
  /// old data saved using the default [DriftWebStorage] will be migrated to the
  /// IndexedDB based implementation. This parameter can be turned off for
  /// applications that never used the local storage implementation as a small
  /// performance improvement.
  ///
  /// When the [inWebWorker] parameter (defaults to false) is set,
  /// the implementation will use [WorkerGlobalScope] instead of [window] as
  /// it isn't accessible from the worker.
  ///
  /// However, older browsers might not support IndexedDB.
  @experimental
  factory DriftWebStorage.indexedDb(String name,
      {bool migrateFromLocalStorage, bool inWebWorker}) = _IndexedDbStorage;

  /// Uses [DriftWebStorage.indexedDb] if the current browser supports it.
  /// Otherwise, falls back to the local storage based implementation.
  static Future<DriftWebStorage> indexedDbIfSupported(String name,
      {bool inWebWorker = false}) async {
    return await supportsIndexedDb(inWebWorker: inWebWorker)
        ? DriftWebStorage.indexedDb(name, inWebWorker: inWebWorker)
        : DriftWebStorage(name);
  }

  /// Attempts to check whether the current browser supports the
  /// [DriftWebStorage.indexedDb] storage implementation.
  static Future<bool> supportsIndexedDb({bool inWebWorker = false}) async {
    var isIndexedDbSupported = false;
    if (inWebWorker && WorkerGlobalScope.instance.indexedDB != null) {
      isIndexedDbSupported = true;
    } else {
      try {
        isIndexedDbSupported = IdbFactory.supported;

        if (isIndexedDbSupported) {
          // Try opening a mock database to check if IndexedDB is really
          // available. This avoids the problem with Firefox incorrectly
          // reporting IndexedDB as supported in private mode.
          final mockDb = await window.indexedDB!.open('drift_mock_db');
          mockDb.close();
        }
      } catch (error) {
        isIndexedDbSupported = false;
      }
    }

    return isIndexedDbSupported && js_util.hasProperty(context, 'FileReader');
  }
}

/// A web storage implementation that stores the schema version outside of the
/// `PRAGMA user_version` of the database.
@internal
abstract class CustomSchemaVersionSave implements DriftWebStorage {
  /// Get or set the current schema version of an opened database file.
  int? get schemaVersion;
  set schemaVersion(int? value);
}

String _persistenceKeyForLocalStorage(String name) {
  return 'moor_db_str_$name';
}

String _legacyVersionKeyForLocalStorage(String name) {
  return 'moor_db_version_$name';
}

Uint8List? _restoreLocalStorage(String name) {
  final raw = window.localStorage[_persistenceKeyForLocalStorage(name)];
  if (raw != null) {
    return bin2str.decode(raw);
  }
  return null;
}

class _LocalStorageImpl implements DriftWebStorage, CustomSchemaVersionSave {
  final String name;

  String get _persistenceKey => _persistenceKeyForLocalStorage(name);
  String get _versionKey => _legacyVersionKeyForLocalStorage(name);

  const _LocalStorageImpl(this.name);

  @override
  int? get schemaVersion {
    final versionStr = window.localStorage[_versionKey];
    // ignore: avoid_returning_null
    if (versionStr == null) return null;

    return int.tryParse(versionStr);
  }

  @override
  set schemaVersion(int? value) {
    final key = _versionKey;

    if (value == null) {
      window.localStorage.remove(key);
    } else {
      window.localStorage[_versionKey] = value.toString();
    }
  }

  @override
  Future<void> close() => Future.value();

  @override
  Future<void> open() => Future.value();

  @override
  Future<Uint8List?> restore() async {
    return _restoreLocalStorage(name);
  }

  @override
  Future<void> store(Uint8List data) {
    final binStr = bin2str.encode(data);
    window.localStorage[_persistenceKey] = binStr;

    return Future.value();
  }
}

class _IndexedDbStorage implements DriftWebStorage {
  static const _objectStoreName = 'moor_databases';

  final String name;
  final bool migrateFromLocalStorage;
  final bool inWebWorker;

  late Database _database;

  _IndexedDbStorage(this.name,
      {this.migrateFromLocalStorage = true, this.inWebWorker = false});

  @override
  Future<void> open() async {
    var wasCreated = false;

    final indexedDb =
        inWebWorker ? WorkerGlobalScope.instance.indexedDB : window.indexedDB;

    _database = await indexedDb!.open(
      _objectStoreName,
      version: 1,
      onUpgradeNeeded: (event) {
        final database = event.target.result as Database;

        database.createObjectStore(_objectStoreName);
        wasCreated = true;
      },
    );

    if (migrateFromLocalStorage && wasCreated) {
      final fromLocalStorage = _restoreLocalStorage(name);
      if (fromLocalStorage != null) {
        await store(fromLocalStorage);
      }
    }
  }

  @override
  Future<void> close() async {
    _database.close();
  }

  @override
  Future<void> store(Uint8List data) async {
    final transaction =
        _database.transactionStore(_objectStoreName, 'readwrite');
    final store = transaction.objectStore(_objectStoreName);

    final request = js_util.callMethod<Request>(store, 'put', [data, name]);

    final completer = Completer.sync();
    request.onSuccess.listen((_) => completer.complete());
    request.onError.listen(completer.completeError);
    await completer.future;

    await transaction.completed;
  }

  @override
  Future<Uint8List?> restore() async {
    final transaction =
        _database.transactionStore(_objectStoreName, 'readonly');
    final store = transaction.objectStore(_objectStoreName);

    final result = await store.getObject(name);
    if (result is Blob) {
      final reader = FileReader();
      reader.readAsArrayBuffer(result);
      // todo: Do we need to handle errors? We're reading from memory
      await reader.onLoad.first;

      return reader.result as Uint8List;
    } else if (result is Uint8List) {
      return result;
    } else {
      return null;
    }
  }
}

class _VolatileStorage implements DriftWebStorage {
  Uint8List? _storedData;

  @override
  Future<void> close() => Future.value();

  @override
  Future<void> open() => Future.value();

  @override
  Future<Uint8List?> restore() => Future.value(_storedData);

  @override
  Future<void> store(Uint8List data) {
    _storedData = data;
    return Future.value();
  }
}
