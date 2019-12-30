import 'package:moor_generator/moor_generator.dart';
import 'package:moor_generator/src/analyzer/options.dart';
import 'package:test/test.dart';

void main() {
  test('companion names', () {
    final table = MoorTable(overriddenName: 'GoogleUser', dartTypeName: 'User');

    expect(table.getNameForCompanionClass(const MoorOptions()),
        'GoogleUserCompanion');

    expect(
      table.getNameForCompanionClass(
          const MoorOptions(useDataClassNameForCompanions: true)),
      'UserCompanion',
    );
  });
}
