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
  @override
  String get tableName => 'todos';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get description => text()();
}

@DriftDatabase(tables: [TodoItems])
class Database extends _$Database {}
''',
  };

  test('names accessors after the class by default', () async {
    final result = await emulateDriftBuild(inputs: input);

    checkOutputs(
      {
        'a|lib/main.drift.dart': decodedMatches(
          allOf(contains('get todoItems =>'), isNot(contains('get todos =>'))),
        ),
      },
      result.dartOutputs,
      result.writer,
    );
  }, tags: 'analyzer');

  test('names accessors after the sql name with the build option', () async {
    final result = await emulateDriftBuild(
      inputs: input,
      options: BuilderOptions({'use_sql_table_name_for_accessors': true}),
    );

    checkOutputs(
      {
        'a|lib/main.drift.dart': decodedMatches(
          allOf(contains('get todos =>'), isNot(contains('get todoItems =>'))),
        ),
      },
      result.dartOutputs,
      result.writer,
    );
  }, tags: 'analyzer');
}
