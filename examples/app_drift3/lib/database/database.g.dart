// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CategoriesTable extends Categories
    with ResultSet<Category, $CategoriesTable>
    implements GeneratedTable<Category, $CategoriesTable> {
  @override
  final String? alias;
  $CategoriesTable([this.alias]);
  @override
  late final TableColumn<int> id = TableColumn<int>(
      name: 'id',
      sqlType: SqlType.int,
      requiredDuringInsert: false,
      constraints: () => [
            const ColumnPrimaryKeyConstraint(isAutoIncrementing: true),
            const ColumnNotNullConstraint()
          ])
    ..owningResultSet = this;
  @override
  late final TableColumn<String> name = TableColumn<String>(
      name: 'name',
      sqlType: SqlType.text,
      requiredDuringInsert: true,
      constraints: () => [const ColumnNotNullConstraint()])
    ..owningResultSet = this;
  @override
  late final TableColumnWithTypeConverter<Color, int> color = TableColumn<int>(
          name: 'color',
          sqlType: SqlType.int,
          requiredDuringInsert: true,
          constraints: () => [const ColumnNotNullConstraint()])
      .withConverter<Color>($CategoriesTable.$convertercolor)
    ..owningResultSet = this;
  @override
  List<TableColumn> get columns => [id, name, color];
  @override
  String get entityName => $name;
  static const String $name = 'categories';
  @override
  $CategoriesTable asSelfType() => this;

  @override
  Category? Function(RawRow) createMapperFromPositions(
      DriftDialect dialect, List<ColumnPosition> positions) {
    final pos$id = positions[0].index;
    final type$0 = SqlType.int.resolveIn(dialect);
    final pos$name = positions[1].index;
    final type$1 = SqlType.text.resolveIn(dialect);
    final pos$color = positions[2].index;
    return (RawRow row) {
      // Not part of row if non-nullable column "id" is missing
      if (row[pos$id] == null) {
        return null;
      }
      return Category(
        id: type$0.dartValue(row[pos$id]!),
        name: type$1.dartValue(row[pos$name]!),
        color: $CategoriesTable.$convertercolor
            .fromSql(type$0.dartValue(row[pos$color]!)),
      );
    };
  }

  @override
  $CategoriesTable withAlias(String alias) {
    return $CategoriesTable(alias);
  }

  static TypeConverter<Color, int> $convertercolor = const ColorConverter();
}

class Category extends LegacyDataClass implements Insertable<Category> {
  final int id;
  final String name;
  final Color color;
  const Category({required this.id, required this.name, required this.color});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id, SqlType.int);
    map['name'] = Variable<String>(name, SqlType.text);
    {
      map['color'] = Variable<int>(
          $CategoriesTable.$convertercolor.toSql(color), SqlType.int);
    }
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      color: Value(color),
    );
  }

  factory Category.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<Color>(json['color']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<Color>(color),
    };
  }

  Category copyWith({int? id, String? name, Color? color}) => Category(
        id: id ?? this.id,
        name: name ?? this.name,
        color: color ?? this.color,
      );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, color);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<int> id;
  final Value<String> name;
  final Value<Color> color;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required Color color,
  })  : name = Value(name),
        color = Value(color);
  static Insertable<Category> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? color,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
    });
  }

  CategoriesCompanion copyWith(
      {Value<int>? id, Value<String>? name, Value<Color>? color}) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value, SqlType.int);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value, SqlType.text);
    }
    if (color.present) {
      map['color'] = Variable<int>(
          $CategoriesTable.$convertercolor.toSql(color.value), SqlType.int);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color')
          ..write(')'))
        .toString();
  }
}

class $TodoEntriesTable extends TodoEntries
    with ResultSet<TodoEntry, $TodoEntriesTable>
    implements GeneratedTable<TodoEntry, $TodoEntriesTable> {
  @override
  final String? alias;
  $TodoEntriesTable([this.alias]);
  @override
  late final TableColumn<int> id = TableColumn<int>(
      name: 'id',
      sqlType: SqlType.int,
      requiredDuringInsert: false,
      constraints: () => [
            const ColumnPrimaryKeyConstraint(isAutoIncrementing: true),
            const ColumnNotNullConstraint()
          ])
    ..owningResultSet = this;
  @override
  late final TableColumn<String> description = TableColumn<String>(
      name: 'description',
      sqlType: SqlType.text,
      requiredDuringInsert: true,
      constraints: () => [const ColumnNotNullConstraint()])
    ..owningResultSet = this;
  @override
  late final TableColumn<int> category = TableColumn<int>(
      name: 'category',
      sqlType: SqlType.int,
      requiredDuringInsert: false,
      constraints: () => [
            const ColumnForeignKeyConstraint(
              otherTableName: 'categories',
              otherColumnName: 'id',
            )
          ])
    ..owningResultSet = this;
  @override
  late final TableColumn<DateTime> dueDate = TableColumn<DateTime>(
      name: 'due_date', sqlType: SqlType.dateTime, requiredDuringInsert: false)
    ..owningResultSet = this;
  @override
  List<TableColumn> get columns => [id, description, category, dueDate];
  @override
  String get entityName => $name;
  static const String $name = 'todo_entries';
  @override
  $TodoEntriesTable asSelfType() => this;

  @override
  TodoEntry? Function(RawRow) createMapperFromPositions(
      DriftDialect dialect, List<ColumnPosition> positions) {
    final pos$id = positions[0].index;
    final type$0 = SqlType.int.resolveIn(dialect);
    final pos$description = positions[1].index;
    final type$1 = SqlType.text.resolveIn(dialect);
    final pos$category = positions[2].index;
    final pos$dueDate = positions[3].index;
    final type$2 = SqlType.dateTime.resolveIn(dialect);
    return (RawRow row) {
      // Not part of row if non-nullable column "id" is missing
      if (row[pos$id] == null) {
        return null;
      }
      return TodoEntry(
        id: type$0.dartValue(row[pos$id]!),
        description: type$1.dartValue(row[pos$description]!),
        category: type$0.nullableDartValue(row[pos$category]),
        dueDate: type$2.nullableDartValue(row[pos$dueDate]),
      );
    };
  }

  @override
  $TodoEntriesTable withAlias(String alias) {
    return $TodoEntriesTable(alias);
  }
}

class TodoEntry extends LegacyDataClass implements Insertable<TodoEntry> {
  final int id;
  final String description;
  final int? category;
  final DateTime? dueDate;
  const TodoEntry(
      {required this.id,
      required this.description,
      this.category,
      this.dueDate});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id, SqlType.int);
    map['description'] = Variable<String>(description, SqlType.text);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<int>(category, SqlType.int);
    }
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate, SqlType.dateTime);
    }
    return map;
  }

  TodoEntriesCompanion toCompanion(bool nullToAbsent) {
    return TodoEntriesCompanion(
      id: Value(id),
      description: Value(description),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
    );
  }

  factory TodoEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TodoEntry(
      id: serializer.fromJson<int>(json['id']),
      description: serializer.fromJson<String>(json['description']),
      category: serializer.fromJson<int?>(json['category']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'description': serializer.toJson<String>(description),
      'category': serializer.toJson<int?>(category),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
    };
  }

  TodoEntry copyWith(
          {int? id,
          String? description,
          Value<int?> category = const Value.absent(),
          Value<DateTime?> dueDate = const Value.absent()}) =>
      TodoEntry(
        id: id ?? this.id,
        description: description ?? this.description,
        category: category.present ? category.value : this.category,
        dueDate: dueDate.present ? dueDate.value : this.dueDate,
      );
  TodoEntry copyWithCompanion(TodoEntriesCompanion data) {
    return TodoEntry(
      id: data.id.present ? data.id.value : this.id,
      description:
          data.description.present ? data.description.value : this.description,
      category: data.category.present ? data.category.value : this.category,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TodoEntry(')
          ..write('id: $id, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('dueDate: $dueDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, description, category, dueDate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TodoEntry &&
          other.id == this.id &&
          other.description == this.description &&
          other.category == this.category &&
          other.dueDate == this.dueDate);
}

class TodoEntriesCompanion extends UpdateCompanion<TodoEntry> {
  final Value<int> id;
  final Value<String> description;
  final Value<int?> category;
  final Value<DateTime?> dueDate;
  const TodoEntriesCompanion({
    this.id = const Value.absent(),
    this.description = const Value.absent(),
    this.category = const Value.absent(),
    this.dueDate = const Value.absent(),
  });
  TodoEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String description,
    this.category = const Value.absent(),
    this.dueDate = const Value.absent(),
  }) : description = Value(description);
  static Insertable<TodoEntry> custom({
    Expression<int>? id,
    Expression<String>? description,
    Expression<int>? category,
    Expression<DateTime>? dueDate,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (dueDate != null) 'due_date': dueDate,
    });
  }

  TodoEntriesCompanion copyWith(
      {Value<int>? id,
      Value<String>? description,
      Value<int?>? category,
      Value<DateTime?>? dueDate}) {
    return TodoEntriesCompanion(
      id: id ?? this.id,
      description: description ?? this.description,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value, SqlType.int);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value, SqlType.text);
    }
    if (category.present) {
      map['category'] = Variable<int>(category.value, SqlType.int);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value, SqlType.dateTime);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TodoEntriesCompanion(')
          ..write('id: $id, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('dueDate: $dueDate')
          ..write(')'))
        .toString();
  }
}

class TextEntries extends Table
    with ResultSet<TextEntry, TextEntries>
    implements
        GeneratedTable<TextEntry, TextEntries>,
        VirtualTableInfo<TextEntry, TextEntries> {
  @override
  final String? alias;
  TextEntries([this.alias]);
  late final TableColumn<String> description = TableColumn<String>(
      name: 'description',
      sqlType: SqlType.text,
      requiredDuringInsert: true,
      constraints: () => [const ColumnNotNullConstraint()])
    ..owningResultSet = this;
  @override
  List<TableColumn> get columns => [description];
  @override
  String get entityName => $name;
  static const String $name = 'text_entries';
  @override
  TextEntries asSelfType() => this;

  @override
  TextEntry? Function(RawRow) createMapperFromPositions(
      DriftDialect dialect, List<ColumnPosition> positions) {
    final pos$description = positions[0].index;
    final type$0 = SqlType.text.resolveIn(dialect);
    return (RawRow row) {
      // Not part of row if non-nullable column "description" is missing
      if (row[pos$description] == null) {
        return null;
      }
      return TextEntry(
        description: type$0.dartValue(row[pos$description]!),
      );
    };
  }

  @override
  TextEntries withAlias(String alias) {
    return TextEntries(alias);
  }

  @override
  bool get dontWriteConstraints => true;
  @override
  String get moduleAndArgs =>
      'fts5(description, content=todo_entries, content_rowid=id)';
}

class TextEntry extends LegacyDataClass implements Insertable<TextEntry> {
  final String description;
  const TextEntry({required this.description});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['description'] = Variable<String>(description, SqlType.text);
    return map;
  }

  TextEntriesCompanion toCompanion(bool nullToAbsent) {
    return TextEntriesCompanion(
      description: Value(description),
    );
  }

  factory TextEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TextEntry(
      description: serializer.fromJson<String>(json['description']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'description': serializer.toJson<String>(description),
    };
  }

  TextEntry copyWith({String? description}) => TextEntry(
        description: description ?? this.description,
      );
  TextEntry copyWithCompanion(TextEntriesCompanion data) {
    return TextEntry(
      description:
          data.description.present ? data.description.value : this.description,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TextEntry(')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => description.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TextEntry && other.description == this.description);
}

class TextEntriesCompanion extends UpdateCompanion<TextEntry> {
  final Value<String> description;
  final Value<int> rowid;
  const TextEntriesCompanion({
    this.description = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TextEntriesCompanion.insert({
    required String description,
    this.rowid = const Value.absent(),
  }) : description = Value(description);
  static Insertable<TextEntry> custom({
    Expression<String>? description,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (description != null) 'description': description,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TextEntriesCompanion copyWith(
      {Value<String>? description, Value<int>? rowid}) {
    return TextEntriesCompanion(
      description: description ?? this.description,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (description.present) {
      map['description'] = Variable<String>(description.value, SqlType.text);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value, SqlType.int);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TextEntriesCompanion(')
          ..write('description: $description, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract base class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(super.implementation);
  $CategoriesTable get categories => $CategoriesTable();
  $TodoEntriesTable get todoEntries => $TodoEntriesTable();
  TextEntries get textEntries => TextEntries();
  Trigger get todosInsert => _$todosInsert;
  Trigger get todosDelete => _$todosDelete;
  Trigger get todosUpdate => _$todosUpdate;
  TableOrViewStatements<Category, $CategoriesTable> get categoriesQueries =>
      this.categories.statements(this);
  TableOrViewStatements<TodoEntry, $TodoEntriesTable> get todoEntriesQueries =>
      this.todoEntries.statements(this);
  TableOrViewStatements<TextEntry, TextEntries> get textEntriesQueries =>
      this.textEntries.statements(this);
  @override
  Map<KnownSqlDialect, Object> get dialectOptions => {
        KnownSqlDialect.sqlite: const SqliteOptions(
          strictTablesByDefault: false,
          storeDateTimesAsText: false,
          useBinaryJsonRepresentation: false,
        ),
      };
  Selectable<CategoriesWithCountResult> _categoriesWithCount() {
    return customSelectMapped<CategoriesWithCountResult>(
        query:
            'SELECT c.*, (SELECT COUNT(*) FROM todo_entries WHERE category = c.id) AS amount FROM categories AS c UNION ALL SELECT NULL, NULL, NULL, (SELECT COUNT(*) FROM todo_entries WHERE category IS NULL)',
        variables: [],
        readsFrom: {
          $TodoEntriesTable(),
          $CategoriesTable(),
        },
        createMapper: (RawResultSet _) {
          final type$0 = SqlType.int.resolveIn(dialect);
          final type$1 = SqlType.text.resolveIn(dialect);

          return (RawRow row) => CategoriesWithCountResult(
                id: type$0.nullableDartValue(row[0]),
                name: type$1.nullableDartValue(row[1]),
                color: NullAwareTypeConverter.wrapFromSql(
                    $CategoriesTable.$convertercolor,
                    type$0.nullableDartValue(row[2])),
                amount: type$0.dartValue(row[3]!),
              );
        });
  }

  Selectable<SearchResult> _search(String query) {
    return customSelectMapped<SearchResult>(
        query:
            'SELECT"todos"."id", "todos"."description", "todos"."category", "todos"."due_date","cat"."id", "cat"."name", "cat"."color" FROM text_entries INNER JOIN todo_entries AS todos ON todos.id = text_entries."rowid" LEFT OUTER JOIN categories AS cat ON cat.id = todos.category WHERE text_entries MATCH ?1 ORDER BY rank',
        variables: [Variable<String>(query, SqlType.text)],
        readsFrom: {
          TextEntries(),
          $TodoEntriesTable(),
          $CategoriesTable(),
        },
        createMapper: (RawResultSet _) {
          final map_0 =
              $TodoEntriesTable().createMapperFromPositions(dialect, const [
            ColumnPosition(0),
            ColumnPosition(1),
            ColumnPosition(2),
            ColumnPosition(3),
          ]);
          final map_1 =
              $CategoriesTable().createMapperFromPositions(dialect, const [
            ColumnPosition(4),
            ColumnPosition(5),
            ColumnPosition(6),
          ]);

          return (RawRow row) => SearchResult(
                todos: map_0(row)!,
                cat: map_1(row),
              );
        });
  }

  @override
  DatabaseSchema get schema => _$schema;
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('todo_entries',
                limitUpdateKind: UpdateKind.insert),
            result: [
              TableUpdate('text_entries', kind: UpdateKind.insert),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('todo_entries',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('text_entries', kind: UpdateKind.insert),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('todo_entries',
                limitUpdateKind: UpdateKind.update),
            result: [
              TableUpdate('text_entries', kind: UpdateKind.insert),
            ],
          ),
        ],
      );
  static final _$todosInsert = Trigger(
      'todos_insert',
      CustomComponent(
          'CREATE TRIGGER todos_insert AFTER INSERT ON todo_entries BEGIN INSERT INTO text_entries ("rowid", description) VALUES (new.id, new.description);END'));
  static final _$todosDelete = Trigger(
      'todos_delete',
      CustomComponent(
          'CREATE TRIGGER todos_delete AFTER DELETE ON todo_entries BEGIN INSERT INTO text_entries (text_entries, "rowid", description) VALUES (\'delete\', old.id, old.description);END'));
  static final _$todosUpdate = Trigger(
      'todos_update',
      CustomComponent(
          'CREATE TRIGGER todos_update AFTER UPDATE ON todo_entries BEGIN INSERT INTO text_entries (text_entries, "rowid", description) VALUES (\'delete\', new.id, new.description);INSERT INTO text_entries ("rowid", description) VALUES (new.id, new.description);END'));
  static final DatabaseSchema _$schema = DatabaseSchema([
    $CategoriesTable(),
    $TodoEntriesTable(),
    TextEntries(),
    _$todosInsert,
    _$todosDelete,
    _$todosUpdate,
  ]);
}

final class CategoriesWithCountResult {
  final int? id;
  final String? name;
  final Color? color;
  final int amount;
  CategoriesWithCountResult({
    this.id,
    this.name,
    this.color,
    required this.amount,
  });
}

final class SearchResult {
  final TodoEntry todos;
  final Category? cat;
  SearchResult({
    required this.todos,
    this.cat,
  });
}
