// ignore_for_file: unused_local_variable

import 'package:drift3_preview/drift.dart';
import 'package:drift_manager/drift_manager.dart';
import 'package:test/test.dart';

import 'database.dart';

/// All managers `Managers` are Selectable classes that
/// are used by the Manager API to return results.
/// This test will ensure that they all behave as expected, no matter what filters/ordering/limit/offsets/references are applied.

void main() {
  late TestDatabase db;

  setUp(() {
    db = TestDatabase.inMemory();
  });

  tearDown(() => db.close());

  test('manager - selectable tests', () async {
    final stores = await Future.wait([
      for (final store in _storeData)
        db.managers.store.createReturning(
          (o) => o(name: Value(store.name), id: Value(store.id)),
        ),
    ]);

    final departments = await Future.wait([
      for (final dep in _departmentData)
        db.managers.department.createReturning(
          (o) => o(name: Value(dep.name), id: Value(dep.id)),
        ),
    ]);

    final products = await Future.wait([
      for (final prod in _productData)
        db.managers.product.createReturning(
          (o) => o(name: prod.name, department: prod.department, sku: prod.sku),
        ),
    ]);

    final listings = await Future.wait([
      for (final l in _listingsData)
        db.managers.listing.createReturning(
          (o) => o(
            product: l.product,
            store: Value(l.store),
            price: Value(l.price),
          ),
        ),
    ]);

    final getAllStores = db.managers.store;
    final getAllStoresWithFilter = db.managers.store.filter(
      (f) => f.id.not(10),
    );
    final getAllStoresWithOrdering = db.managers.store.orderBy(
      (f) => f.id.asc(),
    );
    final getAllStoresWithFilterAndOrdering = db.managers.store
        .filter((f) => f.id.not(10))
        .orderBy((f) => f.id.asc());
    final getAllStoresWithFilterAndOrderingWithReferences = db.managers.store
        .filter((f) => f.id.not(10))
        .orderBy((f) => f.id.asc())
        .withReferences();

    Future<void> testManager(
      // ignore: strict_raw_type
      BaseTableManager selectable,
    ) async {
      expect(await selectable.get(), hasLength(3));
      expect(await selectable.get(limit: 1), hasLength(1));
      expect(await selectable.get(offset: 1, limit: 2), hasLength(2));
      expect(await selectable.get(offset: 1, limit: 2), hasLength(2));
    }

    // ignore: strict_raw_type
    for (final selectable in <BaseTableManager>[
      getAllStores,
      getAllStoresWithFilter,
      getAllStoresWithOrdering,
      getAllStoresWithFilterAndOrdering,
      getAllStoresWithFilterAndOrderingWithReferences,
    ]) {
      await testManager(selectable);
    }
  });
}

const _storeData = [
  (name: "Walmart", id: 1),
  (name: "Target", id: 2),
  (name: "Costco", id: 3),
];

const _departmentData = [
  (name: "Electronics", id: 1),
  (name: "Grocery", id: 2),
  (name: "Clothing", id: 3),
];

final _productData = [
  (name: Value("TV"), department: Value(_departmentData[0].id), sku: "1"),
  (
    name: Value("Cell Phone"),
    department: Value(_departmentData[0].id),
    sku: "2",
  ),
  (name: Value("Charger"), department: Value(_departmentData[0].id), sku: "3"),
  (name: Value("Cereal"), department: Value(_departmentData[1].id), sku: "4"),
  (name: Value("Meat"), department: Value(_departmentData[1].id), sku: "5"),
  (name: Value("Shirt"), department: Value(_departmentData[2].id), sku: "6"),
  (name: Value("Pants"), department: Value(_departmentData[2].id), sku: "7"),
  (name: Value("Socks"), department: Value(_departmentData[2].id), sku: "8"),
  (name: Value("Cap"), department: Value(_departmentData[2].id), sku: "9"),
];
final _listingsData = [
  // Walmart - Electronics
  (product: "1", store: 1, price: 100.0),
  (product: "2", store: 1, price: 200.0),
  (product: "3", store: 1, price: 10.0),
  // Walmart - Grocery
  (product: "4", store: 1, price: 5.0),
  (product: "5", store: 1, price: 15.0),
  // Walmart - Clothing
  (product: "6", store: 1, price: 20.0),
  (product: "7", store: 1, price: 30.0),
  (product: "8", store: 1, price: 5.0),
  (product: "9", store: 1, price: 10.0),
  // Target - Electronics
  (product: "2", store: 2, price: 150.0),
  (product: "3", store: 2, price: 15.0),
  // Target - Grocery
  (product: "4", store: 2, price: 10.0),
  (product: "5", store: 2, price: 20.0),
  // Target - Clothing
  (product: "8", store: 2, price: 5.0),
  (product: "9", store: 2, price: 10.0),
  // Costco - Electronics
  (product: "1", store: 3, price: 50.0),
  (product: "2", store: 3, price: 100.0),
  (product: "3", store: 3, price: 2.50),
  // Costco - Grocery
  (product: "4", store: 3, price: 20.0),
  (product: "5", store: 3, price: 900.0),
];
