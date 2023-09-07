import 'package:drift_network_bridge/drift_network_bridge.dart';
import 'package:drift_testcases/tests.dart';

Future<void> main() async {
  final gw = MqttDatabaseGateway('127.0.0.1', 'unit_device', 'drift/test_site');
  final remoteDb = Database(await gw.createRemoteConnection());
  try {
    final test = await remoteDb.users.all().get();
    print(test);
  }
  catch(e,stacktrace){
    print(e);
    print(stacktrace);
  }
}
