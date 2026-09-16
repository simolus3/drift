import 'package:drift3_preview/drift.dart';
import 'package:drift_sqlite/drift_sqlite.dart';

import 'connection_unsupported.dart'
    if (dart.library.js_interop) 'connection_web.dart'
    if (dart.library.ffi) 'connection_native.dart';

part 'main.g.dart';

void main() async {
  final db = ExampleDatabase(
    DriftConnection(dialect: SqliteDialect.new, openConnection: openConnection),
  );

  final note = await db.createNote('Drift example!');
  print('Created note: $note');

  final query = db.notesQueries.all();
  await for (final snapshot in query.watch()) {
    print('Notes in database: $snapshot');
  }
}

class Notes extends Table {
  IntColumn get id => integer().autoIncrement();
  TextColumn get contents => text();
}

@DriftDatabase(tables: [Notes])
final class ExampleDatabase extends _$ExampleDatabase {
  ExampleDatabase(super.implementation);

  @override
  int get schemaVersion => 1;

  Future<Note> createNote(String contents) async {
    return await into(
      notes,
    ).insertReturning(NotesCompanion.insert(contents: contents));
  }
}
