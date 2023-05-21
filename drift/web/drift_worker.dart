import 'dart:async';
import 'dart:html';

import 'package:drift/src/web/wasm_setup/dedicated_worker.dart';
import 'package:drift/src/web/wasm_setup/shared_worker.dart';

Future<void> main() async {
  final self = WorkerGlobalScope.instance;

  if (self is DedicatedWorkerGlobalScope) {
    DedicatedDriftWorker(self).start();
  } else if (self is SharedWorkerGlobalScope) {
    SharedDriftWorker(self).start();
  }
}
