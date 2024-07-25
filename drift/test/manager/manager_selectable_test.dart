// ignore_for_file: unused_local_variable

import 'package:drift/drift.dart';
import 'package:drift/src/utils/async.dart';
import 'package:test/test.dart';

import '../generated/todos.dart';
import '../test_utils/test_utils.dart';

/// All managers `Managers` are Selectable classes that
/// are used by the Manager API to return results.
/// This test will ensure that they all behave as expected, no matter what filters/ordering/limit/offsets/references are applied.

void main() {
  late TodoDb db;

  setUp(() {
    db = TodoDb(testInMemoryDatabase());
  });

  tearDown(() => db.close());

  test('manager - selectable tests', () async {
    final stores = await _storeData.mapAsyncAndAwait((p0) => db.managers.store
        .createReturning((o) => o(name: Value(p0.name), id: Value(p0.id))));

    final departments = await _departmentData.mapAsyncAndAwait(
      (p0) => db.managers.department
          .createReturning((o) => o(name: Value(p0.name), id: Value(p0.id))),
    );

    final products = await _productData.mapAsyncAndAwait(
      (p0) => db.managers.product.createReturning(
          (o) => o(name: p0.name, department: p0.department, id: Value(p0.id))),
    );

    final listings = await _listingsData.mapAsyncAndAwait(
      (p0) => db.managers.listing.createReturning((o) => o(
          product: Value(p0.product),
          store: Value(p0.store),
          price: Value(p0.price))),
    );

    final getAllStores = db.managers.store;
    final getAllStoresWithFilter =
        db.managers.store.filter((f) => f.id.not(10));
    final getAllStoresWithOrdering =
        db.managers.store.orderBy((f) => f.id.asc());
    final getAllStoresWithFilterAndOrdering = db.managers.store
        .filter((f) => f.id.not(10))
        .orderBy((f) => f.id.asc());
    final getAllStoresWithFilterAndOrderingWithReferences = db.managers.store
        .filter((f) => f.id.not(10))
        .orderBy((f) => f.id.asc())
        .withReferences();

    Future testManager<T, M>(
        BaseTableManager<dynamic, dynamic, T, dynamic, dynamic, dynamic,
                dynamic, M, T, dynamic>
            selectable) async {
      expect(await selectable.get(), hasLength(3));
      expect(await selectable.get(limit: 1), hasLength(1));
      expect(await selectable.get(offset: 1, limit: 2), hasLength(2));
      expect(await selectable.get(offset: 1, limit: 2), hasLength(2));
    }

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
  (name: Value("TV"), department: Value(_departmentData[0].id), id: 1),
  (name: Value("Cell Phone"), department: Value(_departmentData[0].id), id: 2),
  (name: Value("Charger"), department: Value(_departmentData[0].id), id: 3),
  (name: Value("Cereal"), department: Value(_departmentData[1].id), id: 4),
  (name: Value("Meat"), department: Value(_departmentData[1].id), id: 5),
  (name: Value("Shirt"), department: Value(_departmentData[2].id), id: 6),
  (name: Value("Pants"), department: Value(_departmentData[2].id), id: 7),
  (name: Value("Socks"), department: Value(_departmentData[2].id), id: 8),
  (name: Value("Cap"), department: Value(_departmentData[2].id), id: 9),
];
final _listingsData = [
  // Walmart - Electronics
  (product: 1, store: 1, price: 100.0),
  (product: 2, store: 1, price: 200.0),
  (product: 3, store: 1, price: 10.0),
  // Walmart - Grocery
  (product: 4, store: 1, price: 5.0),
  (product: 5, store: 1, price: 15.0),
  // Walmart - Clothing
  (product: 6, store: 1, price: 20.0),
  (product: 7, store: 1, price: 30.0),
  (product: 8, store: 1, price: 5.0),
  (product: 9, store: 1, price: 10.0),
  // Target - Electronics
  (product: 2, store: 2, price: 150.0),
  (product: 3, store: 2, price: 15.0),
  // Target - Grocery
  (product: 4, store: 2, price: 10.0),
  (product: 5, store: 2, price: 20.0),
  // Target - Clothing
  (product: 8, store: 2, price: 5.0),
  (product: 9, store: 2, price: 10.0),
  // Costco - Electronics
  (product: 1, store: 3, price: 50.0),
  (product: 2, store: 3, price: 100.0),
  (product: 3, store: 3, price: 2.50),
  // Costco - Grocery
  (product: 4, store: 3, price: 20.0),
  (product: 5, store: 3, price: 900.0),
];
