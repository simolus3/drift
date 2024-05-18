import 'package:drift_macros/drift_macros.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

@DriftTable()
final class User {
  final int id;
  final String name;

  User({required this.id, required this.name});
}

final class MacroDatabase extends GeneratedDatabase {
  MacroDatabase(super.executor);

  late final users = User.createTable(this);

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => [users];

  @override
  int get schemaVersion => 1;
}

void main() async {
  final database = MacroDatabase(NativeDatabase.memory(logStatements: true));

  await database.users.select().get();
}
