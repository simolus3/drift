import 'package:moor_generator/src/analyzer/options.dart';
import 'package:moor_generator/src/analyzer/runner/results.dart';
import 'package:moor_generator/src/writer/database_writer.dart';
import 'package:moor_generator/src/writer/writer.dart';
import 'package:test/test.dart';

import '../analyzer/utils.dart';

void main() {
  test('does not generate multiple converters for the same enum', () async {
    final state = TestState.withContent({
      'foo|lib/a.dart': '''
        import 'package:moor/moor.dart';
        
        enum MyEnum { foo, bar, baz }
        
        class TableA extends Table {
          IntColumn get col => intEnum<MyEnum>()();
        }
        
        class TableB extends Table {
          IntColumn get another => intEnum<MyEnum>()();
        }
        
        @UseMoor(tables: [TableA, TableB])
        class Database {
        
        }
      ''',
    });

    final file = await state.analyze('package:foo/a.dart');
    final db = (file.currentResult as ParsedDartFile).declaredDatabases.single;

    final writer = Writer(const MoorOptions());
    DatabaseWriter(db, writer.child()).write();

    expect(
      writer.writeGenerated(),
      allOf(
        contains(r'_$GeneratedConverter$0'),
        isNot(contains(r'_$GeneratedConverter$1')),
      ),
    );
  });
}
