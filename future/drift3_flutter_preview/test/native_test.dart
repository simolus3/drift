@TestOn('vm')
library;

import 'package:drift3_preview/drift.dart';
import 'package:drift3_preview/internal/versioned_schema.dart';
import 'package:drift3_flutter_preview/drift_flutter.dart';
import 'package:drift3_flutter_preview/src/native.dart'
    show hasConfiguredSqlite;
import 'package:drift_sqlite/drift_sqlite.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(pathProviderChannel, (call) async {
        return switch (call.method) {
          'getTemporaryDirectory' => d.sandbox,
          'getApplicationDocumentsDirectory' => d.path('applications'),
          'getApplicationSupportDirectory' => d.path('support'),
          _ => throw UnsupportedError('Unexpected path provider call: $call'),
        };
      });

  setUp(() => hasConfiguredSqlite = false);

  test('sets sqlite cachebase', () async {
    final database = SimpleDatabase(driftDatabase(name: 'database'));
    await database.customSelect('SELECT 1').get();

    expect(sqlite3.tempDirectory, d.sandbox);
    await database.close();
  });

  test('uses correct database path', () async {
    final database = SimpleDatabase(driftDatabase(name: 'database'));
    await database.customSelect('SELECT 1').get();

    expect(sqlite3.tempDirectory, d.sandbox);
    await d.dir('applications', [
      d.FileDescriptor.binaryMatcher('database.sqlite', anything),
    ]).validate();
    await database.close();
  });

  test('can use custom database path', () async {
    final database = SimpleDatabase(
      driftDatabase(
        name: 'database',
        native: DriftNativeOptions(
          databasePath: () async => d.path('my_dir/custom_file'),
        ),
      ),
    );
    await database.customSelect('SELECT 1').get();

    expect(sqlite3.tempDirectory, d.sandbox);
    await d.dir('my_dir', [
      d.FileDescriptor.binaryMatcher('custom_file', anything),
    ]).validate();
    await database.close();
  });

  test('can use custom database directory', () async {
    final database = SimpleDatabase(
      driftDatabase(
        name: 'database',
        native: DriftNativeOptions(
          databaseDirectory: getApplicationSupportDirectory,
        ),
      ),
    );
    await database.customSelect('SELECT 1').get();

    expect(sqlite3.tempDirectory, d.sandbox);
    await d.dir('support', [
      d.FileDescriptor.binaryMatcher('database.sqlite', anything),
    ]).validate();
    await database.close();
  });

  test('forbids passing custom directory and custom path', () async {
    expect(
      () => SimpleDatabase(
        driftDatabase(
          name: 'database',
          native: DriftNativeOptions(
            databasePath: () async => d.path('my_dir/custom_file'),
            databaseDirectory: getApplicationSupportDirectory,
          ),
        ),
      ),
      throwsAssertionError,
    );
  });

  test('can use custom temporary directory', () async {
    final database = SimpleDatabase(
      driftDatabase(
        name: 'database',
        native: DriftNativeOptions(tempDirectoryPath: () async => '/tmp/'),
      ),
    );
    await database.customSelect('SELECT 1').get();

    expect(sqlite3.tempDirectory, '/tmp/');
    await database.close();
  });

  test('can use setup', () async {
    final database = SimpleDatabase(
      driftDatabase(
        name: 'database',
        native: DriftNativeOptions(
          setup: (db, {required bool isWriter}) => db.createFunction(
            functionName: 'hello_dart',
            function: (_) => 'Hello from Dart!',
          ),
        ),
      ),
    );
    addTearDown(database.close);

    final [row] = await database
        .customSelect('SELECT hello_dart() as r;')
        .get();
    expect(row.row, ['Hello from Dart!']);
  }, skip: 'Custom functions are no longer supported');

  group('works with widget tests', () {
    // Regression test for https://github.com/simolus3/drift/issues/3556
    late SimpleDatabase db;

    setUp(() async {
      db = SimpleDatabase(
        DriftConnection(
          dialect: SqliteDialect.new,
          openConnection: () async => SqliteConnection(sqlite3.openInMemory()),
          closeStreamsSynchronously: true,
        ),
      );
    });

    tearDown(() async {
      await db.close();
      await db.close();
    });

    testWidgets('when closing', (tester) async {
      await db.customSelect('SELECT 1').get();

      tester.runAsync(() async {
        await db.close();
      });
    });

    testWidgets('for joins', (tester) async {
      // Regression test for https://github.com/simolus3/drift/issues/3779
      await (db.select(db.simpleTable)).get();

      await (db.selectOnly(db.simpleTable)..addColumns([Literal(1)])).get();
    });
  });
}

final class SimpleDatabase extends GeneratedDatabase {
  SimpleDatabase(super.implementation);

  late final simpleTable = VersionedTable(
    entityName: 'users',
    isStrict: true,
    withoutRowId: false,
    columns: [
      (name) => TableColumn(
        name: 'id',
        sqlType: .int,
        requiredDuringInsert: false,
        constraints: () => const [
          ColumnNotNullConstraint(),
          ColumnPrimaryKeyConstraint(isAutoIncrementing: true),
        ],
      ),
    ],
    tableConstraints: const [],
  );

  @override
  int get schemaVersion => 1;

  @override
  DatabaseSchema get schema => DatabaseSchema([simpleTable]);
}
