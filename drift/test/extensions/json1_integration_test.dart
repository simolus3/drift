@Tags(['integration'])
import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/extensions/json1.dart';
import 'package:test/test.dart';

import '../generated/todos.dart';
import '../test_utils/test_utils.dart';

void main() {
  const jsonObject = {
    'foo': 'bar',
    'array': [
      'one',
      'two',
      'three',
    ],
  };

  late TodoDb db;

  setUp(() => db = TodoDb(testInMemoryDatabase()));
  tearDown(() => db.close());

  test('json1 integration test', () async {
    await db.into(db.pureDefaults).insert(PureDefaultsCompanion(
        txt: Value(MyCustomObject(json.encode(jsonObject)))));

    final arrayLengthExpr = db.pureDefaults.txt.jsonArrayLength(r'$.array');
    final query = db.select(db.pureDefaults).addColumns([arrayLengthExpr]);
    query.where(db.pureDefaults.txt
        .jsonExtract(r'$.foo')
        .equalsExp(Variable.withString('bar')));

    final resultRow = await query.getSingle();
    expect(resultRow.read(arrayLengthExpr), 3);
  });

  test('json_each', () async {
    final function = Variable<String>(json.encode(jsonObject)).jsonEach(db);
    final rows = await db.select(function).get();

    expect(rows, hasLength(2));

    expect(rows[0].read(function.key), DriftAny('foo'));
    expect(rows[0].read(function.value), DriftAny('bar'));
    expect(rows[0].read(function.type), 'text');
    expect(rows[0].read(function.atom), DriftAny('bar'));
    expect(rows[0].read(function.id), 2);
    expect(rows[0].read(function.parent), isNull);
    expect(rows[0].read(function.fullKey), r'$.foo');
    expect(rows[0].read(function.path), r'$');
  });

  test('json_tree', () async {
    // Make sure we can use aliases as well
    final function = Variable<String>(json.encode(jsonObject)).jsonTree(db);
    final parent = db.alias(function, 'parent');

    final query = db
        .selectOnly(function)
        .join([leftOuterJoin(parent, parent.id.equalsExp(function.parent))])
      ..addColumns([function.atom, parent.id])
      ..where(function.atom.isNotNull());

    final rows = await query
        .map((row) => (row.read(function.atom), row.read(parent.id)))
        .get();

    expect(rows, [
      (DriftAny('bar'), 0),
      (DriftAny('one'), 10),
      (DriftAny('two'), 10),
      (DriftAny('three'), 10),
    ]);
  });

  group('aggregate', () {
    setUp(() async {
      await db.batch((batch) {
        batch
          ..insert(db.categories, CategoriesCompanion.insert(description: '_'))
          ..insertAll(db.todosTable, [
            TodosTableCompanion.insert(
                title: Value('first title'),
                content: 'entry in category',
                category: Value(1)),
            TodosTableCompanion.insert(content: 'not in category'),
            TodosTableCompanion.insert(
                title: Value('second title'),
                content: 'another in category',
                category: Value(1))
          ]);
      });
    });

    test('json_group_array', () async {
      final query = db.select(db.categories).join([
        leftOuterJoin(
            db.todosTable, db.todosTable.category.equalsExp(db.categories.id))
      ]);

      final stringArray = jsonGroupArray(db.todosTable.id);
      final binaryArray = jsonbGroupArray(db.todosTable.id).json();
      query
        ..groupBy([db.categories.id])
        ..addColumns([stringArray, binaryArray]);

      final row = await query.getSingle();
      expect(json.decode(row.read(stringArray)!), unorderedEquals([1, 3]));
      expect(json.decode(row.read(binaryArray)!), unorderedEquals([1, 3]));
    });

    test('json_group_object', () async {
      final query = db.select(db.categories).join([
        leftOuterJoin(
            db.todosTable, db.todosTable.category.equalsExp(db.categories.id))
      ]);

      final stringObject = jsonGroupObject({
        db.todosTable.title: db.todosTable.content,
      });
      final binaryObject = jsonbGroupObject({
        db.todosTable.title: db.todosTable.content,
      }).json();
      query
        ..groupBy([db.categories.id])
        ..addColumns([stringObject, binaryObject]);

      final row = await query.getSingle();
      expect(json.decode(row.read(stringObject)!), {
        'first title': 'entry in category',
        'second title': 'another in category',
      });
      expect(json.decode(row.read(binaryObject)!), {
        'first title': 'entry in category',
        'second title': 'another in category',
      });
    });
  });

  group('jsonb', () {
    setUp(() async {
      await db.categories
          .insertOne(CategoriesCompanion.insert(description: '_'));
    });

    Expression<Uint8List> jsonb(Object? dart) {
      return Variable(json.encode(dart)).jsonb();
    }

    Future<T?> eval<T extends Object>(Expression<T> expr) {
      final query = db.selectOnly(db.categories)..addColumns([expr]);
      return query.getSingle().then((row) => row.read(expr));
    }

    test('json', () async {
      expect(await eval(jsonb([1, 2, 3]).json()), '[1,2,3]');
    });

    test('jsonArrayLength', () async {
      expect(await eval(jsonb([1, 2, 3]).jsonArrayLength()), 3);
    });

    test('jsonExtract', () async {
      expect(
          await eval(jsonb(jsonObject).jsonExtract<String>(r'$.foo')), 'bar');
    });
  });
}
