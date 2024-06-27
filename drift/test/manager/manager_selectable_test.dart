// ignore_for_file: unused_local_variable

import 'package:drift/drift.dart';
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
    final stores = [
      await db.managers.store.createReturning((o) => o(name: Value("Walmart"))),
      await db.managers.store.createReturning((o) => o(name: Value("Target"))),
      await db.managers.store.createReturning((o) => o(name: Value("Costco")))
    ];

    final departments = [
      await db.managers.department
          .createReturning((o) => o(name: Value("Electronics"))),
      await db.managers.department
          .createReturning((o) => o(name: Value("Grocery"))),
      await db.managers.department
          .createReturning((o) => o(name: Value("Clothing")))
    ];

    final products = [
      // Electronics
      await db.managers.product.createReturning(
          (o) => o(name: Value("TV"), department: Value(departments[0].id))),
      await db.managers.product.createReturning((o) =>
          o(name: Value("Cell Phone"), department: Value(departments[0].id))),
      await db.managers.product.createReturning((o) =>
          o(name: Value("Charger"), department: Value(departments[0].id))),
      // Grocery
      await db.managers.product.createReturning((o) =>
          o(name: Value("Cereal"), department: Value(departments[1].id))),
      await db.managers.product.createReturning(
          (o) => o(name: Value("Meat"), department: Value(departments[1].id))),
      // Clothing
      await db.managers.product.createReturning(
          (o) => o(name: Value("Shirt"), department: Value(departments[2].id))),
      await db.managers.product.createReturning(
          (o) => o(name: Value("Pants"), department: Value(departments[2].id))),
      await db.managers.product.createReturning(
          (o) => o(name: Value("Socks"), department: Value(departments[2].id))),
      await db.managers.product.createReturning(
          (o) => o(name: Value("Cap"), department: Value(departments[2].id)))
    ];

    final listings = [
      // Walmart - Electronics
      await db.managers.listing.create((o) => o(
          product: Value(products[0].id),
          store: Value(stores[0].id),
          price: Value(100.0))),
      await db.managers.listing.create((o) => o(
          product: Value(products[1].id),
          store: Value(stores[0].id),
          price: Value(200.0))),
      await db.managers.listing.create((o) => o(
          product: Value(products[2].id),
          store: Value(stores[0].id),
          price: Value(10.0))),

      // Walmart - Grocery
      await db.managers.listing.create((o) => o(
          product: Value(products[3].id),
          store: Value(stores[0].id),
          price: Value(5.0))),
      await db.managers.listing.create((o) => o(
          product: Value(products[4].id),
          store: Value(stores[0].id),
          price: Value(15.0))),

      // Walmart - Clothing
      await db.managers.listing.create((o) => o(
          product: Value(products[5].id),
          store: Value(stores[0].id),
          price: Value(20.0))),
      await db.managers.listing.create((o) => o(
          product: Value(products[6].id),
          store: Value(stores[0].id),
          price: Value(30.0))),
      await db.managers.listing.create((o) => o(
          product: Value(products[7].id),
          store: Value(stores[0].id),
          price: Value(5.0))),
      await db.managers.listing.create((o) => o(
          product: Value(products[8].id),
          store: Value(stores[0].id),
          price: Value(10.0))),

      // Target - Electronics

      // Target does not have any TVs
      // But is otherwise cheaper on electronics
      // await db.managers.listing.create((o) => o(
      //     product: Value(products[0].id),
      //     store: Value(stores[0].id),
      //     price: Value(100.0))),
      await db.managers.listing.create((o) => o(
          product: Value(products[1].id),
          store: Value(stores[1].id),
          price: Value(150.0))),
      await db.managers.listing.create((o) => o(
          product: Value(products[2].id),
          store: Value(stores[1].id),
          price: Value(15.0))),

      // Target - Grocery

      // More expensive groceries
      await db.managers.listing.create((o) => o(
          product: Value(products[3].id),
          store: Value(stores[1].id),
          price: Value(10.0))),
      await db.managers.listing.create((o) => o(
          product: Value(products[4].id),
          store: Value(stores[1].id),
          price: Value(20.0))),

      // Target - Clothing

      // Does not have any shirts or pants
      // await db.managers.listing.create((o) => o(
      //     product: Value(products[5].id),
      //     store: Value(stores[1].id),
      //     price: Value(20.0))),
      // await db.managers.listing.create((o) => o(
      //     product: Value(products[6].id),
      //     store: Value(stores[1].id),
      //     price: Value(30.0))),
      await db.managers.listing.create((o) => o(
          product: Value(products[7].id),
          store: Value(stores[1].id),
          price: Value(5.0))),
      await db.managers.listing.create((o) => o(
          product: Value(products[8].id),
          store: Value(stores[1].id),
          price: Value(10.0))),

      // Costco - Electronics
      // Much cheaper electronics
      await db.managers.listing.create((o) => o(
          product: Value(products[0].id),
          store: Value(stores[2].id),
          price: Value(50.0))),
      await db.managers.listing.create((o) => o(
          product: Value(products[1].id),
          store: Value(stores[2].id),
          price: Value(100.0))),
      await db.managers.listing.create((o) => o(
          product: Value(products[2].id),
          store: Value(stores[2].id),
          price: Value(2.50))),

      // Costco - Grocery

      // More expensive groceries
      await db.managers.listing.create((o) => o(
          product: Value(products[3].id),
          store: Value(stores[2].id),
          price: Value(20.0))),
      await db.managers.listing.create((o) => o(
          product: Value(products[4].id),
          store: Value(stores[2].id),
          price: Value(900.0)))
    ];

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

    void testManager<T, M>(
        BaseTableManager<dynamic, dynamic, T, dynamic, dynamic, dynamic,
                dynamic, M, T>
            selectable) {
      expect(selectable.get().then((v) => v.length), completion(3));
      expect(selectable.get(limit: 1).then((v) => v.length), completion(1));
      expect(selectable.get(offset: 1, limit: 2).then((v) => v.length),
          completion(2));
      expect(selectable.get(offset: 1, limit: 2).then((v) => v.length),
          completion(2));
    }

    for (final selectable in <BaseTableManager>[
      getAllStores,
      getAllStoresWithFilter,
      getAllStoresWithOrdering,
      getAllStoresWithFilterAndOrdering,
      getAllStoresWithFilterAndOrderingWithReferences,
    ]) {
      testManager(selectable);
    }
  });
}
