import 'dart:async';

import 'package:drift/src/runtime/api/runtime_api.dart';

/// This will directly execute the passed computation as a future with the
/// current Database.
Future<Ret>
    computeWithDatabaseImplementation<Ret, DB extends GeneratedDatabase>({
  required FutureOr<Ret> Function(DB) computation,
  required DB Function(DatabaseConnection) connect,
  required DB database,
}) async =>
        await computation(database);
