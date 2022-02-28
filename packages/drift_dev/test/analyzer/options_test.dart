import 'package:checked_yaml/checked_yaml.dart';
import 'package:drift_dev/src/analyzer/options.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

void main() {
  MoorOptions parse(String yaml) {
    return checkedYamlDecode(yaml, (m) => MoorOptions.fromJson(m!));
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
      isA<MoorOptions>().having((e) => e.sqliteVersion, 'sqliteVersion',
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
}
