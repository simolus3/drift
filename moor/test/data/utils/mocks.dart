import 'dart:async';

import 'package:mockito/mockito.dart';
import 'package:moor/moor.dart';
import 'package:moor/src/runtime/executor/stream_queries.dart';

export 'package:mockito/mockito.dart';

class MockExecutor extends Mock implements QueryExecutor {
  final MockTransactionExecutor transactions = MockTransactionExecutor();
  final OpeningDetails openingDetails;

  var _opened = false;

  MockExecutor([this.openingDetails]) {
    when(runSelect(any, any)).thenAnswer((_) {
      assert(_opened);
      return Future.value([]);
    });
    when(runUpdate(any, any)).thenAnswer((_) {
      assert(_opened);
      return Future.value(0);
    });
    when(runDelete(any, any)).thenAnswer((_) {
      assert(_opened);
      return Future.value(0);
    });
    when(runInsert(any, any)).thenAnswer((_) {
      assert(_opened);
      return Future.value(0);
    });
    when(runCustom(any, any)).thenAnswer((_) {
      assert(_opened);
      return Future.value();
    });
    when(beginTransaction()).thenAnswer((_) {
      assert(_opened);
      return transactions;
    });

    when(ensureOpen(any)).thenAnswer((i) async {
      if (!_opened && openingDetails != null) {
        _opened = true;
        await (i.positionalArguments.single as QueryExecutorUser)
            .beforeOpen(this, openingDetails);
      }

      _opened = true;

      return true;
    });

    when(close()).thenAnswer((_) async {
      _opened = false;
    });
  }
}

class MockTransactionExecutor extends Mock implements TransactionExecutor {
  MockTransactionExecutor() {
    when(runSelect(any, any)).thenAnswer((_) => Future.value([]));
    when(runUpdate(any, any)).thenAnswer((_) => Future.value(0));
    when(runDelete(any, any)).thenAnswer((_) => Future.value(0));
    when(runInsert(any, any)).thenAnswer((_) => Future.value(0));
    when(ensureOpen(any)).thenAnswer((_) => Future.value());

    when(send()).thenAnswer((_) => Future.value(null));
    when(rollback()).thenAnswer((_) => Future.value(null));
  }
}

class MockStreamQueries extends Mock implements StreamQueryStore {}

DatabaseConnection createConnection(QueryExecutor executor,
    [StreamQueryStore streams]) {
  return DatabaseConnection(
      SqlTypeSystem.defaultInstance, executor, streams ?? StreamQueryStore());
}
