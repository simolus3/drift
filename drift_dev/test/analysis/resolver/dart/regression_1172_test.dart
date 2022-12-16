import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  test('can define abstract tables', () async {
    final test = TestBackend.inTest({
      'a|lib/main.dart': '''
import 'package:drift/drift.dart';

abstract class CategoriesTable extends Table {
  IntColumn get id => integer()();
  IntColumn get parentId => integer().nullable()();
  TextColumn get title => text()();

  @override
  String get tableName;

  @override
  Set<Column> get primaryKey => {id};
}

class OccurrenceCategoriesTable extends CategoriesTable {
  @override
  String get tableName => 'occurrence_categories';

  @override
  List<String> get customConstraints =>
      ['FOREIGN KEY(parentId) REFERENCES occurrence_categories(id)'];
}

class SocietiesCategoriesTable extends CategoriesTable {
  @override
  String get tableName => 'societies_categories';

  @override
  List<String> get customConstraints =>
      ['FOREIGN KEY(parentId) REFERENCES societies_categories(id)'];
}

@DriftDatabase(tables: [OccurrenceCategoriesTable, SocietiesCategoriesTable])
class Database {}
''',
    });

    await test.driver.fullyAnalyze(Uri.parse('package:a/main.dart'));
    test.expectNoErrors();
  });
}
