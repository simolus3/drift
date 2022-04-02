import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift/remote.dart';
import 'package:stream_channel/stream_channel.dart';

/// This function is used as a [hybrid test] call to use the system's sqlite
/// in browser test.
///
/// To avoid excessive mocking, drift tests run against an actual sqlite3, but
/// getting sqlite3 to run on the browser is a bit of a hassle and most tests
/// exist to test core drift components, not the sqlite3 web implementation.
///
/// While we have separate integration tests to ensure drift works in the
/// browser, unit tests just use a stream channel and a drift remote.
///
/// [hybrid test]: https://pub.dev/packages/test#browservm-hybrid-tests
Future<void> hybridMain(StreamChannel channel) async {
  final connection = DatabaseConnection.fromExecutor(NativeDatabase.memory());
  final server = DriftServer(connection);
  server.serve(channel);
}
