import 'package:drift_core/drift_core.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  test('in', () {
    expect(
      Expression<int>.sql('a', precedence: Precedence.primary).isIn([1, 2, 3]),
      generates('a IN (?,?,?)', [1, 2, 3]),
    );
  });
}
