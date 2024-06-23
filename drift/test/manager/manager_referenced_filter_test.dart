// ignore_for_file: unused_local_variable

import 'package:drift/drift.dart';
import 'package:test/test.dart';

import '../generated/todos.dart';
import '../test_utils/test_utils.dart';

void main() {
  late TodoDb db;

  setUp(() {
    db = TodoDb(testInMemoryDatabase());
  });

  tearDown(() => db.close());

  test('manager - filter related with regualar id', () async {
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
          price: Value(900.0))),

      // Costco - Clothing

      // Does not have any clothing
      // await db.managers.listing.create((o) => o(
      //     product: Value(products[5].id),
      //     store: Value(stores[0].id),
      //     price: Value(20.0))),
      // await db.managers.listing.create((o) => o(
      //     product: Value(products[6].id),
      //     store: Value(stores[0].id),
      //     price: Value(30.0))),
      // await db.managers.listing.create((o) => o(
      //     product: Value(products[7].id),
      //     store: Value(stores[0].id),
      //     price: Value(5.0))),
      // await db.managers.listing.create((o) => o(
      //     product: Value(products[8].id),
      //     store: Value(stores[0].id),
      //     price: Value(10.0))),
    ];

    // Filter on related table's reference id - Does not require a join
    ComposableFilter? filter;
    expect(
        db.managers.product.filter((f) {
          filter = f.department.id(departments[0].id);
          return filter!;
        }).count(),
        completion(3));
    expect(filter?.joinBuilders.length, 0);

    // Filter on a unrelated column on a related table - Requires a join
    expect(
        db.managers.product.filter((f) {
          filter = f.department.name("Electronics");
          return filter!;
        }).count(),
        completion(3));
    expect(filter?.joinBuilders.length, 1);

    // Filter on a unrelated column on a related table & on
    // a related table's reference id - Requires a join
    expect(
        db.managers.product.filter((f) {
          filter = f.department.name("Electronics") |
              f.department.id(departments[1].id);
          return filter!;
        }).count(),
        completion(5));
    expect(filter?.joinBuilders.length, 1);

    // Ordering on current table & Filtering on related table
    expect(
        db.managers.product
            .filter((f) => f.department.name("Electronics"))
            .orderBy((f) => f.name.asc())
            .get(),
        completion([
          products[1],
          products[2],
          products[0],
        ]));

    // Ordering on related table & Filtering on current table
    expect(
        db.managers.product
            .filter((f) => f.name.startsWith("c"))
            .orderBy((f) => f.department.name.asc() & f.name.desc())
            .get(),
        completion([
          products[8],
          products[2],
          products[1],
          products[3],
        ]));

    // Filtering on reverse related table
    expect(
        // Any product that is available for more than $10
        // Socks & Cap are excluded
        db.managers.product
            .filter((f) => f.listings((f) => f.price.isBiggerThan(10.0)))
            .count(distinct: true),
        completion(7));

    // Filtering on reverse related table with ordering
    expect(
        // Any product that is available for more than $10
        // Socks & Cap are excluded, and the rest are ordered by name
        db.managers.product
            .filter((f) => f.listings((f) => f.price.isBiggerThan(10.0)))
            .orderBy((f) => f.name.asc())
            .get(distinct: true),
        completion([
          products[1],
          products[3],
          products[2],
          products[4],
          products[6],
          products[5],
          products[0],
        ]));

    // Filter on reverse related column and then a related column
    expect(
        db.managers.product.filter((f) {
          filter = f.listings((f) => f.store.name("Target"));
          return filter!;
        }).count(),
        completion(6));
    expect(filter?.joinBuilders.length, 2);
    expect(
        db.managers.product.filter((f) {
          filter = f.listings((f) => f.store.name("Target")) | f.name("TV");
          return filter!;
        }).count(),
        completion(7));
    expect(filter?.joinBuilders.length, 2);

    // Filter on a related column and then a related column
    expect(
        db.managers.listing.filter((f) {
          // Listings of products in the electronics department
          filter = f.product.department.name("Electronics");
          return filter!;
        }).count(),
        completion(8));
    expect(
        db.managers.listing.filter((f) {
          // Listings of products in the electronics department
          filter = f.product.department.name("Electronics") |
              f.price.isBiggerThan(150.0);
          return filter!;
        }).count(),
        completion(9));

    // Filter on a reverse related column and then a reverse related column
    expect(
        db.managers.department.filter((f) {
          // Departments that have products listed for more than $10
          filter = f.productRefs(
              (f) => f.listings((f) => f.price.isBiggerThan(100.0)));
          return filter!;
        }).count(),
        completion(2));
    expect(
        db.managers.department.filter((f) {
          // Departments that have products listed for more than $10 or is available at Walmart
          filter = f.productRefs((f) => f.listings(
              (f) => f.price.isBiggerThan(100.0) | f.store.name("Walmart")));
          return filter!;
        }).count(),
        completion(3));

    // Stores that have products in the clothing department
    expect(
        db.managers.store.filter((f) {
          // Products that are sold in a store that sells clothing
          filter = f.listings((f) => f.product.department.name("Clothing"));
          return filter!;
        }).count(),
        completion(2));

    // Any product that is sold in a store that sells clothing
    expect(
        db.managers.product.filter((f) {
          filter = f.listings((f) =>
              f.store.listings((f) => f.product.department.name("Clothing")));
          return filter!;
        }).count(distinct: true),
        completion(9));
  });

  test('manager - filter related with custom type for primary key', () async {
    final categoryData = [
      (description: "School", priority: Value(CategoryPriority.high)),
      (description: "Work", priority: Value(CategoryPriority.low)),
    ];

    final schoolCategoryId = await db.managers.categories.create((o) => o(
        priority: categoryData[0].priority,
        description: categoryData[0].description));
    final workCategoryId = await db.managers.categories.create((o) => o(
        priority: categoryData[1].priority,
        description: categoryData[1].description));

    final todoData = <({
      int? category,
      String content,
      Value<TodoStatus> status,
      Value<DateTime> targetDate,
      Value<String> title
    })>[
      // School
      (
        content: "Get that math homework done",
        title: Value("Math Homework"),
        category: schoolCategoryId,
        status: Value(TodoStatus.open),
        targetDate: Value(DateTime.now().add(Duration(days: 1, seconds: 10)))
      ),
      (
        content: "Finish that report",
        title: Value("Report"),
        category: schoolCategoryId,
        status: Value(TodoStatus.workInProgress),
        targetDate: Value(DateTime.now().add(Duration(days: 2, seconds: 10)))
      ),
      (
        content: "Get that english homework done",
        title: Value("English Homework"),
        category: schoolCategoryId,
        status: Value(TodoStatus.open),
        targetDate: Value(DateTime.now().add(Duration(days: 1, seconds: 15)))
      ),
      (
        content: "Finish that Book report",
        title: Value("Book Report"),
        category: schoolCategoryId,
        status: Value(TodoStatus.done),
        targetDate:
            Value(DateTime.now().subtract(Duration(days: 2, seconds: 15)))
      ),
      // Work
      (
        content: "File those reports",
        title: Value("File Reports"),
        category: workCategoryId,
        status: Value(TodoStatus.open),
        targetDate: Value(DateTime.now().add(Duration(days: 1, seconds: 20)))
      ),
      (
        content: "Clean the office",
        title: Value("Clean Office"),
        category: workCategoryId,
        status: Value(TodoStatus.workInProgress),
        targetDate: Value(DateTime.now().add(Duration(days: 2, seconds: 20)))
      ),
      (
        content: "Nail that presentation",
        title: Value("Presentation"),
        category: workCategoryId,
        status: Value(TodoStatus.open),
        targetDate: Value(DateTime.now().add(Duration(days: 1, seconds: 25)))
      ),
      (
        content: "Take a break",
        title: Value("Break"),
        category: workCategoryId,
        status: Value(TodoStatus.done),
        targetDate:
            Value(DateTime.now().subtract(Duration(days: 2, seconds: 25)))
      ),
      // Items with no category
      (
        content: "Get Whiteboard",
        title: Value("Whiteboard"),
        status: Value(TodoStatus.open),
        targetDate: Value(DateTime.now().add(Duration(days: 1, seconds: 50))),
        category: null,
      ),
      (
        category: null,
        content: "Drink Water",
        title: Value("Water"),
        status: Value(TodoStatus.workInProgress),
        targetDate: Value(DateTime.now().add(Duration(days: 2, seconds: 50)))
      ),
    ];

    for (var i in todoData) {
      await db.managers.todosTable.create((o) => o(
          content: i.content,
          title: i.title,
          category: Value(i.category == null ? null : RowId(i.category!)),
          status: i.status,
          targetDate: i.targetDate));
    }

    // item without title

    // Equals
    expect(
        db.managers.todosTable
            .filter((f) => f.category.id(RowId(schoolCategoryId)))
            .count(),
        completion(4));

    // Not Equals
    expect(
        db.managers.todosTable
            .filter((f) => f.category.id.not(RowId(schoolCategoryId)))
            .count(),
        completion(4));

    // Multiple filters
    expect(
        db.managers.todosTable
            .filter((f) => f.category.id(
                  RowId(schoolCategoryId),
                ))
            .filter((f) => f.status.equals(TodoStatus.open))
            .count(),
        completion(2));

    // Multiple use related filters twice
    expect(
        db.managers.todosTable
            .filter((f) =>
                f.category.priority(CategoryPriority.low) |
                f.category.descriptionInUpperCase("SCHOOL"))
            .count(),
        completion(8));

    // Use .filter multiple times
    expect(
        db.managers.todosTable
            .filter((f) => f.category.priority.equals(CategoryPriority.high))
            .filter((f) => f.category.descriptionInUpperCase("SCHOOL"))
            .count(),
        completion(4));

    // Use backreference
    expect(
        db.managers.categories
            .filter((f) => f.todos((f) => f.title.equals("Math Homework")))
            .getSingle()
            .then((value) => value.description),
        completion("School"));

    // Nested backreference
    expect(
        db.managers.categories
            .filter((f) => f.todos((f) {
                  final q =
                      f.category.todos((f) => f.title.equals("Math Homework"));
                  return q;
                }))
            .getSingle()
            .then((value) => value.description),
        completion("School"));
  });

  test('manager - filter related with regualar id with references', () async {
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
          price: Value(900.0))),

      // Costco - Clothing

      // Does not have any clothing
      // await db.managers.listing.create((o) => o(
      //     product: Value(products[5].id),
      //     store: Value(stores[0].id),
      //     price: Value(20.0))),
      // await db.managers.listing.create((o) => o(
      //     product: Value(products[6].id),
      //     store: Value(stores[0].id),
      //     price: Value(30.0))),
      // await db.managers.listing.create((o) => o(
      //     product: Value(products[7].id),
      //     store: Value(stores[0].id),
      //     price: Value(5.0))),
      // await db.managers.listing.create((o) => o(
      //     product: Value(products[8].id),
      //     store: Value(stores[0].id),
      //     price: Value(10.0))),
    ];

    // Filter on related table's reference id - Does not require a join
    ComposableFilter? filter;
    expect(
        db.managers.product
            .filter((f) {
              filter = f.department.id(departments[0].id);
              return filter!;
            })
            .withReferences()
            .get(distinct: true)
            .then((value) => value.length),
        completion(3));
    expect(filter?.joinBuilders.length, 0);

    // Filter on a unrelated column on a related table - Requires a join
    expect(
        db.managers.product
            .filter((f) {
              filter = f.department.name("Electronics");
              return filter!;
            })
            .withReferences()
            .get(distinct: true)
            .then((value) => value.length),
        completion(3));
    expect(filter?.joinBuilders.length, 1);

    // Filter on a unrelated column on a related table & on
    // a related table's reference id - Requires a join
    expect(
        db.managers.product
            .filter((f) {
              filter = f.department.name("Electronics") |
                  f.department.id(departments[1].id);
              return filter!;
            })
            .withReferences()
            .get(distinct: true)
            .then((value) => value.length),
        completion(5));
    expect(filter?.joinBuilders.length, 1);

    // Ordering on current table & Filtering on related table
    expect(
        db.managers.product
            .filter((f) => f.department.name("Electronics"))
            .orderBy((f) => f.name.asc())
            .withReferences()
            .get()
            .then((value) => value.map((e) => e.product).toList()),
        completion([
          products[1],
          products[2],
          products[0],
        ]));

    // Ordering on related table & Filtering on current table
    expect(
        db.managers.product
            .filter((f) => f.name.startsWith("c"))
            .orderBy((f) => f.department.name.asc() & f.name.desc())
            .withReferences()
            .get()
            .then((value) => value.map((e) => e.product).toList()),
        completion([
          products[8],
          products[2],
          products[1],
          products[3],
        ]));

    // Filtering on reverse related table
    expect(
        // Any product that is available for more than $10
        // Socks & Cap are excluded
        db.managers.product
            .filter((f) => f.listings((f) => f.price.isBiggerThan(10.0)))
            .withReferences()
            .get(distinct: true)
            .then((value) => value.length),
        completion(7));

    // Filtering on reverse related table with ordering
    expect(
        // Any product that is available for more than $10
        // Socks & Cap are excluded, and the rest are ordered by name
        db.managers.product
            .filter((f) => f.listings((f) => f.price.isBiggerThan(10.0)))
            .orderBy((f) => f.name.asc())
            .withReferences()
            .get(distinct: true)
            .then((value) => value.map((e) => e.product).toList()),
        completion([
          products[1],
          products[3],
          products[2],
          products[4],
          products[6],
          products[5],
          products[0],
        ]));

    // Filter on reverse related column and then a related column
    expect(
        db.managers.product
            .filter((f) {
              filter = f.listings((f) => f.store.name("Target"));
              return filter!;
            })
            .withReferences()
            .get(distinct: true)
            .then((value) => value.length),
        completion(6));
    expect(filter?.joinBuilders.length, 2);
    expect(
        db.managers.product
            .filter((f) {
              filter = f.listings((f) => f.store.name("Target")) | f.name("TV");
              return filter!;
            })
            .withReferences()
            .get(distinct: true)
            .then((value) => value.length),
        completion(7));
    expect(filter?.joinBuilders.length, 2);

    // Filter on a related column and then a related column
    expect(
        db.managers.listing
            .filter((f) {
              // Listings of products in the electronics department
              filter = f.product.department.name("Electronics");
              return filter!;
            })
            .withReferences()
            .get(distinct: true)
            .then((value) => value.length),
        completion(8));
    expect(
        db.managers.listing
            .filter((f) {
              // Listings of products in the electronics department
              filter = f.product.department.name("Electronics") |
                  f.price.isBiggerThan(150.0);
              return filter!;
            })
            .withReferences()
            .get(distinct: true)
            .then((value) => value.length),
        completion(9));

    // Filter on a reverse related column and then a reverse related column
    expect(
        db.managers.department
            .filter((f) {
              // Departments that have products listed for more than $10
              filter = f.productRefs(
                  (f) => f.listings((f) => f.price.isBiggerThan(100.0)));
              return filter!;
            })
            .withReferences()
            .get(distinct: true)
            .then((value) => value.length),
        completion(2));
    expect(
        db.managers.department
            .filter((f) {
              // Departments that have products listed for more than $10 or is available at Walmart
              filter = f.productRefs((f) => f.listings((f) =>
                  f.price.isBiggerThan(100.0) | f.store.name("Walmart")));
              return filter!;
            })
            .withReferences()
            .get(distinct: true)
            .then((value) => value.length),
        completion(3));

    // Stores that have products in the clothing department
    expect(
        db.managers.store
            .filter((f) {
              // Products that are sold in a store that sells clothing
              filter = f.listings((f) => f.product.department.name("Clothing"));
              return filter!;
            })
            .withReferences()
            .get(distinct: true)
            .then((value) => value.length),
        completion(2));

    // Any product that is sold in a store that sells clothing
    expect(
        db.managers.product
            .filter((f) {
              filter = f.listings((f) => f.store
                  .listings((f) => f.product.department.name("Clothing")));
              return filter!;
            })
            .withReferences()
            .get(distinct: true)
            .then((value) => value.length),
        completion(9));
  });

  test(
      'manager - filter related with custom type for primary key with references',
      () async {
    final categoryData = [
      (description: "School", priority: Value(CategoryPriority.high)),
      (description: "Work", priority: Value(CategoryPriority.low)),
    ];

    final schoolCategoryId = await db.managers.categories.create((o) => o(
        priority: categoryData[0].priority,
        description: categoryData[0].description));
    final workCategoryId = await db.managers.categories.create((o) => o(
        priority: categoryData[1].priority,
        description: categoryData[1].description));

    final todoData = <({
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
        category: Value(RowId(schoolCategoryId)),
        status: Value(TodoStatus.open),
        targetDate: Value(DateTime.now().add(Duration(days: 1, seconds: 10)))
      ),
      (
        content: "Finish that report",
        title: Value("Report"),
        category: Value(RowId(schoolCategoryId)),
        status: Value(TodoStatus.workInProgress),
        targetDate: Value(DateTime.now().add(Duration(days: 2, seconds: 10)))
      ),
      (
        content: "Get that english homework done",
        title: Value("English Homework"),
        category: Value(RowId(schoolCategoryId)),
        status: Value(TodoStatus.open),
        targetDate: Value(DateTime.now().add(Duration(days: 1, seconds: 15)))
      ),
      (
        content: "Finish that Book report",
        title: Value("Book Report"),
        category: Value(RowId(schoolCategoryId)),
        status: Value(TodoStatus.done),
        targetDate:
            Value(DateTime.now().subtract(Duration(days: 2, seconds: 15)))
      ),
      // Work
      (
        content: "File those reports",
        title: Value("File Reports"),
        category: Value(RowId(workCategoryId)),
        status: Value(TodoStatus.open),
        targetDate: Value(DateTime.now().add(Duration(days: 1, seconds: 20)))
      ),
      (
        content: "Clean the office",
        title: Value("Clean Office"),
        category: Value(RowId(workCategoryId)),
        status: Value(TodoStatus.workInProgress),
        targetDate: Value(DateTime.now().add(Duration(days: 2, seconds: 20)))
      ),
      (
        content: "Nail that presentation",
        title: Value("Presentation"),
        category: Value(RowId(workCategoryId)),
        status: Value(TodoStatus.open),
        targetDate: Value(DateTime.now().add(Duration(days: 1, seconds: 25)))
      ),
      (
        content: "Take a break",
        title: Value("Break"),
        category: Value(RowId(workCategoryId)),
        status: Value(TodoStatus.done),
        targetDate:
            Value(DateTime.now().subtract(Duration(days: 2, seconds: 25)))
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

    for (var i in todoData) {
      await db.managers.todosTable.create((o) => o(
          content: i.content,
          title: i.title,
          category: i.category,
          status: i.status,
          targetDate: i.targetDate));
    }

    // item without title

    // Equals
    expect(
        db.managers.todosTable
            .filter((f) => f.category.id(RowId(schoolCategoryId)))
            .withReferences()
            .get(distinct: true)
            .then((value) => value.length),
        completion(4));

    // Not Equals
    expect(
        db.managers.todosTable
            .filter((f) => f.category.id.not(RowId(schoolCategoryId)))
            .withReferences()
            .get(distinct: true)
            .then((value) => value.length),
        completion(4));

    // Multiple filters
    expect(
        db.managers.todosTable
            .filter((f) => f.category.id(
                  RowId(schoolCategoryId),
                ))
            .filter((f) => f.status.equals(TodoStatus.open))
            .withReferences()
            .get(distinct: true)
            .then((value) => value.length),
        completion(2));

    // Multiple use related filters twice
    expect(
        db.managers.todosTable
            .filter((f) =>
                f.category.priority(CategoryPriority.low) |
                f.category.descriptionInUpperCase("SCHOOL"))
            .withReferences()
            .get(distinct: true)
            .then((value) => value.length),
        completion(8));

    // Use .filter multiple times
    expect(
        db.managers.todosTable
            .filter((f) => f.category.priority.equals(CategoryPriority.high))
            .filter((f) => f.category.descriptionInUpperCase("SCHOOL"))
            .withReferences()
            .get(distinct: true)
            .then((value) => value.length),
        completion(4));

    // Use backreference
    expect(
        db.managers.categories
            .filter((f) => f.todos((f) => f.title.equals("Math Homework")))
            .withReferences()
            .getSingle()
            .then((value) => value.categories.description),
        completion("School"));

    // Nested backreference
    expect(
        db.managers.categories
            .filter((f) => f.todos((f) {
                  final q =
                      f.category.todos((f) => f.title.equals("Math Homework"));
                  return q;
                }))
            .withReferences()
            .getSingle()
            .then((value) => value.categories.description),
        completion("School"));
  });
}
