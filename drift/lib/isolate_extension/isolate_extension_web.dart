/// Provides utilities that replicate Drift's background isolate functionality
/// for web environments.
library;

import 'dart:async';

import 'package:drift/isolate.dart';
import 'package:meta/meta.dart';

import '../drift.dart';

/// Experimental methods to provide the same interface for web as for native.
extension ComputeWithDriftIsolate<DB extends DatabaseConnectionUser> on DB {
  /// Since web does not have the concept of isoaltes it is impossible to get a
  /// serializable Connection.
  @experimental
  Future<DriftIsolate> serializableConnection() => throw UnimplementedError();

  /// Will directly execute the passed computation as a future with the current
  /// Database.
  @experimental
  Future<Ret> computeWithDatabase<Ret>({
    required FutureOr<Ret> Function(DB) computation,
    required DB Function(DatabaseConnection) connect,
  }) async =>
      await computation(this);
}
