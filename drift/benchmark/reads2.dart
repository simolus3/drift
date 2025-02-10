import 'package:drift/src/connections/connection.dart';
import 'package:drift/src/connections/sqlite3/connection.dart';
import 'package:drift/src/dialect/sqlite.dart';
import 'package:drift/src/query_builder/results.dart';
import 'package:drift/src/query_builder/schema/column.dart';
import 'package:drift/src/query_builder/schema/result_set.dart';
import 'package:drift/src/query_builder/schema/table.dart';
import 'package:drift/src/query_builder/statements/select.dart';
import 'package:drift/src/query_builder/types.dart';
import 'package:drift/src/runtime/database/db_base.dart';
import 'package:sqlite3/sqlite3.dart' show sqlite3;

typedef Item = ({int id, String content});

final class Items extends GeneratedTable<Item, Items> {
  late final SchemaColumn<int> id =
      TableColumn(name: 'id', type: BuiltinDriftType.int.resolveIn)
        ..owningResultSet = this;

  late final SchemaColumn<String> content =
      TableColumn(name: 'content', type: BuiltinDriftType.text.resolveIn)
        ..owningResultSet = this;

  Items({required super.alias}) : super(entityName: 'items');

  @override
  late final List<SchemaColumn<Object>> columns = [id, content];

  @override
  Item? mapToDart(DriftRow row) {
    final columnPositions = row.resultSet.structure.tables[this]!;
    if (row.raw.rawValue(columnPositions[0]) == null) {
      return null; // id is null, table does not exist in row
    }

    return (
      id: row.read(id)!,
      content: row.read(content)!,
    );
  }

  @override
  Items withAlias(String alias) {
    return Items(alias: alias);
  }
}

final class TestDatabase extends GeneratedDatabase {
  TestDatabase(super.implementation);

  @override
  int get schemaVersion => 1;

  @override
  Iterable<dynamic> get allSchemaEntities => [items];

  late final Items items = Items(alias: null);
}

void main() async {
  final connection = SqliteConnection.synchronous(open: () {
    return sqlite3.openInMemory()..execute('''
CREATE TABLE items(
  id INTEGER NOT NULL PRIMARY KEY,
  content TEXT NOT NULL
) STRICT;

WITH RECURSIVE
  cnt(x) AS (VALUES(1) UNION ALL SELECT x+1 FROM cnt WHERE x<1000000)
INSERT INTO items (content) SELECT x FROM cnt;
''');
  });

  final sw = Stopwatch()..start();

  final database = TestDatabase(connection);

  final select = SingleTableSelectStatement(database.items);
  final compiled = dialect.compile(select);

  final rawRows = await connection.execute(SqlStatement(compiled));
  final mappedRows =
      DriftResultSet(select.structure, rawRows.resultSet!, dialect);

  final rows = mappedRows.map((row) => row.readTable(items)).toList();

  print('Selecting ${rows.length}: ${sw.elapsed}');
}
