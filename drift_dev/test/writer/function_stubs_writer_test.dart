import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  test('writes function stubs in modular build mode', () async {
    final logger = Logger.detached('driftBuild');

    expect(logger.onRecord, neverEmits(anything));
    final writer = await emulateDriftBuild(
      inputs: {
        'a|lib/a.dart': '''
import 'package:drift/drift.dart';

@DriftDatabase(include: {'queries.drift'})
class MyDatabase {}
''',
        'a|lib/queries.drift': '''
a: SELECT dart_version(), gcd(13, 15);
''',
      },
      modularBuild: true,
      options: builderOptionsFromYaml('''
store_date_time_values_as_text: true
named_parameters: true
sql:
  dialect: sqlite
  options:
    version: "3.39"
    modules: [fts5]
    known_functions:
      "dart_version": "text()"
      "gcd": "int(int, int)"
'''),
      logger: logger,
    );

    checkOutputs(
      {
        'a|lib/a.drift.dart': decodedMatches(
          contains('''
extension DefineFunctions on i3.CommonDatabase {
  void defineFunctions({
    required String Function() dartVersion,
    required int Function(int, int) gcd,
  }) {
    createFunction(
      functionName: 'dart_version',
      argumentCount: const i3.AllowedArgumentCount(0),
      function: (args) {
        return dartVersion();
      },
    );
    createFunction(
      functionName: 'gcd',
      argumentCount: const i3.AllowedArgumentCount(2),
      function: (args) {
        final arg0 = args[0] as int;
        final arg1 = args[1] as int;
        return gcd(arg0, arg1);
      },
    );
  }
}
'''),
        ),
        'a|lib/queries.drift.dart': anything,
      },
      writer.dartOutputs,
      writer,
    );
  });
}
