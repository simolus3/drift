import 'dart:ui';

import 'package:drift/drift.dart';
import 'package:drift/isolate.dart';
import 'package:drift/native.dart';

class Database extends GeneratedDatabase {
  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const Iterable.empty();

  @override
  int get schemaVersion => 1;

  Database() : super(DatabaseConnection.delayed(_getBackgroundExecutor()));

  Future<void> testQuery() async {
    await customSelect('SELECT 1').get();
  }

  static Future<DatabaseConnection> _getBackgroundExecutor() async {
    const databaseIsolate = 'drift_database_server';

    // Either get the existing connect port, or create a new connection
    final existingPort = IsolateNameServer.lookupPortByName(databaseIsolate);

    if (existingPort != null) {
      // We can connect to the existing database isolate!
      return DriftIsolate.fromConnectPort(existingPort).connect();
    } else {
      // We need to spawn a new isolate and register it
      final isolate = DriftIsolate.inCurrent(() {
        print('creating database');
        return NativeDatabase.memory();
      });

      IsolateNameServer.registerPortWithName(
        isolate.connectPort,
        databaseIsolate,
      );

      return isolate.connect();
    }
  }
}
