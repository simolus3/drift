import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  test('references right parent class for Dart-defined tables', () async {
    final result = await emulateDriftBuild(
      inputs: {
        'a|lib/a.dart': '''
import 'package:drift/drift.dart';

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
          contains("import 'package:a/a.dart' as i2;"),
          contains(
            r'class $TagsTable extends i2.Tags with i0.TableInfo<$TagsTable, i1.Tag>',
          ),
        ),
      ),
    }, result.dartOutputs, result);
  });
}
