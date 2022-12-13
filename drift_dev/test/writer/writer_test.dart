import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('modular writer', () {
    test('generates import for type converter', () async {
      final result = await emulateDriftBuild(
        inputs: {
          'a|lib/converter.dart': '''
import 'package:drift/drift.dart';

TypeConverter<String, String> get myConverter => throw UnimplementedError();
''',
          'a|lib/table.drift': '''
import 'converter.dart';

CREATE TABLE my_table (
  foo TEXT MAPPED BY `myConverter`,
  bar INT
);
''',
          'a|lib/query.drift': '''
import 'table.drift';

foo: SELECT foo FROM my_table;
''',
        },
        modularBuild: true,
      );

      checkOutputs({
        'a|lib/table.drift.dart': decodedMatches(
          allOf(
            contains("import 'package:a/converter.dart' as i2;"),
            contains(r'$converterfoo = i2.myConverter;'),
          ),
        ),
        'a|lib/query.drift.dart': decodedMatches(
          allOf(
            contains("import 'package:a/table.drift.dart' as i2;"),
            contains(r'i2.MyTable.$converterfoo'),
          ),
        )
      }, result.dartOutputs, result);
    });
  });
}
