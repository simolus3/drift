import 'dart:isolate';

import 'package:drift/connections/isolate.dart';
import 'package:drift/drift.dart';
import 'package:drift/src/connections/sqlite3/connection.dart';
import 'package:mockito/mockito.dart';
import 'package:sqlite3/common.dart' as sqlite;

import 'test_utils.dart';

void main(List<String> args, SendPort message) {
  spawnIsolate(message);
}

void spawnIsolate(SendPort sendConnectPortTo) async {
  final isolate = DriftIsolate.inCurrent(
    () {
      final executor = MockSession();
      when(executor.execute(any)).thenAnswer((i) async {
        final args = i.positionalArguments[1];
        return QueryResult(
          resultSet: SqliteResultSet(
              resultSet: sqlite.ResultSet(['a'], null, [args as List])),
        );
      });

      return createConnection(executor);
    },
    shutdownAfterLastDisconnect: true,
    killIsolateWhenDone: true,
  );

  sendConnectPortTo.send(isolate.connectPort);
}
