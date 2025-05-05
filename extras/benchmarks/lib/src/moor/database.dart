import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

part 'database.g.dart';

class KeyValues extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

class Group extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}

class User extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get groupId => integer().references(Group, #id)();
}

@DriftDatabase(tables: [KeyValues, Group, User])
class Database extends _$Database {
  Database({bool cachePreparedStatements = true})
      : super(_obtainExecutor(
          cachePreparedStatements: cachePreparedStatements,
        ));

  @override
  int get schemaVersion => 1;
  Future<void> wipeAll() async {
    await delete(user).go();

    await delete(group).go();

    await delete(keyValues).go();
    ;
  }
}

const _uuid = Uuid();

QueryExecutor _obtainExecutor({
  required bool cachePreparedStatements,
}) {
  final file =
      File(p.join(Directory.systemTemp.path, 'drift_benchmarks', _uuid.v4()));
  file.parent.createSync();

  return NativeDatabase.createInBackground(
    file,
    cachePreparedStatements: cachePreparedStatements,
  );
}
