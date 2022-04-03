import 'package:drift/drift.dart';

// #docregion unique
class WithUniqueConstraints extends Table {
  IntColumn get a => integer().unique()();

  IntColumn get b => integer()();
  IntColumn get c => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {b, c}
      ];

  // Effectively, this table has two unique key sets: (a) and (b, c).
}
// #enddocregion unique
