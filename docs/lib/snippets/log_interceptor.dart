import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

// #docregion class
class LogInterceptor extends QueryInterceptor {
  Future<T> _run<T>(
      String description, FutureOr<T> Function() operation) async {
    final stopwatch = Stopwatch()..start();
    print('Running $description');

    try {
      final result = await operation();
      print(' => succeeded after ${stopwatch.elapsedMilliseconds}ms');
      return result;
    } on Object catch (e) {
      print(' => failed after ${stopwatch.elapsedMilliseconds}ms ($e)');
      rethrow;
    }
  }

  @override
  TransactionExecutor beginTransaction(QueryExecutor parent) {
    print('begin');
    return super.beginTransaction(parent);
  }

  @override
  Future<void> commitTransaction(TransactionExecutor inner) {
    return _run('commit', () => inner.send());
  }

  @override
  Future<void> rollbackTransaction(TransactionExecutor inner) {
    return _run('rollback', () => inner.rollback());
  }

  @override
  Future<void> runBatched(
      QueryExecutor executor, BatchedStatements statements) {
    return _run(
        'batch with $statements', () => executor.runBatched(statements));
  }

  @override
  Future<int> runInsert(
      QueryExecutor executor, String statement, List<Object?> args) {
    return _run(
        '$statement with $args', () => executor.runInsert(statement, args));
  }

  @override
  Future<int> runUpdate(
      QueryExecutor executor, String statement, List<Object?> args) {
    return _run(
        '$statement with $args', () => executor.runUpdate(statement, args));
  }

  @override
  Future<int> runDelete(
      QueryExecutor executor, String statement, List<Object?> args) {
    return _run(
        '$statement with $args', () => executor.runDelete(statement, args));
  }

  @override
  Future<void> runCustom(
      QueryExecutor executor, String statement, List<Object?> args) {
    return _run(
        '$statement with $args', () => executor.runCustom(statement, args));
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(
      QueryExecutor executor, String statement, List<Object?> args) {
    return _run(
        '$statement with $args', () => executor.runSelect(statement, args));
  }
}
// #enddocregion class

void use() {
  final myDatabaseFile = File('/dev/null');

  // #docregion use
  NativeDatabase.createInBackground(
    myDatabaseFile,
  ).interceptWith(LogInterceptor());
  // #enddocregion use
}
