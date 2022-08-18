import 'package:test/test.dart';

import '../database/database.dart';
import 'suite.dart';

void customObjectTests(TestExecutor executor) {
  test('custom objects', () async {
    final db = Database(executor.createConnection());

    var preferences = await db.settingsFor(1).getSingle();
    expect(preferences, isNull);

    await db.updateSettings(1, Preferences(true));
    preferences = await db.settingsFor(1).getSingle();

    expect(preferences?.receiveEmails, true);

    await executor.clearDatabaseAndClose(db);
  });
}
