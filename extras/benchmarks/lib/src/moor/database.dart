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

@DriftDatabase(tables: [KeyValues])
class Database extends _$Database {
  Database({bool cachePreparedStatements = true})
      : super(_obtainExecutor(
          cachePreparedStatements: cachePreparedStatements,
        ));

  @override
  int get schemaVersion => 1;
}

const _uuid = Uuid();

QueryExecutor _obtainExecutor({
  required bool cachePreparedStatements,
}) {
  final file =
      File(p.join(Directory.systemTemp.path, 'drift_benchmarks', _uuid.v4()));
  file.parent.createSync();

  return NativeDatabase(
    file,
    cachePreparedStatements: cachePreparedStatements,
  );
}
