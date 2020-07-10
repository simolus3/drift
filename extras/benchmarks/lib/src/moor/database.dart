import 'dart:io';

import 'package:moor/ffi.dart';
import 'package:moor/moor.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

part 'database.g.dart';

class KeyValues extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@UseMoor(tables: [KeyValues])
class Database extends _$Database {
  Database() : super(_obtainExecutor());

  @override
  int get schemaVersion => 1;
}

final _uuid = Uuid();

QueryExecutor _obtainExecutor() {
  final file =
      File(p.join(Directory.systemTemp.path, 'moor_benchmarks', _uuid.v4()));
  file.parent.createSync();

  return VmDatabase(file);
}
