@Tags(['analyzer'])
import 'dart:convert';

import 'package:drift_dev/src/analysis/options.dart';
import 'package:drift_dev/src/analysis/results/file_results.dart';
import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:drift_dev/src/services/schema/schema_files.dart';
import 'package:drift_dev/src/writer/database_writer.dart';
import 'package:drift_dev/src/writer/import_manager.dart';
import 'package:drift_dev/src/writer/writer.dart';
import 'package:test/test.dart';

import '../../analysis/test_utils.dart';

void main() {
  test('writer integration test', () async {
    final state = TestBackend.inTest({
      'a|lib/a.drift': '''
import 'main.dart';

CREATE TABLE "groups" (
  id INT NOT NULL PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,

  UNIQUE(name)
);

CREATE VIRTUAL TABLE email USING fts5(sender, title, body);

CREATE TABLE group_members (
  "group" INT NOT NULL REFERENCES "groups"(id),
  user INT NOT NULL REFERENCES users(id),
  is_admin BOOLEAN NOT NULL DEFAULT FALSE,

  PRIMARY KEY ("group", user) ON CONFLICT REPLACE
);

CREATE TRIGGER delete_empty_groups AFTER DELETE ON group_members BEGIN
  DELETE FROM "groups"
    WHERE NOT EXISTS (SELECT * FROM group_members WHERE "group" = "groups".id);
END;

CREATE INDEX groups_name ON "groups"(name, upper(name));

CREATE VIEW my_view WITH MyViewRow AS SELECT id FROM "groups";

simple_query: SELECT * FROM my_view; -- not part of the schema
      ''',
      'a|lib/main.dart': '''
import 'package:drift/drift.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get settings => text().named('setting').map(const SettingsConverter())();

  @override
  List<Set<Column>> get uniqueKeys => [{name, settings}];
}

class Settings {}

class SettingsConverter extends TypeConverter<Settings, String> {
  const SettingsConverter();

  String toSql(Settings s) => '';
  Settings fromSql(String db) => Settings();
}

class MyViewRow {
  final int id;
  MyViewRow(this.id);
}

@DriftDatabase(include: {'a.drift'}, tables: [Users])
class Database {}
      ''',
    }, options: const DriftOptions.defaults(modules: [SqlModule.fts5]));

    final file = await state.analyze('package:a/main.dart');
    state.expectNoErrors();

    final db = file.fileAnalysis!.resolvedDatabases.values.single;

    final schemaJson = SchemaWriter(db.availableElements).createSchemaJson();

    expect(schemaJson, json.decode(expected));

    final schemaWithOptions = SchemaWriter(
      db.availableElements,
      options: const DriftOptions.defaults(storeDateTimeValuesAsText: true),
    ).createSchemaJson();
    expect(
        schemaWithOptions['options'], {'store_date_time_values_as_text': true});
  });

  test('can generate code from schema json', () {
    final serializedSchema = json.decode(
            // Column types used to be serialized under a different format, test
            // reading that as well.
            expected.replaceAll('"int"', '"ColumnType.integer"'))
        as Map<String, dynamic>;
    final reader = SchemaReader.readJson(serializedSchema);

    final writer = Writer(
      const DriftOptions.defaults(),
      generationOptions: GenerationOptions(
        forSchema: 1,
        writeCompanions: true,
        writeDataClasses: true,
        imports: ImportManagerForPartFiles(),
      ),
    );

    final database = DriftDatabase(
      id: DriftElementId(SchemaReader.elementUri, 'database'),
      declaration: DriftDeclaration(SchemaReader.elementUri, 0, 'database'),
      declaredIncludes: const [],
      declaredQueries: const [],
      declaredTables: const [],
      declaredViews: const [],
    );
    final resolved =
        ResolvedDatabaseAccessor(const {}, const [], reader.entities.toList());
    final input = DatabaseGenerationInput(database, resolved, const {}, null);

    // Write the database. Not crashing is good enough for us here, we have
    // separate tests for verification
    DatabaseWriter(input, writer.child()).write();
  });
}

const expected = r'''
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
                "without_rowid": false,
                "constraints": [
                    "UNIQUE(name)"
                ],
                "unique_keys": [
                    [
                        "name"
                    ]
                ]
            }
        },
        {
            "id": 1,
            "references": [],
            "type": "table",
            "data": {
                "name": "email",
                "was_declared_in_moor": true,
                "columns": [
                    {
                        "name": "sender",
                        "getter_name": "sender",
                        "moor_type": "string",
                        "nullable": false,
                        "customConstraints": "",
                        "default_dart": null,
                        "default_client_dart": null,
                        "dsl_features": []
                    },
                    {
                        "name": "title",
                        "getter_name": "title",
                        "moor_type": "string",
                        "nullable": false,
                        "customConstraints": "",
                        "default_dart": null,
                        "default_client_dart": null,
                        "dsl_features": []
                    },
                    {
                        "name": "body",
                        "getter_name": "body",
                        "moor_type": "string",
                        "nullable": false,
                        "customConstraints": "",
                        "default_dart": null,
                        "default_client_dart": null,
                        "dsl_features": []
                    }
                ],
                "is_virtual": true,
                "create_virtual_stmt": "CREATE VIRTUAL TABLE \"email\" USING fts5(sender, title, body)",
                "without_rowid": false,
                "constraints": []
            }
        },
        {
            "id": 2,
            "references": [],
            "type": "table",
            "data": {
                "name": "users",
                "was_declared_in_moor": false,
                "columns": [
                    {
                        "name": "id",
                        "getter_name": "id",
                        "moor_type": "int",
                        "nullable": false,
                        "customConstraints": null,
                        "defaultConstraints": "PRIMARY KEY AUTOINCREMENT",
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
                        "customConstraints": null,
                        "default_dart": null,
                        "default_client_dart": null,
                        "dsl_features": []
                    },
                    {
                        "name": "setting",
                        "getter_name": "settings",
                        "moor_type": "string",
                        "nullable": false,
                        "customConstraints": null,
                        "default_dart": null,
                        "default_client_dart": null,
                        "dsl_features": [],
                        "type_converter": {
                            "dart_expr": "const SettingsConverter()",
                            "dart_type_name": "Settings"
                        }
                    }
                ],
                "is_virtual": false,
                "without_rowid": false,
                "constraints": [],
                "unique_keys": [
                    [
                        "name",
                        "setting"
                    ]
                ]
            }
        },
        {
            "id": 3,
            "references": [
                0,
                2
            ],
            "type": "table",
            "data": {
                "name": "group_members",
                "was_declared_in_moor": true,
                "columns": [
                    {
                        "name": "group",
                        "getter_name": "group",
                        "moor_type": "int",
                        "nullable": false,
                        "customConstraints": "NOT NULL REFERENCES \"groups\"(id)",
                        "default_dart": null,
                        "default_client_dart": null,
                        "dsl_features": [
                            "unknown"
                        ]
                    },
                    {
                        "name": "user",
                        "getter_name": "user",
                        "moor_type": "int",
                        "nullable": false,
                        "customConstraints": "NOT NULL REFERENCES users(id)",
                        "default_dart": null,
                        "default_client_dart": null,
                        "dsl_features": [
                            "unknown"
                        ]
                    },
                    {
                        "name": "is_admin",
                        "getter_name": "isAdmin",
                        "moor_type": "bool",
                        "nullable": false,
                        "customConstraints": "NOT NULL DEFAULT FALSE",
                        "default_dart": "const CustomExpression('FALSE')",
                        "default_client_dart": null,
                        "dsl_features": []
                    }
                ],
                "is_virtual": false,
                "without_rowid": false,
                "constraints": [
                    "PRIMARY KEY(\"group\", user)ON CONFLICT REPLACE"
                ],
                "explicit_pk": [
                    "group",
                    "user"
                ]
            }
        },
        {
            "id": 4,
            "references": [
                3,
                0
            ],
            "type": "trigger",
            "data": {
                "on": 3,
                "references_in_body": [
                    3,
                    0
                ],
                "name": "delete_empty_groups",
                "sql": "CREATE TRIGGER delete_empty_groups AFTER DELETE ON group_members BEGIN\n  DELETE FROM \"groups\"\n    WHERE NOT EXISTS (SELECT * FROM group_members WHERE \"group\" = \"groups\".id);\nEND;"
            }
        },
        {
            "id": 5,
            "references": [
                0
            ],
            "type": "index",
            "data": {
                "on": 0,
                "name": "groups_name",
                "sql": "CREATE INDEX groups_name ON \"groups\"(name, upper(name));",
                "unique": false,
                "columns": []
            }
        },
        {
            "id": 6,
            "references": [
                0
            ],
            "type": "view",
            "data": {
                "name": "my_view",
                "sql": "CREATE VIEW my_view AS SELECT id FROM \"groups\";",
                "dart_info_name": "MyView",
                "columns": [
                    {
                        "name": "id",
                        "getter_name": "id",
                        "moor_type": "int",
                        "nullable": false,
                        "customConstraints": null,
                        "default_dart": null,
                        "default_client_dart": null,
                        "dsl_features": []
                    }
                ]
            }
        }
    ]
}
''';
