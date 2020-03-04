import 'package:moor/moor.dart';
import 'package:moor_generator/src/analyzer/runner/results.dart';
import 'package:moor_generator/src/services/find_stream_update_rules.dart';
@Tags(['analyzer'])
import 'package:test/test.dart';

import '../analyzer/utils.dart';

void main() {
  test('finds update rules for triggers', () async {
    final state = TestState.withContent({
      'foo|lib/a.moor': '''
CREATE TABLE users (
  id INTEGER NOT NULL PRIMARY KEY,
  name VARCHAR NOT NULL
);

CREATE TRIGGER add_angry_user
   AFTER INSERT ON users
   WHEN new.name != UPPER(new.name)
BEGIN
  INSERT INTO users (name) VALUES (UPPER(new.name));
END;
      ''',
      'foo|lib/main.dart': '''
import 'package:moor/moor.dart';

@UseMoor(include: {'a.moor'})
class MyDatabase {}      
      '''
    });

    final file = await state.analyze('package:foo/main.dart');
    final db = (file.currentResult as ParsedDartFile).declaredDatabases.single;

    final rules = FindStreamUpdateRules(db).identifyRules();

    expect(rules.rules, hasLength(1));
    expect(
      rules.rules.single,
      isA<WritePropagation>()
          .having((e) => e.onTable, 'onTable', 'users')
          .having((e) => e.updates, 'updates', {'users'}),
    );
  });
}
