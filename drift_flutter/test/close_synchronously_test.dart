import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:material_ui/material_ui.dart' hide Table;
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Regression test for https://github.com/simolus3/drift/issues/3323

  late _EmptyDatabase db;
  setUp(() {
    db = _EmptyDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
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
                  .map((item) => ListTile(title: Text(item.data.toString())))
                  .toList(),
            );
          },
        ),
      ),
    );
  }
}

class _EmptyDatabase extends GeneratedDatabase {
  _EmptyDatabase(super.executor);

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  int get schemaVersion => 1;
}
