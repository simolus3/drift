part of 'package:moor/moor_web.dart';

/// Interface to control how moor should store data on the web.
abstract class MoorWebStorage {
  /// Opens the storage implementation.
  Future<void> open();

  /// Closes the storage implementation.
  ///
  /// No further requests may be sent after [close] was called.
  Future<void> close();

  /// Restore the last database version that was saved with [store].
  ///
  /// If no saved data was found, returns null.
  Future<Uint8List> restore();

  /// Store the entire database.
  Future<void> store(Uint8List data);

  /// Creates the default storage implementation that uses the local storage
  /// apis.
  ///
  /// The [name] parameter can be used to store multiple databases.
  const factory MoorWebStorage(String name) = _LocalStorageImpl;

  /// An experimental storage implementation that uses IndexedDB.
  ///
  /// This implementation is significantly faster than the default
  /// implementation in local storage. Browsers also tend to allow more data
  /// to be saved in IndexedDB.
  ///
  /// When the [migrateFromLocalStorage] parameter (defaults to `true`) is set,
  /// old data saved using the default [MoorWebStorage] will be migrated to the
  /// IndexedDB based implementation. This parameter can be turned off for
  /// applications that never used the local storage implementation as a small
  /// performance improvement.
  ///
  /// However, older browsers might not support IndexedDB.
  @experimental
  factory MoorWebStorage.indexedDb(String name,
      {bool migrateFromLocalStorage, bool inWebWorker}) = _IndexedDbStorage;

  /// Uses [MoorWebStorage.indexedDb] if the current browser supports it.
  /// Otherwise, falls back to the local storage based implementation.
  factory MoorWebStorage.indexedDbIfSupported(String name,
      {bool inWebWorker = false}) {
    return supportsIndexedDb(inWebWorker: inWebWorker)
        ? MoorWebStorage.indexedDb(name, inWebWorker: inWebWorker)
        : MoorWebStorage(name);
  }

  /// Attempts to check whether the current browser supports the
  /// [MoorWebStorage.indexedDb] storage implementation.
  static bool supportsIndexedDb({bool inWebWorker = false}) {
    var isIndexedDbSupported = false;
    if (inWebWorker && WorkerGlobalScope.instance.indexedDB != null) {
      isIndexedDbSupported = true;
    } else {
      try {
        isIndexedDbSupported = IdbFactory.supported;
      } catch (error) {
        isIndexedDbSupported = false;
      }
    }
    return isIndexedDbSupported && context.hasProperty('FileReader');
  }
}

abstract class _CustomSchemaVersionSave implements MoorWebStorage {
  int /*?*/ get schemaVersion;
  set schemaVersion(int value);
}

String _persistenceKeyForLocalStorage(String name) {
  return 'moor_db_str_$name';
}

String _legacyVersionKeyForLocalStorage(String name) {
  return 'moor_db_version_$name';
}

Uint8List /*?*/ _restoreLocalStorage(String name) {
  final raw = window.localStorage[_persistenceKeyForLocalStorage(name)];
  if (raw != null) {
    return bin2str.decode(raw);
  }
  return null;
}

class _LocalStorageImpl implements MoorWebStorage, _CustomSchemaVersionSave {
  final String name;

  String get _persistenceKey => _persistenceKeyForLocalStorage(name);
  String get _versionKey => _legacyVersionKeyForLocalStorage(name);

  const _LocalStorageImpl(this.name);

  @override
  int get schemaVersion {
    final versionStr = window.localStorage[_versionKey];
    // ignore: avoid_returning_null
    if (versionStr == null) return null;

    return int.tryParse(versionStr);
  }

  @override
  set schemaVersion(int value) {
    window.localStorage[_versionKey] = value.toString();
  }

  @override
  Future<void> close() => Future.value();

  @override
  Future<void> open() => Future.value();

  @override
  Future<Uint8List> restore() async {
    return _restoreLocalStorage(name);
  }

  @override
  Future<void> store(Uint8List data) {
    final binStr = bin2str.encode(data);
    window.localStorage[_persistenceKey] = binStr;

    return Future.value();
  }
}

class _IndexedDbStorage implements MoorWebStorage {
  static const _objectStoreName = 'moor_databases';

  final String name;
  final bool migrateFromLocalStorage;
  final bool inWebWorker;

  Database _database;

  _IndexedDbStorage(this.name,
      {this.migrateFromLocalStorage = true, this.inWebWorker = false});

  @override
  Future<void> open() async {
    var wasCreated = false;

    final indexedDb =
    inWebWorker ? WorkerGlobalScope.instance.indexedDB : window.indexedDB;

    _database = await indexedDb.open(
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

    await store.put(Blob([data]), name);
    await transaction.completed;
  }

  @override
  Future<Uint8List> restore() async {
    final transaction =
    _database.transactionStore(_objectStoreName, 'readonly');
    final store = transaction.objectStore(_objectStoreName);

    final result = await store.getObject(name) as Blob /*?*/;
    if (result == null) return null;

    final reader = FileReader();
    reader.readAsArrayBuffer(result);
    // todo: Do we need to handle errors? We're reading from memory
    await reader.onLoad.first;

    return reader.result as Uint8List;
  }
}
