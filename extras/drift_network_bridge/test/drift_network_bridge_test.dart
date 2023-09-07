// ignore_for_file: deprecated_member_use

@TestOn('vm')
@Timeout(Duration(seconds: 120))
import 'dart:async';
import 'dart:cli';
// ignore: unused_import
import 'dart:io';

import 'package:drift/native.dart';
import 'package:drift/remote.dart';
import 'package:drift_network_bridge/implementation/mqtt_database_gateway.dart';
import 'package:drift_testcases/tests.dart';
import 'package:drift_testcases/data/sample_data.dart' as people;
import 'package:test/scaffolding.dart';

class NbExecutor extends TestExecutor {
  final MqttDatabaseGateway gw;
  // late DatabaseConnection clientConn;
  NbExecutor(this.gw);

  @override
  bool get supportsReturning => true;

  @override
  bool get supportsNestedTransactions => true;

  Completer? closedCompleter;

  @override
  DatabaseConnection createConnection() {
    if(closedCompleter != null && !closedCompleter!.isCompleted) {
      waitFor(closedCompleter!.future);
    }
    final connection = gw.createConnection();
    waitFor(connection.connect());
    return waitFor<DatabaseConnection>(connectToRemoteAndInitialize(connection)); // WARNING: This will block the calling thread!
  }

  @override
  Future clearDatabaseAndClose(Database db) async {
    closedCompleter = Completer();
    for (var table in db.allTables) {
      await db.customStatement('DELETE FROM ${table.actualTableName}');
      await db.customStatement('DELETE FROM sqlite_sequence WHERE name = "${table.actualTableName}"');
    }
    await db.transaction(() async {
      await db.batch((batch) {
        batch.insertAll(
            db.users, [people.dash, people.duke, people.gopher]);
      });
    });
    closedCompleter!.complete();
  }

  @override
  Future<void> deleteData() async {

  }
}

Future<void> main() async {
  final db = Database(DatabaseConnection(NativeDatabase.memory(logStatements: true,)));
  final gate = MqttDatabaseGateway('test.mosquitto.org', 'unit_device', 'drift/test_site',);
  gate.serve(db);
  // await gate.isReady;
  await Future.delayed(Duration(seconds: 5));
  runAllTests(NbExecutor(gate));
}
