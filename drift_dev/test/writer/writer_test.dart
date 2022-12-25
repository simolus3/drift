import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import '../analysis/test_utils.dart';
import '../utils.dart';

void main() {
  group('modular writer', () {
    test('generates import for type converter', () async {
      final result = await emulateDriftBuild(
        inputs: {
          'a|lib/converter.dart': '''
import 'package:drift/drift.dart';

TypeConverter<String, String> get myConverter => throw UnimplementedError();
''',
          'a|lib/table.drift': '''
import 'converter.dart';

CREATE TABLE my_table (
  foo TEXT MAPPED BY `myConverter`,
  bar INT
);
''',
          'a|lib/query.drift': '''
import 'table.drift';

foo: SELECT foo FROM my_table;
''',
        },
        modularBuild: true,
      );

      checkOutputs({
        'a|lib/table.drift.dart': decodedMatches(
          allOf(
            contains("import 'package:a/converter.dart' as i2;"),
            contains(r'$converterfoo = i2.myConverter;'),
          ),
        ),
        'a|lib/query.drift.dart': decodedMatches(
          allOf(
            contains("import 'package:a/table.drift.dart' as i2;"),
            contains(r'i2.MyTable.$converterfoo'),
          ),
        )
      }, result.dartOutputs, result);
    });
  });

  test('supports records as row classes', () async {
    final result = await emulateDriftBuild(
      inputs: {
        'a|lib/a.dart': '''
import 'package:drift/drift.dart';

@UseRowClass(Record)
class Users extends Table {
  IntColumn get id => integer().primaryKey()();
  TextColumn get name => text()();
  DateTimeColumn get birthDate => dateTime().nullable()();
}

@DriftDatabase(tables: [Users])
class Database {}
''',
      },
      // We currently generate a warning because dart_style does not support
      // records yet.
      //  logger: loggerThat(neverEmits(anything)),
    );

    checkOutputs({
      'a|lib/a.drift.dart': decodedMatches(allOf(
        contains(
          'typedef User = ({int id, String name, DateTime? birthDate});',
        ),
        contains(
          'return (id: attachedDatabase.typeMapping.read(DriftSqlType.int, data[\'\${effectivePrefix}id\'])!, '
          'name: attachedDatabase.typeMapping.read(DriftSqlType.string, data[\'\${effectivePrefix}name\'])!, '
          'birthDate: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data[\'\${effectivePrefix}birth_date\']), );',
        ),
      ))
    }, result.dartOutputs, result);
  }, skip: requireDart('3.0.0-dev'));
}
