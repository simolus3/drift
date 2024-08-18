// ignore_for_file: unused_local_variable

import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/src/utils/async.dart';
import 'package:test/test.dart';

import '../generated/todos.dart';
import '../test_utils/test_utils.dart';

void main() {
  late TodoDb db;
  late List<StoreData> stores;
  late List<DepartmentData> departments;
  late List<ProductData> products;
  late List<ListingData> listings;

  setUp(() async {
    db = TodoDb(testInMemoryDatabase());
    stores = await _storeData.mapAsyncAndAwait((p0) => db.managers.store
        .createReturning((o) => o(name: Value(p0.name), id: Value(p0.id))));

    departments = await _departmentData.mapAsyncAndAwait(
      (p0) => db.managers.department
          .createReturning((o) => o(name: Value(p0.name), id: Value(p0.id))),
    );

    products = await _productData.mapAsyncAndAwait(
      (p0) => db.managers.product.createReturning(
          (o) => o(name: p0.name, department: p0.department, sku: p0.id)),
    );

    listings = await _listingsData.mapAsyncAndAwait(
      (p0) => db.managers.listing.createReturning((o) => o(
          product: Value(p0.product),
          store: Value(p0.store),
          price: Value(p0.price))),
    );

    final categories =
        await _todoCategoryData.mapAsyncAndAwait((categoryData) async {
      await db.managers.categories.createReturning((o) => o(
          priority: categoryData.priority,
          id: Value(categoryData.id),
          description: categoryData.description));
    });
    final todos = await _todosData.mapAsyncAndAwait((todoData) async {
      await db.managers.todosTable.createReturning((o) => o(
          content: todoData.content,
          title: todoData.title,
          category: todoData.category,
          status: todoData.status,
          targetDate: todoData.targetDate));
    });
  });

  tearDown(() => db.close());

  test('manager - filter related with regualar id', () async {
    // Filter on related table's reference id - Does not require a join
    ComposableFilter? filter;
    expect(
        await db.managers.product.filter((f) {
          filter = f.department.id(departments[0].id);
          return filter!;
        }).count(),
        3);
    expect(filter?.joinBuilders.length, 0);

    // Filter on a unrelated column on a related table - Requires a join
    expect(
        await db.managers.product.filter((f) {
          filter = f.department.name("Electronics");
          return filter!;
        }).count(),
        3);
    expect(filter?.joinBuilders.length, 1);

    // Filter on a unrelated column on a related table & on
    // a related table's reference id - Requires a join
    expect(
        await db.managers.product.filter((f) {
          filter = f.department.name("Electronics") |
              f.department.id(departments[1].id);
          return filter!;
        }).count(),
        5);
    expect(filter?.joinBuilders.length, 1);

    // Ordering on current table & Filtering on related table
    expect(
        await db.managers.product
            .filter((f) => f.department.name("Electronics"))
            .orderBy((f) => f.name.asc())
            .get(),
        [
          products[1],
          products[2],
          products[0],
        ]);

    // Ordering on related table & Filtering on current table
    expect(
        await db.managers.product
            .filter((f) => f.name.startsWith("c"))
            .orderBy((f) => f.department.name.asc() & f.name.desc())
            .get(),
        [
          products[8],
          products[2],
          products[1],
          products[3],
        ]);

    // Filtering on reverse related table
    expect(
        // Any product that is available for more than $10
        // Socks & Cap are excluded
        await db.managers.product
            .filter((f) => f.listings((f) => f.price.isBiggerThan(10.0)))
            .count(distinct: true),
        7);

    // Filtering on reverse related table with ordering
    expect(
        // Any product that is available for more than $10
        // Socks & Cap are excluded, and the rest are ordered by name
        await db.managers.product
            .filter((f) => f.listings((f) => f.price.isBiggerThan(10.0)))
            .orderBy((f) => f.name.asc())
            .get(distinct: true),
        [
          products[1],
          products[3],
          products[2],
          products[4],
          products[6],
          products[5],
          products[0],
        ]);

    // Filter on reverse related column and then a related column
    expect(
        await db.managers.product.filter((f) {
          filter = f.listings((f) => f.store.name("Target"));
          return filter!;
        }).count(),
        6);
    expect(filter?.joinBuilders.length, 2);
    expect(
        await db.managers.product.filter((f) {
          filter = f.listings((f) => f.store.name("Target")) | f.name("TV");
          return filter!;
        }).count(),
        7);
    expect(filter?.joinBuilders.length, 2);

    // Filter on a related column and then a related column
    expect(
        await db.managers.listing.filter((f) {
          // Listings of products in the electronics department
          filter = f.product.department.name("Electronics");
          return filter!;
        }).count(),
        8);
    expect(
        await db.managers.listing.filter((f) {
          // Listings of products in the electronics department
          filter = f.product.department.name("Electronics") |
              f.price.isBiggerThan(150.0);
          return filter!;
        }).count(),
        9);

    // Filter on a reverse related column and then a reverse related column
    expect(
        await db.managers.department.filter((f) {
          // Departments that have products listed for more than $10
          filter = f.productRefs(
              (f) => f.listings((f) => f.price.isBiggerThan(100.0)));
          return filter!;
        }).count(),
        2);
    expect(
        await db.managers.department.filter((f) {
          // Departments that have products listed for more than $10 or is available at Walmart
          filter = f.productRefs((f) => f.listings(
              (f) => f.price.isBiggerThan(100.0) | f.store.name("Walmart")));
          return filter!;
        }).count(),
        3);

    // Stores that have products in the clothing department
    expect(
        await db.managers.store.filter((f) {
          // Products that are sold in a store that sells clothing
          filter = f.listings((f) => f.product.department.name("Clothing"));
          return filter!;
        }).count(),
        2);

    // Any product that is sold in a store that sells clothing
    expect(
        await db.managers.product.filter((f) {
          filter = f.listings((f) =>
              f.store.listings((f) => f.product.department.name("Clothing")));
          return filter!;
        }).count(distinct: true),
        9);
  });

  test('manager - filter related with custom type for primary key', () async {
    // item without title

    // Equals
    expect(
        await db.managers.todosTable
            .filter((f) => f.category.id(_todoCategoryData[0].id))
            .count(),
        4);

    // Not Equals
    expect(
        await db.managers.todosTable
            .filter((f) => f.category.id.not(_todoCategoryData[0].id))
            .count(),
        4);

    // Multiple filters
    expect(
        await db.managers.todosTable
            .filter((f) => f.category.id(
                  _todoCategoryData[0].id,
                ))
            .filter((f) => f.status.equals(TodoStatus.open))
            .count(),
        2);

    // Multiple use related filters twice
    expect(
        await db.managers.todosTable
            .filter((f) =>
                f.category.priority(CategoryPriority.low) |
                f.category.descriptionInUpperCase("SCHOOL"))
            .count(),
        8);

    // Use .filter multiple times
    expect(
        await db.managers.todosTable
            .filter((f) => f.category.priority.equals(CategoryPriority.high))
            .filter((f) => f.category.descriptionInUpperCase("SCHOOL"))
            .count(),
        4);

    // Use backreference
    expect(
        await db.managers.categories
            .filter((f) => f.todos((f) => f.title.equals("Math Homework")))
            .getSingle()
            .then((value) => value.description),
        "School");

    // Nested backreference
    expect(
        await db.managers.categories
            .filter((f) => f.todos((f) {
                  final q =
                      f.category.todos((f) => f.title.equals("Math Homework"));
                  return q;
                }))
            .getSingle()
            .then((value) => value.description),
        "School");
  });

  test('manager - filter related with regualar id with references', () async {
    // Filter on related table's reference id - Does not require a join
    ComposableFilter? filter;
    expect(
        await db.managers.product
            .filter((f) {
              filter = f.department.id(departments[0].id);
              return filter!;
            })
            .withReferences()
            .get(distinct: true)
            .then((value) => value.length),
        3);
    expect(filter?.joinBuilders.length, 0);

    // Filter on a unrelated column on a related table - Requires a join
    expect(
        await db.managers.product
            .filter((f) {
              filter = f.department.name("Electronics");
              return filter!;
            })
            .withReferences()
            .get(distinct: true)
            .then((value) => value.length),
        3);
    expect(filter?.joinBuilders.length, 1);

    // Filter on a unrelated column on a related table & on
    // a related table's reference id - Requires a join
    expect(
        await db.managers.product
            .filter((f) {
              filter = f.department.name("Electronics") |
                  f.department.id(departments[1].id);
              return filter!;
            })
            .withReferences()
            .get(distinct: true)
            .then((value) => value.length),
        5);
    expect(filter?.joinBuilders.length, 1);

    // Ordering on current table & Filtering on related table
    expect(
        await db.managers.product
            .filter((f) => f.department.name("Electronics"))
            .orderBy((f) => f.name.asc())
            .withReferences()
            .get()
            .then((value) => value.map((e) => e.$1).toList()),
        [
          products[1],
          products[2],
          products[0],
        ]);

    // Ordering on related table & Filtering on current table
    expect(
        await db.managers.product
            .filter((f) => f.name.startsWith("c"))
            .orderBy((f) => f.department.name.asc() & f.name.desc())
            .withReferences()
            .get()
            .then((value) => value.map((e) => e.$1).toList()),
        [
          products[8],
          products[2],
          products[1],
          products[3],
        ]);

    // Filtering on reverse related table
    expect(
        // Any product that is available for more than $10
        // Socks & Cap are excluded
        await db.managers.product
            .filter((f) => f.listings((f) => f.price.isBiggerThan(10.0)))
            .withReferences()
            .get(distinct: true)
            .then((value) => value.length),
        7);

    // Filtering on reverse related table with ordering
    expect(
        // Any product that is available for more than $10
        // Socks & Cap are excluded, and the rest are ordered by name
        await db.managers.product
            .filter((f) => f.listings((f) => f.price.isBiggerThan(10.0)))
            .orderBy((f) => f.name.asc())
            .withReferences()
            .get(distinct: true)
            .then((value) => value.map((e) => e.$1).toList()),
        [
          products[1],
          products[3],
          products[2],
          products[4],
          products[6],
          products[5],
          products[0],
        ]);

    // Filter on reverse related column and then a related column
    expect(
        await db.managers.product
            .filter((f) {
              filter = f.listings((f) => f.store.name("Target"));
              return filter!;
            })
            .withReferences()
            .get(distinct: true)
            .then((value) => value.length),
        6);
    expect(filter?.joinBuilders.length, 2);
    expect(
        await db.managers.product
            .filter((f) {
              filter = f.listings((f) => f.store.name("Target")) | f.name("TV");
              return filter!;
            })
            .withReferences()
            .get(distinct: true)
            .then((value) => value.length),
        7);
    expect(filter?.joinBuilders.length, 2);

    // Filter on a related column and then a related column
    expect(
        await db.managers.listing
            .filter((f) {
              // Listings of products in the electronics department
              filter = f.product.department.name("Electronics");
              return filter!;
            })
            .withReferences()
            .get(distinct: true)
            .then((value) => value.length),
        8);
    expect(
        await db.managers.listing
            .filter((f) {
              // Listings of products in the electronics department
              filter = f.product.department.name("Electronics") |
                  f.price.isBiggerThan(150.0);
              return filter!;
            })
            .withReferences()
            .get(distinct: true)
            .then((value) => value.length),
        9);

    // Filter on a reverse related column and then a reverse related column
    expect(
        await db.managers.department
            .filter((f) {
              // Departments that have products listed for more than $10
              filter = f.productRefs(
                  (f) => f.listings((f) => f.price.isBiggerThan(100.0)));
              return filter!;
            })
            .withReferences()
            .get(distinct: true)
            .then((value) => value.length),
        2);
    expect(
        await db.managers.department
            .filter((f) {
              // Departments that have products listed for more than $10 or is available at Walmart
              filter = f.productRefs((f) => f.listings((f) =>
                  f.price.isBiggerThan(100.0) | f.store.name("Walmart")));
              return filter!;
            })
            .withReferences()
            .get(distinct: true)
            .then((value) => value.length),
        3);

    // Stores that have products in the clothing department
    expect(
        await db.managers.store
            .filter((f) {
              // Products that are sold in a store that sells clothing
              filter = f.listings((f) => f.product.department.name("Clothing"));
              return filter!;
            })
            .withReferences()
            .get(distinct: true)
            .then((value) => value.length),
        2);

    // Any product that is sold in a store that sells clothing
    expect(
        await db.managers.product
            .filter((f) {
              filter = f.listings((f) => f.store
                  .listings((f) => f.product.department.name("Clothing")));
              return filter!;
            })
            .withReferences()
            .get(distinct: true)
            .then((value) => value.length),
        9);
  });

  test(
      'manager - filter related with custom type for primary key with references',
      () async {
    // Equals
    expect(
        await db.managers.todosTable
            .filter((f) => f.category.id(_todoCategoryData[0].id))
            .withReferences()
            .get(distinct: true)
            .then((value) => value.length),
        4);

    // Not Equals
    expect(
        await db.managers.todosTable
            .filter((f) => f.category.id.not(_todoCategoryData[0].id))
            .withReferences()
            .get(distinct: true)
            .then((value) => value.length),
        4);

    // Multiple filters
    expect(
        await db.managers.todosTable
            .filter((f) => f.category.id(
                  _todoCategoryData[0].id,
                ))
            .filter((f) => f.status.equals(TodoStatus.open))
            .withReferences()
            .get(distinct: true)
            .then((value) => value.length),
        2);

    // Multiple use related filters twice
    expect(
        await db.managers.todosTable
            .filter((f) =>
                f.category.priority(CategoryPriority.low) |
                f.category.descriptionInUpperCase("SCHOOL"))
            .withReferences()
            .get(distinct: true)
            .then((value) => value.length),
        8);

    // Use .filter multiple times
    expect(
        await db.managers.todosTable
            .filter((f) => f.category.priority.equals(CategoryPriority.high))
            .filter((f) => f.category.descriptionInUpperCase("SCHOOL"))
            .withReferences()
            .get(distinct: true)
            .then((value) => value.length),
        4);

    // Use backreference
    expect(
        await db.managers.categories
            .filter((f) => f.todos((f) => f.title.equals("Math Homework")))
            .withReferences()
            .getSingle()
            .then((value) => value.$1.description),
        "School");

    // Nested backreference
    expect(
        await db.managers.categories
            .filter((f) => f.todos((f) {
                  final q =
                      f.category.todos((f) => f.title.equals("Math Homework"));
                  return q;
                }))
            .withReferences()
            .getSingle()
            .then((value) => value.$1.description),
        "School");
  });

  test('manager - with references tests', () async {
    // Get department for the 1st product
    expect(
        await db.managers.product
            .withReferences()
            .get(distinct: true)
            .then((value) =>
                value.first.$2.department?.getSingle() ?? Future.value(null))
            .then(
              (value) => value?.id,
            ),
        departments[0].id);

    // Get the amount of products in the 1st department
    expect(
        await db.managers.department
            .withReferences()
            .get(distinct: true)
            .then((value) => value.first.$2.productRefs.count()),
        3);

    // Get all the products with all their listings
    final listingsWithProducts = <ProductData, List<ListingData>>{};
    for (final i
        in await db.managers.listing.withReferences().get(distinct: true)) {
      final product = await i.$2.product?.getSingle();
      if (product != null) {
        if (!listingsWithProducts.containsKey(product)) {
          listingsWithProducts[product] = [i.$1];
        } else {
          listingsWithProducts[product]!.add(i.$1);
        }
      }
    }
    expect(listingsWithProducts.length, 9);
    expect(
        listingsWithProducts.entries.fold(
          0,
          (i, o) => i + o.value.length,
        ),
        20);

    // Get the amount of products in the department id 2
    expect(
        await db.managers.department
            .filter((f) => f.id.equals(2))
            .withReferences()
            .getSingle()
            .then((value) => value.$2.productRefs.count()),
        2);
  });
}

const _todoCategoryData = [
  (description: "School", priority: Value(CategoryPriority.high), id: RowId(1)),
  (description: "Work", priority: Value(CategoryPriority.low), id: RowId(2)),
];

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
  (name: Value("TV"), department: Value(_departmentData[0].id), id: "1"),
  (
    name: Value("Cell Phone"),
    department: Value(_departmentData[0].id),
    id: "2"
  ),
  (name: Value("Charger"), department: Value(_departmentData[0].id), id: "3"),
  (name: Value("Cereal"), department: Value(_departmentData[1].id), id: "4"),
  (name: Value("Meat"), department: Value(_departmentData[1].id), id: "5"),
  (name: Value("Shirt"), department: Value(_departmentData[2].id), id: "6"),
  (name: Value("Pants"), department: Value(_departmentData[2].id), id: "7"),
  (name: Value("Socks"), department: Value(_departmentData[2].id), id: "8"),
  (name: Value("Cap"), department: Value(_departmentData[2].id), id: "9"),
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
final _todosData = <({
  Value<RowId> category,
  String content,
  Value<TodoStatus> status,
  Value<DateTime> targetDate,
  Value<String> title
})>[
  // School
  (
    content: "Get that math homework done",
    title: Value("Math Homework"),
    category: Value(_todoCategoryData[0].id),
    status: Value(TodoStatus.open),
    targetDate: Value(DateTime.now().add(Duration(days: 1, seconds: 10)))
  ),
  (
    content: "Finish that report",
    title: Value("Report"),
    category: Value(_todoCategoryData[0].id),
    status: Value(TodoStatus.workInProgress),
    targetDate: Value(DateTime.now().add(Duration(days: 2, seconds: 10)))
  ),
  (
    content: "Get that english homework done",
    title: Value("English Homework"),
    category: Value(_todoCategoryData[0].id),
    status: Value(TodoStatus.open),
    targetDate: Value(DateTime.now().add(Duration(days: 1, seconds: 15)))
  ),
  (
    content: "Finish that Book report",
    title: Value("Book Report"),
    category: Value(_todoCategoryData[0].id),
    status: Value(TodoStatus.done),
    targetDate: Value(DateTime.now().subtract(Duration(days: 2, seconds: 15)))
  ),
  // Work
  (
    content: "File those reports",
    title: Value("File Reports"),
    category: Value(_todoCategoryData[1].id),
    status: Value(TodoStatus.open),
    targetDate: Value(DateTime.now().add(Duration(days: 1, seconds: 20)))
  ),
  (
    content: "Clean the office",
    title: Value("Clean Office"),
    category: Value(_todoCategoryData[1].id),
    status: Value(TodoStatus.workInProgress),
    targetDate: Value(DateTime.now().add(Duration(days: 2, seconds: 20)))
  ),
  (
    content: "Nail that presentation",
    title: Value("Presentation"),
    category: Value(_todoCategoryData[1].id),
    status: Value(TodoStatus.open),
    targetDate: Value(DateTime.now().add(Duration(days: 1, seconds: 25)))
  ),
  (
    content: "Take a break",
    title: Value("Break"),
    category: Value(_todoCategoryData[1].id),
    status: Value(TodoStatus.done),
    targetDate: Value(DateTime.now().subtract(Duration(days: 2, seconds: 25)))
  ),
  // Items with no category
  (
    content: "Get Whiteboard",
    title: Value("Whiteboard"),
    status: Value(TodoStatus.open),
    targetDate: Value(DateTime.now().add(Duration(days: 1, seconds: 50))),
    category: Value.absent(),
  ),
  (
    category: Value.absent(),
    content: "Drink Water",
    title: Value("Water"),
    status: Value(TodoStatus.workInProgress),
    targetDate: Value(DateTime.now().add(Duration(days: 2, seconds: 50)))
  ),
];
