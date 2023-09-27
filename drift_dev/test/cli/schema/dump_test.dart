import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import '../utils.dart';

void main() {
  test('extracts schema json from database file', () async {
    final project = await TestDriftProject.create();

    sqlite3.open(p.join(project.root.path, 'test.db'))
      ..execute('CREATE TABLE users (id int primary key, name text) STRICT;')
      ..execute('CREATE VIEW names AS SELECT name FROM users;')
      ..execute('CREATE TRIGGER to_upper AFTER UPDATE ON users BEGIN '
          '  UPDATE users SET name = upper(new.name) where id = new.id;'
          'END;')
      ..execute('CREATE INDEX idx ON users (name);')
      ..execute('pragma user_version = 1234;')
      ..dispose();

    await project
        .runDriftCli(['schema', 'dump', 'test.db', 'drift_migrations/']);

    await project.validate(d.dir('drift_migrations', [
      d.file(
        'drift_schema_v1234.json',
        isA<String>().having(
          json.decode,
          'parsed as json',
          json.decode('''
{
  "_meta": {
    "description": "This file contains a serialized version of schema entities for drift.",
    "version": "1.1.0"
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
        "name": "users",
        "was_declared_in_moor": true,
        "columns": [
          {
            "name": "id",
            "getter_name": "id",
            "moor_type": "int",
            "nullable": false,
            "customConstraints": "PRIMARY KEY",
            "default_dart": null,
            "default_client_dart": null,
            "dsl_features": [
              "primary-key"
            ]
          },
          {
            "name": "name",
            "getter_name": "name",
            "moor_type": "string",
            "nullable": true,
            "customConstraints": "",
            "default_dart": null,
            "default_client_dart": null,
            "dsl_features": []
          }
        ],
        "is_virtual": false,
        "without_rowid": false,
        "constraints": [],
        "strict": true
      }
    },
    {
      "id": 1,
      "references": [
        0
      ],
      "type": "view",
      "data": {
        "name": "names",
        "sql": "CREATE VIEW names AS SELECT name FROM users;",
        "dart_info_name": "Names",
        "columns": [
          {
            "name": "name",
            "getter_name": "name",
            "moor_type": "string",
            "nullable": true,
            "customConstraints": null,
            "default_dart": null,
            "default_client_dart": null,
            "dsl_features": []
          }
        ]
      }
    },
    {
      "id": 2,
      "references": [
        0
      ],
      "type": "trigger",
      "data": {
        "on": 0,
        "references_in_body": [
          0
        ],
        "name": "to_upper",
        "sql": "CREATE TRIGGER to_upper AFTER UPDATE ON users BEGIN   UPDATE users SET name = upper(new.name) where id = new.id;END;"
      }
    },
    {
      "id": 3,
      "references": [
        0
      ],
      "type": "index",
      "data": {
        "on": 0,
        "name": "idx",
        "sql": "CREATE INDEX idx ON users (name);",
        "unique": false,
        "columns": []
      }
    }
  ]
}
          '''),
        ),
      ),
    ]));
  });
}
