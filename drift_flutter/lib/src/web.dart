import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

import 'connect.dart';

QueryExecutor driftDatabase({
  required String name,
  DriftWebOptions? web,
  DriftNativeOptions? native,
}) {
  if (web == null) {
    throw ArgumentError(
        'When compiling to the web, the `web` parameter needs to be set.');
  }

  return DatabaseConnection.delayed(Future(() async {
    final result = await WasmDatabase.open(
      databaseName: name,
      sqlite3Uri: web.sqlite3Wasm,
      driftWorkerUri: web.driftWorker,
    );

    if (result.missingFeatures.isNotEmpty) {
      // Depending how central local persistence is to your app, you may want
      // to show a warning to the user if only unrealiable implemetentations
      // are available.
      print('Using ${result.chosenImplementation} due to missing browser '
          'features: ${result.missingFeatures}');
    }

    return result.resolvedExecutor;
  }));
}
