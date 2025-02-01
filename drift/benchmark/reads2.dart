import 'package:drift/core.dart';
import 'package:drift/src/connections/sqlite3/connection.dart';
import 'package:drift/src/core/statements/select.dart';
import 'package:drift/src/dialect/sqlite.dart';
import 'package:sqlite3/sqlite3.dart' show sqlite3;

import 'reads.dart';

final class Items extends ResultSet<Item, Items> {
  late final SchemaColumn<int> id =
      TableColumn(name: 'id', type: BuiltinDriftType.int.resolveIn)
        ..owningResultSet = this;

  late final SchemaColumn<String> content =
      TableColumn(name: 'content', type: BuiltinDriftType.text.resolveIn)
        ..owningResultSet = this;

  Items({required super.alias}) : super(name: 'items');

  @override
  late final List<SchemaColumn<Object>> columns = [id, content];

  @override
  Item? mapToDart(DriftRow row) {
    final columnPositions = row.resultSet.structure.tables[this]!;
    if (row.raw.rawValue(columnPositions[0]) == null) {
      return null; // id is null, table does not exist in row
    }

    return Item(
      id: row.read(id)!,
      content: row.read(content)!,
    );
  }

  @override
  Items withAlias(String alias) {
    return Items(alias: alias);
  }
}

void main() async {
  final connection = SqliteConnection(sqlite3.openInMemory()..execute('''
CREATE TABLE items(
  id INTEGER NOT NULL PRIMARY KEY,
  content TEXT NOT NULL
) STRICT;

WITH RECURSIVE
  cnt(x) AS (VALUES(1) UNION ALL SELECT x+1 FROM cnt WHERE x<1000000)
INSERT INTO items (content) SELECT x FROM cnt;
'''));

  final sw = Stopwatch()..start();

  final dialect = SqliteDialect();
  final items = Items(alias: null);
  final select = SingleTableSelectStatement(items);
  final compiled = dialect.compile(select);

  final rawRows = await connection.execute(compiled);
  final mappedRows = DriftResultSet(select.structure, rawRows, dialect);

  final rows = mappedRows.map((row) => row.readTable(items)).toList();

  print('Selecting ${rows.length}: ${sw.elapsed}');
}
