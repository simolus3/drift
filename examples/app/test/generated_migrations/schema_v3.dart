// GENERATED CODE, DO NOT EDIT BY HAND.
//@dart=2.12
import 'package:drift/drift.dart';

class Categories extends Table with TableInfo {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Categories(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
      'color', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, name, color];
  @override
  String get aliasedName => _alias ?? 'categories';
  @override
  String get actualTableName => 'categories';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Never map(Map<String, dynamic> data, {String? tablePrefix}) {
    throw UnsupportedError('TableInfo.map in schema verification code');
  }

  @override
  Categories createAlias(String alias) {
    return Categories(attachedDatabase, alias);
  }
}

class TodoEntries extends Table with TableInfo {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  TodoEntries(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<int> category = GeneratedColumn<int>(
      'category', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES categories (id)'));
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
      'due_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [id, description, category, dueDate];
  @override
  String get aliasedName => _alias ?? 'todo_entries';
  @override
  String get actualTableName => 'todo_entries';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Never map(Map<String, dynamic> data, {String? tablePrefix}) {
    throw UnsupportedError('TableInfo.map in schema verification code');
  }

  @override
  TodoEntries createAlias(String alias) {
    return TodoEntries(attachedDatabase, alias);
  }
}

class TextEntries extends Table with TableInfo, VirtualTableInfo {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  TextEntries(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: '');
  @override
  List<GeneratedColumn> get $columns => [description];
  @override
  String get aliasedName => _alias ?? 'text_entries';
  @override
  String get actualTableName => 'text_entries';
  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  Never map(Map<String, dynamic> data, {String? tablePrefix}) {
    throw UnsupportedError('TableInfo.map in schema verification code');
  }

  @override
  TextEntries createAlias(String alias) {
    return TextEntries(attachedDatabase, alias);
  }

  @override
  String get moduleAndArgs =>
      'fts5(description, content=todo_entries, content_rowid=id)';
}

class DatabaseAtV3 extends GeneratedDatabase {
  DatabaseAtV3(QueryExecutor e) : super(e);
  DatabaseAtV3.connect(DatabaseConnection c) : super.connect(c);
  late final Categories categories = Categories(this);
  late final TodoEntries todoEntries = TodoEntries(this);
  late final TextEntries textEntries = TextEntries(this);
  late final Trigger todosInsert = Trigger(
      'CREATE TRIGGER todos_insert AFTER INSERT ON todo_entries BEGIN INSERT INTO text_entries ("rowid", description) VALUES (new.id, new.description);END',
      'todos_insert');
  late final Trigger todosDelete = Trigger(
      'CREATE TRIGGER todos_delete AFTER DELETE ON todo_entries BEGIN INSERT INTO text_entries (text_entries, "rowid", description) VALUES (\'delete\', old.id, old.description);END',
      'todos_delete');
  late final Trigger todosUpdate = Trigger(
      'CREATE TRIGGER todos_update AFTER UPDATE ON todo_entries BEGIN INSERT INTO text_entries (text_entries, "rowid", description) VALUES (\'delete\', new.id, new.description);INSERT INTO text_entries ("rowid", description) VALUES (new.id, new.description);END',
      'todos_update');
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        categories,
        todoEntries,
        textEntries,
        todosInsert,
        todosDelete,
        todosUpdate
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('todo_entries',
                limitUpdateKind: UpdateKind.delete),
            result: [],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('todo_entries',
                limitUpdateKind: UpdateKind.delete),
            result: [],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('todo_entries',
                limitUpdateKind: UpdateKind.delete),
            result: [],
          ),
        ],
      );
  @override
  int get schemaVersion => 3;
}
