import 'package:drift3_preview/drift.dart';
import 'package:drift_sqlite/drift_sqlite.dart';
import 'package:flutter/material.dart' hide Table;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  // Regression test for https://github.com/simolus3/drift/issues/3323

  late _EmptyDatabase db;
  setUp(() {
    db = _EmptyDatabase(
      DriftConnection(
        dialect: SqliteDialect.new,
        openConnection: () async => SqliteConnection(sqlite3.openInMemory()),
        closeStreamsSynchronously: true,
      ),
    );
  });
  tearDown(() {
    db.close();
  });

  testWidgets('can close streams implicitly', (tester) async {
    await tester.pumpWidget(_MyApp(db));
  });
}

class _MyApp extends StatefulWidget {
  const _MyApp(this.db);
  final _EmptyDatabase db;

  @override
  State<_MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<_MyApp> {
  late final stream = widget.db.customSelect('SELECT 1;').watch();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: Scaffold(
        body: StreamBuilder(
          stream: stream,
          builder: (context, snapshot) {
            final items = snapshot.data ?? const [];
            return ListView(
              children: items
                  .map((item) => ListTile(title: Text(item.row[0].toString())))
                  .toList(),
            );
          },
        ),
      ),
    );
  }
}

final class _EmptyDatabase extends GeneratedDatabase {
  _EmptyDatabase(super.executor);

  @override
  DatabaseSchema get schema => const DatabaseSchema([]);

  @override
  int get schemaVersion => 1;
}
