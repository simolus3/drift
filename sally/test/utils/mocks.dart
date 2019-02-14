import 'package:mockito/mockito.dart';
import 'package:sally/sally.dart';
import 'package:sally/src/runtime/executor/stream_queries.dart';

export 'package:mockito/mockito.dart';

class MockExecutor extends Mock implements QueryExecutor {
  MockExecutor() {
    when(runSelect(any, any)).thenAnswer((_) => Future.value([]));
    when(runUpdate(any, any)).thenAnswer((_) => Future.value(0));
    when(runDelete(any, any)).thenAnswer((_) => Future.value(0));
    when(runInsert(any, any)).thenAnswer((_) => Future.value(0));
  }
}

class MockStreamQueries extends Mock implements StreamQueryStore {}

// used so that we can mock the SqlExecutor typedef
abstract class SqlExecutorAsClass {
  Future<void> call(String sql);
}

class MockQueryExecutor extends Mock implements SqlExecutorAsClass {}
