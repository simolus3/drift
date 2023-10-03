import 'package:checked_yaml/checked_yaml.dart';
import 'package:drift_dev/src/analysis/options.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  DriftOptions parse(String yaml) {
    return checkedYamlDecode(yaml, (m) => DriftOptions.fromJson(m!));
  }

  test('does not allow modules and sqlite options', () {
    expect(
      () => parse('''
sqlite_modules: [moor_ffi]
sqlite:
  modules: [math]
    '''),
      throwsA(
        isA<ParsedYamlException>()
            .having((e) => e.message, 'message',
                contains('May not be set when sqlite options are present.'))
            .having((e) => e.yamlNode?.span.text, 'yamlNode.span.text',
                '[moor_ffi]'),
      ),
    );
  });

  test('parses sqlite version', () {
    expect(
      parse('''
sqlite:
  version: "3.35"
    '''),
      isA<DriftOptions>().having((e) => e.sqliteVersion, 'sqliteVersion',
          const SqliteVersion(3, 35, 0)),
    );
  });

  test('does not allow old versions', () {
    expect(
      () => parse('''
sqlite:
  version: "3.17"
    '''),
      throwsA(
        isA<ParsedYamlException>()
            .having((e) => e.message, 'message',
                contains('Version is not supported for analysis (minimum is'))
            .having(
                (e) => e.yamlNode?.span.text, 'yamlNode.span.text', '"3.17"'),
      ),
    );
  });

  test('does not allow unreleased versions', () {
    expect(
      () => parse('''
sqlite:
  version: "3.99"
    '''),
      throwsA(
        isA<ParsedYamlException>()
            .having(
              (e) => e.message,
              'message',
              contains(
                  'Version is not supported for analysis (current maximum is'),
            )
            .having(
                (e) => e.yamlNode?.span.text, 'yamlNode.span.text', '"3.99"'),
      ),
    );
  });

  test('reports error about table when module is not imported', () async {
    final backend = TestBackend.inTest({
      'a|lib/a.drift': 'CREATE VIRTUAL TABLE place_spellfix USING spellfix1;',
    });

    final file = await backend.analyze('package:a/a.drift');
    expect(file.analyzedElements, isEmpty);
    expect(file.allErrors, [
      isDriftError(contains('Unknown module "spellfix1", did you register it?'))
          .withSpan('place_spellfix'),
    ]);
  });

  group('parses functions', () {
    test('succesfully', () {
      final function = KnownSqliteFunction.fromJson('text (int, boolean nUlL)');

      expect(function.returnType.type, BasicType.text);
      expect(function.argumentTypes, [
        isA<ResolvedType>().having((e) => e.type, 'type', BasicType.int),
        isA<ResolvedType>()
            .having((e) => e.type, 'type', BasicType.int)
            .having((e) => e.hints, 'hints', [IsBoolean()]).having(
                (e) => e.nullable, 'nullable', true),
      ]);
    });

    test('supports empty args', () {
      final function = KnownSqliteFunction.fromJson('text ()');

      expect(function.returnType.type, BasicType.text);
      expect(function.argumentTypes, isEmpty);
    });

    test('fails for invalid syntax', () {
      final throws = throwsFormatException;

      expect(() => KnownSqliteFunction.fromJson('x'), throws);
      expect(() => KnownSqliteFunction.fromJson('(boolean)'), throws);
      expect(() => KnownSqliteFunction.fromJson('int (boolean, )'), throws);
    });
  });
}
