//@dart=2.9
@Tags(['analyzer'])
import 'package:drift_dev/src/analyzer/errors.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  test('reports an error when importing a part file into .moor', () async {
    final state = TestState.withContent({
      'a|lib/base.dart': '''
      import 'package:moor/moor.dart';

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
      'a|lib/file.moor': '''
    import 'tables.dart';
    ''',
    });
    addTearDown(state.close);

    final file = await state.analyze('package:a/file.moor');
    expect(file.errors.errors, hasLength(1));
    expect(
      file.errors.errors.single,
      isA<ErrorInMoorFile>()
          .having(
            (e) => e.message,
            'message',
            contains('Is it a part file?'),
          )
          .having((e) => e.span.text, 'span.text', "import 'tables.dart';"),
    );
  });
}
