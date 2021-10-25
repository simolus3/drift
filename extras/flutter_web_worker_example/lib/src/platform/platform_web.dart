import 'dart:html';

import 'package:drift/drift.dart';
import 'package:drift/remote.dart';
import 'package:drift/web.dart';

class PlatformInterface {
  static QueryExecutor createDatabaseConnection(String databaseName) {
    return LazyDatabase(() async {
      return _connectToWorker(databaseName).executor;
    });
  }

  static DatabaseConnection _connectToWorker(String databaseName) {
    final worker = SharedWorker('worker.dart.js', databaseName);
    return remote(worker.port!.channel());
  }
}
