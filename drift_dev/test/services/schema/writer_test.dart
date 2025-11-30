@Tags(['analyzer'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:build_config/build_config.dart';
import 'package:drift/backends.dart';
import 'package:drift_dev/src/analysis/options.dart';
import 'package:drift_dev/src/cli/cli.dart';
import 'package:drift_dev/src/cli/commands/schema.dart';
import 'package:drift_dev/src/cli/commands/schema/generate_utils.dart';
import 'package:drift_dev/src/cli/project.dart';
import 'package:drift_dev/src/services/schema/schema_files.dart';
import 'package:drift_dev/src/utils/string_escaper.dart';
import 'package:test_descriptor/test_descriptor.dart';
import 'package:test/test.dart';

import '../../analysis/test_utils.dart';

void main() {
  test('writer integration test', () async {
    const options = DriftOptions.defaults(
      dialect: DialectOptions(
        null,
        [SqlDialect.sqlite, SqlDialect.postgres],
        SqliteAnalysisOptions(
          modules: [SqlModule.fts5],
        ),
      ),
    );
    final state = await TestBackend.inTest(
      {
        'a|lib/a.drift': '''
import 'main.dart';

CREATE TABLE "groups" (
  id INT NOT NULL PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  name2 TEXT NOT NULL GENERATED ALWAYS AS (upper(name)) VIRTUAL,

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

CREATE TRIGGER my_view_trigger INSTEAD OF UPDATE ON my_view BEGIN
  UPDATE "groups" SET id = old.id;
END;

simple_query: SELECT * FROM my_view; -- not part of the schema

@create: INSERT INTO "groups" ("name") VALUES ('test');
      ''',
        'a|lib/main.dart': '''
import 'package:drift/drift.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get settings => text()
    .check(settings.length.isBiggerThanValue(10))
    .named('setting')
    .withDefault(Constant('foo' + 'bar'))
    .map(const SettingsConverter())();

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
      },
      options: options,
    );

    final file = await state.analyze('package:a/main.dart');
    await state.analyze('package:a/a.drift');
    state.expectNoErrors();

    final db = file.fileAnalysis!.resolvedDatabases.values.single;

    final schemaJson =
        await SchemaWriter(db.availableElements, options: options)
            .createSchemaJson();

    expect(schemaJson, json.decode(expected));

    final schemaWithOptions = await SchemaWriter(
      db.availableElements,
      options: const DriftOptions.defaults(storeDateTimeValuesAsText: true),
    ).createSchemaJson();
    expect(
        schemaWithOptions['options'], {'store_date_time_values_as_text': true});
  });

  group('can generate code from schema json', () {
    for (final withFixedSql in [false, true]) {
      test(withFixedSql ? 'with fixed sql' : 'without fixed sql', () async {
        var serializedSchema = json.decode(
            // Column types used to be serialized under a different format, test
            // reading that as well.
            expected.replaceAll(
                '"int"', '"ColumnType.integer"')) as Map<String, dynamic>;
        serializedSchema = Map.of(serializedSchema);
        if (!withFixedSql) {
          serializedSchema.remove('fixed_sql');
        }

        final reader = await SchemaReader.readJson(serializedSchema);

        final fakeBuildConfig = runInBuildConfigZone(() {
          return BuildConfig(buildTargets: {});
        }, 'drift_dev', []);
        final generated = await GenerateUtils.generateSchemaCode(
          DriftDevCli()
            ..project = DriftProject(fakeBuildConfig, Directory(sandbox)),
          1,
          ExportedSchema(reader.entities.toList(), {}),
          false,
          false,
        );

        if (withFixedSql) {
          expect(generated, contains('CHECK (LENGTH(setting) > 10)'));
        } else {
          expect(
              generated,
              contains(
                  'ComparableExpr(settings.length).isBiggerThanValue(10)'));
        }

        expect(
            generated,
            contains(
                "OnCreateQuery('INSERT INTO \"groups\" (name) VALUES (\\'test\\')')"));
      });
    }
  });

  test('can export Dart-defined views', () async {
    final backend = await TestBackend.inTest({
      'a|lib/main.dart': '''
import 'package:drift/drift.dart';

class MyTable extends Table {
  IntColumn get id => integer()();
}

class MyView extends View {
  MyTable get a;
  MyTable get b;
  MyTable get c;

  @override
  Query as() => select([
    a.id,
    b.id,
    c.id,
  ]).from(a).join([
    innerJoin(b, b.id.equalsExp(a.id)),
    innerJoin(c, c.id.equalsExp(a.id)),
  ]);
}

@DriftDatabase(tables: [MyTable], views: [MyView])
class Database {}
''',
    });

    final file = await backend.analyze('package:a/main.dart');
    backend.expectNoErrors();

    final db = file.fileAnalysis!.resolvedDatabases.values.single;

    final schemaJson =
        await SchemaWriter(db.availableElements).createSchemaJson();
    final serializedView = (schemaJson['entities'] as List)[1];

    expect(serializedView['data'], {
      'name': 'my_view',
      'sql':
          'CREATE VIEW IF NOT EXISTS "my_view" ("id", "id1", "id2") AS SELECT "t0"."id" AS "id", "t1"."id" AS "id1", "t2"."id" AS "id2" FROM "my_table" "t0" INNER JOIN "my_table" "t1" ON "t1"."id" = "t0"."id" INNER JOIN "my_table" "t2" ON "t2"."id" = "t0"."id"',
      'dart_info_name': r'$MyViewView',
      'columns': everyElement(containsPair('dsl_features', [
        // Views should include generated_as information about each column.
        containsPair('generated_as', anything),
      ])),
    });

    final reader = await SchemaReader.readJson(schemaJson);
    final fakeBuildConfig = runInBuildConfigZone(() {
      return BuildConfig(buildTargets: {});
    }, 'drift_dev', []);
    final generated = await GenerateUtils.generateSchemaCode(
      DriftDevCli()
        ..project = DriftProject(fakeBuildConfig, Directory(sandbox)),
      1,
      ExportedSchema(reader.entities.toList(), {}),
      false,
      false,
    );

    // The generated_as constraint is not applicable for views when we generate
    // columns, so it shouldn't be generated there.
    expect(generated, isNot(contains('GeneratedAs')));
  });

  test('can export Dart-defined index', () async {
    final backend = await TestBackend.inTest({
      'a|lib/main.dart': '''
import 'package:drift/drift.dart';

@TableIndex(name: 'tbl_name', columns: {IndexedColumn(#name, orderBy: OrderingMode.desc)})
class MyTable extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
}

@DriftDatabase(tables: [MyTable])
class Database {}
''',
    });

    final file = await backend.analyze('package:a/main.dart');
    backend.expectNoErrors();

    final db = file.fileAnalysis!.resolvedDatabases.values.single;

    final schemaJson =
        await SchemaWriter(db.availableElements).createSchemaJson();
    // Force testing with old format that doesn't have the actual SQL statements
    // yet.
    schemaJson.remove('fixed_sql');
    final serializedIndex = (schemaJson['entities'] as List)[1];

    expect(serializedIndex['data'], {
      'on': 0,
      'name': 'tbl_name',
      'sql': null,
      'unique': false,
      'columns': [
        {'column': 'name', 'order_by': 'descending'}
      ]
    });

    final newFormat = schemaJson;
    // Older versions of drift_dev used to only include the column name in the
    // schema and did not support specifying an ordering mode.
    final oldFormat = json.decode(json.encode(newFormat));
    oldFormat['entities'][1]['data']['columns'] = ['name'];

    for (final format in [oldFormat, newFormat]) {
      final reader =
          await SchemaReader.readJson(format as Map<String, Object?>);
      final fakeBuildConfig = runInBuildConfigZone(() {
        return BuildConfig(buildTargets: {});
      }, 'drift_dev', []);
      final generated = await GenerateUtils.generateSchemaCode(
        DriftDevCli()
          ..project = DriftProject(fakeBuildConfig, Directory(sandbox)),
        1,
        ExportedSchema(reader.entities.toList(), {}),
        false,
        false,
      );

      if (format == newFormat) {
        expect(generated,
            contains('CREATE INDEX tbl_name ON my_table (name DESC)'));
      } else {
        expect(generated, contains('CREATE INDEX tbl_name ON my_table (name)'));
      }
    }
  });

  group('generates correct datetime mode', () {
    Future<void> runTest(bool storeAsText, String expectedDefault) async {
      final options =
          DriftOptions.defaults(storeDateTimeValuesAsText: storeAsText);
      final backend = await TestBackend.inTest(
        {
          'a|lib/main.dart': '''
import 'package:drift/drift.dart';

class MyTable extends Table {
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [MyTable])
class Database {}
''',
        },
        options: options,
      );

      final file = await backend.analyze('package:a/main.dart');
      backend.expectNoErrors();

      final db = file.fileAnalysis!.resolvedDatabases.values.single;

      final schemaJson =
          await SchemaWriter(db.availableElements, options: options)
              .createSchemaJson();
      final serializedTable = (schemaJson['entities'] as List)[0];
      final data = serializedTable['data'];
      expect(data, {
        'name': 'my_table',
        'was_declared_in_moor': false,
        'is_virtual': false,
        'without_rowid': false,
        'columns': hasLength(1),
        'constraints': [],
      });

      expect(
        data['columns'][0]['default_dart'],
        'const CustomExpression(${asDartLiteral(expectedDefault)})',
      );
    }

    test('with integer times', () async {
      await runTest(
          false, "CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)");
    });

    test('with text times', () async {
      await runTest(true, 'CURRENT_TIMESTAMP');
    });
  });

  test('merges SQL for @create queries', () async {
    final options = DriftOptions.defaults();
    final backend = await TestBackend.inTest(
      {
        'a|lib/main.drift': '''
CREATE TABLE foo (bar TEXT);

@create: INSERT INTO foo DEFAULT VALUES;
@create: UPDATE foo SET bar = 'testing';
''',
      },
    );

    final file = await backend.analyze('package:a/main.drift');
    backend.expectNoErrors();

    final schemaJson =
        await SchemaWriter(file.analyzedElements.toList(), options: options)
            .createSchemaJson();
    final reader = await SchemaReader.readJson(schemaJson);
    final fakeBuildConfig = runInBuildConfigZone(() {
      return BuildConfig(buildTargets: {});
    }, 'drift_dev', []);
    final generated = await GenerateUtils.generateSchemaCode(
      DriftDevCli()
        ..project = DriftProject(fakeBuildConfig, Directory(sandbox)),
      1,
      ExportedSchema(reader.entities.toList(), {}),
      false,
      false,
    );

    expect(generated, contains('INSERT INTO foo DEFAULT VALUES'));
    expect(generated, contains("UPDATE foo SET bar = \\'testing\\'"));
  });
}

const expected = r'''
{
  "_meta": {
    "description": "This file contains a serialized version of schema entities for drift.",
    "version": "1.3.0"
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
          },
          {
            "name": "name2",
            "getter_name": "name2",
            "moor_type": "string",
            "nullable": false,
            "customConstraints": "NOT NULL GENERATED ALWAYS AS (upper(name)) VIRTUAL",
            "default_dart": null,
            "default_client_dart": null,
            "dsl_features": [
              {
                "generated_as": {
                  "dart_expression": {
                    "elements": [
                      "const ",
                      {
                        "lexeme": "CustomExpression",
                        "import_uri": "package:drift/drift.dart"
                      },
                      "('upper(name)')"
                    ]
                  },
                  "stored": false
                }
              }
            ]
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
            "dialectAwareDefaultConstraints": {
              "sqlite": "PRIMARY KEY AUTOINCREMENT",
              "postgres": "PRIMARY KEY AUTOINCREMENT"
            },
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
            "default_dart": "const CustomExpression('\\'foobar\\'')",
            "default_client_dart": null,
            "dsl_features": [
              {
                "check": {
                  "dart_expression": {
                    "elements": [
                      {
                        "lexeme": "ComparableExpr",
                        "import_uri": "package:drift/src/runtime/query_builder/query_builder.dart"
                      },
                      "(",
                      {
                        "lexeme": "settings",
                        "tag": "settings"
                      },
                      ".length).isBiggerThanValue(10)"
                    ]
                  }
                }
              }
            ],
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
              {
                "foreign_key": {
                  "to": {
                    "table": "groups",
                    "column": "id"
                  },
                  "initially_deferred": false,
                  "on_update": null,
                  "on_delete": null
                }
              }
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
              {
                "foreign_key": {
                  "to": {
                    "table": "users",
                    "column": "id"
                  },
                  "initially_deferred": false,
                  "on_update": null,
                  "on_delete": null
                }
              }
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
        "sql": "CREATE VIEW my_view AS SELECT id FROM \"groups\"",
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
    },
    {
      "id": 7,
      "references": [
        6,
        0
      ],
      "type": "trigger",
      "data": {
        "on": 6,
        "references_in_body": [
          6,
          0
        ],
        "name": "my_view_trigger",
        "sql": "CREATE TRIGGER my_view_trigger INSTEAD OF UPDATE ON my_view BEGIN\n  UPDATE \"groups\" SET id = old.id;\nEND;"
      }
    },
    {
      "id": 8,
      "references": [
        0
      ],
      "type": "special-query",
      "data": {
        "scenario": "create",
        "sql": "INSERT INTO \"groups\" (\"name\") VALUES ('test')"
      }
    }
  ],
  "fixed_sql": [
    {
      "name": "groups",
      "sql": [
        {
          "dialect": "sqlite",
          "sql": "CREATE TABLE IF NOT EXISTS \"groups\" (\"id\" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, \"name\" TEXT NOT NULL, \"name2\" TEXT NOT NULL GENERATED ALWAYS AS (upper(name)) VIRTUAL, UNIQUE(name));"
        },
        {
          "dialect": "postgres",
          "sql": "CREATE TABLE IF NOT EXISTS \"groups\" (\"id\" bigserial PRIMARY KEY NOT NULL NOT NULL PRIMARY KEY AUTOINCREMENT, \"name\" text NOT NULL, \"name2\" text NOT NULL GENERATED ALWAYS AS (upper(name)) VIRTUAL, UNIQUE(name));"
        }
      ]
    },
    {
      "name": "email",
      "sql": [
        {
          "dialect": "sqlite",
          "sql": "CREATE VIRTUAL TABLE IF NOT EXISTS \"email\" USING fts5(sender, title, body);"
        },
        {
          "dialect": "postgres",
          "sql": "CREATE VIRTUAL TABLE IF NOT EXISTS \"email\" USING fts5(sender, title, body);"
        }
      ]
    },
    {
      "name": "users",
      "sql": [
        {
          "dialect": "sqlite",
          "sql": "CREATE TABLE IF NOT EXISTS \"users\" (\"id\" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, \"name\" TEXT NOT NULL, \"setting\" TEXT NOT NULL DEFAULT 'foobar' CHECK(LENGTH(\"setting\") > 10), UNIQUE (\"name\", \"setting\"));"
        },
        {
          "dialect": "postgres",
          "sql": "CREATE TABLE IF NOT EXISTS \"users\" (\"id\" bigserial PRIMARY KEY NOT NULL, \"name\" text NOT NULL, \"setting\" text NOT NULL DEFAULT 'foobar' CHECK(LENGTH(\"setting\") > 10), UNIQUE (\"name\", \"setting\"));"
        }
      ]
    },
    {
      "name": "group_members",
      "sql": [
        {
          "dialect": "sqlite",
          "sql": "CREATE TABLE IF NOT EXISTS \"group_members\" (\"group\" INTEGER NOT NULL REFERENCES \"groups\"(id), \"user\" INTEGER NOT NULL REFERENCES users(id), \"is_admin\" INTEGER NOT NULL DEFAULT FALSE, PRIMARY KEY(\"group\", user)ON CONFLICT REPLACE);"
        },
        {
          "dialect": "postgres",
          "sql": "CREATE TABLE IF NOT EXISTS \"group_members\" (\"group\" bigint NOT NULL REFERENCES \"groups\"(id), \"user\" bigint NOT NULL REFERENCES users(id), \"is_admin\" boolean NOT NULL DEFAULT FALSE, PRIMARY KEY(\"group\", user)ON CONFLICT REPLACE);"
        }
      ]
    },
    {
      "name": "delete_empty_groups",
      "sql": [
        {
          "dialect": "sqlite",
          "sql": "CREATE TRIGGER delete_empty_groups AFTER DELETE ON group_members BEGIN DELETE FROM \"groups\" WHERE NOT EXISTS (SELECT * FROM group_members WHERE \"group\" = \"groups\".id);END"
        },
        {
          "dialect": "postgres",
          "sql": "CREATE TRIGGER delete_empty_groups AFTER DELETE ON group_members BEGIN DELETE FROM \"groups\" WHERE NOT EXISTS (SELECT * FROM group_members WHERE \"group\" = \"groups\".id);END"
        }
      ]
    },
    {
      "name": "groups_name",
      "sql": [
        {
          "dialect": "sqlite",
          "sql": "CREATE INDEX groups_name ON \"groups\" (name, upper(name))"
        },
        {
          "dialect": "postgres",
          "sql": "CREATE INDEX groups_name ON \"groups\" (name, upper(name))"
        }
      ]
    },
    {
      "name": "my_view",
      "sql": [
        {
          "dialect": "sqlite",
          "sql": "CREATE VIEW my_view AS SELECT id FROM \"groups\""
        },
        {
          "dialect": "postgres",
          "sql": "CREATE VIEW my_view AS SELECT id FROM \"groups\""
        }
      ]
    },
    {
      "name": "my_view_trigger",
      "sql": [
        {
          "dialect": "sqlite",
          "sql": "CREATE TRIGGER my_view_trigger INSTEAD OF UPDATE ON my_view BEGIN UPDATE \"groups\" SET id = old.id;END"
        },
        {
          "dialect": "postgres",
          "sql": "CREATE TRIGGER my_view_trigger INSTEAD OF UPDATE ON my_view BEGIN UPDATE \"groups\" SET id = old.id;END"
        }
      ]
    },
    {
      "name": "$internal$",
      "sql": [
        {
          "dialect": "sqlite",
          "sql": "INSERT INTO \"groups\" (name) VALUES ('test')"
        },
        {
          "dialect": "postgres",
          "sql": "INSERT INTO \"groups\" (name) VALUES ('test')"
        }
      ]
    }
  ]
}
''';
