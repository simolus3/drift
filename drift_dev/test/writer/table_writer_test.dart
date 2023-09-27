import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  test('references right parent class for Dart-defined tables', () async {
    final result = await emulateDriftBuild(
      inputs: {
        'a|lib/a.dart': '''
import 'package:drift/drift.dart';

abstract class MyBaseDataClass extends DataClass {}

@DataClassName('MyTag', extending: MyBaseDataClass)
class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
}
''',
      },
      modularBuild: true,
    );

    checkOutputs({
      'a|lib/a.drift.dart': decodedMatches(
        allOf(
          contains("import 'package:a/a.dart' as i0;"),
          contains(
            r'class $TagsTable extends i0.Tags with i2.TableInfo<$TagsTable, i1.MyTag>',
          ),
          contains('class MyTag extends i0.MyBaseDataClass'),
        ),
      ),
    }, result.dartOutputs, result.writer);
  });

  test('generates index attached to table in monolithic build', () async {
    final result = await emulateDriftBuild(
      inputs: {
        'a|lib/a.dart': '''
import 'package:drift/drift.dart';

import 'table.dart';

@DriftDatabase(tables: [Tags])
class MyDatabase {}
''',
        'a|lib/table.dart': '''
import 'package:drift/drift.dart';

@TableIndex(name: 'tag_id', columns: {#id})
class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
}
''',
      },
    );

    checkOutputs({
      'a|lib/a.drift.dart': decodedMatches(allOf(
        contains(
          "Index tagId = Index('tag_id', 'CREATE INDEX tag_id ON tags (id)')",
        ),
        contains('allSchemaEntities => [tags, tagId]'),
      )),
    }, result.dartOutputs, result.writer);
  });

  test('generates index attached to table in modular build', () async {
    final result = await emulateDriftBuild(
      inputs: {
        'a|lib/database.dart': '''
import 'package:drift/drift.dart';

import 'table.dart';

@DriftDatabase(tables: [Tags])
class MyDatabase {}
''',
        'a|lib/table.dart': '''
import 'package:drift/drift.dart';

@TableIndex(name: 'tag_id', columns: {#id})
class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
}
''',
      },
      modularBuild: true,
    );

    checkOutputs({
      'a|lib/database.drift.dart':
          decodedMatches(contains('get allSchemaEntities => [tags, i1.tagId]')),
      'a|lib/table.drift.dart': decodedMatches(
        contains(
            "i0.Index get tagId => i0.Index('tag_id', 'CREATE INDEX tag_id ON tags (id)')"),
      ),
    }, result.dartOutputs, result.writer);
  });
}
