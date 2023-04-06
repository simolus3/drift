import 'package:drift/drift.dart';
import 'package:drift/web/worker.dart';

class Approach1 {
  // #docregion approach1
  Future<DatabaseConnection> connectToWorker() async {
    return await connectToDriftWorker('/database_worker.dart.js',
        mode: DriftWorkerMode.dedicatedInShared);
  }
  // #enddocregion approach1
}
