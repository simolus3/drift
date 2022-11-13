@Tags(['analyzer'])
import 'package:build_test/build_test.dart';
import 'package:drift_dev/src/analysis/backend.dart';
import 'package:drift_dev/src/backends/build/backend.dart';
import 'package:test/test.dart';

void main() {
  test('throws NotALibraryException when resolving a part file', () {
    testBuilder(
      TestBuilder(
        build: (step, _) async {
          final backend = DriftBuildBackend(step);
          final partOfUri = Uri.parse('package:foo/helper.dart');

          await expectLater(
            () => backend.readDart(partOfUri),
            throwsA(const TypeMatcher<NotALibraryException>()
                .having((e) => e.uri, 'uri', partOfUri)),
          );
        },
      ),
      {
        'foo|lib/main.dart': '''
part 'helper.dart';
         ''',
        'foo|lib/helper.dart': '''
part of 'main.dart';
        '''
      },
    );
  });
}
