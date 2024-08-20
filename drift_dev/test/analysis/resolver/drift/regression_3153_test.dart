import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  test('does not include private superclasses reached via .drift', () async {
    final backend = await TestBackend.inTest({
      'a|lib/database.dart': '''
import 'package:drift/drift.dart';
import 'tables.dart';

@DriftDatabase(include: {'test.drift'}, tables: [PartOfDatabase])
class Database {}
''',
      'a|lib/tables.dart': '''
import 'package:drift/drift.dart';

class PartOfDatabase extends _AlsoNotPartOfDatabase {

}

class _NotPartOfDatabase extends Table {
  IntColumn get id => integer()();
}

@DataClassName('AlsoNotPartOfDatabase')
class _AlsoNotPartOfDatabase extends _NotPartOfDatabase {
  IntColumn get id => integer()();
}

''',
      'a|lib/test.drift': '''
import 'tables.dart';
''',
    });

    final state = await backend.analyze('package:a/database.dart');
    backend.expectNoErrors();

    final database = state.fileAnalysis!.resolvedDatabases.values.single;
    
    expect(database.availableElements, hasLength(1));
    expect(database.availableElements.first.declaration.name, equals('PartOfDatabase'));
  });
}
