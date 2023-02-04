import 'package:drift/native.dart';
import 'package:drift_lock_bug/database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets("deadlock test", (tester) async {
    final db = Database.executor(
      NativeDatabase.memory(logStatements: true),
    );

    addTearDown(() async {
      print("closing db");
      await db.close();
      print("db closed");
    });

    await db.customSelect("SELECT 1").get();
  });
}
