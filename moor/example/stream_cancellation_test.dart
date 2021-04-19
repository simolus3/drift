import 'package:moor/ffi.dart';
import 'package:moor/isolate.dart';
import 'package:moor/moor.dart';
import 'package:test/test.dart';

DatabaseConnection createConnection() =>
    DatabaseConnection.fromExecutor(VmDatabase.memory(logStatements: true));

class EmptyDb extends GeneratedDatabase {
  EmptyDb.connect(DatabaseConnection c) : super.connect(c);
  @override
  final List<TableInfo> allTables = const [];
  @override
  final int schemaVersion = 1;
}

void main() async {
  final isolate = await MoorIsolate.spawn(createConnection);
  final db = EmptyDb.connect(await isolate.connect(isolateDebugLog: true));

  var i = 0;
  String slowQuery() => '''
    with recursive slow(x) as (values(1) union all select x+1 from slow where x < 1000000)
    select ${i++} from slow;
  '''; // ^ to get different `StreamKey`s

  await db.doWhenOpened((e) {});

  final subscriptions = List.generate(
      4, (_) => db.customSelect(slowQuery()).watch().listen(null));
  await pumpEventQueue();
  await Future.wait(subscriptions.map((e) => e.cancel()));

  await db.customSelect('select 1').getSingle();
}
