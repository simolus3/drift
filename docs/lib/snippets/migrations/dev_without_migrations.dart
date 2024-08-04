import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_docs/snippets/migrations/migrations.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'dev_without_migrations.g.dart';

class Articles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 6, max: 10)();
  TextColumn get content => text().named('body')();
}

// #docregion dev_migrations
@DriftDatabase(tables: [Articles])
class ArticlesDatabase extends _$ArticlesDatabase {
  /// Use a brand new in-memory database during development.
  ArticlesDatabase()
      : super(kDebugMode
            ? NativeDatabase.memory()
            : driftDatabase(name: "articles"));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        /// Create some initial data when the database is created.
        beforeOpen: (details) async {
          if (details.wasCreated && kDebugMode) {
            await managers.articles.bulkCreate((create) => [
                  create(title: "Hello", content: "World"),
                  create(title: "Foo", content: "Bar")
                ]);
          }
        },
      );
}
// #enddocregion dev_migrations
