import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'reads.g.dart';

class Items extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get content => text()();
}

@DriftDatabase(tables: [Items])
final class BenchmarkReadsDatabase extends _$BenchmarkReadsDatabase {
  BenchmarkReadsDatabase(super.e);

  @override
  int get schemaVersion => 1;
}

void main() async {
  final db = BenchmarkReadsDatabase(NativeDatabase.memory());
  await db.customStatement('''
WITH RECURSIVE
  cnt(x) AS (VALUES(1) UNION ALL SELECT x+1 FROM cnt WHERE x<1000000)
INSERT INTO items (content) SELECT x FROM cnt;
''');

  print('has items');
  final sw = Stopwatch()..start();
  final items = await db.items.all().get();
  sw.stop();

  print('Selecting ${items.length}: ${sw.elapsed}');
}
