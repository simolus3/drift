import 'package:test/test.dart';

import 'utils.dart';

void main() {
  test('WITH without following statement', () {
    enforceError('WITH foo AS (SELECT * FROM bar)',
        contains('to follow this WITH clause'));
  });
}
