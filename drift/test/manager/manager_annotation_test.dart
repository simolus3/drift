// ignore_for_file: unused_local_variable

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
  });

  tearDown(() => db.close());

  tearDown(() => db.close());

  test('manager - generic annotation', () async {
    await db.managers.tableWithEveryColumnType.create((o) => o(
        aBlob: Value(Uint8List(0)),
        aBool: Value(true),
        anInt: Value(5),
        anInt64: Value(BigInt.from(5)),
        aText: Value("Get that math homework done"),
        anIntEnum: Value(TodoStatus.open),
        aReal: Value(3.0),
        aDateTime: Value(DateTime.now().add(Duration(days: 3)))));

    final aTextAnnotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.aText);
    final aRealAnnotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.aReal);
    final anIntEnumAnnotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.anIntEnum);
    final anIntEnumWithConverterAnnotation = db
        .managers.tableWithEveryColumnType
        .annotationWithConverter((a) => a.anIntEnum);
    final aDateTimeAnnotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.aDateTime);
    final aBlobAnnotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.aBlob);
    final aBoolAnnotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.aBool);
    final anIntAnnotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.anInt);
    final anInt64Annotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.anInt64);
    final (_, refs) =
        await db.managers.tableWithEveryColumnType.withAnnotations([
      aTextAnnotation,
      aRealAnnotation,
      anIntEnumAnnotation,
      aDateTimeAnnotation,
      aBlobAnnotation,
      aBoolAnnotation,
      anIntAnnotation,
      anInt64Annotation,
      anIntEnumWithConverterAnnotation,
    ]).getSingle();
    expect(aTextAnnotation.read(refs), "Get that math homework done");
    expect(aRealAnnotation.read(refs), 3.0);
    expect(anIntEnumAnnotation.read(refs), TodoStatus.open.index);
    expect(anIntEnumWithConverterAnnotation.read(refs), TodoStatus.open);
    expect(aDateTimeAnnotation.read(refs), isA<DateTime>());
    expect(aBlobAnnotation.read(refs), isA<Uint8List>());
    expect(aBoolAnnotation.read(refs), true);
    expect(anIntAnnotation.read(refs), 5);
    expect(anInt64Annotation.read(refs), BigInt.from(5));
  });

  test('manager - generic nullable annotation', () async {
    await db.managers.tableWithEveryColumnType.create((o) => o());

    final aTextAnnotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.aText);
    final aRealAnnotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.aReal);
    final anIntEnumAnnotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.anIntEnum);
    final anIntEnumWithConverterAnnotation = db
        .managers.tableWithEveryColumnType
        .annotationWithConverter((a) => a.anIntEnum);
    final aDateTimeAnnotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.aDateTime);
    final aBlobAnnotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.aBlob);
    final aBoolAnnotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.aBool);
    final anIntAnnotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.anInt);
    final anInt64Annotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.anInt64);
    final (_, refs) =
        await db.managers.tableWithEveryColumnType.withAnnotations([
      aTextAnnotation,
      aRealAnnotation,
      anIntEnumAnnotation,
      aDateTimeAnnotation,
      aBlobAnnotation,
      aBoolAnnotation,
      anIntAnnotation,
      anInt64Annotation,
      anIntEnumWithConverterAnnotation,
    ]).getSingle();
    expect(aTextAnnotation.read(refs), null);
    expect(aRealAnnotation.read(refs), null);
    expect(anIntEnumAnnotation.read(refs), null);
    expect(anIntEnumWithConverterAnnotation.read(refs), null);
    expect(aDateTimeAnnotation.read(refs), null);
    expect(aBlobAnnotation.read(refs), null);
    expect(aBoolAnnotation.read(refs), null);
    expect(anIntAnnotation.read(refs), null);
    expect(anInt64Annotation.read(refs), null);
  });

  test('manager - generic filter annotation', () async {
    final in3Days = DateTime.now().add(Duration(days: 3));
    await db.managers.tableWithEveryColumnType.create((o) => o(
        aBlob: Value(Uint8List(0)),
        aBool: Value(true),
        anInt: Value(5),
        anInt64: Value(BigInt.from(5)),
        aText: Value("Get that math homework done"),
        anIntEnum: Value(TodoStatus.open),
        aReal: Value(3.0),
        aDateTime: Value(in3Days)));
    await db.managers.tableWithEveryColumnType.create((o) => o(
        aBlob: Value(Uint8List(50)),
        aBool: Value(false),
        anInt: Value(1),
        anInt64: Value(BigInt.from(10)),
        aText: Value("Do Nothing"),
        anIntEnum: Value(TodoStatus.done),
        aReal: Value(2),
        aDateTime: Value(DateTime.now().add(Duration(days: 2)))));

    final aTextAnnotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.aText);
    final aRealAnnotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.aReal);
    final anIntEnumAnnotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.anIntEnum);
    final anIntEnumWithConverterAnnotation = db
        .managers.tableWithEveryColumnType
        .annotationWithConverter((a) => a.anIntEnum);
    final aDateTimeAnnotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.aDateTime);
    final aBlobAnnotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.aBlob);
    final aBoolAnnotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.aBool);
    final anIntAnnotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.anInt);
    final anInt64Annotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.anInt64);

    // If any of these filters dont work, there will be more than one row returned, which will cause an exception
    expect(
        await db.managers.tableWithEveryColumnType
            .withAnnotations([aTextAnnotation])
            .filter(
                (f) => aTextAnnotation.filter("Get that math homework done"))
            .getSingle()
            .then((value) => aTextAnnotation.read(value.$2)),
        "Get that math homework done");
    expect(
        await db.managers.tableWithEveryColumnType
            .withAnnotations([aRealAnnotation])
            .filter((f) => aRealAnnotation.filter(3.0))
            .getSingle()
            .then((value) => aRealAnnotation.read(value.$2)),
        3.0);
    expect(
        await db.managers.tableWithEveryColumnType
            .withAnnotations([anIntEnumAnnotation])
            .filter((f) => anIntEnumAnnotation.filter(TodoStatus.open.index))
            .getSingle()
            .then((value) => anIntEnumAnnotation.read(value.$2)),
        TodoStatus.open.index);
    expect(
        await db.managers.tableWithEveryColumnType
            .withAnnotations([anIntEnumWithConverterAnnotation])
            .filter(
                (f) => anIntEnumWithConverterAnnotation.filter(TodoStatus.open))
            .getSingle()
            .then((value) => anIntEnumWithConverterAnnotation.read(value.$2)),
        TodoStatus.open);
    expect(
        await db.managers.tableWithEveryColumnType
            .withAnnotations([aDateTimeAnnotation])
            .filter((f) => aDateTimeAnnotation.filter(in3Days))
            .getSingle()
            // Default DB only has second level precision
            .then((value) =>
                aDateTimeAnnotation.read(value.$2)!.millisecondsSinceEpoch ~/
                1000),
        in3Days.millisecondsSinceEpoch ~/ 1000);
    expect(
        await db.managers.tableWithEveryColumnType
            .withAnnotations([aBlobAnnotation])
            .filter((f) => aBlobAnnotation.filter(Uint8List(0)))
            .getSingle()
            .then((value) => aBlobAnnotation.read(value.$2)),
        Uint8List(0));
    expect(
        await db.managers.tableWithEveryColumnType
            .withAnnotations([aBoolAnnotation])
            .filter((f) => aBoolAnnotation.filter(true))
            .getSingle()
            .then((value) => aBoolAnnotation.read(value.$2)),
        true);
    expect(
        await db.managers.tableWithEveryColumnType
            .withAnnotations([anIntAnnotation])
            .filter((f) => anIntAnnotation.filter(5))
            .getSingle()
            .then((value) => anIntAnnotation.read(value.$2)),
        5);
    expect(
        await db.managers.tableWithEveryColumnType
            .withAnnotations([anInt64Annotation])
            .filter((f) => anInt64Annotation.filter(BigInt.from(5)))
            .getSingle()
            .then((value) => anInt64Annotation.read(value.$2)),
        BigInt.from(5));
  });

  test('manager - many to one annotation', () async {
    final productNameAnnotation =
        db.managers.listing.annotation((a) => a.product.name);
    final departmentNameAnnotation =
        db.managers.listing.annotation((a) => a.product.department.name);
    final storeNameAnnotation =
        db.managers.listing.annotation((a) => a.store.name);

    final (_, refs) = await db.managers.listing
        .withAnnotations([
          productNameAnnotation,
          departmentNameAnnotation,
          storeNameAnnotation
        ])
        .limit(1)
        .getSingle();
    expect(productNameAnnotation.read(refs), "TV");
    expect(departmentNameAnnotation.read(refs), "Electronics");
    expect(storeNameAnnotation.read(refs), "Walmart");
  });
  test('manager - one to many aggregation annotation', () async {
    final productCountAnnotation =
        db.managers.store.annotation((a) => a.listings((a) => a.id).count());

    final (_, refs) = await db.managers.store
        .withAnnotations([productCountAnnotation])
        .limit(1)
        .getSingle();
    expect(productCountAnnotation.read(refs), 9);
  });

  test('manager - aggregation on annotation', () async {
    final productCountAnnotation = db.managers.store
        .annotation((a) => a.listings((a) => a.product.name).groupConcat());

    final (_, refs) = await db.managers.store
        .withAnnotations([productCountAnnotation])
        .limit(1)
        .getSingle();
    expect(productCountAnnotation.read(refs),
        'TV,Cell Phone,Charger,Cereal,Meat,Shirt,Pants,Socks,Cap');
  });
  test('manager - annotation of aggregation', () async {
    final productCountAnnotation = db.managers.listing
        .annotation((a) => a.product.listings((a) => a.id).groupConcat());

    final (_, refs) = await db.managers.listing
        .withAnnotations([productCountAnnotation])
        .limit(1)
        .getSingle();
    expect(productCountAnnotation.read(refs), '1,16');
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
