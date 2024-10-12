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
      }, result.dartOutputs, result.writer);
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
          'typedef User = ({DateTime? birthDate, int id, String name});',
        ),
        contains(r'''
    return (
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      birthDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}birth_date']),
    );
'''),
      ))
    }, result.dartOutputs, result.writer);
  }, skip: requireDart('3.0.0-dev'));

  test(
    'references nullable variant of converter on non-nullable column',
    () async {
      final result = await emulateDriftBuild(
        inputs: {
          'a|lib/converter.dart': '''
import 'package:drift/drift.dart';

TypeConverter<int, String> get testConverter => throw '';
''',
          'a|lib/a.drift': '''
import 'converter.dart';

CREATE TABLE foo (
  bar TEXT MAPPED BY `testConverter` NOT NULL
);

CREATE VIEW a AS SELECT nullif(bar, '') FROM foo;
''',
        },
        modularBuild: true,
        logger: loggerThat(neverEmits(anything)),
      );

      checkOutputs({
        'a|lib/a.drift.dart': decodedMatches(
          allOf(isNot(contains('converterbarn'))),
        ),
      }, result.dartOutputs, result.writer);
    },
  );

  test(
      'generates valid code for for references whose target columnis a reference column itself',
      () async {
    final result = await emulateDriftBuild(
      inputs: {
        'a|lib/a.dart': r'''
import 'package:drift/drift.dart';

class FkToPk0 extends Table {
  IntColumn get fk => integer().references(FkToPk0, #fk)();
}

class FkToPk1 extends Table {
  IntColumn get fk => integer().references(FkToPk2, #fk)();
}

class FkToPk2 extends Table {
  IntColumn get fk => integer().references(FkToPk3, #id)();
}

class FkToPk3 extends Table {
  IntColumn get id => integer().autoIncrement()();
}

@DriftDatabase(tables: [FkToPk0,FkToPk1,FkToPk2,FkToPk3])
class MyDatabase {}
''',
      },
      logger: loggerThat(neverEmits(anything)),
    );

    checkOutputs(
      {
        'a|lib/a.drift.dart': allOf(IsValidDartFile(anything),
            decodedMatches(isNot(contains('f.fk.fk'))))
      },
      result.dartOutputs,
      result.writer,
    );
  });

  test('generates valid code for columns containing dollar signs', () async {
    final result = await emulateDriftBuild(
      inputs: {
        'a|lib/a.dart': r'''
import 'package:drift/drift.dart';

class Todo extends Table {
  TextColumn get id => text()();
  TextColumn get listid => text().nullable()();
  TextColumn get text$ => text().named('text').nullable()();
  BoolColumn get completed => boolean()();
}

@DriftDatabase(tables: [Todo])
class MyDatabase {}
''',
      },
      logger: loggerThat(neverEmits(anything)),
    );

    // Make sure we don't generate invalid code in string literals for dollar
    // signs in names - https://github.com/simolus3/drift/issues/2761.
    checkOutputs(
      {'a|lib/a.drift.dart': IsValidDartFile(anything)},
      result.dartOutputs,
      result.writer,
    );
  });

  test('generates code for view with multiple group by', () async {
    final result = await emulateDriftBuild(
      inputs: {
        'a|lib/a.dart': r'''
import 'package:drift/drift.dart';

class Todo extends Table {
  TextColumn get id => text()();
  TextColumn get listid => text().nullable()();
  BoolColumn get completed => boolean()();
}

@DriftView()
abstract class SomeView extends View {
  Todo get todoItems;

  @override
  Query as() => select([todoItems.id]).from(todoItems)
        ..groupBy([todoItems.id, todoItems.listId]);
}

@DriftDatabase(tables: [Todo], views: [SomeView])
class MyDatabase {}
''',
      },
      logger: loggerThat(neverEmits(anything)),
    );

    checkOutputs(
      {
        'a|lib/a.drift.dart': allOf(IsValidDartFile(anything),
            decodedMatches(contains('todoItems.id, todoItems.listId')))
      },
      result.dartOutputs,
      result.writer,
    );
  });
}
