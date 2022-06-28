// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// **************************************************************************
// MoorGenerator
// **************************************************************************

// ignore_for_file: type=lint
class Category extends DataClass implements Insertable<Category> {
  final int id;
  final String name;
  final Color? color;
  Category({required this.id, required this.name, this.color});
  factory Category.fromData(Map<String, dynamic> data, {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return Category(
      id: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}id'])!,
      name: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}name'])!,
      color: $CategoriesTable.$converter0.fromSql(const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}color'])!),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    {
      final converter = $CategoriesTable.$converter0;
      map['color'] = Variable<int>(converter.toSql(color)!);
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
      color: serializer.fromJson<Color?>(json['color']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<Color?>(color),
    };
  }

  Category copyWith(
          {int? id,
          String? name,
          Value<Color?> color = const Value.absent()}) =>
      Category(
        id: id ?? this.id,
        name: name ?? this.name,
        color: color.present ? color.value : this.color,
      );
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
  final Value<Color?> color;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required Color? color,
  })  : name = Value(name),
        color = Value(color);
  static Insertable<Category> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<Color?>? color,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
    });
  }

  CategoriesCompanion copyWith(
      {Value<int>? id, Value<String>? name, Value<Color?>? color}) {
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
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      final converter = $CategoriesTable.$converter0;
      map['color'] = Variable<int>(converter.toSql(color.value)!);
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

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int?> id = GeneratedColumn<int?>(
      'id', aliasedName, false,
      type: const IntType(),
      requiredDuringInsert: false,
      defaultConstraints: 'PRIMARY KEY AUTOINCREMENT');
  final VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String?> name = GeneratedColumn<String?>(
      'name', aliasedName, false,
      type: const StringType(), requiredDuringInsert: true);
  final VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumnWithTypeConverter<Color?, int?> color =
      GeneratedColumn<int?>('color', aliasedName, false,
              type: const IntType(), requiredDuringInsert: true)
          .withConverter<Color?>($CategoriesTable.$converter0);
  @override
  List<GeneratedColumn> get $columns => [id, name, color];
  @override
  String get aliasedName => _alias ?? 'categories';
  @override
  String get actualTableName => 'categories';
  @override
  VerificationContext validateIntegrity(Insertable<Category> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    context.handle(_colorMeta, const VerificationResult.success());
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    return Category.fromData(data,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }

  static TypeConverter<Color?, int?> $converter0 = const ColorConverter();
}

class TodoEntry extends DataClass implements Insertable<TodoEntry> {
  final int id;
  final String description;
  final int? category;
  final DateTime? dueDate;
  TodoEntry(
      {required this.id,
      required this.description,
      this.category,
      this.dueDate});
  factory TodoEntry.fromData(Map<String, dynamic> data, {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return TodoEntry(
      id: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}id'])!,
      description: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}description'])!,
      category: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}category']),
      dueDate: const DateTimeType()
          .mapFromDatabaseResponse(data['${effectivePrefix}due_date']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['description'] = Variable<String>(description);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<int?>(category);
    }
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime?>(dueDate);
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
    Expression<int?>? category,
    Expression<DateTime?>? dueDate,
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
      map['id'] = Variable<int>(id.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (category.present) {
      map['category'] = Variable<int?>(category.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime?>(dueDate.value);
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

class $TodoEntriesTable extends TodoEntries
    with TableInfo<$TodoEntriesTable, TodoEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TodoEntriesTable(this.attachedDatabase, [this._alias]);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int?> id = GeneratedColumn<int?>(
      'id', aliasedName, false,
      type: const IntType(),
      requiredDuringInsert: false,
      defaultConstraints: 'PRIMARY KEY AUTOINCREMENT');
  final VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String?> description = GeneratedColumn<String?>(
      'description', aliasedName, false,
      type: const StringType(), requiredDuringInsert: true);
  final VerificationMeta _categoryMeta = const VerificationMeta('category');
  @override
  late final GeneratedColumn<int?> category = GeneratedColumn<int?>(
      'category', aliasedName, true,
      type: const IntType(),
      requiredDuringInsert: false,
      defaultConstraints: 'REFERENCES categories (id)');
  final VerificationMeta _dueDateMeta = const VerificationMeta('dueDate');
  @override
  late final GeneratedColumn<DateTime?> dueDate = GeneratedColumn<DateTime?>(
      'due_date', aliasedName, true,
      type: const IntType(), requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [id, description, category, dueDate];
  @override
  String get aliasedName => _alias ?? 'todo_entries';
  @override
  String get actualTableName => 'todo_entries';
  @override
  VerificationContext validateIntegrity(Insertable<TodoEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('due_date')) {
      context.handle(_dueDateMeta,
          dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TodoEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    return TodoEntry.fromData(data,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  $TodoEntriesTable createAlias(String alias) {
    return $TodoEntriesTable(attachedDatabase, alias);
  }
}

class TextEntrie extends DataClass implements Insertable<TextEntrie> {
  final String description;
  TextEntrie({required this.description});
  factory TextEntrie.fromData(Map<String, dynamic> data, {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return TextEntrie(
      description: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}description'])!,
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['description'] = Variable<String>(description);
    return map;
  }

  TextEntriesCompanion toCompanion(bool nullToAbsent) {
    return TextEntriesCompanion(
      description: Value(description),
    );
  }

  factory TextEntrie.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TextEntrie(
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

  TextEntrie copyWith({String? description}) => TextEntrie(
        description: description ?? this.description,
      );
  @override
  String toString() {
    return (StringBuffer('TextEntrie(')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => description.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TextEntrie && other.description == this.description);
}

class TextEntriesCompanion extends UpdateCompanion<TextEntrie> {
  final Value<String> description;
  const TextEntriesCompanion({
    this.description = const Value.absent(),
  });
  TextEntriesCompanion.insert({
    required String description,
  }) : description = Value(description);
  static Insertable<TextEntrie> custom({
    Expression<String>? description,
  }) {
    return RawValuesInsertable({
      if (description != null) 'description': description,
    });
  }

  TextEntriesCompanion copyWith({Value<String>? description}) {
    return TextEntriesCompanion(
      description: description ?? this.description,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TextEntriesCompanion(')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }
}

class TextEntries extends Table
    with
        TableInfo<TextEntries, TextEntrie>,
        VirtualTableInfo<TextEntries, TextEntrie> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  TextEntries(this.attachedDatabase, [this._alias]);
  final VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  late final GeneratedColumn<String?> description = GeneratedColumn<String?>(
      'description', aliasedName, false,
      type: const StringType(),
      requiredDuringInsert: true,
      $customConstraints: '');
  @override
  List<GeneratedColumn> get $columns => [description];
  @override
  String get aliasedName => _alias ?? 'text_entries';
  @override
  String get actualTableName => 'text_entries';
  @override
  VerificationContext validateIntegrity(Insertable<TextEntrie> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => <GeneratedColumn>{};
  @override
  TextEntrie map(Map<String, dynamic> data, {String? tablePrefix}) {
    return TextEntrie.fromData(data,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  TextEntries createAlias(String alias) {
    return TextEntries(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
  @override
  String get moduleAndArgs =>
      'fts5(description, content=todo_entries, content_rowid=id)';
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(SqlTypeSystem.defaultInstance, e);
  _$AppDatabase.connect(DatabaseConnection c) : super.connect(c);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $TodoEntriesTable todoEntries = $TodoEntriesTable(this);
  late final TextEntries textEntries = TextEntries(this);
  late final Trigger todosInsert = Trigger(
      'CREATE TRIGGER todos_insert AFTER INSERT ON todo_entries BEGIN INSERT INTO text_entries ("rowid", description) VALUES (new.id, new.description);END',
      'todos_insert');
  Selectable<CategoriesWithCountResult> _categoriesWithCount() {
    return customSelect(
        'SELECT c.*, (SELECT COUNT(*) FROM todo_entries WHERE category = c.id) AS amount FROM categories AS c UNION ALL SELECT NULL, NULL, NULL, (SELECT COUNT(*) FROM todo_entries WHERE category IS NULL)',
        variables: [],
        readsFrom: {
          todoEntries,
          categories,
        }).map((QueryRow row) {
      return CategoriesWithCountResult(
        id: row.read<int?>('id'),
        name: row.read<String?>('name'),
        color: $CategoriesTable.$converter0.fromSql(row.read<int?>('color')),
        amount: row.read<int>('amount'),
      );
    });
  }

  Selectable<SearchResult> _search(String query) {
    return customSelect(
        'SELECT"todos"."id" AS "nested_0.id", "todos"."description" AS "nested_0.description", "todos"."category" AS "nested_0.category", "todos"."due_date" AS "nested_0.due_date","cat"."id" AS "nested_1.id", "cat"."name" AS "nested_1.name", "cat"."color" AS "nested_1.color" FROM text_entries INNER JOIN todo_entries AS todos ON todos.id = text_entries."rowid" LEFT OUTER JOIN categories AS cat ON cat.id = todos.category WHERE text_entries MATCH ?1 ORDER BY rank',
        variables: [
          Variable<String>(query)
        ],
        readsFrom: {
          textEntries,
          todoEntries,
          categories,
        }).map((QueryRow row) {
      return SearchResult(
        todos: todoEntries.mapFromRow(row, tablePrefix: 'nested_0'),
        cat: categories.mapFromRowOrNull(row, tablePrefix: 'nested_1'),
      );
    });
  }

  @override
  Iterable<TableInfo> get allTables => allSchemaEntities.whereType<TableInfo>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [categories, todoEntries, textEntries, todosInsert];
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
        ],
      );
}

class CategoriesWithCountResult {
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

class SearchResult {
  final TodoEntry todos;
  final Category? cat;
  SearchResult({
    required this.todos,
    this.cat,
  });
}
