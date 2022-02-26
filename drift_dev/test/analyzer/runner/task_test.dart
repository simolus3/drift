import 'package:drift_dev/src/analyzer/errors.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group("reports error when an import can't be found", () {
    test('in moor file', () async {
      final state = TestState.withContent({
        'foo|lib/a.moor': '''
import 'b.moor';
        ''',
      });

      final result = await state.analyze('package:foo/a.moor');
      state.close();

      expect(
        result.errors.errors,
        contains(const TypeMatcher<ErrorInMoorFile>().having(
          (e) => e.message,
          'message',
          allOf(contains('b.moor'), contains('file does not exist')),
        )),
      );
    });

    test('in a dart file', () async {
      final state = TestState.withContent({
        'foo|lib/a.dart': '''
import 'package:drift/drift.dart';        

@DriftDatabase(include: {'b.moor'})
class Database {

}        
            ''',
      });

      final result = await state.analyze('package:foo/a.dart');
      state.close();

      expect(
        result.errors.errors,
        contains(const TypeMatcher<ErrorInDartCode>().having(
          (e) => e.message,
          'message',
          allOf(contains('b.moor'), contains('file does not exist')),
        )),
      );
    }, tags: 'analyzer');
  });
}
