import 'package:drift_dev/src/analyzer/errors.dart';
import 'package:drift_dev/src/analyzer/runner/results.dart';
import 'package:drift_dev/src/model/table.dart';
import 'package:drift_dev/src/model/used_type_converter.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  late TestState state;

  setUp(() {
    state = TestState.withContent({
      'a|lib/json.dart': '''
import 'package:drift/drift.dart';

TypeConverter<String, String> withoutJson() => throw 'stub';
JsonTypeConverter<String, String> withJson() => throw 'stub';

class Users extends Table {
  TextColumn get foo => text().map(withoutJson())();
  TextColumn get bar => text().map(withJson())();
}
''',
      'a|lib/nullability.dart': '''
import 'package:drift/drift.dart';

TypeConverter<Dart, Sql> tc<Dart, Sql>() => throw 'stub';

class Users extends Table {
  TextColumn get wrongSqlType => text().map(tc<int, int>())();
  TextColumn get illegalNull => text().map(tc<String, String?>())();
  TextColumn get illegalNonNull => text().map(tc<String?, String>()).nullable()();
  TextColumn get implicitlyNullAware => text().map(tc<String, String>()).nullable()();
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
    final table = result.currentResult!.declaredEntities.single as DriftTable;

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
    return testWith('package:a/json.dart');
  });

  test('warns about type issues around converters', () async {
    final result = await state.analyze('package:a/nullability.dart');
    final table =
        (result.currentResult as ParsedDartFile).declaredTables.single;

    expect(
      result.errors.errors,
      [
        isA<ErrorInDartCode>()
            .having((e) => e.message, 'message', contains('must accept String'))
            .having((e) => e.span?.text, 'span', 'tc<int, int>()'),
        isA<ErrorInDartCode>()
            .having((e) => e.message, 'message',
                contains('has a type converter with a nullable SQL type'))
            .having((e) => e.span?.text, 'span', 'tc<String, String?>()'),
        isA<ErrorInDartCode>()
            .having((e) => e.message, 'message',
                contains('This column is nullable'))
            .having((e) => e.span?.text, 'span', 'tc<String?, String>()'),
      ],
    );

    final implicitlyNullAware = table.columns[3];
    expect(implicitlyNullAware.typeConverter?.canBeSkippedForNulls, isTrue);
  });

  test('json converters in drift files', () {
    return testWith('package:a/main.drift');
  }, skip: 'Reading Dart expressions not currently supported in tests');
}
