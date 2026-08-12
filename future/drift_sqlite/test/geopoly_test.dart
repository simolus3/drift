@TestOn('dart-vm')
library;

import 'package:drift3/drift.dart';
import 'package:drift_sqlite/drift_sqlite.dart';
import 'package:drift_sqlite/extensions/geopoly.dart';
import 'package:sqlite3/sqlite3.dart' show sqlite3;
import 'package:test/test.dart';

part 'geopoly_test.g.dart';

void main() {
  test(
    'can access geopoly types',
    () async {
      final database = _GeopolyTestDatabase(
        DriftConnection(
          dialect: SqliteDialect.new,
          openConnection: () async => SqliteConnection(sqlite3.openInMemory()),
        ),
      );
      expect(database.geopolyTest.shape.sqlType, isA<GeopolyPolygonType>());

      final id = await database.geopolyTestQueries.insertOne(
        GeopolyTestCompanion.insert(
          shape: Value(GeopolyPolygon.text('[[0,0],[1,0],[0.5,1],[0,0]]')),
        ),
      );

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
  final result = db.select('SELECT sqlite_compileoption_used(?)', [
    'ENABLE_GEOPOLY',
  ]).single;
  db.close();
  return result.values[0] == 1;
}

@DriftDatabase(include: {'geopoly.drift'})
final class _GeopolyTestDatabase extends _$_GeopolyTestDatabase {
  _GeopolyTestDatabase(super.implementation);

  @override
  int get schemaVersion => 1;
}
