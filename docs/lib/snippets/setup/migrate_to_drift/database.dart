// #docregion start
import 'package:drift/drift.dart';

part 'database.g.dart';

@DriftDatabase(
    // include: {'schema.drift'}
    )
// #enddocregion start
class HackToIncludePartialAnnotationInDocs
    extends _$HackToIncludePartialAnnotationInDocs {
  HackToIncludePartialAnnotationInDocs(super.e);

  @override
  int get schemaVersion => 1;
}

@DriftDatabase(include: {'schema.drift'})
// #docregion start
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openDatabase());

  @override
  int get schemaVersion => throw UnimplementedError(
        'todo: The schema version used by your existing database',
      );

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        // This is similar to the `onUpgrade` callback from sqflite. When
        // migrating to drift, it should contain your existing migration logic.
        // You can access the raw database by using `customStatement`
      },
      beforeOpen: (details) async {
        // This is a good place to enable pragmas you expect, e.g.
        await customStatement('pragma foreign_keys = ON;');
      },
    );
  }

  static QueryExecutor _openDatabase() {
    throw UnimplementedError(
      'todo: Open database compatible with the one that already exists',
    );
  }

  // #enddocregion start
  // #docregion drift-query
  Future<List<TestData>> queryWithGeneratedCode() async {
    return findWithValue(12).get();
  }
  // #enddocregion drift-query

  // #docregion dart-query
  Stream<List<TestData>> queryWithDartCode() {
    final query = select(test)..where((row) => row.value.isBiggerThanValue(12));
    return query.watch();
  }
  // #enddocregion dart-query
  // #docregion start
}
// #enddocregion start
