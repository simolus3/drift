import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  const input = {
    'a|lib/main.dart': r'''
import 'package:drift/drift.dart';

part 'main.drift.dart';

class TodoItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get description => text().nullable()();
}

@DriftDatabase(tables: [TodoItems])
class Database extends _$Database {}
''',
  };

  test('does not override options by default', () async {
    final result = await emulateDriftBuild(inputs: input);

    checkOutputs(
      {
        'a|lib/main.drift.dart': decodedMatches(
          isNot(contains('upsertsWriteNullValues')),
        ),
      },
      result.dartOutputs,
      result.writer,
    );
  }, tags: 'analyzer');

  test('overrides options with the build option', () async {
    final result = await emulateDriftBuild(
      inputs: input,
      options: BuilderOptions({'upserts_write_null_values': true}),
    );

    checkOutputs(
      {
        'a|lib/main.drift.dart': decodedMatches(
          contains('DriftDatabaseOptions(upsertsWriteNullValues: true)'),
        ),
      },
      result.dartOutputs,
      result.writer,
    );
  }, tags: 'analyzer');

  test('combines with store_date_time_values_as_text', () async {
    final result = await emulateDriftBuild(
      inputs: input,
      options: BuilderOptions({
        'store_date_time_values_as_text': true,
        'upserts_write_null_values': true,
      }),
    );

    checkOutputs(
      {
        'a|lib/main.drift.dart': decodedMatches(
          // The generated file is formatted, so the arguments may be wrapped
          // across lines.
          allOf(
            contains('DriftDatabaseOptions get options =>'),
            contains('storeDateTimeAsText: true'),
            contains('upsertsWriteNullValues: true'),
          ),
        ),
      },
      result.dartOutputs,
      result.writer,
    );
  }, tags: 'analyzer');
}
