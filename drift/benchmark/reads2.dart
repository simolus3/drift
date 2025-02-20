import 'package:drift/src/connections/sqlite3/connection.dart';
import 'package:drift/src/dsl/columns.dart';
import 'package:drift/src/dsl/table.dart';
import 'package:drift/src/query_builder/results.dart';
import 'package:drift/src/query_builder/schema/column.dart';
import 'package:drift/src/query_builder/schema/entities.dart';
import 'package:drift/src/query_builder/schema/result_set.dart';
import 'package:drift/src/query_builder/schema/table.dart';
import 'package:drift/src/query_builder/statements/select.dart';
import 'package:drift/src/query_builder/types.dart';
import 'package:drift/src/runtime/database/db_base.dart';
import 'package:sqlite3/sqlite3.dart' show sqlite3;

typedef Item = ({int id, String content});

abstract class Items extends Table {
  IntColumn get id => integer().autoIncrement();
  TextColumn get content => text();
}

final class $Items extends Items
    with ResultSet<Item, $Items>
    implements GeneratedTable<Item, $Items> {
  late final SchemaColumn<int> id =
      TableColumn(name: 'id', type: BuiltinDriftType.int.resolveIn)
        ..owningResultSet = this;

  late final SchemaColumn<String> content =
      TableColumn(name: 'content', type: BuiltinDriftType.text.resolveIn)
        ..owningResultSet = this;

  @override
  final String? alias;

  $Items({this.alias});

  @override
  String get entityName => 'items';

  @override
  late final List<SchemaColumn<Object>> columns = [id, content];

  @override
  Item? Function(DriftRow) createMapperToDart(DriftResultSet resultSet) {
    final columnPositions = resultSet.structure.tables[this]!;
    final nullCheck = columnPositions[0];
    final boundId = resultSet.bindExpression(id);
    final boundContent = resultSet.bindExpression(content);

    return (row) {
      if (row.raw.rawValue(nullCheck) == null) {
        return null; // id is null, table does not exist in row
      }

      return (
        id: boundId(row)!,
        content: boundContent(row)!,
      );
    };
  }

  @override
  Item? mapToDart(DriftRow row) {
    throw 'should use mapper';
  }

  @override
  $Items asSelfType() => this;

  @override
  $Items withAlias(String alias) {
    return $Items(alias: alias);
  }
}

final class TestDatabase extends GeneratedDatabase {
  TestDatabase(super.implementation);

  @override
  int get schemaVersion => 1;

  @override
  Iterable<DatabaseSchemaEntity> get allSchemaEntities => [items];

  late final $Items items = $Items(alias: null);
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

  final select = SingleTableSelectStatement(database, database.items);
  final rows = await select.get();

  print('Selecting ${rows.length}: ${sw.elapsed}');
}
