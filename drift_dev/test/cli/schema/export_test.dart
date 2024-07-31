import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('exports schema', () {
    final project = TestDriftProject(Directory('../drift/').absolute);

    test('for drift-file definitions', () async {
      final statements =
          await project.collectSchema('test/generated/custom_tables.dart');
      expect(
        statements,
        containsAll(
          [startsWith('CREATE TABLE IF NOT EXISTS "mytable"')],
        ),
      );
      expect(statements, everyElement(endsWith(';')));
    });
  });
}

extension on TestDriftProject {
  Future<List<String>> collectSchema(String source) async {
    final printStatements = <String>[];
    await runZoned(
      () async {
        await runDriftCli(['schema', 'export', source]);
      },
      zoneSpecification: ZoneSpecification(
        print: (_, __, ___, msg) => printStatements.add(msg),
      ),
    );

    return printStatements;
  }
}
