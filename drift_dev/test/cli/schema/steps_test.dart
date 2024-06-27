import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import '../../utils.dart';
import '../utils.dart';

void main() {
  test('generates valid code when no schemas have been saved', () async {
    final project = await TestDriftProject.create([d.dir('drift_schemas/')]);
    final path = project.root.path;
    await project.runDriftCli([
      'schema',
      'steps',
      '$path/drift_schemas/',
      '$path/schema_versions.dart',
    ]);

    await d
        .file('app/schema_versions.dart', IsValidDartFile(anything))
        .validate();
  });

  test('generates valid code when only one schema version is saved', () async {
    final project = await TestDriftProject.create([
      d.dir(
        'drift_schemas/',
        [
          d.file('v1.json', '''
{
  "meta": {
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
  ],
}
'''),
        ],
      ),
    ]);
    final path = project.root.path;
    await project.runDriftCli([
      'schema',
      'steps',
      '$path/drift_schemas/',
      '$path/schema_versions.dart',
    ]);

    await d
        .file('app/schema_versions.dart', IsValidDartFile(anything))
        .validate();
  });
}
