@Tags(['analyzer'])
import 'package:drift_dev/moor_generator.dart';
import 'package:drift_dev/src/analyzer/errors.dart';
import 'package:drift_dev/src/analyzer/runner/results.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  late TestState state;

  setUpAll(() async {
    state = TestState.withContent({
      'foo|lib/main.dart': '''
        import 'package:drift/drift.dart';

        enum Fruits {
          apple, orange, banana
        }

        class NotAnEnum {}

        class ValidUsage extends Table {
          IntColumn get fruit => intEnum<Fruits>()();
        }

        class InvalidNoEnum extends Table {
          IntColumn get fruit => intEnum<NotAnEnum>()();
        }
      ''',
    });

    await state.analyze('package:foo/main.dart');
  });

  tearDownAll(() => state.close());

  test('parses enum columns', () {
    final file =
        state.file('package:foo/main.dart').currentResult as ParsedDartFile;
    final table =
        file.declaredTables.singleWhere((t) => t.sqlName == 'valid_usage');

    expect(
      table.converters,
      contains(
        isA<UsedTypeConverter>().having(
            (e) => e.expression, 'expression', contains('EnumIndexConverter')),
      ),
    );
  });

  test('fails when used with a non-enum class', () {
    final errors = state.file('package:foo/main.dart').errors.errors;

    expect(
      errors,
      contains(isA<DriftError>().having((e) => e.message, 'message',
          allOf(contains('Not an enum'), contains('NotAnEnum')))),
    );
  });
}
