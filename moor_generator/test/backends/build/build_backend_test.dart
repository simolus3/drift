//@dart=2.9
@Tags(['analyzer'])
import 'package:build_test/build_test.dart';
import 'package:moor_generator/src/backends/backend.dart';
import 'package:moor_generator/src/backends/build/build_backend.dart';
import 'package:test/test.dart';

void main() {
  final backend = BuildBackend();

  test('throws NotALibraryException when resolving a part file', () {
    testBuilder(
      TestBuilder(
        build: (step, _) async {
          final task = backend.createTask(step);
          final partOfUri = Uri.parse('package:foo/helper.dart');

          await expectLater(
            () => task.resolveDart(partOfUri),
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
