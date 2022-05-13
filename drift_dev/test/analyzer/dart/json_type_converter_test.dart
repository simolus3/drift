import 'package:drift_dev/src/model/table.dart';
import 'package:drift_dev/src/model/used_type_converter.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  late TestState state;

  setUp(() {
    state = TestState.withContent({
      'a|lib/main.dart': '''
import 'package:drift/drift.dart';

TypeConverter<String, String> withoutJson() => throw 'stub';
JsonTypeConverter<String, String> withJson() => throw 'stub';

class Users extends Table {
  TextColumn get foo => text().map(withoutJson())();
  TextColumn get bar => text().map(withJson())();
}
''',
      'a|lib/main.drift': '''
import 'main.dart';

CREATE TABLE users (
  foo TEXT MAPPED BY `withoutJson()`,
  bar TEXT MAPPED BY `withJson()`
);
''',
    });
  });

  Future<void> testWith(String fileName) async {
    final result = await state.analyze(fileName);
    final table = result.currentResult!.declaredEntities.single as MoorTable;

    final foo = table.columns[0];
    final bar = table.columns[1];

    expect(foo.name.name, 'foo');
    expect(
      foo.typeConverter,
      isA<UsedTypeConverter>().having((e) => e.alsoAppliesToJsonConversion,
          'alsoAppliesToJsonConversion', isFalse),
    );

    expect(bar.name.name, 'bar');
    expect(
      bar.typeConverter,
      isA<UsedTypeConverter>().having((e) => e.alsoAppliesToJsonConversion,
          'alsoAppliesToJsonConversion', isTrue),
    );
  }

  test('recognizes json-capable type converters', () {
    return testWith('package:a/main.dart');
  });

  test('json converters in drift files', () {
    return testWith('package:a/main.drift');
  }, skip: 'Reading Dart expressions not currently supported in tests');
}
