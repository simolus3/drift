@TestOn('vm')
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift/extensions/geopoly.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

import '../test_utils/database_vm.dart';

part 'geopoly_integration_test.g.dart';

void main() {
  preferLocalSqlite3();

  test(
    'can access geopoly types',
    () async {
      final database = _GeopolyTestDatabase(NativeDatabase.memory());
      expect(database.geopolyTest.shape.type, isA<GeopolyPolygonType>());

      final id =
          await database.geopolyTest.insertOne(GeopolyTestCompanion.insert(
        shape: Value(GeopolyPolygon.text('[[0,0],[1,0],[0.5,1],[0,0]]')),
      ));

      final area = await database.area(id).getSingle();
      expect(area, 0.5);
    },
    skip: _canUseGeopoly()
        ? null
        : 'Cannot test, your sqlite3 does not support geopoly.',
  );
}

bool _canUseGeopoly() {
  final db = sqlite3.openInMemory();
  final result = db
      .select('SELECT sqlite_compileoption_used(?)', ['ENABLE_GEOPOLY']).single;
  db.dispose();
  return result.values[0] == 1;
}

@DriftDatabase(include: {'geopoly.drift'})
class _GeopolyTestDatabase extends _$_GeopolyTestDatabase {
  _GeopolyTestDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
