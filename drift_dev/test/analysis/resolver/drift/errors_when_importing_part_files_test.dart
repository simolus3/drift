@Tags(['analyzer'])
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  test('reports an error when importing a part file into .drift', () async {
    final state = TestBackend.inTest({
      'a|lib/base.dart': '''
      import 'package:drift/drift.dart';

      part 'tables.dart';
      ''',
      'a|lib/tables.dart': '''
      part of 'base.dart';

      class Events extends Table {
        IntColumn get id => integer().autoIncrement()();

        RealColumn get sumVal => real().withDefault(Constant(0))();
      }

      class Records extends Table {
        IntColumn get eventId => integer()();

        RealColumn get value => real().nullable()();
      }
      ''',
      'a|lib/file.drift': '''
    import 'tables.dart';
    ''',
    });

    final file = await state.analyze('package:a/file.drift');
    expect(file.allErrors, [
      isDriftError(contains("does not exist or can't be imported."))
          .withSpan("import 'tables.dart';")
    ]);
  });
}
