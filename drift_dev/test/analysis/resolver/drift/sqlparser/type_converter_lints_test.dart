import 'package:test/test.dart';

import '../../../test_utils.dart';

const _enum = '''
enum Fruit {
  apple,
  banana,
  melon,
  strawberry
}
''';

void main() {
  group('warns about invalid type converter value', () {
    test('in table definition', () async {
      final backend = TestBackend.inTest({
        'a|lib/a.drift': '''
import 'enum.dart';

CREATE TABLE a (
  a ENUMNAME(Fruit) NOT NULL DEFAULT 'raspberry',
  b ENUM(Fruit) NOT NULL GENERATED ALWAYS AS (7),
  c ENUM(Fruit) NOT NULL DEFAULT (-1)
);
''',
        'a|lib/enum.dart': _enum,
      });

      final file = await backend.analyze('package:a/a.drift');
      expect(file.allErrors, [
        isDriftError(contains(
                '`Fruit`. However, that enum declares no member with this name'))
            .withSpan("'raspberry'"),
        isDriftError(contains('the constant index is too large')).withSpan('7'),
        isDriftError(contains("it can't be negative")).withSpan('-1'),
      ]);
    });

    test('for query', () async {
      final backend = TestBackend.inTest({
        'a|lib/a.drift': '''
import 'enum.dart';

CREATE TABLE a (
  a ENUMNAME(Fruit) NOT NULL
);

b: INSERT INTO a VALUES ('not a fruit');
''',
        'a|lib/enum.dart': _enum,
      });

      final file = await backend.analyze('package:a/a.drift');
      expect(file.allErrors, [
        isDriftError(contains('declares no member with this name'))
            .withSpan("'not a fruit'")
      ]);
    });
  });
}
