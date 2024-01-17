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
