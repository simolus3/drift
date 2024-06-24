@TestOn('vm')
library;

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
    final database = EmptyDatabase(driftDatabase(name: 'database'));
    await database.customSelect('SELECT 1').get();

    expect(sqlite3.tempDirectory, d.sandbox);
    await database.close();
  });

  test('uses correct database path', () async {
    final database = EmptyDatabase(driftDatabase(name: 'database'));
    await database.customSelect('SELECT 1').get();

    expect(sqlite3.tempDirectory, d.sandbox);
    await d.dir('applications', [
      d.FileDescriptor.binaryMatcher('database.sqlite', anything),
    ]).validate();
    await database.close();
  });
}

class EmptyDatabase extends GeneratedDatabase {
  EmptyDatabase(super.executor);

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const Iterable.empty();

  @override
  int get schemaVersion => 1;
}
