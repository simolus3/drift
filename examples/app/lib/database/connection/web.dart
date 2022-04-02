import 'package:drift/drift.dart';
import 'package:drift/web.dart';

/// Obtains a database connection for running drift on the web.
DatabaseConnection connect({bool isInWebWorker = false}) {
  return DatabaseConnection.delayed(Future.sync(() async {
    final storage = await DriftWebStorage.indexedDbIfSupported('app_database',
        inWebWorker: isInWebWorker);
    final databaseImpl = WebDatabase.withStorage(storage);

    return DatabaseConnection.fromExecutor(databaseImpl);
  }));
}
