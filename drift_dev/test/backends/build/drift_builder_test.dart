@Tags(['analyzer'])
library;

import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import '../../utils.dart';

void main() {
  test('emits warning about outdated language version', () async {
    final logger = Logger.detached('test');
    expect(
      logger.onRecord.map((e) => e.message),
      emitsThrough(
        allOf(
          contains('Dart 2.11'),
          contains('Please consider raising the minimum SDK version'),
        ),
      ),
    );

    await emulateDriftBuild(inputs: {
      'a|lib/a.dart': '''
// @dart = 2.11

import 'package:drift/drift.dart';

@DriftDatabase(tables: [])
class Database {}
        ''',
    }, logger: logger);
  });

  test('includes version override in part file mode', () async {
    final writer = await emulateDriftBuild(inputs: {
      'a|lib/a.dart': '''
// @dart = 2.13

import 'package:drift/drift.dart';

@DriftDatabase(tables: [])
class Database {}
        ''',
    });

    checkOutputs(
      {
        'a|lib/a.drift.dart': decodedMatches(contains('// @dart=2.13')),
      },
      writer.dartOutputs,
      writer.writer,
    );
  });
}
