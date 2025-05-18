import 'package:drift/connections/sqlite/native.dart';
import 'package:drift/dialect/sqlite.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart' hide Table;
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Regression test for https://github.com/simolus3/drift/issues/3323

  late _EmptyDatabase db;
  setUp(() {
    db = _EmptyDatabase(DriftConnection(
      dialect: const SqliteDialect(),
      openConnection: () => NativeDatabase.memoryImplementation(),
      closeStreamsSynchronously: true,
    ));
  });
  tearDown(() {
    db.close();
  });

  testWidgets('can close streams implicitly', (tester) async {
    await tester.pumpWidget(_MyApp(db));

    while (find.text('loading').tryEvaluate()) {
      await tester.pumpAndSettle();
    }
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
            if (!snapshot.hasData) {
              return Text('loading');
            }

            final items = snapshot.data ?? const [];
            return ListView(
              children: items
                  .map((item) => ListTile(title: Text(item.row.toString())))
                  .toList(),
            );
          },
        ),
      ),
    );
  }
}

final class _EmptyDatabase extends GeneratedDatabase {
  _EmptyDatabase(super.implementation);

  @override
  Iterable<DatabaseSchemaEntity> get allSchemaEntities =>
      const Iterable.empty();

  @override
  int get schemaVersion => 1;
}
