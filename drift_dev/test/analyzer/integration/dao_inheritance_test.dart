@Tags(['analyzer'])
import 'package:drift_dev/src/analyzer/runner/results.dart';
import 'package:drift_dev/src/utils/type_utils.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  test('supports inheritance for daos', () async {
    final state = TestState.withContent({
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

@DriftAccessor(tables: [ProductTable])
class ProductsDao extends BaseProductsDao with _$ProductDaoMixin {
  ProductsDao(MyDatabase db): super(db);
}
      ''',
    });

    await state.runTask('package:a/database.dart');
    final file = state.file('package:a/database.dart');

    expect(file.isAnalyzed, isTrue);
    expect(file.errors.errors, isEmpty);

    final dao = (file.currentResult as ParsedDartFile).declaredDaos.single;
    expect(dao.dbClass.nameIfInterfaceType, 'MyDatabase');

    state.close();
  });
}
