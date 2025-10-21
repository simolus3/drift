import 'dart:async';
import 'dart:isolate';

import 'package:drift/isolate.dart';
import 'package:drift/src/runtime/api/runtime_api.dart';

/// Spawns a short-lived isolate to run the [computation] with a drift
/// database.
Future<Ret>
    computeWithDatabaseImplementation<Ret, DB extends GeneratedDatabase>({
  required FutureOr<Ret> Function(DB) computation,
  required DB Function(DatabaseConnection) connect,
  required DB database,
}) async {
  final connection = await database.serializableConnection();

  return await Isolate.run(() async {
    final database = connect(await connection.connect());
    try {
      return await computation(database);
    } finally {
      await database.close();
    }
  });
}
