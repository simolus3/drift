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
  /// However, older browsers might not support IndexedDB.
  @experimental
  factory MoorWebStorage.indexedDb(String name) = _IndexedDbStorage;
}

abstract class _CustomSchemaVersionSave implements MoorWebStorage {
  int /*?*/ get schemaVersion;
  set schemaVersion(int value);
}

class _LocalStorageImpl implements MoorWebStorage, _CustomSchemaVersionSave {
  final String name;

  String get _persistenceKey => 'moor_db_str_$name';
  String get _versionKey => 'moor_db_version_$name';

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
    final raw = window.localStorage[_persistenceKey];
    if (raw != null) {
      return bin2str.decode(raw);
    }
    return null;
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

  Database _database;

  _IndexedDbStorage(this.name);

  @override
  Future<void> open() async {
    _database = await window.indexedDB.open(
      _objectStoreName,
      version: 1,
      onUpgradeNeeded: (event) {
        final database = event.target.result as Database;
        database.createObjectStore(_objectStoreName);
      },
    );
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
