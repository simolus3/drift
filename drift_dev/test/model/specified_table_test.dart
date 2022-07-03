import 'package:drift_dev/moor_generator.dart';
import 'package:drift_dev/src/analyzer/options.dart';
import 'package:test/test.dart';

void main() {
  test('companion names', () {
    final table = DriftTable(
        sqlName: 'user', overriddenName: 'GoogleUser', dartTypeName: 'User');

    expect(table.getNameForCompanionClass(const DriftOptions.defaults()),
        'GoogleUserCompanion');

    expect(
      table.getNameForCompanionClass(
          const DriftOptions.defaults(useDataClassNameForCompanions: true)),
      'UserCompanion',
    );
  });
}
