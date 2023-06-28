import 'package:drift/internal/versioned_schema.dart' as i0;
import 'package:drift/drift.dart' as i1;
import 'package:drift/drift.dart';

final class VersionedSchema extends i0.VersionedSchema {
  VersionedSchema(super.database);
  late final List<i1.DatabaseSchemaEntity> entities = [
    // VERSION 1
    i0.VersionedTable(
      entityName: 'users',
      withoutRowId: false,
      isStrict: false,
      attachedDatabase: database,
      columns: [
        column_0,
      ],
      tableConstraints: [],
    ),
    // VERSION 2
    i0.VersionedTable(
      entityName: 'users',
      withoutRowId: false,
      isStrict: false,
      attachedDatabase: database,
      columns: [
        column_0,
        column_1,
      ],
      tableConstraints: [],
    ),
    // VERSION 3
    i0.VersionedTable(
      entityName: 'users',
      withoutRowId: false,
      isStrict: false,
      attachedDatabase: database,
      columns: [
        column_0,
        column_1,
      ],
      tableConstraints: [],
    ),
    i0.VersionedTable(
      entityName: 'groups',
      withoutRowId: false,
      isStrict: false,
      attachedDatabase: database,
      columns: [
        column_2,
        column_3,
        column_4,
        column_5,
      ],
      tableConstraints: [],
    ),
    // VERSION 4
    i0.VersionedTable(
      entityName: 'users',
      withoutRowId: false,
      isStrict: false,
      attachedDatabase: database,
      columns: [
        column_0,
        column_6,
      ],
      tableConstraints: [],
    ),
    i0.VersionedTable(
      entityName: 'groups',
      withoutRowId: false,
      isStrict: false,
      attachedDatabase: database,
      columns: [
        column_2,
        column_3,
        column_4,
        column_5,
      ],
      tableConstraints: [],
    ),
    // VERSION 5
    i0.VersionedTable(
      entityName: 'users',
      withoutRowId: false,
      isStrict: false,
      attachedDatabase: database,
      columns: [
        column_0,
        column_6,
        column_7,
      ],
      tableConstraints: [],
    ),
    i0.VersionedTable(
      entityName: 'groups',
      withoutRowId: false,
      isStrict: false,
      attachedDatabase: database,
      columns: [
        column_2,
        column_3,
        column_4,
        column_5,
      ],
      tableConstraints: [],
    ),
    null,
    // VERSION 6
    i0.VersionedTable(
      entityName: 'users',
      withoutRowId: false,
      isStrict: false,
      attachedDatabase: database,
      columns: [
        column_0,
        column_6,
        column_8,
        column_7,
      ],
      tableConstraints: [],
    ),
    i0.VersionedTable(
      entityName: 'groups',
      withoutRowId: false,
      isStrict: false,
      attachedDatabase: database,
      columns: [
        column_2,
        column_3,
        column_4,
        column_5,
      ],
      tableConstraints: [],
    ),
    null,
    // VERSION 7
    i0.VersionedTable(
      entityName: 'users',
      withoutRowId: false,
      isStrict: false,
      attachedDatabase: database,
      columns: [
        column_0,
        column_6,
        column_8,
        column_7,
      ],
      tableConstraints: [],
    ),
    i0.VersionedTable(
      entityName: 'groups',
      withoutRowId: false,
      isStrict: false,
      attachedDatabase: database,
      columns: [
        column_2,
        column_3,
        column_4,
        column_5,
      ],
      tableConstraints: [],
    ),
    null,
    i0.VersionedTable(
      entityName: 'notes',
      withoutRowId: false,
      isStrict: false,
      attachedDatabase: database,
      columns: [
        column_9,
        column_10,
        column_11,
      ],
      tableConstraints: [],
    ),
    // VERSION 8
    i0.VersionedTable(
      entityName: 'users',
      withoutRowId: false,
      isStrict: false,
      attachedDatabase: database,
      columns: [
        column_0,
        column_6,
        column_8,
        column_12,
      ],
      tableConstraints: [],
    ),
    i0.VersionedTable(
      entityName: 'groups',
      withoutRowId: false,
      isStrict: false,
      attachedDatabase: database,
      columns: [
        column_2,
        column_3,
        column_4,
        column_5,
      ],
      tableConstraints: [],
    ),
    null,
    i0.VersionedTable(
      entityName: 'notes',
      withoutRowId: false,
      isStrict: false,
      attachedDatabase: database,
      columns: [
        column_9,
        column_10,
        column_11,
      ],
      tableConstraints: [],
    ),
    // VERSION 9
    i0.VersionedTable(
      entityName: 'users',
      withoutRowId: false,
      isStrict: false,
      attachedDatabase: database,
      columns: [
        column_0,
        column_6,
        column_8,
        column_7,
      ],
      tableConstraints: [],
    ),
    i0.VersionedTable(
      entityName: 'groups',
      withoutRowId: false,
      isStrict: false,
      attachedDatabase: database,
      columns: [
        column_2,
        column_3,
        column_13,
        column_14,
      ],
      tableConstraints: [],
    ),
    i0.VersionedTable(
      entityName: 'notes',
      withoutRowId: false,
      isStrict: false,
      attachedDatabase: database,
      columns: [
        column_9,
        column_10,
        column_11,
      ],
      tableConstraints: [],
    ),
    null,
  ];
  @override
  Iterable<i1.DatabaseSchemaEntity> allEntitiesAt(int version) {
    int start, count;
    switch (version) {
      case 1:
        start = 0;
        count = 1;
      case 2:
        start = 1;
        count = 1;
      case 3:
        start = 2;
        count = 2;
      case 4:
        start = 4;
        count = 2;
      case 5:
        start = 6;
        count = 3;
      case 6:
        start = 9;
        count = 3;
      case 7:
        start = 12;
        count = 4;
      case 8:
        start = 16;
        count = 4;
      case 9:
        start = 20;
        count = 4;
      default:
        throw ArgumentError('Unknown schema version $version');
    }
    return entities.skip(start).take(count);
  }
}

i1.GeneratedColumn<int> column_0(String aliasedName) =>
    i1.GeneratedColumn<int>('id', aliasedName, false,
        hasAutoIncrement: true,
        type: i1.DriftSqlType.int,
        defaultConstraints:
            i1.GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
i1.GeneratedColumn<String> column_1(String aliasedName) =>
    i1.GeneratedColumn<String>('name', aliasedName, false,
        type: i1.DriftSqlType.string);
i1.GeneratedColumn<int> column_2(String aliasedName) =>
    i1.GeneratedColumn<int>('id', aliasedName, false,
        type: i1.DriftSqlType.int, $customConstraints: 'NOT NULL');
i1.GeneratedColumn<String> column_3(String aliasedName) =>
    i1.GeneratedColumn<String>('title', aliasedName, false,
        type: i1.DriftSqlType.string, $customConstraints: 'NOT NULL');
i1.GeneratedColumn<bool> column_4(String aliasedName) =>
    i1.GeneratedColumn<bool>('deleted', aliasedName, true,
        type: i1.DriftSqlType.bool,
        $customConstraints: 'DEFAULT FALSE',
        defaultValue: const CustomExpression<bool>('FALSE'));
i1.GeneratedColumn<int> column_5(String aliasedName) =>
    i1.GeneratedColumn<int>('owner', aliasedName, false,
        type: i1.DriftSqlType.int,
        $customConstraints: 'NOT NULL REFERENCES users (id)');
i1.GeneratedColumn<String> column_6(String aliasedName) =>
    i1.GeneratedColumn<String>('name', aliasedName, false,
        type: i1.DriftSqlType.string, defaultValue: const Constant('name'));
i1.GeneratedColumn<int> column_7(String aliasedName) =>
    i1.GeneratedColumn<int>('next_user', aliasedName, true,
        type: i1.DriftSqlType.int,
        defaultConstraints:
            i1.GeneratedColumn.constraintIsAlways('REFERENCES users (id)'));
i1.GeneratedColumn<DateTime> column_8(String aliasedName) =>
    i1.GeneratedColumn<DateTime>('birthday', aliasedName, true,
        type: i1.DriftSqlType.dateTime);
i1.GeneratedColumn<String> column_9(String aliasedName) =>
    i1.GeneratedColumn<String>('title', aliasedName, false,
        type: i1.DriftSqlType.string, $customConstraints: '');
i1.GeneratedColumn<String> column_10(String aliasedName) =>
    i1.GeneratedColumn<String>('content', aliasedName, false,
        type: i1.DriftSqlType.string, $customConstraints: '');
i1.GeneratedColumn<String> column_11(String aliasedName) =>
    i1.GeneratedColumn<String>('search_terms', aliasedName, false,
        type: i1.DriftSqlType.string, $customConstraints: '');
i1.GeneratedColumn<int> column_12(String aliasedName) =>
    i1.GeneratedColumn<int>('next_user', aliasedName, true,
        type: i1.DriftSqlType.int,
        defaultConstraints:
            i1.GeneratedColumn.constraintIsAlways('REFERENCES "users" ("id")'));
i1.GeneratedColumn<bool> column_13(String aliasedName) =>
    i1.GeneratedColumn<bool>('deleted', aliasedName, true,
        type: i1.DriftSqlType.bool,
        $customConstraints: 'DEFAULT FALSE',
        defaultValue: const CustomExpression('FALSE'));
i1.GeneratedColumn<int> column_14(String aliasedName) =>
    i1.GeneratedColumn<int>('owner', aliasedName, false,
        type: i1.DriftSqlType.int,
        $customConstraints: 'NOT NULL REFERENCES users(id)');
