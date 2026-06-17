import 'package:drift3/drift.dart';
import 'package:drift_sqlite/drift_sqlite.dart';
import 'package:drift_sqlite/web.dart' hide WasmDatabaseResult;
import 'package:sqlite3_web/sqlite3_web.dart';

import 'connect.dart';

/// A web drift database implementation based on the `sqlite3_web` package.
DriftConnection driftDatabase({
  required String name,
  required SqliteOptions dialectOptions,
  DriftWebOptions? web,
  DriftNativeOptions? native,
}) {
  if (web == null) {
    throw ArgumentError(
      'When compiling to the web, the `web` parameter needs to be set.',
    );
  }

  return DriftConnection(
    dialect: SqliteDialect(options: dialectOptions),
    openConnection: () async {
      final sqlite = WebSqlite.open(
        workers: .defaultWorkers(web.driftWorker.toString()),
        wasmModule: web.sqlite3Wasm.toString(),
      );
      final result = await sqlite.connectToRecommended(name);
      final resultHandler = web.onResult ?? _defaultResultHandler;
      final session = WasmDatabase.wrapDatabase(result.database);
      resultHandler(
        WasmDatabaseResult(
          resolvedSession: session,
          features: result.features,
          databaseImplementation: result.implementation,
        ),
      );

      return WasmDatabase.wrapDatabase(result.database);
    },
  );
}

void _defaultResultHandler(WasmDatabaseResult result) {
  if (result.features.missingFeatures.isNotEmpty) {
    // Depending how central local persistence is to your app, you may want
    // to show a warning to the user if only unrealiable implemetentations
    // are available.
    print(
      'Using ${result.databaseImplementation} due to missing browser '
      'features: ${result.features.missingFeatures}',
    );
  }
}
