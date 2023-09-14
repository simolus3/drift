import 'dart:convert';

import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:drift_dev/src/services/schema/schema_files.dart';
import 'package:test/test.dart';

import '../../analysis/test_utils.dart';

void main() {
  test('keeps data class name for views', () async {
    final elements = await _analyzeAndSerialize('''
CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT NOT NULL);
CREATE VIEW user_ids AS SELECT id FROM users;
''');

    expect(
      elements[0],
      isA<DriftTable>()
          .having((e) => e.nameOfRowClass, 'nameOfRowClass', 'UsersData'),
    );
    expect(
      elements[1],
      isA<DriftView>()
          .having((e) => e.nameOfRowClass, 'nameOfRowClass', 'UserId'),
    );
  });

  test('can read old index format', () async {
    final reader = SchemaReader.readJson(
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
''') as Map<String, Object?>,
    );

    final index = reader.entities.whereType<DriftIndex>().first;

    expect(index.unique, isTrue);
    expect(index.indexedColumns, hasLength(2));
  });
}

Future<List<DriftElement>> _analyzeAndSerialize(String source) async {
  final state = TestBackend.inTest({'a|lib/a.drift': source});
  final file = await state.analyze('package:a/a.drift');

  final writer = SchemaWriter(file.analyzedElements.toList());
  final schemaJson = json.decode(json.encode(writer.createSchemaJson()));

  final deserialized =
      SchemaReader.readJson(schemaJson as Map<String, Object?>);
  return deserialized.entities.toList();
}
