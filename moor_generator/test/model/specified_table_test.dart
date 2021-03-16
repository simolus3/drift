//@dart=2.9
import 'package:moor_generator/moor_generator.dart';
import 'package:moor_generator/src/analyzer/options.dart';
import 'package:test/test.dart';

void main() {
  test('companion names', () {
    final table = MoorTable(overriddenName: 'GoogleUser', dartTypeName: 'User');

    expect(table.getNameForCompanionClass(const MoorOptions.defaults()),
        'GoogleUserCompanion');

    expect(
      table.getNameForCompanionClass(
          const MoorOptions.defaults(useDataClassNameForCompanions: true)),
      'UserCompanion',
    );
  });
}
