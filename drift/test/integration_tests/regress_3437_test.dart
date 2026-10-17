@TestOn('vm')
library;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

part 'regress_3437_test.g.dart';

class Groups extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}

// A custom row class that doesn't expose the column referencing Groups.
@UseRowClass(Member)
class Members extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get group => integer().references(Groups, #id)();
}

class Member {
  final int id;

  Member({required this.id});
}

@DriftDatabase(tables: [Groups, Members])
class _Database extends _$_Database {
  _Database(super.e);

  @override
  int get schemaVersion => 1;
}

void main() {
  late _Database db;

  setUp(() async {
    db = _Database(NativeDatabase.memory());
    await db.groups.insertAll([
      GroupsCompanion.insert(name: 'a'),
      GroupsCompanion.insert(name: 'b'),
    ]);
    await db.members.insertAll([
      MembersCompanion.insert(group: 1),
      MembersCompanion.insert(group: 1),
      MembersCompanion.insert(group: 2),
    ]);
  });

  tearDown(() => db.close());

  test('reads forward references without getter on row class', () async {
    final rows = await db.managers.members.withReferences().get();
    final groups = [
      for (final (member, refs) in rows)
        (member.id, (await refs.group.getSingle()).name),
    ];

    expect(groups, [(1, 'a'), (2, 'a'), (3, 'b')]);
  });

  test('prefetches reverse references without getter on row class', () async {
    final rows = await db.managers.groups
        .withReferences((prefetch) => prefetch(membersRefs: true))
        .get();

    expect(
      {
        for (final (group, refs) in rows)
          group.name: refs.membersRefs.prefetchedData
              ?.map((m) => m.id)
              .toList(),
      },
      {
        'a': [1, 2],
        'b': [3],
      },
    );
  });
}
