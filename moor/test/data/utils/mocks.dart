import 'dart:async';

// ignore: import_of_legacy_library_into_null_safe
import 'package:mockito/annotations.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:mockito/mockito.dart';
import 'package:moor/moor.dart';
import 'package:moor/src/runtime/executor/stream_queries.dart';

import 'mocks.mocks.dart';
export 'mocks.mocks.dart';

@GenerateMocks(
  [],
  customMocks: [
    MockSpec<QueryExecutor>(as: #MockExecutorInternal),
    MockSpec<TransactionExecutor>(as: #MockTransactionsInternal),
    MockSpec<StreamQueryStore>(
        as: #MockStreamQueries, returnNullOnMissingStub: true)
  ],
)
// ignore: unused_element
void _pleaseGenerateMocks() {
  // needed so that mockito generates classes for us.
}

class MockExecutor extends MockExecutorInternal {
  final MockTransactionExecutor transactions = MockTransactionExecutor();
  final OpeningDetails? openingDetails;
  bool _opened = false;

  MockExecutor([this.openingDetails]) {
    when(dialect).thenReturn(SqlDialect.sqlite);
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
    when(runBatched(any)).thenAnswer((_) {
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
            .beforeOpen(this, openingDetails!);
      }

      _opened = true;

      return true;
    });

    when(close()).thenAnswer((_) async {
      _opened = false;
    });
  }
}

class MockTransactionExecutor extends MockTransactionsInternal {
  MockTransactionExecutor() {
    when(dialect).thenReturn(SqlDialect.sqlite);
    when(runSelect(any, any)).thenAnswer((_) => Future.value([]));
    when(runUpdate(any, any)).thenAnswer((_) => Future.value(0));
    when(runDelete(any, any)).thenAnswer((_) => Future.value(0));
    when(runInsert(any, any)).thenAnswer((_) => Future.value(0));
    when(runCustom(any, any)).thenAnswer((_) => Future.value());
    when(runBatched(any)).thenAnswer((_) => Future.value());
    when(ensureOpen(any)).thenAnswer((_) => Future.value(true));

    when(send()).thenAnswer((_) => Future.value(null));
    when(rollback()).thenAnswer((_) => Future.value(null));
  }
}

DatabaseConnection createConnection(QueryExecutor executor,
    [StreamQueryStore? streams]) {
  return DatabaseConnection(
      SqlTypeSystem.defaultInstance, executor, streams ?? StreamQueryStore());
}
