// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// **************************************************************************
// MoorGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps, unnecessary_this
class TodoGroupsCompanion extends UpdateCompanion<TodoGroupModel> {
  final Value<int> id;
  final Value<String> title;
  final Value<int?> itemCount;
  const TodoGroupsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.itemCount = const Value.absent(),
  });
  TodoGroupsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.itemCount = const Value.absent(),
  }) : title = Value(title);
  static Insertable<TodoGroupModel> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<int?>? itemCount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (itemCount != null) 'item_count': itemCount,
    });
  }

  TodoGroupsCompanion copyWith(
      {Value<int>? id, Value<String>? title, Value<int?>? itemCount}) {
    return TodoGroupsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      itemCount: itemCount ?? this.itemCount,
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
    if (itemCount.present) {
      map['item_count'] = Variable<int?>(itemCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TodoGroupsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('itemCount: $itemCount')
          ..write(')'))
        .toString();
  }
}

class $TodoGroupsTable extends TodoGroups
    with TableInfo<$TodoGroupsTable, TodoGroupModel> {
  final GeneratedDatabase _db;
  final String? _alias;
  $TodoGroupsTable(this._db, [this._alias]);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int?> id = GeneratedColumn<int?>(
      'id', aliasedName, false,
      typeName: 'INTEGER',
      requiredDuringInsert: false,
      defaultConstraints: 'PRIMARY KEY AUTOINCREMENT');
  final VerificationMeta _titleMeta = const VerificationMeta('title');
  late final GeneratedColumn<String?> title = GeneratedColumn<String?>(
      'title', aliasedName, false,
      typeName: 'TEXT', requiredDuringInsert: true);
  final VerificationMeta _itemCountMeta = const VerificationMeta('itemCount');
  late final GeneratedColumn<int?> itemCount = GeneratedColumn<int?>(
      'item_count', aliasedName, true,
      typeName: 'INTEGER',
      requiredDuringInsert: false,
      virtualSql: 'COUNT(todo_items.id)');
  @override
  List<GeneratedColumn> get $columns => [id, title, itemCount];
  @override
  String get aliasedName => _alias ?? 'todo_groups';
  @override
  String get actualTableName => 'todo_groups';
  @override
  VerificationContext validateIntegrity(Insertable<TodoGroupModel> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('item_count')) {
      context.handle(_itemCountMeta,
          itemCount.isAcceptableOrUnknown(data['item_count']!, _itemCountMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TodoGroupModel map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TodoGroupModel(
      const IntType().mapFromDatabaseResponse(data['${effectivePrefix}id'])!,
      const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}title'])!,
      const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}item_count']),
    );
  }

  @override
  $TodoGroupsTable createAlias(String alias) {
    return $TodoGroupsTable(_db, alias);
  }
}

class TodoItem extends DataClass implements Insertable<TodoItem> {
  final int id;
  final String title;
  final String content;
  final int priority;
  final int groupId;
  final String titleWithContent;
  final String? titleWithPriority;
  final String? groupName;
  TodoItem(
      {required this.id,
      required this.title,
      required this.content,
      required this.priority,
      required this.groupId,
      required this.titleWithContent,
      this.titleWithPriority,
      this.groupName});
  factory TodoItem.fromData(Map<String, dynamic> data, {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return TodoItem(
      id: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}id'])!,
      title: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}title'])!,
      content: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}content'])!,
      priority: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}priority'])!,
      groupId: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}group_id'])!,
      titleWithContent: const StringType().mapFromDatabaseResponse(
          data['${effectivePrefix}title_with_content'])!,
      titleWithPriority: const StringType().mapFromDatabaseResponse(
          data['${effectivePrefix}title_with_priority']),
      groupName: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}group_name']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['content'] = Variable<String>(content);
    map['priority'] = Variable<int>(priority);
    map['group_id'] = Variable<int>(groupId);
    map['title_with_content'] = Variable<String>(titleWithContent);
    if (!nullToAbsent || titleWithPriority != null) {
      map['title_with_priority'] = Variable<String?>(titleWithPriority);
    }
    if (!nullToAbsent || groupName != null) {
      map['group_name'] = Variable<String?>(groupName);
    }
    return map;
  }

  TodoItemsCompanion toCompanion(bool nullToAbsent) {
    return TodoItemsCompanion(
      id: Value(id),
      title: Value(title),
      content: Value(content),
      priority: Value(priority),
      groupId: Value(groupId),
      titleWithContent: Value(titleWithContent),
      titleWithPriority: titleWithPriority == null && nullToAbsent
          ? const Value.absent()
          : Value(titleWithPriority),
      groupName: groupName == null && nullToAbsent
          ? const Value.absent()
          : Value(groupName),
    );
  }

  factory TodoItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TodoItem(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      priority: serializer.fromJson<int>(json['priority']),
      groupId: serializer.fromJson<int>(json['groupId']),
      titleWithContent: serializer.fromJson<String>(json['titleWithContent']),
      titleWithPriority:
          serializer.fromJson<String?>(json['titleWithPriority']),
      groupName: serializer.fromJson<String?>(json['groupName']),
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
      'content': serializer.toJson<String>(content),
      'priority': serializer.toJson<int>(priority),
      'groupId': serializer.toJson<int>(groupId),
      'titleWithContent': serializer.toJson<String>(titleWithContent),
      'titleWithPriority': serializer.toJson<String?>(titleWithPriority),
      'groupName': serializer.toJson<String?>(groupName),
    };
  }

  TodoItem copyWith(
          {int? id,
          String? title,
          String? content,
          int? priority,
          int? groupId,
          String? titleWithContent,
          Value<String?> titleWithPriority = const Value.absent(),
          Value<String?> groupName = const Value.absent()}) =>
      TodoItem(
        id: id ?? this.id,
        title: title ?? this.title,
        content: content ?? this.content,
        priority: priority ?? this.priority,
        groupId: groupId ?? this.groupId,
        titleWithContent: titleWithContent ?? this.titleWithContent,
        titleWithPriority: titleWithPriority.present
            ? titleWithPriority.value
            : this.titleWithPriority,
        groupName: groupName.present ? groupName.value : this.groupName,
      );
  @override
  String toString() {
    return (StringBuffer('TodoItem(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('priority: $priority, ')
          ..write('groupId: $groupId, ')
          ..write('titleWithContent: $titleWithContent, ')
          ..write('titleWithPriority: $titleWithPriority, ')
          ..write('groupName: $groupName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, content, priority, groupId,
      titleWithContent, titleWithPriority, groupName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TodoItem &&
          other.id == this.id &&
          other.title == this.title &&
          other.content == this.content &&
          other.priority == this.priority &&
          other.groupId == this.groupId &&
          other.titleWithContent == this.titleWithContent &&
          other.titleWithPriority == this.titleWithPriority &&
          other.groupName == this.groupName);
}

class TodoItemsCompanion extends UpdateCompanion<TodoItem> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> content;
  final Value<int> priority;
  final Value<int> groupId;
  final Value<String> titleWithContent;
  final Value<String?> titleWithPriority;
  final Value<String?> groupName;
  const TodoItemsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.priority = const Value.absent(),
    this.groupId = const Value.absent(),
    this.titleWithContent = const Value.absent(),
    this.titleWithPriority = const Value.absent(),
    this.groupName = const Value.absent(),
  });
  TodoItemsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String content,
    required int priority,
    required int groupId,
    this.titleWithContent = const Value.absent(),
    this.titleWithPriority = const Value.absent(),
    this.groupName = const Value.absent(),
  })  : title = Value(title),
        content = Value(content),
        priority = Value(priority),
        groupId = Value(groupId);
  static Insertable<TodoItem> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? content,
    Expression<int>? priority,
    Expression<int>? groupId,
    Expression<String>? titleWithContent,
    Expression<String?>? titleWithPriority,
    Expression<String?>? groupName,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (priority != null) 'priority': priority,
      if (groupId != null) 'group_id': groupId,
      if (titleWithContent != null) 'title_with_content': titleWithContent,
      if (titleWithPriority != null) 'title_with_priority': titleWithPriority,
      if (groupName != null) 'group_name': groupName,
    });
  }

  TodoItemsCompanion copyWith(
      {Value<int>? id,
      Value<String>? title,
      Value<String>? content,
      Value<int>? priority,
      Value<int>? groupId,
      Value<String>? titleWithContent,
      Value<String?>? titleWithPriority,
      Value<String?>? groupName}) {
    return TodoItemsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      priority: priority ?? this.priority,
      groupId: groupId ?? this.groupId,
      titleWithContent: titleWithContent ?? this.titleWithContent,
      titleWithPriority: titleWithPriority ?? this.titleWithPriority,
      groupName: groupName ?? this.groupName,
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
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<int>(groupId.value);
    }
    if (titleWithContent.present) {
      map['title_with_content'] = Variable<String>(titleWithContent.value);
    }
    if (titleWithPriority.present) {
      map['title_with_priority'] = Variable<String?>(titleWithPriority.value);
    }
    if (groupName.present) {
      map['group_name'] = Variable<String?>(groupName.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TodoItemsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('priority: $priority, ')
          ..write('groupId: $groupId, ')
          ..write('titleWithContent: $titleWithContent, ')
          ..write('titleWithPriority: $titleWithPriority, ')
          ..write('groupName: $groupName')
          ..write(')'))
        .toString();
  }
}

class $TodoItemsTable extends TodoItems
    with TableInfo<$TodoItemsTable, TodoItem> {
  final GeneratedDatabase _db;
  final String? _alias;
  $TodoItemsTable(this._db, [this._alias]);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int?> id = GeneratedColumn<int?>(
      'id', aliasedName, false,
      typeName: 'INTEGER',
      requiredDuringInsert: false,
      defaultConstraints: 'PRIMARY KEY AUTOINCREMENT');
  final VerificationMeta _titleMeta = const VerificationMeta('title');
  late final GeneratedColumn<String?> title = GeneratedColumn<String?>(
      'title', aliasedName, false,
      typeName: 'TEXT', requiredDuringInsert: true);
  final VerificationMeta _contentMeta = const VerificationMeta('content');
  late final GeneratedColumn<String?> content = GeneratedColumn<String?>(
      'content', aliasedName, false,
      typeName: 'TEXT', requiredDuringInsert: true);
  final VerificationMeta _priorityMeta = const VerificationMeta('priority');
  late final GeneratedColumn<int?> priority = GeneratedColumn<int?>(
      'priority', aliasedName, false,
      typeName: 'INTEGER', requiredDuringInsert: true);
  final VerificationMeta _groupIdMeta = const VerificationMeta('groupId');
  late final GeneratedColumn<int?> groupId = GeneratedColumn<int?>(
      'group_id', aliasedName, false,
      typeName: 'INTEGER',
      requiredDuringInsert: true,
      defaultConstraints: 'REFERENCES todo_groups (id)');
  final VerificationMeta _titleWithContentMeta =
      const VerificationMeta('titleWithContent');
  late final GeneratedColumn<String?> titleWithContent =
      GeneratedColumn<String?>('title_with_content', aliasedName, false,
          typeName: 'TEXT',
          requiredDuringInsert: false,
          virtualSql: 'todo_items.title || \': \' || todo_items.content');
  final VerificationMeta _titleWithPriorityMeta =
      const VerificationMeta('titleWithPriority');
  late final GeneratedColumn<String?> titleWithPriority =
      GeneratedColumn<String?>('title_with_priority', aliasedName, true,
          typeName: 'TEXT',
          requiredDuringInsert: false,
          virtualSql:
              'todo_items.title || \' (\' || todo_items.priority || \')\'');
  final VerificationMeta _groupNameMeta = const VerificationMeta('groupName');
  late final GeneratedColumn<String?> groupName = GeneratedColumn<String?>(
      'group_name', aliasedName, true,
      typeName: 'TEXT',
      requiredDuringInsert: false,
      virtualSql: 'todo_groups.title');
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        content,
        priority,
        groupId,
        titleWithContent,
        titleWithPriority,
        groupName
      ];
  @override
  String get aliasedName => _alias ?? 'todo_items';
  @override
  String get actualTableName => 'todo_items';
  @override
  VerificationContext validateIntegrity(Insertable<TodoItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    } else if (isInserting) {
      context.missing(_priorityMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('title_with_content')) {
      context.handle(
          _titleWithContentMeta,
          titleWithContent.isAcceptableOrUnknown(
              data['title_with_content']!, _titleWithContentMeta));
    }
    if (data.containsKey('title_with_priority')) {
      context.handle(
          _titleWithPriorityMeta,
          titleWithPriority.isAcceptableOrUnknown(
              data['title_with_priority']!, _titleWithPriorityMeta));
    }
    if (data.containsKey('group_name')) {
      context.handle(_groupNameMeta,
          groupName.isAcceptableOrUnknown(data['group_name']!, _groupNameMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TodoItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    return TodoItem.fromData(data,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  $TodoItemsTable createAlias(String alias) {
    return $TodoItemsTable(_db, alias);
  }
}

class TodoPriorityListItem extends DataClass {
  final int id;
  final String? titleWithPriority;
  TodoPriorityListItem({required this.id, this.titleWithPriority});
  factory TodoPriorityListItem.fromData(Map<String, dynamic> data,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return TodoPriorityListItem(
      id: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}id'])!,
      titleWithPriority: const StringType().mapFromDatabaseResponse(
          data['${effectivePrefix}title_with_priority']),
    );
  }
  factory TodoPriorityListItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TodoPriorityListItem(
      id: serializer.fromJson<int>(json['id']),
      titleWithPriority:
          serializer.fromJson<String?>(json['titleWithPriority']),
    );
  }
  factory TodoPriorityListItem.fromJsonString(String encodedJson,
          {ValueSerializer? serializer}) =>
      TodoPriorityListItem.fromJson(
          DataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'titleWithPriority': serializer.toJson<String?>(titleWithPriority),
    };
  }

  TodoPriorityListItem copyWith(
          {int? id, Value<String?> titleWithPriority = const Value.absent()}) =>
      TodoPriorityListItem(
        id: id ?? this.id,
        titleWithPriority: titleWithPriority.present
            ? titleWithPriority.value
            : this.titleWithPriority,
      );
  @override
  String toString() {
    return (StringBuffer('TodoPriorityListItem(')
          ..write('id: $id, ')
          ..write('titleWithPriority: $titleWithPriority')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, titleWithPriority);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TodoPriorityListItem &&
          other.id == this.id &&
          other.titleWithPriority == this.titleWithPriority);
}

class TodoPriorityListItemView
    extends View<TodoPriorityListItemView, TodoPriorityListItem> {
  TodoPriorityListItemView() : super('todo_items', null);
  @override
  List<GeneratedColumn> get $columns => [id, titleWithPriority];
  @override
  TodoPriorityListItemView get asDslTable => this;
  @override
  TodoPriorityListItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    return TodoPriorityListItem.fromData(data,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  late final GeneratedColumn<int?> id = GeneratedColumn<int?>(
      'id', aliasedName, false,
      typeName: 'INTEGER', defaultConstraints: 'PRIMARY KEY AUTOINCREMENT');
  late final GeneratedColumn<String?> titleWithPriority =
      GeneratedColumn<String?>('title_with_priority', aliasedName, true,
          typeName: 'TEXT',
          virtualSql:
              'todo_items.title || \' (\' || todo_items.priority || \')\'');
}

class TodoListItemWithGroupNameView
    extends View<TodoListItemWithGroupNameView, TodoListItemWithGroupName> {
  TodoListItemWithGroupNameView() : super('todo_items', null);
  @override
  List<GeneratedColumn> get $columns => [title, groupName];
  @override
  TodoListItemWithGroupNameView get asDslTable => this;
  @override
  TodoListItemWithGroupName map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TodoListItemWithGroupName(
      const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}title'])!,
      const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}group_name']),
    );
  }

  late final GeneratedColumn<String?> title =
      GeneratedColumn<String?>('title', aliasedName, false, typeName: 'TEXT');
  late final GeneratedColumn<String?> groupName = GeneratedColumn<String?>(
      'group_name', aliasedName, true,
      typeName: 'TEXT', virtualSql: 'todo_groups.title');
}

class TodoGroupWithCount extends DataClass {
  final int id;
  final int? itemCount;
  TodoGroupWithCount({required this.id, this.itemCount});
  factory TodoGroupWithCount.fromData(Map<String, dynamic> data,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return TodoGroupWithCount(
      id: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}id'])!,
      itemCount: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}item_count']),
    );
  }
  factory TodoGroupWithCount.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TodoGroupWithCount(
      id: serializer.fromJson<int>(json['id']),
      itemCount: serializer.fromJson<int?>(json['itemCount']),
    );
  }
  factory TodoGroupWithCount.fromJsonString(String encodedJson,
          {ValueSerializer? serializer}) =>
      TodoGroupWithCount.fromJson(
          DataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'itemCount': serializer.toJson<int?>(itemCount),
    };
  }

  TodoGroupWithCount copyWith(
          {int? id, Value<int?> itemCount = const Value.absent()}) =>
      TodoGroupWithCount(
        id: id ?? this.id,
        itemCount: itemCount.present ? itemCount.value : this.itemCount,
      );
  @override
  String toString() {
    return (StringBuffer('TodoGroupWithCount(')
          ..write('id: $id, ')
          ..write('itemCount: $itemCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, itemCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TodoGroupWithCount &&
          other.id == this.id &&
          other.itemCount == this.itemCount);
}

class TodoGroupWithCountView
    extends View<TodoGroupWithCountView, TodoGroupWithCount> {
  TodoGroupWithCountView() : super('todo_groups', null);
  @override
  List<GeneratedColumn> get $columns => [id, itemCount];
  @override
  TodoGroupWithCountView get asDslTable => this;
  @override
  TodoGroupWithCount map(Map<String, dynamic> data, {String? tablePrefix}) {
    return TodoGroupWithCount.fromData(data,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  late final GeneratedColumn<int?> id = GeneratedColumn<int?>(
      'id', aliasedName, false,
      typeName: 'INTEGER', defaultConstraints: 'PRIMARY KEY AUTOINCREMENT');
  late final GeneratedColumn<int?> itemCount = GeneratedColumn<int?>(
      'item_count', aliasedName, true,
      typeName: 'INTEGER', virtualSql: 'COUNT(todo_items.id)');
}

abstract class _$Database extends GeneratedDatabase {
  _$Database(QueryExecutor e) : super(SqlTypeSystem.defaultInstance, e);
  _$Database.connect(DatabaseConnection c) : super.connect(c);
  late final $TodoGroupsTable todoGroups = $TodoGroupsTable(this);
  late final $TodoItemsTable todoItems = $TodoItemsTable(this);
  late final TodoPriorityListItemView todoPriorityListItem =
      TodoPriorityListItemView();
  late final TodoListItemWithGroupNameView todoListItemWithGroupName =
      TodoListItemWithGroupNameView();
  late final TodoGroupWithCountView todoGroupWithCount =
      TodoGroupWithCountView();
  @override
  Iterable<TableInfo> get allTables => allSchemaEntities.whereType<TableInfo>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        todoGroups,
        todoItems,
        todoPriorityListItem,
        todoListItemWithGroupName,
        todoGroupWithCount
      ];
}
