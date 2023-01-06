import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  late TestBackend state;

  setUp(() {
    state = TestBackend({
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
import 'json.dart';

CREATE TABLE users (
  foo TEXT MAPPED BY `withoutJson()`,
  bar TEXT MAPPED BY `withJson()`
);
''',
    });
  });

  tearDown(() => state.dispose());

  Future<void> testWith(String fileName) async {
    final result = await state.driver.fullyAnalyze(Uri.parse(fileName));
    expect(result.allErrors, isEmpty);
    final table = result.analyzedElements.whereType<DriftTable>().single;

    final foo = table.columns[0];
    final bar = table.columns[1];

    expect(foo.nameInSql, 'foo');
    expect(
      foo.typeConverter,
      isA<AppliedTypeConverter>().having((e) => e.alsoAppliesToJsonConversion,
          'alsoAppliesToJsonConversion', isFalse),
    );

    expect(bar.nameInSql, 'bar');
    expect(
      bar.typeConverter,
      isA<AppliedTypeConverter>().having((e) => e.alsoAppliesToJsonConversion,
          'alsoAppliesToJsonConversion', isTrue),
    );
  }

  test('recognizes json-capable type converters', () {
    return testWith('package:a/json.dart');
  });

  test('warns about type issues around converters', () async {
    final result = await state.driver
        .fullyAnalyze(Uri.parse('package:a/nullability.dart'));
    final table = result.analyzedElements.whereType<DriftTable>().single;

    expect(
      result.allErrors,
      [
        isDriftError(contains('must accept String')).withSpan('tc<int, int>()'),
        isDriftError(contains('has a type converter with a nullable SQL type'))
            .withSpan('tc<String, String?>()'),
        isDriftError(contains('This column is nullable'))
            .withSpan('tc<String?, String>()'),
      ],
    );

    final implicitlyNullAware = table.columns[3];
    expect(implicitlyNullAware.typeConverter?.canBeSkippedForNulls, isTrue);
  });

  test('json converters in drift files', () {
    return testWith('package:a/main.drift');
  });
}
