import 'dart:convert';

import 'package:drift_dev/src/analysis/options.dart';
import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:drift_dev/src/services/schema/schema_files.dart';
import 'package:test/test.dart';

import '../../analysis/test_utils.dart';

void main() {
  test('keeps data class name for views', () async {
    final elements = await _serializationRoundtrip('''
CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT NOT NULL);
CREATE VIEW user_ids AS SELECT id FROM users;
''');

    expect(
      elements[0],
      isA<DriftTable>().having(
        (e) => e.nameOfRowClass,
        'nameOfRowClass',
        'UsersData',
      ),
    );
    expect(
      elements[1],
      isA<DriftView>().having(
        (e) => e.nameOfRowClass,
        'nameOfRowClass',
        'UserId',
      ),
    );
  });

  test('keeps information about generatedAs', () async {
    final [table as DriftTable] = await _serializationRoundtrip('''
CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  entity_json TEXT NOT NULL GENERATED ALWAYS AS (json_object('id', id, 'type', 'users')) VIRTUAL
);
''');

    final [id, name, entityJson] = table.columns;
    expect(id.isGenerated, isFalse);
    expect(name.isGenerated, isFalse);
    expect(entityJson.isGenerated, isTrue);
    expect(
      entityJson.constraints,
      contains(
        isA<ColumnGeneratedAs>().having((e) => e.stored, 'stored', false),
      ),
    );
  });

  test('can read old index format', () async {
    final reader = await SchemaReader.readJson(
      json.decode('''
{
    "_meta": {
        "description": "This file contains a serialized version of schema entities for drift.",
        "version": "1.0.0"
    },
    "options": {
        "store_date_time_values_as_text": false
    },
    "entities": [
        {
            "id": 0,
            "references": [],
            "type": "table",
            "data": {
                "name": "groups",
                "was_declared_in_moor": true,
                "columns": [
                    {
                        "name": "id",
                        "getter_name": "id",
                        "moor_type": "int",
                        "nullable": false,
                        "customConstraints": "NOT NULL PRIMARY KEY AUTOINCREMENT",
                        "default_dart": null,
                        "default_client_dart": null,
                        "dsl_features": [
                            "auto-increment"
                        ]
                    },
                    {
                        "name": "name",
                        "getter_name": "name",
                        "moor_type": "string",
                        "nullable": false,
                        "customConstraints": "NOT NULL",
                        "default_dart": null,
                        "default_client_dart": null,
                        "dsl_features": []
                    }
                ],
                "is_virtual": false,
                "without_rowid": false
            }
        },
        {
          "id": 1,
          "references": [0],
          "type": "index",
          "data": {
            "on": 0,
            "name": "my_index",
            "sql": "CREATE UNIQUE INDEX my_index ON \\"groups\\" (id, name);"
          }
        }
    ]
}
''')
          as Map<String, Object?>,
    );

    final index = reader.entities.whereType<DriftIndex>().first;

    expect(index.unique, isTrue);
    expect(index.indexedColumns, hasLength(2));
  });

  test('can read drift3 option format', () async {
    final serialized = await _analyzeAndSerialize('''
CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL
);
''', const DriftOptions.defaults(drift3Preview: true));

    final deserialized = await SchemaReader.readJson(serialized);
    expect(deserialized.options, containsPair('dialects', isNotNull));
  });
}

Future<Map<String, Object?>> _analyzeAndSerialize(
  String source, [
  DriftOptions options = const DriftOptions.defaults(),
]) async {
  final state = await TestBackend.inTest({
    'a|lib/a.drift': source,
  }, options: options);
  final file = await state.analyze('package:a/a.drift');

  final writer = SchemaWriter(file.analyzedElements.toList(), options: options);
  return json.decode(json.encode(await writer.createSchemaJson()))
      as Map<String, Object?>;
}

Future<List<DriftElement>> _serializationRoundtrip(
  String source, [
  DriftOptions options = const DriftOptions.defaults(),
]) async {
  final schemaJson = await _analyzeAndSerialize(source, options);

  final deserialized = await SchemaReader.readJson(schemaJson);
  return deserialized.entities.toList();
}
