//@dart=2.9
@Tags(['analyzer'])
import 'dart:async';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:drift_dev/integrations/build.dart';
import 'package:test/test.dart';

void main() {
  test('generator emits warning about wrong language version', () async {
    final logs = StreamController<String>();

    final expectation = expectLater(
      logs.stream,
      emitsThrough(
        allOf(
          contains('Dart 2.1'),
          contains('Please consider raising the minimum SDK version'),
        ),
      ),
    );

    await testBuilder(
      moorBuilder(BuilderOptions.empty),
      {
        'foo|lib/a.dart': '''
// @dart = 2.1

import 'package:drift/drift.dart';

@DriftDatabase(tables: [])
class Database {}
        ''',
      },
      reader: await PackageAssetReader.currentIsolate(),
      onLog: (log) {
        logs.add(log.message);
      },
    );

    await expectation;
    await logs.close();
  });
}
