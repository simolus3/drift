@TestOn('vm')
library;

import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:async/async.dart';
import 'package:drift/drift.dart';
import 'package:drift/internal/versioned_schema.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:drift_flutter/src/native.dart'
    show hasConfiguredSqlite, portName;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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
      _ => throw UnsupportedError('Unexpected path provider call: $call')
    };
  });

  test('sets sqlite cachebase', () async {
    hasConfiguredSqlite = false;
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

  group('shared between isolates', () {
    const options = DriftNativeOptions(shareAcrossIsolates: true);

    test('synchronizes streams', () async {
      final database =
          SimpleDatabase(driftDatabase(name: 'database', native: options));
      final stream = StreamQueue(database.simpleTable.all().watch());
      await expectLater(stream, emits(isEmpty));

      // Insert with an independent connection on another isolate.
      await Isolate.run(() async {
        // Setting up a background isolate messenger here crashes because
        // the mock method call handler implementation uses closures, which
        // can't directly be invoked from other isolates.
        // So, skip the setup!
        hasConfiguredSqlite = true;

        final database =
            SimpleDatabase(driftDatabase(name: 'database', native: options));
        await database.simpleTable.insertOne(RawValuesInsertable({}));
        await database.close();
      });

      // Should be reflected here!
      await expectLater(stream, emits(hasLength(1)));
      await database.close();
    });

    test('closes database after clients disconnect', () async {
      final database =
          SimpleDatabase(driftDatabase(name: 'database', native: options));
      await database.customStatement('SELECT 1'); // make sure it's open

      await Isolate.run(() async {
        hasConfiguredSqlite = true;

        final database =
            SimpleDatabase(driftDatabase(name: 'database', native: options));
        await database.customStatement('SELECT 1'); // make sure it's open
        await database.close();
      });

      await database.customStatement('BEGIN EXCLUSIVE');
      await database.close();

      // Wait for the drift isolate to shut down
      while (IsolateNameServer.lookupPortByName(portName('database')) != null) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      final raw = SimpleDatabase(
          NativeDatabase(File(d.path('applications/database.sqlite'))));
      // This wouldn't work if the database is still open, as the exclusive
      // would block the write.
      await raw.simpleTable.insertOne(RawValuesInsertable({}));
    });
  });
}

class SimpleDatabase extends GeneratedDatabase {
  SimpleDatabase(super.executor);

  late final simpleTable = VersionedTable(
    entityName: 'users',
    isStrict: true,
    withoutRowId: false,
    attachedDatabase: attachedDatabase,
    columns: [
      (name) => GeneratedColumn(
            'id',
            name,
            false,
            type: DriftSqlType.int,
            requiredDuringInsert: false,
            $customConstraints: 'NOT NULL PRIMARY KEY',
          ),
    ],
    tableConstraints: const [],
  );

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => [simpleTable];

  @override
  int get schemaVersion => 1;
}
