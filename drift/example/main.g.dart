// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// ignore_for_file: type=lint
class $TodoCategoriesTable extends TodoCategories
    with ResultSet<TodoCategory, $TodoCategoriesTable>
    implements GeneratedTable<TodoCategory, $TodoCategoriesTable> {
  @override
  final String? alias;
  $TodoCategoriesTable([this.alias]);
  @override
  late final TableColumn<int> id = TableColumn<int>(
      name: 'id',
      type: BuiltinDriftType.int,
      isNullable: false,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'))
    ..owningResultSet = this;
  @override
  late final TableColumn<String> name = TableColumn<String>(
      name: 'name',
      type: BuiltinDriftType.text,
      isNullable: false,
      requiredDuringInsert: true)
    ..owningResultSet = this;
  @override
  List<TableColumn> get columns => [id, name];
  @override
  String get entityName => $name;
  static const String $name = 'todo_categories';
  @override
  $TodoCategoriesTable asSelfType() => this;

  @override
  Set<TableColumn> get primaryKey => {id};
  @override
  TodoCategory? Function(DriftRow) createMapperToDart(
      DriftResultSet resultSet) {
    final columnPositions = resultSet.structure.tables[this]!;
    return (DriftRow row) {
// Table not part of row if non-nullable column id is missing
      if (row.raw.rawValue(columnPositions[0]) == null) {
        return null;
      }
      return TodoCategory(
        id: row.readWithType(columnPositions[0], BuiltinDriftType.int)!,
        name: row.readWithType(columnPositions[1], BuiltinDriftType.text)!,
      );
    };
  }

  @override
  $TodoCategoriesTable withAlias(String alias) {
    return $TodoCategoriesTable(alias);
  }
}

class TodoCategory extends DataClass implements Insertable<TodoCategory> {
  final int id;
  final String name;
  const TodoCategory({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  TodoCategoriesCompanion toCompanion(bool nullToAbsent) {
    return TodoCategoriesCompanion(
      id: Value(id),
      name: Value(name),
    );
  }

  factory TodoCategory.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TodoCategory(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  factory TodoCategory.fromJsonString(String encodedJson,
          {ValueSerializer? serializer}) =>
      TodoCategory.fromJson(
          DataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  TodoCategory copyWith({int? id, String? name}) => TodoCategory(
        id: id ?? this.id,
        name: name ?? this.name,
      );
  TodoCategory copyWithCompanion(TodoCategoriesCompanion data) {
    return TodoCategory(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TodoCategory(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TodoCategory && other.id == this.id && other.name == this.name);
}

class TodoCategoriesCompanion extends UpdateCompanion<TodoCategory> {
  final Value<int> id;
  final Value<String> name;
  const TodoCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  TodoCategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
  }) : name = Value(name);
  static Insertable<TodoCategory> custom({
    Expression<int>? id,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  TodoCategoriesCompanion copyWith({Value<int>? id, Value<String>? name}) {
    return TodoCategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TodoCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $TodoItemsTable extends TodoItems
    with ResultSet<TodoItem, $TodoItemsTable>
    implements GeneratedTable<TodoItem, $TodoItemsTable> {
  @override
  final String? alias;
  $TodoItemsTable([this.alias]);
  @override
  late final TableColumn<int> id = TableColumn<int>(
      name: 'id',
      type: BuiltinDriftType.int,
      isNullable: false,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'))
    ..owningResultSet = this;
  @override
  late final TableColumn<String> title = TableColumn<String>(
      name: 'title',
      type: BuiltinDriftType.text,
      isNullable: false,
      requiredDuringInsert: true)
    ..owningResultSet = this;
  @override
  late final TableColumn<String> content = TableColumn<String>(
      name: 'content',
      type: BuiltinDriftType.text,
      isNullable: true,
      requiredDuringInsert: false)
    ..owningResultSet = this;
  @override
  late final TableColumn<int> categoryId = TableColumn<int>(
      name: 'category_id',
      type: BuiltinDriftType.int,
      isNullable: false,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES "todo_categories" ("id")'))
    ..owningResultSet = this;
  @override
  late final TableColumn<String> generatedText = TableColumn<String>(
      name: 'generated_text',
      type: BuiltinDriftType.text,
      isNullable: true,
      generatedAs: GeneratedAs(
          title + const Literal(' (') + content + const Literal(')'), false),
      requiredDuringInsert: false)
    ..owningResultSet = this;
  @override
  List<TableColumn> get columns =>
      [id, title, content, categoryId, generatedText];
  @override
  String get entityName => $name;
  static const String $name = 'todo_items';
  @override
  $TodoItemsTable asSelfType() => this;

  @override
  Set<TableColumn> get primaryKey => {id};
  @override
  TodoItem? Function(DriftRow) createMapperToDart(DriftResultSet resultSet) {
    final columnPositions = resultSet.structure.tables[this]!;
    return (DriftRow row) {
// Table not part of row if non-nullable column id is missing
      if (row.raw.rawValue(columnPositions[0]) == null) {
        return null;
      }
      return TodoItem(
        id: row.readWithType(columnPositions[0], BuiltinDriftType.int)!,
        title: row.readWithType(columnPositions[1], BuiltinDriftType.text)!,
        content: row.readWithType(columnPositions[2], BuiltinDriftType.text),
        categoryId: row.readWithType(columnPositions[3], BuiltinDriftType.int)!,
        generatedText:
            row.readWithType(columnPositions[4], BuiltinDriftType.text),
      );
    };
  }

  @override
  $TodoItemsTable withAlias(String alias) {
    return $TodoItemsTable(alias);
  }
}

class TodoItem extends DataClass implements Insertable<TodoItem> {
  final int id;
  final String title;
  final String? content;
  final int categoryId;
  final String? generatedText;
  const TodoItem(
      {required this.id,
      required this.title,
      this.content,
      required this.categoryId,
      this.generatedText});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    map['category_id'] = Variable<int>(categoryId);
    return map;
  }

  TodoItemsCompanion toCompanion(bool nullToAbsent) {
    return TodoItemsCompanion(
      id: Value(id),
      title: Value(title),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      categoryId: Value(categoryId),
    );
  }

  factory TodoItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TodoItem(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String?>(json['content']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      generatedText: serializer.fromJson<String?>(json['generatedText']),
    );
  }
  factory TodoItem.fromJsonString(String encodedJson,
          {ValueSerializer? serializer}) =>
      TodoItem.fromJson(
          DataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'content': serializer.toJson<String?>(content),
      'categoryId': serializer.toJson<int>(categoryId),
      'generatedText': serializer.toJson<String?>(generatedText),
    };
  }

  TodoItem copyWith(
          {int? id,
          String? title,
          Value<String?> content = const Value.absent(),
          int? categoryId,
          Value<String?> generatedText = const Value.absent()}) =>
      TodoItem(
        id: id ?? this.id,
        title: title ?? this.title,
        content: content.present ? content.value : this.content,
        categoryId: categoryId ?? this.categoryId,
        generatedText:
            generatedText.present ? generatedText.value : this.generatedText,
      );
  @override
  String toString() {
    return (StringBuffer('TodoItem(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('categoryId: $categoryId, ')
          ..write('generatedText: $generatedText')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, content, categoryId, generatedText);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TodoItem &&
          other.id == this.id &&
          other.title == this.title &&
          other.content == this.content &&
          other.categoryId == this.categoryId &&
          other.generatedText == this.generatedText);
}

class TodoItemsCompanion extends UpdateCompanion<TodoItem> {
  final Value<int> id;
  final Value<String> title;
  final Value<String?> content;
  final Value<int> categoryId;
  const TodoItemsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.categoryId = const Value.absent(),
  });
  TodoItemsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.content = const Value.absent(),
    required int categoryId,
  })  : title = Value(title),
        categoryId = Value(categoryId);
  static Insertable<TodoItem> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? content,
    Expression<int>? categoryId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (categoryId != null) 'category_id': categoryId,
    });
  }

  TodoItemsCompanion copyWith(
      {Value<int>? id,
      Value<String>? title,
      Value<String?>? content,
      Value<int>? categoryId}) {
    return TodoItemsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TodoItemsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('categoryId: $categoryId')
          ..write(')'))
        .toString();
  }
}

class TodoCategoryItemCountData extends DataClass {
  final String name;
  final int? itemCount;
  const TodoCategoryItemCountData({required this.name, this.itemCount});
  factory TodoCategoryItemCountData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TodoCategoryItemCountData(
      name: serializer.fromJson<String>(json['name']),
      itemCount: serializer.fromJson<int?>(json['itemCount']),
    );
  }
  factory TodoCategoryItemCountData.fromJsonString(String encodedJson,
          {ValueSerializer? serializer}) =>
      TodoCategoryItemCountData.fromJson(
          DataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'itemCount': serializer.toJson<int?>(itemCount),
    };
  }

  TodoCategoryItemCountData copyWith(
          {String? name, Value<int?> itemCount = const Value.absent()}) =>
      TodoCategoryItemCountData(
        name: name ?? this.name,
        itemCount: itemCount.present ? itemCount.value : this.itemCount,
      );
  @override
  String toString() {
    return (StringBuffer('TodoCategoryItemCountData(')
          ..write('name: $name, ')
          ..write('itemCount: $itemCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(name, itemCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TodoCategoryItemCountData &&
          other.name == this.name &&
          other.itemCount == this.itemCount);
}

class $TodoCategoryItemCountView
    extends ViewInfo<$TodoCategoryItemCountView, TodoCategoryItemCountData>
    implements HasResultSet {
  final String? _alias;
  @override
  final _$Database attachedDatabase;
  $TodoCategoryItemCountView(this.attachedDatabase, [this._alias]);
  $TodoItemsTable get todoItems => attachedDatabase.todoItems.createAlias('t0');
  $TodoCategoriesTable get todoCategories =>
      attachedDatabase.todoCategories.createAlias('t1');
  @override
  List<SchemaColumn> get columns => [name, itemCount];
  @override
  String get aliasedName => _alias ?? entityName;
  @override
  String get entityName => 'todo_category_item_count';
  @override
  Map<SqlDialect, String>? get createViewStatements => null;
  @override
  $TodoCategoryItemCountView asSelfType() => this;

  @override
  TodoCategoryItemCountData? Function(DriftRow) createMapperToDart(
      DriftResultSet resultSet) {
    final columnPositions = resultSet.structure.tables[this]!;
    return (DriftRow row) {
// Table not part of row if non-nullable column name is missing
      if (row.raw.rawValue(columnPositions[0]) == null) {
        return null;
      }
      return TodoCategoryItemCountData(
        name: row.readWithType(columnPositions[0], BuiltinDriftType.text)!,
        itemCount: row.readWithType(columnPositions[1], BuiltinDriftType.int),
      );
    };
  }

  late final SchemaColumn<String> name = SchemaColumn<String>(
      name: 'name',
      type: BuiltinDriftType.text,
      isNullable: false,
      generatedAs: GeneratedAs(todoCategories.name, false))
    ..owningResultSet = this;
  late final SchemaColumn<int> itemCount = SchemaColumn<int>(
      name: 'item_count',
      type: BuiltinDriftType.int,
      isNullable: true,
      generatedAs: GeneratedAs(BaseAggregate(todoItems.id).count(), false))
    ..owningResultSet = this;
  @override
  $TodoCategoryItemCountView createAlias(String alias) {
    return $TodoCategoryItemCountView(attachedDatabase, alias);
  }

  @override
  Query? get query =>
      (attachedDatabase.selectOnly(todoCategories)..addColumns($columns))
          .innerJoin(todoItems,
              on: todoItems.categoryId.equalsExp(todoCategories.id));
  @override
  Set<String> get readTables => const {'todo_items', 'todo_categories'};
}

class TodoItemWithCategoryNameViewData extends DataClass {
  final int id;
  final String? title;
  const TodoItemWithCategoryNameViewData({required this.id, this.title});
  factory TodoItemWithCategoryNameViewData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TodoItemWithCategoryNameViewData(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String?>(json['title']),
    );
  }
  factory TodoItemWithCategoryNameViewData.fromJsonString(String encodedJson,
          {ValueSerializer? serializer}) =>
      TodoItemWithCategoryNameViewData.fromJson(
          DataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String?>(title),
    };
  }

  TodoItemWithCategoryNameViewData copyWith(
          {int? id, Value<String?> title = const Value.absent()}) =>
      TodoItemWithCategoryNameViewData(
        id: id ?? this.id,
        title: title.present ? title.value : this.title,
      );
  @override
  String toString() {
    return (StringBuffer('TodoItemWithCategoryNameViewData(')
          ..write('id: $id, ')
          ..write('title: $title')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TodoItemWithCategoryNameViewData &&
          other.id == this.id &&
          other.title == this.title);
}

class $TodoItemWithCategoryNameViewView extends ViewInfo<
    $TodoItemWithCategoryNameViewView,
    TodoItemWithCategoryNameViewData> implements HasResultSet {
  final String? _alias;
  @override
  final _$Database attachedDatabase;
  $TodoItemWithCategoryNameViewView(this.attachedDatabase, [this._alias]);
  $TodoItemsTable get todoItems => attachedDatabase.todoItems.createAlias('t0');
  $TodoCategoriesTable get todoCategories =>
      attachedDatabase.todoCategories.createAlias('t1');
  @override
  List<SchemaColumn> get columns => [id, title];
  @override
  String get aliasedName => _alias ?? entityName;
  @override
  String get entityName => 'customViewName';
  @override
  Map<SqlDialect, String>? get createViewStatements => null;
  @override
  $TodoItemWithCategoryNameViewView asSelfType() => this;

  @override
  TodoItemWithCategoryNameViewData? Function(DriftRow) createMapperToDart(
      DriftResultSet resultSet) {
    final columnPositions = resultSet.structure.tables[this]!;
    return (DriftRow row) {
// Table not part of row if non-nullable column id is missing
      if (row.raw.rawValue(columnPositions[0]) == null) {
        return null;
      }
      return TodoItemWithCategoryNameViewData(
        id: row.readWithType(columnPositions[0], BuiltinDriftType.int)!,
        title: row.readWithType(columnPositions[1], BuiltinDriftType.text),
      );
    };
  }

  late final SchemaColumn<int> id = SchemaColumn<int>(
      name: 'id',
      type: BuiltinDriftType.int,
      isNullable: false,
      generatedAs: GeneratedAs(todoItems.id, false))
    ..owningResultSet = this;
  late final SchemaColumn<String> title = SchemaColumn<String>(
      name: 'title',
      type: BuiltinDriftType.text,
      isNullable: true,
      generatedAs: GeneratedAs(
          todoItems.title +
              const Literal('(') +
              todoCategories.name +
              const Literal(')'),
          false))
    ..owningResultSet = this;
  @override
  $TodoItemWithCategoryNameViewView createAlias(String alias) {
    return $TodoItemWithCategoryNameViewView(attachedDatabase, alias);
  }

  @override
  Query? get query =>
      (attachedDatabase.selectOnly(todoItems)..addColumns($columns)).innerJoin(
          todoCategories,
          on: todoCategories.id.equalsExp(todoItems.categoryId));
  @override
  Set<String> get readTables => const {'todo_items', 'todo_categories'};
}

abstract class _$Database extends GeneratedDatabase {
  _$Database(super.implementation);
  late final $TodoCategoriesTable todoCategories = $TodoCategoriesTable(this);
  late final $TodoItemsTable todoItems = $TodoItemsTable(this);
  late final $TodoCategoryItemCountView todoCategoryItemCount =
      $TodoCategoryItemCountView(this);
  late final $TodoItemWithCategoryNameViewView customViewName =
      $TodoItemWithCategoryNameViewView(this);
  late final Index itemTitle = Index.byDialect('item_title', {
    SqlDialect.sqlite: 'CREATE INDEX item_title ON todo_items (title)',
  });
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        todoCategories,
        todoItems,
        todoCategoryItemCount,
        customViewName,
        itemTitle
      ];
}
