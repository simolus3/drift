part of 'manager.dart';

/// Base class for reading a rows from a table and optionally including references to other tables.
///
/// An extended class is generated for each table in the database.
/// [TableDataClass] is the dataclass for the table being read.
/// [DataClassWithReferences] is a record which includes the dataclass and any references.
abstract class ReferenceReader<TableDataClass extends DataClass,
    DataClassWithReferences extends Record> {
  /// The manager for the table being read.
  BaseTableManager get $manager;

  /// The database for the table being read.
  GeneratedDatabase get _db => $manager.$state.db;

  /// Returns the table for a column.
  TableInfo _tableFromColumn(GeneratedColumn column) {
    return _db.allTables
        .firstWhere((element) => element.actualTableName == column.tableName);
  }

  /// Returns a single referenced item from a reference column.
  /// [ReturnType] is the type of the item being returned. When [ReturnType] is void, null is returned. e.g. Category, void
  Future<ReturnType?> $getSingleReferenced<ReturnType>(
      Object? currentId, GeneratedColumn referencedColumn) async {
    if (_typesEqual<ReturnType, void>() || currentId == null) {
      return null;
    } else {
      final select = _db.select(_tableFromColumn(referencedColumn))
        ..where((tbl) => referencedColumn.equals(currentId));
      return (await select.getSingleOrNull() as ReturnType?);
    }
  }

  /// Returns a list of referenced items from a reverse reference column.
  /// [ReturnType] is the type of the item being returned. When [ReturnType] is void, null is returned. e.g. List<Category>, void
  /// [ReferencedItemType] is the type of the items in the list being returned. e.g. Category
  Future<List<ReferencedItemType>?>
      $getReverseReferenced<ReturnType, ReferencedItemType>(
          Object currentId, GeneratedColumn referencedColumn) async {
    if (_typesEqual<ReturnType, void>()) {
      return null;
    } else {
      final select = _db.select(_tableFromColumn(referencedColumn))
        ..where((tbl) => referencedColumn.equals(currentId));
      return (await select.get()).whereType<ReferencedItemType>().toList();
    }
  }

  /// Returns a single [TableDataClass] with whatever references that are included.
  Future<DataClassWithReferences> $withReferences(covariant DataClass value);

  /// Returns a list of rows with whichever references are included.
  ///
  /// See [BaseTableManager.get] for more information.
  Future<Iterable<DataClassWithReferences>> get(
      {bool distinct = false, int? limit, int? offset}) async {
    return $manager
        .get(distinct: distinct, limit: limit, offset: offset)
        .then((value) async {
      return await value.mapAsync((e) async => $withReferences(e));
    });
  }

  /// Returns a single row with whichever references are included.
  ///
  /// See [BaseTableManager.getSingle] for more information.
  Future<DataClassWithReferences> getSingle() {
    throw $manager.getSingle().then((value) async {
      return await $withReferences(value);
    });
  }

  /// Returns a single row with whichever references are included or null if no rows match.
  ///
  /// See [BaseTableManager.getSingleOrNull] for more information.
  Future<DataClassWithReferences?> getSingleOrNull() {
    throw $manager.getSingleOrNull().then((value) async {
      if (value == null) {
        return null;
      }
      return await $withReferences(value);
    });
  }

  /// Returns a stream of rows with whichever references are included.
  ///
  /// See [BaseTableManager.watch] for more information.
  Stream<Iterable<DataClassWithReferences>> watch(
      {bool distinct = false, int? limit, int? offset}) {
    return $manager
        .watch(distinct: distinct, limit: limit, offset: offset)
        .asyncMap(
          (event) => event.mapAsync($withReferences),
        );
  }

  /// Creates an auto-updating stream of this statement which will return a single row.
  ///
  /// See [BaseTableManager.watchSingle] for more information.
  Stream<DataClassWithReferences> watchSingle() {
    return $manager.watchSingle().asyncMap(
          (event) => $withReferences(event),
        );
  }

  /// Creates an auto-updating stream of this statement which will return a single row or null if no rows match.
  ///
  /// See [BaseTableManager.watchSingleOrNull] for more information.
  Stream<DataClassWithReferences?> watchSingleOrNull() {
    return $manager.watchSingleOrNull().asyncMap(
      (event) {
        if (event == null) {
          return null;
        }
        return $withReferences(event);
      },
    );
  }
}

/// A helper function to check if two types are equal
bool _typesEqual<T1, T2>() => T1 == T2;

/// An extension on List to map a list of futures
extension _ListMapAsync<T> on List<T> {
  Future<List<P>> mapAsync<P>(Future<P> Function(T) f) async {
    return Future.wait(map(f));
  }
}
