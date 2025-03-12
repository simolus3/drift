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
      constraints: [const ColumnPrimaryKeyConstraint(isAutoIncrementing: true)])
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
      // Not part of row if non-nullable column "id" is missing
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

class TodoCategory extends LegacyDataClass implements Insertable<TodoCategory> {
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
          LegacyDataClass.parseJson(encodedJson) as Map<String, dynamic>,
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
      constraints: [const ColumnPrimaryKeyConstraint(isAutoIncrementing: true)])
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
      constraints: [
        const ColumnForeignKeyConstraint(
          otherTableName: 'todo_categories',
          otherColumnName: 'id',
        )
      ])
    ..owningResultSet = this;
  @override
  late final TableColumn<String> generatedText = TableColumn<String>(
      name: 'generated_text',
      type: BuiltinDriftType.text,
      isNullable: true,
      requiredDuringInsert: false,
      constraints: [
        ColumnGeneratedAs(
            title + const Literal(' (') + content + const Literal(')'),
            stored: false)
      ])
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
      // Not part of row if non-nullable column "id" is missing
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

class TodoItem extends LegacyDataClass implements Insertable<TodoItem> {
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
          LegacyDataClass.parseJson(encodedJson) as Map<String, dynamic>,
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

class TodoCategoryItemCountData extends LegacyDataClass {
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
          LegacyDataClass.parseJson(encodedJson) as Map<String, dynamic>,
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

class $TodoCategoryItemCountView extends TodoCategoryItemCount
    with ResultSet<TodoCategoryItemCountData, $TodoCategoryItemCountView>
    implements
        GeneratedView<TodoCategoryItemCountData, $TodoCategoryItemCountView> {
  @override
  final String? alias;
  final _$Database _attachedDatabase;
  $TodoCategoryItemCountView(this._attachedDatabase, [this.alias]);
  $TodoItemsTable get todoItems => _attachedDatabase.todoItems.withAlias('t0');
  $TodoCategoriesTable get todoCategories =>
      _attachedDatabase.todoCategories.withAlias('t1');
  @override
  List<SchemaColumn> get columns => [name, itemCount];
  @override
  String get entityName => 'todo_category_item_count';
  @override
  $TodoCategoryItemCountView asSelfType() => this;

  @override
  TodoCategoryItemCountData? Function(DriftRow) createMapperToDart(
      DriftResultSet resultSet) {
    final columnPositions = resultSet.structure.tables[this]!;
    return (DriftRow row) {
      // Not part of row if non-nullable column "name" is missing
      if (row.raw.rawValue(columnPositions[0]) == null) {
        return null;
      }
      return TodoCategoryItemCountData(
        name: row.readWithType(columnPositions[0], BuiltinDriftType.text)!,
        itemCount: row.readWithType(columnPositions[1], BuiltinDriftType.int),
      );
    };
  }

  late final ViewColumn<String> name = ViewColumn<String>(
      name: 'name',
      type: BuiltinDriftType.text,
      isNullable: false,
      expression: todoCategories.name)
    ..owningResultSet = this;
  late final ViewColumn<int> itemCount = ViewColumn<int>(
      name: 'item_count',
      type: BuiltinDriftType.int,
      isNullable: true,
      expression: BaseAggregate(todoItems.id).count())
    ..owningResultSet = this;
  @override
  $TodoCategoryItemCountView withAlias(String alias) {
    return $TodoCategoryItemCountView(_attachedDatabase, alias);
  }

  @override
  SelectStatement? get query =>
      (_attachedDatabase.selectOnly(todoCategories)..addColumns(columns))
          .innerJoin(todoItems,
              on: todoItems.categoryId.equalsExp(todoCategories.id));
  @override
  Set<String> get readTables => const {'todo_items', 'todo_categories'};
}

class TodoItemWithCategoryNameViewData extends LegacyDataClass {
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
          LegacyDataClass.parseJson(encodedJson) as Map<String, dynamic>,
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

class $TodoItemWithCategoryNameViewView extends TodoItemWithCategoryNameView
    with
        ResultSet<TodoItemWithCategoryNameViewData,
            $TodoItemWithCategoryNameViewView>
    implements
        GeneratedView<TodoItemWithCategoryNameViewData,
            $TodoItemWithCategoryNameViewView> {
  @override
  final String? alias;
  final _$Database _attachedDatabase;
  $TodoItemWithCategoryNameViewView(this._attachedDatabase, [this.alias]);
  $TodoItemsTable get todoItems => _attachedDatabase.todoItems.withAlias('t0');
  $TodoCategoriesTable get todoCategories =>
      _attachedDatabase.todoCategories.withAlias('t1');
  @override
  List<SchemaColumn> get columns => [id, title];
  @override
  String get entityName => 'customViewName';
  @override
  $TodoItemWithCategoryNameViewView asSelfType() => this;

  @override
  TodoItemWithCategoryNameViewData? Function(DriftRow) createMapperToDart(
      DriftResultSet resultSet) {
    final columnPositions = resultSet.structure.tables[this]!;
    return (DriftRow row) {
      // Not part of row if non-nullable column "id" is missing
      if (row.raw.rawValue(columnPositions[0]) == null) {
        return null;
      }
      return TodoItemWithCategoryNameViewData(
        id: row.readWithType(columnPositions[0], BuiltinDriftType.int)!,
        title: row.readWithType(columnPositions[1], BuiltinDriftType.text),
      );
    };
  }

  late final ViewColumn<int> id = ViewColumn<int>(
      name: 'id',
      type: BuiltinDriftType.int,
      isNullable: false,
      expression: todoItems.id)
    ..owningResultSet = this;
  late final ViewColumn<String> title = ViewColumn<String>(
      name: 'title',
      type: BuiltinDriftType.text,
      isNullable: true,
      expression: todoItems.title +
          const Literal('(') +
          todoCategories.name +
          const Literal(')'))
    ..owningResultSet = this;
  @override
  $TodoItemWithCategoryNameViewView withAlias(String alias) {
    return $TodoItemWithCategoryNameViewView(_attachedDatabase, alias);
  }

  @override
  SelectStatement? get query =>
      (_attachedDatabase.selectOnly(todoItems)..addColumns(columns)).innerJoin(
          todoCategories,
          on: todoCategories.id.equalsExp(todoItems.categoryId));
  @override
  Set<String> get readTables => const {'todo_items', 'todo_categories'};
}

abstract base class _$Database extends GeneratedDatabase {
  _$Database(super.implementation);
  $DatabaseManager get managers => $DatabaseManager(this);
  late final $TodoCategoriesTable todoCategories = $TodoCategoriesTable();
  late final $TodoItemsTable todoItems = $TodoItemsTable();
  late final $TodoCategoryItemCountView todoCategoryItemCount =
      $TodoCategoryItemCountView(this);
  late final $TodoItemWithCategoryNameViewView customViewName =
      $TodoItemWithCategoryNameViewView(this);
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [todoCategories, todoItems, todoCategoryItemCount, customViewName];
}

typedef $$TodoCategoriesTableCreateCompanionBuilder = TodoCategoriesCompanion
    Function({
  Value<int> id,
  required String name,
});
typedef $$TodoCategoriesTableUpdateCompanionBuilder = TodoCategoriesCompanion
    Function({
  Value<int> id,
  Value<String> name,
});

final class $$TodoCategoriesTableReferences
    extends BaseReferences<_$Database, $TodoCategoriesTable, TodoCategory> {
  $$TodoCategoriesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TodoItemsTable, List<TodoItem>>
      _todoItemsRefsTable(_$Database db) =>
          MultiTypedResultKey.fromTable(db.todoItems,
              aliasName: $_aliasNameGenerator(
                  db.todoCategories.id, db.todoItems.categoryId));

  $$TodoItemsTableProcessedTableManager get todoItemsRefs {
    final manager = $$TodoItemsTableTableManager($_db, $_db.todoItems)
        .filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_todoItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$TodoCategoriesTableFilterComposer
    extends Composer<_$Database, $TodoCategoriesTable> {
  $$TodoCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  Expression<bool> todoItemsRefs(
      Expression<bool> Function($$TodoItemsTableFilterComposer f) f) {
    final $$TodoItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.todoItems,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TodoItemsTableFilterComposer(
              $db: $db,
              $table: $db.todoItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TodoCategoriesTableOrderingComposer
    extends Composer<_$Database, $TodoCategoriesTable> {
  $$TodoCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));
}

class $$TodoCategoriesTableAnnotationComposer
    extends Composer<_$Database, $TodoCategoriesTable> {
  $$TodoCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  Expression<T> todoItemsRefs<T extends Object>(
      Expression<T> Function($$TodoItemsTableAnnotationComposer a) f) {
    final $$TodoItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.todoItems,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TodoItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.todoItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TodoCategoriesTableTableManager extends RootTableManager<
    _$Database,
    $TodoCategoriesTable,
    TodoCategory,
    $$TodoCategoriesTableFilterComposer,
    $$TodoCategoriesTableOrderingComposer,
    $$TodoCategoriesTableAnnotationComposer,
    $$TodoCategoriesTableCreateCompanionBuilder,
    $$TodoCategoriesTableUpdateCompanionBuilder,
    (TodoCategory, $$TodoCategoriesTableReferences),
    TodoCategory,
    PrefetchHooks Function({bool todoItemsRefs})> {
  $$TodoCategoriesTableTableManager(_$Database db, $TodoCategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TodoCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TodoCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TodoCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
          }) =>
              TodoCategoriesCompanion(
            id: id,
            name: name,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
          }) =>
              TodoCategoriesCompanion.insert(
            id: id,
            name: name,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TodoCategoriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({todoItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (todoItemsRefs) db.todoItems],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (todoItemsRefs)
                    await $_getPrefetchedData<TodoCategory,
                            $TodoCategoriesTable, TodoItem>(
                        currentTable: table,
                        referencedTable: $$TodoCategoriesTableReferences
                            ._todoItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TodoCategoriesTableReferences(db, table, p0)
                                .todoItemsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.categoryId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$TodoCategoriesTableProcessedTableManager = ProcessedTableManager<
    _$Database,
    $TodoCategoriesTable,
    TodoCategory,
    $$TodoCategoriesTableFilterComposer,
    $$TodoCategoriesTableOrderingComposer,
    $$TodoCategoriesTableAnnotationComposer,
    $$TodoCategoriesTableCreateCompanionBuilder,
    $$TodoCategoriesTableUpdateCompanionBuilder,
    (TodoCategory, $$TodoCategoriesTableReferences),
    TodoCategory,
    PrefetchHooks Function({bool todoItemsRefs})>;
typedef $$TodoItemsTableCreateCompanionBuilder = TodoItemsCompanion Function({
  Value<int> id,
  required String title,
  Value<String?> content,
  required int categoryId,
});
typedef $$TodoItemsTableUpdateCompanionBuilder = TodoItemsCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<String?> content,
  Value<int> categoryId,
});

final class $$TodoItemsTableReferences
    extends BaseReferences<_$Database, $TodoItemsTable, TodoItem> {
  $$TodoItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TodoCategoriesTable _categoryIdTable(_$Database db) =>
      db.todoCategories.createAlias(
          $_aliasNameGenerator(db.todoItems.categoryId, db.todoCategories.id));

  $$TodoCategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<int>('category_id')!;

    final manager = $$TodoCategoriesTableTableManager($_db, $_db.todoCategories)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TodoItemsTableFilterComposer
    extends Composer<_$Database, $TodoItemsTable> {
  $$TodoItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get generatedText => $composableBuilder(
      column: $table.generatedText, builder: (column) => ColumnFilters(column));

  $$TodoCategoriesTableFilterComposer get categoryId {
    final $$TodoCategoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.todoCategories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TodoCategoriesTableFilterComposer(
              $db: $db,
              $table: $db.todoCategories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TodoItemsTableOrderingComposer
    extends Composer<_$Database, $TodoItemsTable> {
  $$TodoItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get generatedText => $composableBuilder(
      column: $table.generatedText,
      builder: (column) => ColumnOrderings(column));

  $$TodoCategoriesTableOrderingComposer get categoryId {
    final $$TodoCategoriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.todoCategories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TodoCategoriesTableOrderingComposer(
              $db: $db,
              $table: $db.todoCategories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TodoItemsTableAnnotationComposer
    extends Composer<_$Database, $TodoItemsTable> {
  $$TodoItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get generatedText => $composableBuilder(
      column: $table.generatedText, builder: (column) => column);

  $$TodoCategoriesTableAnnotationComposer get categoryId {
    final $$TodoCategoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.todoCategories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TodoCategoriesTableAnnotationComposer(
              $db: $db,
              $table: $db.todoCategories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TodoItemsTableTableManager extends RootTableManager<
    _$Database,
    $TodoItemsTable,
    TodoItem,
    $$TodoItemsTableFilterComposer,
    $$TodoItemsTableOrderingComposer,
    $$TodoItemsTableAnnotationComposer,
    $$TodoItemsTableCreateCompanionBuilder,
    $$TodoItemsTableUpdateCompanionBuilder,
    (TodoItem, $$TodoItemsTableReferences),
    TodoItem,
    PrefetchHooks Function({bool categoryId})> {
  $$TodoItemsTableTableManager(_$Database db, $TodoItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TodoItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TodoItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TodoItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> content = const Value.absent(),
            Value<int> categoryId = const Value.absent(),
          }) =>
              TodoItemsCompanion(
            id: id,
            title: title,
            content: content,
            categoryId: categoryId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String title,
            Value<String?> content = const Value.absent(),
            required int categoryId,
          }) =>
              TodoItemsCompanion.insert(
            id: id,
            title: title,
            content: content,
            categoryId: categoryId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TodoItemsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({categoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (categoryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.categoryId,
                    referencedTable:
                        $$TodoItemsTableReferences._categoryIdTable(db),
                    referencedColumn:
                        $$TodoItemsTableReferences._categoryIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$TodoItemsTableProcessedTableManager = ProcessedTableManager<
    _$Database,
    $TodoItemsTable,
    TodoItem,
    $$TodoItemsTableFilterComposer,
    $$TodoItemsTableOrderingComposer,
    $$TodoItemsTableAnnotationComposer,
    $$TodoItemsTableCreateCompanionBuilder,
    $$TodoItemsTableUpdateCompanionBuilder,
    (TodoItem, $$TodoItemsTableReferences),
    TodoItem,
    PrefetchHooks Function({bool categoryId})>;

class $DatabaseManager {
  final _$Database _db;
  $DatabaseManager(this._db);
  $$TodoCategoriesTableTableManager get todoCategories =>
      $$TodoCategoriesTableTableManager(_db, _db.todoCategories);
  $$TodoItemsTableTableManager get todoItems =>
      $$TodoItemsTableTableManager(_db, _db.todoItems);
}
