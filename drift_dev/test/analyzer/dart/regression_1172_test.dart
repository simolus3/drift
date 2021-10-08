// @dart=2.9
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  test('can define abstract tables', () async {
    final test = TestState.withContent({
      'a|lib/main.dart': '''
import 'package:moor/moor.dart';

abstract class CategoriesTable extends Table {
  IntColumn get id => integer()();
  IntColumn get parentId => integer().nullable()();
  TextColumn get title => text()();

  @override
  String get tableName;

  @override
  List<String> get customConstraints =>
      ['FOREIGN KEY(parentId) REFERENCES ' + tableName + '(id)'];

  @override
  Set<Column> get primaryKey => {id};
}

class OccurrenceCategoriesTable extends CategoriesTable {
  @override
  String get tableName => 'occurrence_categories';
}

class SocietiesCategoriesTable extends CategoriesTable {
  @override
  String get tableName => 'societies_categories';
}

@UseMoor(tables: [OccurrenceCategoriesTable, SocietiesCategoriesTable])
class Database {}
''',
    });
    addTearDown(test.close);

    final file = await test.analyze('package:a/main.dart');
    expect(file.errors.errors, isEmpty);
  });
}
