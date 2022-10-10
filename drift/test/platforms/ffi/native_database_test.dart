@TestOn('vm')
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

import '../../test_utils/database_vm.dart';

void main() {
  preferLocalSqlite3();

  group('NativeDatabase.opened', () {
    test('disposes the underlying database by default', () async {
      final underlying = sqlite3.openInMemory();
      final db = NativeDatabase.opened(underlying);
      await db.ensureOpen(_FakeExecutorUser());
      await db.close();

      expect(() => underlying.execute('SELECT 1'), throwsStateError);
    });

    test('can avoid disposing the underlying instance', () async {
      final underlying = sqlite3.openInMemory();
      final db =
          NativeDatabase.opened(underlying, closeUnderlyingOnClose: false);
      await db.ensureOpen(_FakeExecutorUser());
      await db.close();

      expect(() => underlying.execute('SELECT 1'), isNot(throwsA(anything)));
      underlying.dispose();
    });
  });

  group('checks for trailing statement content', () {
    late NativeDatabase db;

    setUp(() async {
      db = NativeDatabase.memory();
      await db.ensureOpen(_FakeExecutorUser());
    });

    tearDown(() => db.close());

    test('multiple statements are allowed for runCustom without args', () {
      return db.runCustom('SELECT 1; SELECT 2;');
    });

    test('throws for runCustom with args', () async {
      expect(db.runCustom('SELECT ?; SELECT ?;', [1, 2]), throwsArgumentError);
    });

    test('in runSelect', () async {
      expect(db.runSelect('SELECT ?; SELECT ?;', [1, 2]), throwsArgumentError);
    });

    test('in runBatched', () {
      expect(
        db.runBatched(BatchedStatements([
          'SELECT ?; SELECT ?;'
        ], [
          ArgumentsForBatchedStatement(0, []),
        ])),
        throwsArgumentError,
      );
    });
  });
}

class _FakeExecutorUser extends QueryExecutorUser {
  @override
  Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) {
    return Future.value();
  }

  @override
  int get schemaVersion => 1;
}
