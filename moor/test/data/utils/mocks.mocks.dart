import 'package:mockito/mockito.dart' as _i1;
import 'package:moor/src/runtime/executor/executor.dart' as _i2;
import 'package:moor/src/runtime/query_builder/query_builder.dart' as _i3;
import 'dart:async' as _i4;
import 'package:moor/src/runtime/executor/stream_queries.dart' as _i5;
import 'package:moor/src/runtime/api/runtime_api.dart' as _i6;

class _FakeType extends _i1.Fake implements Type {}

class _FakeTransactionExecutor extends _i1.Fake
    implements _i2.TransactionExecutor {}

/// A class which mocks [QueryExecutor].
///
/// See the documentation for Mockito's code generation for more information.
class MockExecutorInternal extends _i1.Mock implements _i2.QueryExecutor {
  MockExecutorInternal() {
    _i1.throwOnMissingStub(this);
  }

  _i3.SqlDialect get dialect =>
      super.noSuchMethod(Invocation.getter(#dialect), _i3.SqlDialect.sqlite);
  int get hashCode => super.noSuchMethod(Invocation.getter(#hashCode), 0);
  Type get runtimeType =>
      super.noSuchMethod(Invocation.getter(#runtimeType), _FakeType());
  _i4.Future<bool> ensureOpen(_i2.QueryExecutorUser? user) =>
      super.noSuchMethod(
          Invocation.method(#ensureOpen, [user]), Future.value(false));
  _i4.Future<List<Map<String, Object?>>> runSelect(
          String? statement, List<Object?>? args) =>
      super.noSuchMethod(Invocation.method(#runSelect, [statement, args]),
          Future.value(<Map<String, Object?>>[]));
  _i4.Future<int> runInsert(String? statement, List<Object?>? args) =>
      super.noSuchMethod(
          Invocation.method(#runInsert, [statement, args]), Future.value(0));
  _i4.Future<int> runUpdate(String? statement, List<Object?>? args) =>
      super.noSuchMethod(
          Invocation.method(#runUpdate, [statement, args]), Future.value(0));
  _i4.Future<int> runDelete(String? statement, List<Object?>? args) =>
      super.noSuchMethod(
          Invocation.method(#runDelete, [statement, args]), Future.value(0));
  _i4.Future<void> runCustom(String? statement, [List<Object?>? args]) =>
      super.noSuchMethod(
          Invocation.method(#runCustom, [statement, args]), Future.value(null));
  _i4.Future<void> runBatched(_i2.BatchedStatements? statements) =>
      super.noSuchMethod(
          Invocation.method(#runBatched, [statements]), Future.value(null));
  _i2.TransactionExecutor beginTransaction() => super.noSuchMethod(
      Invocation.method(#beginTransaction, []), _FakeTransactionExecutor());
  _i4.Future<void> close() =>
      super.noSuchMethod(Invocation.method(#close, []), Future.value(null));
  bool operator ==(Object? other) =>
      super.noSuchMethod(Invocation.method(#==, [other]), false);
  String toString() => super.noSuchMethod(Invocation.method(#toString, []), '');
}

/// A class which mocks [TransactionExecutor].
///
/// See the documentation for Mockito's code generation for more information.
class MockTransactionsInternal extends _i1.Mock
    implements _i2.TransactionExecutor {
  MockTransactionsInternal() {
    _i1.throwOnMissingStub(this);
  }

  _i3.SqlDialect get dialect =>
      super.noSuchMethod(Invocation.getter(#dialect), _i3.SqlDialect.sqlite);
  int get hashCode => super.noSuchMethod(Invocation.getter(#hashCode), 0);
  Type get runtimeType =>
      super.noSuchMethod(Invocation.getter(#runtimeType), _FakeType());
  _i4.Future<void> send() =>
      super.noSuchMethod(Invocation.method(#send, []), Future.value(null));
  _i4.Future<void> rollback() =>
      super.noSuchMethod(Invocation.method(#rollback, []), Future.value(null));
  _i4.Future<bool> ensureOpen(_i2.QueryExecutorUser? user) =>
      super.noSuchMethod(
          Invocation.method(#ensureOpen, [user]), Future.value(false));
  _i4.Future<List<Map<String, Object?>>> runSelect(
          String? statement, List<Object?>? args) =>
      super.noSuchMethod(Invocation.method(#runSelect, [statement, args]),
          Future.value(<Map<String, Object?>>[]));
  _i4.Future<int> runInsert(String? statement, List<Object?>? args) =>
      super.noSuchMethod(
          Invocation.method(#runInsert, [statement, args]), Future.value(0));
  _i4.Future<int> runUpdate(String? statement, List<Object?>? args) =>
      super.noSuchMethod(
          Invocation.method(#runUpdate, [statement, args]), Future.value(0));
  _i4.Future<int> runDelete(String? statement, List<Object?>? args) =>
      super.noSuchMethod(
          Invocation.method(#runDelete, [statement, args]), Future.value(0));
  _i4.Future<void> runCustom(String? statement, [List<Object?>? args]) =>
      super.noSuchMethod(
          Invocation.method(#runCustom, [statement, args]), Future.value(null));
  _i4.Future<void> runBatched(_i2.BatchedStatements? statements) =>
      super.noSuchMethod(
          Invocation.method(#runBatched, [statements]), Future.value(null));
  _i2.TransactionExecutor beginTransaction() => super.noSuchMethod(
      Invocation.method(#beginTransaction, []), _FakeTransactionExecutor());
  _i4.Future<void> close() =>
      super.noSuchMethod(Invocation.method(#close, []), Future.value(null));
  bool operator ==(Object? other) =>
      super.noSuchMethod(Invocation.method(#==, [other]), false);
  String toString() => super.noSuchMethod(Invocation.method(#toString, []), '');
}

/// A class which mocks [StreamQueryStore].
///
/// See the documentation for Mockito's code generation for more information.
class MockStreamQueries extends _i1.Mock implements _i5.StreamQueryStore {
  int get hashCode => super.noSuchMethod(Invocation.getter(#hashCode), 0);
  Type get runtimeType =>
      super.noSuchMethod(Invocation.getter(#runtimeType), _FakeType());
  _i4.Stream<T> registerStream<T>(_i5.QueryStreamFetcher<T>? fetcher) =>
      super.noSuchMethod(
          Invocation.method(#registerStream, [fetcher]), Stream<T>.empty());
  _i4.Stream<Null?> updatesForSync(_i6.TableUpdateQuery? query) =>
      super.noSuchMethod(
          Invocation.method(#updatesForSync, [query]), Stream<Null?>.empty());
  void handleTableUpdates(Set<_i6.TableUpdate>? updates) =>
      super.noSuchMethod(Invocation.method(#handleTableUpdates, [updates]));
  void markAsClosed(
          _i5.QueryStream<dynamic>? stream, dynamic Function()? whenRemoved) =>
      super.noSuchMethod(
          Invocation.method(#markAsClosed, [stream, whenRemoved]));
  void markAsOpened(_i5.QueryStream<dynamic>? stream) =>
      super.noSuchMethod(Invocation.method(#markAsOpened, [stream]));
  _i4.Future<void> close() =>
      super.noSuchMethod(Invocation.method(#close, []), Future.value(null));
  bool operator ==(Object? other) =>
      super.noSuchMethod(Invocation.method(#==, [other]), false);
  String toString() => super.noSuchMethod(Invocation.method(#toString, []), '');
}
