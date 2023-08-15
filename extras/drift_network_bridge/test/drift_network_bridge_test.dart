import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_network_bridge/drift_network_bridge.dart';
import 'package:drift_network_bridge/src/client_db.dart';
import 'package:drift_network_bridge/src/host_db.dart';
import 'package:drift_testcases/tests.dart';
import 'package:test/test.dart';
import 'package:path/path.dart';
import 'impl/database/test_db.dart';
import 'impl/mqtt_stream/mqtt_stream.dart';
import 'impl/test_mqtt_client.dart';
import 'impl/test_mqtt_client_impl.dart';
import 'impl/test_mqtt_host.dart';
import 'impl/test_mqtt_server.dart';


class NbExecutor extends TestExecutor {
  @override
  bool get supportsReturning => true;

  @override
  bool get supportsNestedTransactions => true;

  @override
  DatabaseConnection createConnection() {
    return DatabaseConnection(ClientDatabase(
      TestMqttClient(),
    ));

  }

  @override
  Future clearDatabaseAndClose(Database db) async {
    await db.close();
  }

  @override
  Future<void> deleteData() async {}
}

class HbExecutor extends TestExecutor {
  @override
  DatabaseConnection createConnection() {
    return DatabaseConnection(HostDatabase(TestMqttHost(NativeDatabase(File('app.db')))));

  }
  @override
  bool get supportsNestedTransactions => true;


  @override
  Future deleteData() async {   
    final file = File('app.db');
    if (await file.exists()) {
      await file.delete();
    }
  }
}
Future<void> main() async {






  // final hostDb = HostDatabase(TestMqttHost(NativeDatabase.memory()));
  // final testDb = NativeDatabase.memory();
  // testDb.runCustom('PRAGMA user_version;');
  // Future.delayed(Duration(seconds: 1));
  // final hostDb =  TestDatabase(HostDatabase(TestMqttHost(NativeDatabase.memory())));
  // final clientDb = TestDatabase(ClientDatabase(TestMqttClient()));
  // await hostDb.select(hostDb.todoItems).get();
  // hostDb.allItems.listen((event) {
  //   print('Todo-item in database: $event');
  // });
  // runAllTests(HbExecutor());
  final hostExec = HbExecutor();
  final db = Database(hostExec.createConnection());
  final a = await db.getUserById(1);
  final nb = NbExecutor();
  // runAllTests(NbExecutor());
  //
  // MqttServerImpl  server = MqttServerImpl(NativeDatabase.memory(), true, true);
  // server.serve(MqttStream(hostExec.client, 'drift_server'));
  // MqttDriftClient client = MqttDriftClient(MqttStream(nb.client, 'drift_client'),true,true,true);
  //
  // runAllTests(server);

}
