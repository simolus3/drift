import 'package:drift/drift.dart';
import 'package:drift/native.dart';

DatabaseConnection testInMemoryDatabase() {
  return DatabaseConnection.fromExecutor(NativeDatabase.memory());
}
