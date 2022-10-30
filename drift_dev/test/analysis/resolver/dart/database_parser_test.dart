import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  final mainUri = Uri.parse('package:a/main.dart');

  test('parses schema version getter', () async {
    final backend = TestBackend.inTest({
      'a|lib/main.dart': r'''
import 'package:drift/drift.dart';

@DriftDatabase()
class MyDatabase extends _$MyDatabase {
  @override
  int get schemaVersion => 13;
}
''',
    });

    final fileState = await backend.driver.fullyAnalyze(mainUri);
    backend.expectNoErrors();

    final db = fileState.analyzedElements.single as DriftDatabase;
    expect(db.schemaVersion, 13);
  });

  test('parses schema version field', () async {
    final backend = TestBackend.inTest({
      'a|lib/main.dart': r'''
import 'package:drift/drift.dart';

@DriftDatabase()
class MyDatabase extends _$MyDatabase {
  @override
  final int schemaVersion = 23;
}
''',
    });

    final fileState = await backend.driver.fullyAnalyze(mainUri);
    backend.expectNoErrors();

    final db = fileState.analyzedElements.single as DriftDatabase;
    expect(db.schemaVersion, 23);
  });

  test('does not warn about missing tables parameter', () async {
    final backend = TestBackend.inTest({
      'a|lib/main.dart': r'''
import 'package:drift/drift.dart';

@DriftDatabase(include: {'foo.drift'})
class MyDatabase extends _$MyDatabase {

}

@DriftDatabase(include: {'foo.drift'}, tables: [])
class MyDatabase2 extends _$MyDatabase {

}
''',
    });

    await backend.driver.fullyAnalyze(mainUri);
    backend.expectNoErrors();
  });

  test('supports inheritance for daos', () async {
    final state = TestBackend.inTest({
      'a|lib/database.dart': r'''
import 'package:drift/drift.dart';

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}

@DriftDatabase(tables: [Products], daos: [ProductsDao])
class MyDatabase {}

abstract class BaseDao<T extends Table, D >
  extends DatabaseAccessor<MyDatabase> {

  final TableInfo<T, D> _table;

  BaseDao(MyDatabase db, this._table): super(db);

  Future<void> insertOne(Insertable<T> value) => into(_table).insert(value);

  Future<List<T>> selectAll() => select(_table).get();
}

abstract class BaseProductsDao extends BaseDao<Products, Product> {
  BaseProductsDao(MyDatabase db): super(db, db.products);
}

@DriftAccessor(tables: [Products])
class ProductsDao extends BaseProductsDao with _$ProductDaoMixin {
  ProductsDao(MyDatabase db): super(db);
}
      ''',
    });

    final file = await state.analyze('package:a/database.dart');

    expect(file.isFullyAnalyzed, isTrue);
    state.expectNoErrors();

    final dao =
        file.analysis[file.id('ProductsDao')]!.result as DatabaseAccessor;
    expect(dao.databaseClass.toString(), 'MyDatabase');
  });

  test('only includes duplicate elements once', () async {
    final state = TestBackend.inTest({
      'a|lib/main.dart': '''
import 'package:drift/drift.dart';

import 'table.dart';

@DriftDatabase(tables: [Users], include: {'file.drift'})
class MyDatabase {}
      ''',
      'a|lib/file.drift': '''
import 'table.dart';
      ''',
      'a|lib/table.dart': '''
import 'package:drift/drift.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
}
      '''
    });

    final dbFile = await state.analyze('package:a/main.dart');
    final db = dbFile.fileAnalysis!.resolvedDatabases.values.single;

    expect(db.availableElements, hasLength(1));
  });
}
