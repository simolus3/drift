import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  test('references right parent class for Dart-defined tables', () async {
    final result = await emulateDriftBuild(
      inputs: {
        'a|lib/a.dart': '''
import 'package:drift/drift.dart';

abstract class MyBaseDataClass extends DataClass {}

@DataClassName('MyTag', extending: MyBaseDataClass)
class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
}
''',
      },
      modularBuild: true,
    );

    checkOutputs({
      'a|lib/a.drift.dart': decodedMatches(
        allOf(
          contains("import 'package:a/a.dart' as i0;"),
          contains(
            r'class $TagsTable extends i0.Tags with i2.TableInfo<$TagsTable, i1.MyTag>',
          ),
          contains('class MyTag extends i0.MyBaseDataClass'),
        ),
      ),
    }, result.dartOutputs, result.writer);
  });
}
