@Tags(['analyzer'])
import 'package:drift_dev/src/analysis/driver/error.dart';
import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  late TestBackend backend;

  setUpAll(() async {
    backend = TestBackend({
      'a|lib/main.dart': '''
        import 'package:drift/drift.dart';

        enum Fruits {
          apple, orange, banana
        }

        enum FruitsWithGeneric<T> {
          apple, orange, banana
        }

        class NotAnEnum {}

        class ValidUsage extends Table {
          IntColumn get intFruit => intEnum<Fruits>()();
          IntColumn get intFruitsWithGeneric => intEnum<FruitsWithGeneric>()();
          TextColumn get textFruit => textEnum<Fruits>()();
        }

        class InvalidNoEnum extends Table {
          IntColumn get intFruit => intEnum<NotAnEnum>()();
          TextColumn get textFruit => textEnum<NotAnEnum>()();
        }
      ''',
    });

    await backend.driver.fullyAnalyze(Uri.parse('package:a/main.dart'));
  });

  tearDownAll(() => backend.dispose());

  test('parses enum columns', () {
    final file =
        backend.driver.cache.knownFiles[Uri.parse('package:a/main.dart')]!;
    final table = file.analyzedElements
        .singleWhere((e) => e.id.name == 'valid_usage') as DriftTable;

    expect(
      table.appliedConverters,
      contains(
        isA<AppliedTypeConverter>().having((e) => e.expression.toString(),
            'expression', contains('EnumIndexConverter')),
      ),
    );
    expect(
      table.appliedConverters,
      contains(
        isA<AppliedTypeConverter>().having((e) => e.expression.toString(),
            'expression', contains('EnumNameConverter')),
      ),
    );
  });

  test('fails when used with a non-enum class', () {
    final file =
        backend.driver.cache.knownFiles[Uri.parse('package:a/main.dart')]!;

    final notAnEnumError = isA<DriftAnalysisError>().having((e) => e.message,
        'message', allOf(contains('Not an enum'), contains('NotAnEnum')));
    expect(
      file.allErrors,
      containsAllInOrder(
        [notAnEnumError, notAnEnumError],
      ),
    );
  });
}
