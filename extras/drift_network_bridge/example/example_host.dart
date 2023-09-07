import 'package:drift/native.dart';
import 'package:drift_network_bridge/drift_network_bridge.dart';
import 'package:drift_testcases/tests.dart';

Future<void> main() async {
  final db = Database(DatabaseConnection(NativeDatabase.memory(logStatements: true)));
  final gate = MqttDatabaseGateway('127.0.0.1', 'unit_device', 'drift/test_site');
  await gate.serve(db);
}
