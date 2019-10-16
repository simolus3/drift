import 'package:moor_generator/src/backends/build/moor_builder.dart';
import 'package:moor_generator/src/model/specified_table.dart';
import 'package:test/test.dart';

void main() {
  test('companion names', () {
    final table =
        SpecifiedTable(overriddenName: 'GoogleUser', dartTypeName: 'User');

    expect(table.getNameForCompanionClass(const MoorOptions()),
        'GoogleUserCompanion');

    expect(
      table.getNameForCompanionClass(
          const MoorOptions(useDataClassNameForCompanions: true)),
      'UserCompanion',
    );
  });
}
