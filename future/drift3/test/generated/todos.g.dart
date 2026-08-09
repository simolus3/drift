// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todos.dart';

// ignore_for_file: type=lint
class $CategoriesTable extends Categories
    with ResultSet<Category, $CategoriesTable>
    implements GeneratedTable<Category, $CategoriesTable> {
  @override
  final String? alias;
  $CategoriesTable([this.alias]);
  @override
  late final TableColumnWithTypeConverter<RowId, int> id = TableColumn<int>(
    name: 'id',
    sqlType: BuiltinDriftType.int,
    requiredDuringInsert: false,
    constraints: () => [
      const ColumnPrimaryKeyConstraint(isAutoIncrementing: true),
      const ColumnNotNullConstraint(),
    ],
  ).withConverter<RowId>($CategoriesTable.$converterid)..owningResultSet = this;
  @override
  late final TableColumn<String> description = TableColumn<String>(
    name: 'desc',
    sqlType: BuiltinDriftType.text,
    requiredDuringInsert: true,
    constraints: () => [ColumnConstraint.customSql('NOT NULL UNIQUE')],
  )..owningResultSet = this;
  @override
  late final TableColumnWithTypeConverter<CategoryPriority, int> priority =
      TableColumn<int>(
          name: 'priority',
          sqlType: BuiltinDriftType.int,
          requiredDuringInsert: false,
          constraints: () => [
            const ColumnNotNullConstraint(),
            ColumnDefaultConstraint<int>(const Literal(0)),
          ],
        ).withConverter<CategoryPriority>($CategoriesTable.$converterpriority)
        ..owningResultSet = this;
  @override
  late final TableColumn<String> descriptionInUpperCase = TableColumn<String>(
    name: 'description_in_upper_case',
    sqlType: BuiltinDriftType.text,
    requiredDuringInsert: false,
    constraints: () => [
      const ColumnNotNullConstraint(),
      ColumnGeneratedAs(
        StringExpressionOperators(description).upper(),
        stored: false,
      ),
    ],
  )..owningResultSet = this;
  @override
  List<TableColumn> get columns => [
    id,
    description,
    priority,
    descriptionInUpperCase,
  ];
  @override
  String get entityName => $name;
  static const String $name = 'categories';
  @override
  $CategoriesTable asSelfType() => this;

  @override
  Category? Function(RawRow) createMapperFromPositions(
    DriftDialect dialect,
    List<ColumnPosition> positions,
  ) {
    final pos$id = positions[0].index;
    final type$0 = BuiltinDriftType.int.resolveIn(dialect);
    final pos$description = positions[1].index;
    final type$1 = BuiltinDriftType.text.resolveIn(dialect);
    final pos$priority = positions[2].index;
    final pos$descriptionInUpperCase = positions[3].index;
    return (RawRow row) {
      // Not part of row if non-nullable column "id" is missing
      if (row[pos$id] == null) {
        return null;
      }
      return Category(
        id: $CategoriesTable.$converterid.fromSql(
          type$0.dartValue(row[pos$id]!),
        ),
        description: type$1.dartValue(row[pos$description]!),
        priority: $CategoriesTable.$converterpriority.fromSql(
          type$0.dartValue(row[pos$priority]!),
        ),
        descriptionInUpperCase: type$1.dartValue(
          row[pos$descriptionInUpperCase]!,
        ),
      );
    };
  }

  @override
  $CategoriesTable withAlias(String alias) {
    return $CategoriesTable(alias);
  }

  static JsonTypeConverter2<RowId, int, int> $converterid =
      TypeConverter.extensionType<RowId, int>();
  static JsonTypeConverter2<CategoryPriority, int, int> $converterpriority =
      const EnumIndexConverter<CategoryPriority>(CategoryPriority.values);
}

class Category extends LegacyDataClass implements Insertable<Category> {
  final RowId id;
  final String description;
  final CategoryPriority priority;
  final String descriptionInUpperCase;
  const Category({
    required this.id,
    required this.description,
    required this.priority,
    required this.descriptionInUpperCase,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['id'] = Variable<int>(
        $CategoriesTable.$converterid.toSql(id),
        BuiltinDriftType.int,
      );
    }
    map['desc'] = Variable<String>(description, BuiltinDriftType.text);
    {
      map['priority'] = Variable<int>(
        $CategoriesTable.$converterpriority.toSql(priority),
        BuiltinDriftType.int,
      );
    }
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      description: Value(description),
      priority: Value(priority),
    );
  }

  factory Category.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: $CategoriesTable.$converterid.fromJson(
        serializer.fromJson<int>(json['id']),
      ),
      description: serializer.fromJson<String>(json['description']),
      priority: $CategoriesTable.$converterpriority.fromJson(
        serializer.fromJson<int>(json['priority']),
      ),
      descriptionInUpperCase: serializer.fromJson<String>(
        json['descriptionInUpperCase'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>($CategoriesTable.$converterid.toJson(id)),
      'description': serializer.toJson<String>(description),
      'priority': serializer.toJson<int>(
        $CategoriesTable.$converterpriority.toJson(priority),
      ),
      'descriptionInUpperCase': serializer.toJson<String>(
        descriptionInUpperCase,
      ),
    };
  }

  Category copyWith({
    RowId? id,
    String? description,
    CategoryPriority? priority,
    String? descriptionInUpperCase,
  }) => Category(
    id: id ?? this.id,
    description: description ?? this.description,
    priority: priority ?? this.priority,
    descriptionInUpperCase:
        descriptionInUpperCase ?? this.descriptionInUpperCase,
  );
  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('description: $description, ')
          ..write('priority: $priority, ')
          ..write('descriptionInUpperCase: $descriptionInUpperCase')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, description, priority, descriptionInUpperCase);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.description == this.description &&
          other.priority == this.priority &&
          other.descriptionInUpperCase == this.descriptionInUpperCase);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<RowId> id;
  final Value<String> description;
  final Value<CategoryPriority> priority;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.description = const Value.absent(),
    this.priority = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String description,
    this.priority = const Value.absent(),
  }) : description = Value(description);
  static Insertable<Category> custom({
    Expression<int>? id,
    Expression<String>? description,
    Expression<int>? priority,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (description != null) 'desc': description,
      if (priority != null) 'priority': priority,
    });
  }

  CategoriesCompanion copyWith({
    Value<RowId>? id,
    Value<String>? description,
    Value<CategoryPriority>? priority,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      description: description ?? this.description,
      priority: priority ?? this.priority,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(
        $CategoriesTable.$converterid.toSql(id.value),
        BuiltinDriftType.int,
      );
    }
    if (description.present) {
      map['desc'] = Variable<String>(description.value, BuiltinDriftType.text);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(
        $CategoriesTable.$converterpriority.toSql(priority.value),
        BuiltinDriftType.int,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('description: $description, ')
          ..write('priority: $priority')
          ..write(')'))
        .toString();
  }
}

class $TodosTableTable extends TodosTable
    with ResultSet<TodoEntry, $TodosTableTable>
    implements GeneratedTable<TodoEntry, $TodosTableTable> {
  @override
  final String? alias;
  $TodosTableTable([this.alias]);
  @override
  late final TableColumnWithTypeConverter<RowId, int> id = TableColumn<int>(
    name: 'id',
    sqlType: BuiltinDriftType.int,
    requiredDuringInsert: false,
    constraints: () => [
      const ColumnPrimaryKeyConstraint(isAutoIncrementing: true),
      const ColumnNotNullConstraint(),
    ],
  ).withConverter<RowId>($TodosTableTable.$converterid)..owningResultSet = this;
  @override
  late final TableColumn<String> title = TableColumn<String>(
    name: 'title',
    sqlType: BuiltinDriftType.text,
    requiredDuringInsert: false,
  )..owningResultSet = this;
  @override
  late final TableColumn<String> content = TableColumn<String>(
    name: 'content',
    sqlType: BuiltinDriftType.text,
    requiredDuringInsert: true,
    constraints: () => [const ColumnNotNullConstraint()],
  )..owningResultSet = this;
  @override
  late final TableColumn<DateTime> targetDate = TableColumn<DateTime>(
    name: 'target_date',
    sqlType: BuiltinDriftType.dateTime,
    requiredDuringInsert: false,
    constraints: () => [const ColumnUniqueConstraint()],
  )..owningResultSet = this;
  @override
  late final TableColumnWithTypeConverter<RowId?, int> category =
      TableColumn<int>(
          name: 'category',
          sqlType: BuiltinDriftType.int,
          requiredDuringInsert: false,
          constraints: () => [
            const ColumnForeignKeyConstraint(
              otherTableName: 'categories',
              otherColumnName: 'id',
              initiallyDeferred: true,
            ),
          ],
        ).withConverter<RowId?>($TodosTableTable.$convertercategoryn)
        ..owningResultSet = this;
  @override
  late final TableColumnWithTypeConverter<TodoStatus?, String> status =
      TableColumn<String>(
          name: 'status',
          sqlType: BuiltinDriftType.text,
          requiredDuringInsert: false,
        ).withConverter<TodoStatus?>($TodosTableTable.$converterstatusn)
        ..owningResultSet = this;
  @override
  List<TableColumn> get columns => [
    id,
    title,
    content,
    targetDate,
    category,
    status,
  ];
  @override
  String get entityName => $name;
  static const String $name = 'todos';
  @override
  $TodosTableTable asSelfType() => this;

  @override
  List<Set<TableColumn>> get uniqueKeys => [
    {title, category},
    {title, targetDate},
  ];
  @override
  TodoEntry? Function(RawRow) createMapperFromPositions(
    DriftDialect dialect,
    List<ColumnPosition> positions,
  ) {
    final pos$id = positions[0].index;
    final type$0 = BuiltinDriftType.int.resolveIn(dialect);
    final pos$title = positions[1].index;
    final type$1 = BuiltinDriftType.text.resolveIn(dialect);
    final pos$content = positions[2].index;
    final pos$targetDate = positions[3].index;
    final type$2 = BuiltinDriftType.dateTime.resolveIn(dialect);
    final pos$category = positions[4].index;
    final pos$status = positions[5].index;
    return (RawRow row) {
      // Not part of row if non-nullable column "id" is missing
      if (row[pos$id] == null) {
        return null;
      }
      return TodoEntry(
        id: $TodosTableTable.$converterid.fromSql(
          type$0.dartValue(row[pos$id]!),
        ),
        title: type$1.nullableDartValue(row[pos$title]),
        content: type$1.dartValue(row[pos$content]!),
        targetDate: type$2.nullableDartValue(row[pos$targetDate]),
        category: $TodosTableTable.$convertercategoryn.fromSql(
          type$0.nullableDartValue(row[pos$category]),
        ),
        status: $TodosTableTable.$converterstatusn.fromSql(
          type$1.nullableDartValue(row[pos$status]),
        ),
      );
    };
  }

  @override
  $TodosTableTable withAlias(String alias) {
    return $TodosTableTable(alias);
  }

  static JsonTypeConverter2<RowId, int, int> $converterid =
      TypeConverter.extensionType<RowId, int>();
  static JsonTypeConverter2<RowId, int, int> $convertercategory =
      TypeConverter.extensionType<RowId, int>();
  static JsonTypeConverter2<RowId?, int?, int?> $convertercategoryn =
      JsonTypeConverter2.asNullable($convertercategory);
  static JsonTypeConverter2<TodoStatus, String, String> $converterstatus =
      const EnumNameConverter<TodoStatus>(TodoStatus.values);
  static JsonTypeConverter2<TodoStatus?, String?, String?> $converterstatusn =
      JsonTypeConverter2.asNullable($converterstatus);
}

class TodoEntry extends LegacyDataClass implements Insertable<TodoEntry> {
  final RowId id;
  final String? title;
  final String content;
  final DateTime? targetDate;
  final RowId? category;
  final TodoStatus? status;
  const TodoEntry({
    required this.id,
    this.title,
    required this.content,
    this.targetDate,
    this.category,
    this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['id'] = Variable<int>(
        $TodosTableTable.$converterid.toSql(id),
        BuiltinDriftType.int,
      );
    }
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title, BuiltinDriftType.text);
    }
    map['content'] = Variable<String>(content, BuiltinDriftType.text);
    if (!nullToAbsent || targetDate != null) {
      map['target_date'] = Variable<DateTime>(
        targetDate,
        BuiltinDriftType.dateTime,
      );
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<int>(
        $TodosTableTable.$convertercategoryn.toSql(category),
        BuiltinDriftType.int,
      );
    }
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<String>(
        $TodosTableTable.$converterstatusn.toSql(status),
        BuiltinDriftType.text,
      );
    }
    return map;
  }

  TodosTableCompanion toCompanion(bool nullToAbsent) {
    return TodosTableCompanion(
      id: Value(id),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      content: Value(content),
      targetDate: targetDate == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDate),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      status: status == null && nullToAbsent
          ? const Value.absent()
          : Value(status),
    );
  }

  factory TodoEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TodoEntry(
      id: $TodosTableTable.$converterid.fromJson(
        serializer.fromJson<int>(json['id']),
      ),
      title: serializer.fromJson<String?>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      targetDate: serializer.fromJson<DateTime?>(json['targetDate']),
      category: $TodosTableTable.$convertercategoryn.fromJson(
        serializer.fromJson<int?>(json['category']),
      ),
      status: $TodosTableTable.$converterstatusn.fromJson(
        serializer.fromJson<String?>(json['status']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>($TodosTableTable.$converterid.toJson(id)),
      'title': serializer.toJson<String?>(title),
      'content': serializer.toJson<String>(content),
      'targetDate': serializer.toJson<DateTime?>(targetDate),
      'category': serializer.toJson<int?>(
        $TodosTableTable.$convertercategoryn.toJson(category),
      ),
      'status': serializer.toJson<String?>(
        $TodosTableTable.$converterstatusn.toJson(status),
      ),
    };
  }

  TodoEntry copyWith({
    RowId? id,
    Value<String?> title = const Value.absent(),
    String? content,
    Value<DateTime?> targetDate = const Value.absent(),
    Value<RowId?> category = const Value.absent(),
    Value<TodoStatus?> status = const Value.absent(),
  }) => TodoEntry(
    id: id ?? this.id,
    title: title.present ? title.value : this.title,
    content: content ?? this.content,
    targetDate: targetDate.present ? targetDate.value : this.targetDate,
    category: category.present ? category.value : this.category,
    status: status.present ? status.value : this.status,
  );
  TodoEntry copyWithCompanion(TodosTableCompanion data) {
    return TodoEntry(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      targetDate: data.targetDate.present
          ? data.targetDate.value
          : this.targetDate,
      category: data.category.present ? data.category.value : this.category,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TodoEntry(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('targetDate: $targetDate, ')
          ..write('category: $category, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, content, targetDate, category, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TodoEntry &&
          other.id == this.id &&
          other.title == this.title &&
          other.content == this.content &&
          other.targetDate == this.targetDate &&
          other.category == this.category &&
          other.status == this.status);
}

class TodosTableCompanion extends UpdateCompanion<TodoEntry> {
  final Value<RowId> id;
  final Value<String?> title;
  final Value<String> content;
  final Value<DateTime?> targetDate;
  final Value<RowId?> category;
  final Value<TodoStatus?> status;
  const TodosTableCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.category = const Value.absent(),
    this.status = const Value.absent(),
  });
  TodosTableCompanion.insert({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    required String content,
    this.targetDate = const Value.absent(),
    this.category = const Value.absent(),
    this.status = const Value.absent(),
  }) : content = Value(content);
  static Insertable<TodoEntry> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? content,
    Expression<DateTime>? targetDate,
    Expression<int>? category,
    Expression<String>? status,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (targetDate != null) 'target_date': targetDate,
      if (category != null) 'category': category,
      if (status != null) 'status': status,
    });
  }

  TodosTableCompanion copyWith({
    Value<RowId>? id,
    Value<String?>? title,
    Value<String>? content,
    Value<DateTime?>? targetDate,
    Value<RowId?>? category,
    Value<TodoStatus?>? status,
  }) {
    return TodosTableCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      targetDate: targetDate ?? this.targetDate,
      category: category ?? this.category,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(
        $TodosTableTable.$converterid.toSql(id.value),
        BuiltinDriftType.int,
      );
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value, BuiltinDriftType.text);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value, BuiltinDriftType.text);
    }
    if (targetDate.present) {
      map['target_date'] = Variable<DateTime>(
        targetDate.value,
        BuiltinDriftType.dateTime,
      );
    }
    if (category.present) {
      map['category'] = Variable<int>(
        $TodosTableTable.$convertercategoryn.toSql(category.value),
        BuiltinDriftType.int,
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $TodosTableTable.$converterstatusn.toSql(status.value),
        BuiltinDriftType.text,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TodosTableCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('targetDate: $targetDate, ')
          ..write('category: $category, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }
}

class $UsersTable extends Users
    with ResultSet<User, $UsersTable>
    implements GeneratedTable<User, $UsersTable> {
  @override
  final String? alias;
  $UsersTable([this.alias]);
  @override
  late final TableColumnWithTypeConverter<RowId, int> id = TableColumn<int>(
    name: 'id',
    sqlType: BuiltinDriftType.int,
    requiredDuringInsert: false,
    constraints: () => [
      const ColumnPrimaryKeyConstraint(isAutoIncrementing: true),
      const ColumnNotNullConstraint(),
    ],
  ).withConverter<RowId>($UsersTable.$converterid)..owningResultSet = this;
  @override
  late final TableColumn<String> name = TableColumn<String>(
    name: 'name',
    sqlType: BuiltinDriftType.text,
    requiredDuringInsert: true,
    constraints: () => [
      const ColumnNotNullConstraint(),
      const ColumnUniqueConstraint(),
    ],
  )..owningResultSet = this;
  @override
  late final TableColumn<bool> isAwesome = TableColumn<bool>(
    name: 'is_awesome',
    sqlType: BuiltinDriftType.bool,
    requiredDuringInsert: false,
    constraints: () => [
      const ColumnNotNullConstraint(),
      ColumnDefaultConstraint<bool>(const Literal(true)),
    ],
  )..owningResultSet = this;
  @override
  late final TableColumn<Uint8List> profilePicture = TableColumn<Uint8List>(
    name: 'profile_picture',
    sqlType: BuiltinDriftType.byteArray,
    requiredDuringInsert: true,
    constraints: () => [const ColumnNotNullConstraint()],
  )..owningResultSet = this;
  @override
  late final TableColumn<DateTime> creationTime = TableColumn<DateTime>(
    name: 'creation_time',
    sqlType: BuiltinDriftType.dateTime,
    requiredDuringInsert: false,
    constraints: () => [
      const ColumnNotNullConstraint(),
      ColumnDefaultConstraint<DateTime>(currentDateAndTime),
      ColumnCheckConstraint(
        ComparableExpr(creationTime).isGreaterThan(Literal(DateTime.utc(1950))),
      ),
    ],
  )..owningResultSet = this;
  @override
  List<TableColumn> get columns => [
    id,
    name,
    isAwesome,
    profilePicture,
    creationTime,
  ];
  @override
  String get entityName => $name;
  static const String $name = 'users';
  @override
  $UsersTable asSelfType() => this;

  @override
  User? Function(RawRow) createMapperFromPositions(
    DriftDialect dialect,
    List<ColumnPosition> positions,
  ) {
    final pos$id = positions[0].index;
    final type$0 = BuiltinDriftType.int.resolveIn(dialect);
    final pos$name = positions[1].index;
    final type$1 = BuiltinDriftType.text.resolveIn(dialect);
    final pos$isAwesome = positions[2].index;
    final type$2 = BuiltinDriftType.bool.resolveIn(dialect);
    final pos$profilePicture = positions[3].index;
    final type$3 = BuiltinDriftType.byteArray.resolveIn(dialect);
    final pos$creationTime = positions[4].index;
    final type$4 = BuiltinDriftType.dateTime.resolveIn(dialect);
    return (RawRow row) {
      // Not part of row if non-nullable column "id" is missing
      if (row[pos$id] == null) {
        return null;
      }
      return User(
        id: $UsersTable.$converterid.fromSql(type$0.dartValue(row[pos$id]!)),
        name: type$1.dartValue(row[pos$name]!),
        isAwesome: type$2.dartValue(row[pos$isAwesome]!),
        profilePicture: type$3.dartValue(row[pos$profilePicture]!),
        creationTime: type$4.dartValue(row[pos$creationTime]!),
      );
    };
  }

  @override
  $UsersTable withAlias(String alias) {
    return $UsersTable(alias);
  }

  static JsonTypeConverter2<RowId, int, int> $converterid =
      TypeConverter.extensionType<RowId, int>();
}

class User extends LegacyDataClass implements Insertable<User> {
  final RowId id;
  final String name;
  final bool isAwesome;
  final Uint8List profilePicture;
  final DateTime creationTime;
  const User({
    required this.id,
    required this.name,
    required this.isAwesome,
    required this.profilePicture,
    required this.creationTime,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['id'] = Variable<int>(
        $UsersTable.$converterid.toSql(id),
        BuiltinDriftType.int,
      );
    }
    map['name'] = Variable<String>(name, BuiltinDriftType.text);
    map['is_awesome'] = Variable<bool>(isAwesome, BuiltinDriftType.bool);
    map['profile_picture'] = Variable<Uint8List>(
      profilePicture,
      BuiltinDriftType.byteArray,
    );
    map['creation_time'] = Variable<DateTime>(
      creationTime,
      BuiltinDriftType.dateTime,
    );
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      name: Value(name),
      isAwesome: Value(isAwesome),
      profilePicture: Value(profilePicture),
      creationTime: Value(creationTime),
    );
  }

  factory User.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: $UsersTable.$converterid.fromJson(
        serializer.fromJson<int>(json['id']),
      ),
      name: serializer.fromJson<String>(json['name']),
      isAwesome: serializer.fromJson<bool>(json['isAwesome']),
      profilePicture: serializer.fromJson<Uint8List>(json['profilePicture']),
      creationTime: serializer.fromJson<DateTime>(json['creationTime']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>($UsersTable.$converterid.toJson(id)),
      'name': serializer.toJson<String>(name),
      'isAwesome': serializer.toJson<bool>(isAwesome),
      'profilePicture': serializer.toJson<Uint8List>(profilePicture),
      'creationTime': serializer.toJson<DateTime>(creationTime),
    };
  }

  User copyWith({
    RowId? id,
    String? name,
    bool? isAwesome,
    Uint8List? profilePicture,
    DateTime? creationTime,
  }) => User(
    id: id ?? this.id,
    name: name ?? this.name,
    isAwesome: isAwesome ?? this.isAwesome,
    profilePicture: profilePicture ?? this.profilePicture,
    creationTime: creationTime ?? this.creationTime,
  );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      isAwesome: data.isAwesome.present ? data.isAwesome.value : this.isAwesome,
      profilePicture: data.profilePicture.present
          ? data.profilePicture.value
          : this.profilePicture,
      creationTime: data.creationTime.present
          ? data.creationTime.value
          : this.creationTime,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isAwesome: $isAwesome, ')
          ..write('profilePicture: $profilePicture, ')
          ..write('creationTime: $creationTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    isAwesome,
    $driftBlobEquality.hash(profilePicture),
    creationTime,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.name == this.name &&
          other.isAwesome == this.isAwesome &&
          $driftBlobEquality.equals(
            other.profilePicture,
            this.profilePicture,
          ) &&
          other.creationTime == this.creationTime);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<RowId> id;
  final Value<String> name;
  final Value<bool> isAwesome;
  final Value<Uint8List> profilePicture;
  final Value<DateTime> creationTime;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.isAwesome = const Value.absent(),
    this.profilePicture = const Value.absent(),
    this.creationTime = const Value.absent(),
  });
  UsersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.isAwesome = const Value.absent(),
    required Uint8List profilePicture,
    this.creationTime = const Value.absent(),
  }) : name = Value(name),
       profilePicture = Value(profilePicture);
  static Insertable<User> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<bool>? isAwesome,
    Expression<Uint8List>? profilePicture,
    Expression<DateTime>? creationTime,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (isAwesome != null) 'is_awesome': isAwesome,
      if (profilePicture != null) 'profile_picture': profilePicture,
      if (creationTime != null) 'creation_time': creationTime,
    });
  }

  UsersCompanion copyWith({
    Value<RowId>? id,
    Value<String>? name,
    Value<bool>? isAwesome,
    Value<Uint8List>? profilePicture,
    Value<DateTime>? creationTime,
  }) {
    return UsersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      isAwesome: isAwesome ?? this.isAwesome,
      profilePicture: profilePicture ?? this.profilePicture,
      creationTime: creationTime ?? this.creationTime,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(
        $UsersTable.$converterid.toSql(id.value),
        BuiltinDriftType.int,
      );
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value, BuiltinDriftType.text);
    }
    if (isAwesome.present) {
      map['is_awesome'] = Variable<bool>(
        isAwesome.value,
        BuiltinDriftType.bool,
      );
    }
    if (profilePicture.present) {
      map['profile_picture'] = Variable<Uint8List>(
        profilePicture.value,
        BuiltinDriftType.byteArray,
      );
    }
    if (creationTime.present) {
      map['creation_time'] = Variable<DateTime>(
        creationTime.value,
        BuiltinDriftType.dateTime,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isAwesome: $isAwesome, ')
          ..write('profilePicture: $profilePicture, ')
          ..write('creationTime: $creationTime')
          ..write(')'))
        .toString();
  }
}

class $SharedTodosTable extends SharedTodos
    with ResultSet<SharedTodo, $SharedTodosTable>
    implements GeneratedTable<SharedTodo, $SharedTodosTable> {
  @override
  final String? alias;
  $SharedTodosTable([this.alias]);
  @override
  late final TableColumn<int> todo = TableColumn<int>(
    name: 'todo',
    sqlType: BuiltinDriftType.int,
    requiredDuringInsert: true,
    constraints: () => [const ColumnNotNullConstraint()],
  )..owningResultSet = this;
  @override
  late final TableColumn<int> user = TableColumn<int>(
    name: 'user',
    sqlType: BuiltinDriftType.int,
    requiredDuringInsert: true,
    constraints: () => [const ColumnNotNullConstraint()],
  )..owningResultSet = this;
  @override
  List<TableColumn> get columns => [todo, user];
  @override
  String get entityName => $name;
  static const String $name = 'shared_todos';
  @override
  $SharedTodosTable asSelfType() => this;

  @override
  Set<TableColumn> get primaryKey => {todo, user};
  @override
  SharedTodo? Function(RawRow) createMapperFromPositions(
    DriftDialect dialect,
    List<ColumnPosition> positions,
  ) {
    final pos$todo = positions[0].index;
    final type$0 = BuiltinDriftType.int.resolveIn(dialect);
    final pos$user = positions[1].index;
    return (RawRow row) {
      // Not part of row if non-nullable column "todo" is missing
      if (row[pos$todo] == null) {
        return null;
      }
      return SharedTodo(
        todo: type$0.dartValue(row[pos$todo]!),
        user: type$0.dartValue(row[pos$user]!),
      );
    };
  }

  @override
  $SharedTodosTable withAlias(String alias) {
    return $SharedTodosTable(alias);
  }
}

class SharedTodo extends LegacyDataClass implements Insertable<SharedTodo> {
  final int todo;
  final int user;
  const SharedTodo({required this.todo, required this.user});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['todo'] = Variable<int>(todo, BuiltinDriftType.int);
    map['user'] = Variable<int>(user, BuiltinDriftType.int);
    return map;
  }

  SharedTodosCompanion toCompanion(bool nullToAbsent) {
    return SharedTodosCompanion(todo: Value(todo), user: Value(user));
  }

  factory SharedTodo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SharedTodo(
      todo: serializer.fromJson<int>(json['todo']),
      user: serializer.fromJson<int>(json['user']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'todo': serializer.toJson<int>(todo),
      'user': serializer.toJson<int>(user),
    };
  }

  SharedTodo copyWith({int? todo, int? user}) =>
      SharedTodo(todo: todo ?? this.todo, user: user ?? this.user);
  SharedTodo copyWithCompanion(SharedTodosCompanion data) {
    return SharedTodo(
      todo: data.todo.present ? data.todo.value : this.todo,
      user: data.user.present ? data.user.value : this.user,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SharedTodo(')
          ..write('todo: $todo, ')
          ..write('user: $user')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(todo, user);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SharedTodo &&
          other.todo == this.todo &&
          other.user == this.user);
}

class SharedTodosCompanion extends UpdateCompanion<SharedTodo> {
  final Value<int> todo;
  final Value<int> user;
  final Value<int> rowid;
  const SharedTodosCompanion({
    this.todo = const Value.absent(),
    this.user = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SharedTodosCompanion.insert({
    required int todo,
    required int user,
    this.rowid = const Value.absent(),
  }) : todo = Value(todo),
       user = Value(user);
  static Insertable<SharedTodo> custom({
    Expression<int>? todo,
    Expression<int>? user,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (todo != null) 'todo': todo,
      if (user != null) 'user': user,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SharedTodosCompanion copyWith({
    Value<int>? todo,
    Value<int>? user,
    Value<int>? rowid,
  }) {
    return SharedTodosCompanion(
      todo: todo ?? this.todo,
      user: user ?? this.user,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (todo.present) {
      map['todo'] = Variable<int>(todo.value, BuiltinDriftType.int);
    }
    if (user.present) {
      map['user'] = Variable<int>(user.value, BuiltinDriftType.int);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value, BuiltinDriftType.int);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SharedTodosCompanion(')
          ..write('todo: $todo, ')
          ..write('user: $user, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TableWithEveryColumnTypeTable extends TableWithEveryColumnType
    with ResultSet<TableWithEveryColumnTypeData, $TableWithEveryColumnTypeTable>
    implements
        GeneratedTable<
          TableWithEveryColumnTypeData,
          $TableWithEveryColumnTypeTable
        > {
  @override
  final String? alias;
  $TableWithEveryColumnTypeTable([this.alias]);
  @override
  late final TableColumnWithTypeConverter<RowId, int> id =
      TableColumn<int>(
          name: 'id',
          sqlType: BuiltinDriftType.int,
          requiredDuringInsert: false,
          constraints: () => [
            const ColumnPrimaryKeyConstraint(isAutoIncrementing: true),
            const ColumnNotNullConstraint(),
          ],
        ).withConverter<RowId>($TableWithEveryColumnTypeTable.$converterid)
        ..owningResultSet = this;
  @override
  late final TableColumn<bool> aBool = TableColumn<bool>(
    name: 'a_bool',
    sqlType: BuiltinDriftType.bool,
    requiredDuringInsert: false,
  )..owningResultSet = this;
  @override
  late final TableColumn<DateTime> aDateTime = TableColumn<DateTime>(
    name: 'a_date_time',
    sqlType: BuiltinDriftType.dateTime,
    requiredDuringInsert: false,
  )..owningResultSet = this;
  @override
  late final TableColumn<String> aText = TableColumn<String>(
    name: 'a_text',
    sqlType: BuiltinDriftType.text,
    requiredDuringInsert: false,
  )..owningResultSet = this;
  @override
  late final TableColumn<int> anInt = TableColumn<int>(
    name: 'an_int',
    sqlType: BuiltinDriftType.int,
    requiredDuringInsert: false,
  )..owningResultSet = this;
  @override
  late final TableColumn<BigInt> anInt64 = TableColumn<BigInt>(
    name: 'an_int64',
    sqlType: BuiltinDriftType.int64,
    requiredDuringInsert: false,
  )..owningResultSet = this;
  @override
  late final TableColumn<double> aReal = TableColumn<double>(
    name: 'a_real',
    sqlType: BuiltinDriftType.double,
    requiredDuringInsert: false,
  )..owningResultSet = this;
  @override
  late final TableColumn<Uint8List> aBlob = TableColumn<Uint8List>(
    name: 'a_blob',
    sqlType: BuiltinDriftType.byteArray,
    requiredDuringInsert: false,
  )..owningResultSet = this;
  @override
  late final TableColumnWithTypeConverter<TodoStatus?, int> anIntEnum =
      TableColumn<int>(
          name: 'an_int_enum',
          sqlType: BuiltinDriftType.int,
          requiredDuringInsert: false,
        ).withConverter<TodoStatus?>(
          $TableWithEveryColumnTypeTable.$converteranIntEnumn,
        )
        ..owningResultSet = this;
  @override
  late final TableColumnWithTypeConverter<MyCustomObject?, String>
  aTextWithConverter =
      TableColumn<String>(
          name: 'insert',
          sqlType: BuiltinDriftType.text,
          requiredDuringInsert: false,
        ).withConverter<MyCustomObject?>(
          $TableWithEveryColumnTypeTable.$converteraTextWithConvertern,
        )
        ..owningResultSet = this;
  @override
  List<TableColumn> get columns => [
    id,
    aBool,
    aDateTime,
    aText,
    anInt,
    anInt64,
    aReal,
    aBlob,
    anIntEnum,
    aTextWithConverter,
  ];
  @override
  String get entityName => $name;
  static const String $name = 'table_with_every_column_type';
  @override
  $TableWithEveryColumnTypeTable asSelfType() => this;

  @override
  TableWithEveryColumnTypeData? Function(RawRow) createMapperFromPositions(
    DriftDialect dialect,
    List<ColumnPosition> positions,
  ) {
    final pos$id = positions[0].index;
    final type$0 = BuiltinDriftType.int.resolveIn(dialect);
    final pos$aBool = positions[1].index;
    final type$1 = BuiltinDriftType.bool.resolveIn(dialect);
    final pos$aDateTime = positions[2].index;
    final type$2 = BuiltinDriftType.dateTime.resolveIn(dialect);
    final pos$aText = positions[3].index;
    final type$3 = BuiltinDriftType.text.resolveIn(dialect);
    final pos$anInt = positions[4].index;
    final pos$anInt64 = positions[5].index;
    final type$4 = BuiltinDriftType.int64.resolveIn(dialect);
    final pos$aReal = positions[6].index;
    final type$5 = BuiltinDriftType.double.resolveIn(dialect);
    final pos$aBlob = positions[7].index;
    final type$6 = BuiltinDriftType.byteArray.resolveIn(dialect);
    final pos$anIntEnum = positions[8].index;
    final pos$aTextWithConverter = positions[9].index;
    return (RawRow row) {
      // Not part of row if non-nullable column "id" is missing
      if (row[pos$id] == null) {
        return null;
      }
      return TableWithEveryColumnTypeData(
        id: $TableWithEveryColumnTypeTable.$converterid.fromSql(
          type$0.dartValue(row[pos$id]!),
        ),
        aBool: type$1.nullableDartValue(row[pos$aBool]),
        aDateTime: type$2.nullableDartValue(row[pos$aDateTime]),
        aText: type$3.nullableDartValue(row[pos$aText]),
        anInt: type$0.nullableDartValue(row[pos$anInt]),
        anInt64: type$4.nullableDartValue(row[pos$anInt64]),
        aReal: type$5.nullableDartValue(row[pos$aReal]),
        aBlob: type$6.nullableDartValue(row[pos$aBlob]),
        anIntEnum: $TableWithEveryColumnTypeTable.$converteranIntEnumn.fromSql(
          type$0.nullableDartValue(row[pos$anIntEnum]),
        ),
        aTextWithConverter: $TableWithEveryColumnTypeTable
            .$converteraTextWithConvertern
            .fromSql(type$3.nullableDartValue(row[pos$aTextWithConverter])),
      );
    };
  }

  @override
  $TableWithEveryColumnTypeTable withAlias(String alias) {
    return $TableWithEveryColumnTypeTable(alias);
  }

  static JsonTypeConverter2<RowId, int, int> $converterid =
      TypeConverter.extensionType<RowId, int>();
  static JsonTypeConverter2<TodoStatus, int, int> $converteranIntEnum =
      const EnumIndexConverter<TodoStatus>(TodoStatus.values);
  static JsonTypeConverter2<TodoStatus?, int?, int?> $converteranIntEnumn =
      JsonTypeConverter2.asNullable($converteranIntEnum);
  static JsonTypeConverter2<MyCustomObject, String, Map<String, Object?>>
  $converteraTextWithConverter = const CustomJsonConverter();
  static JsonTypeConverter2<MyCustomObject?, String?, Map<String, Object?>?>
  $converteraTextWithConvertern = JsonTypeConverter2.asNullable(
    $converteraTextWithConverter,
  );
}

class TableWithEveryColumnTypeData extends LegacyDataClass
    implements Insertable<TableWithEveryColumnTypeData> {
  final RowId id;
  final bool? aBool;
  final DateTime? aDateTime;
  final String? aText;
  final int? anInt;
  final BigInt? anInt64;
  final double? aReal;
  final Uint8List? aBlob;
  final TodoStatus? anIntEnum;
  final MyCustomObject? aTextWithConverter;
  const TableWithEveryColumnTypeData({
    required this.id,
    this.aBool,
    this.aDateTime,
    this.aText,
    this.anInt,
    this.anInt64,
    this.aReal,
    this.aBlob,
    this.anIntEnum,
    this.aTextWithConverter,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['id'] = Variable<int>(
        $TableWithEveryColumnTypeTable.$converterid.toSql(id),
        BuiltinDriftType.int,
      );
    }
    if (!nullToAbsent || aBool != null) {
      map['a_bool'] = Variable<bool>(aBool, BuiltinDriftType.bool);
    }
    if (!nullToAbsent || aDateTime != null) {
      map['a_date_time'] = Variable<DateTime>(
        aDateTime,
        BuiltinDriftType.dateTime,
      );
    }
    if (!nullToAbsent || aText != null) {
      map['a_text'] = Variable<String>(aText, BuiltinDriftType.text);
    }
    if (!nullToAbsent || anInt != null) {
      map['an_int'] = Variable<int>(anInt, BuiltinDriftType.int);
    }
    if (!nullToAbsent || anInt64 != null) {
      map['an_int64'] = Variable<BigInt>(anInt64, BuiltinDriftType.int64);
    }
    if (!nullToAbsent || aReal != null) {
      map['a_real'] = Variable<double>(aReal, BuiltinDriftType.double);
    }
    if (!nullToAbsent || aBlob != null) {
      map['a_blob'] = Variable<Uint8List>(aBlob, BuiltinDriftType.byteArray);
    }
    if (!nullToAbsent || anIntEnum != null) {
      map['an_int_enum'] = Variable<int>(
        $TableWithEveryColumnTypeTable.$converteranIntEnumn.toSql(anIntEnum),
        BuiltinDriftType.int,
      );
    }
    if (!nullToAbsent || aTextWithConverter != null) {
      map['insert'] = Variable<String>(
        $TableWithEveryColumnTypeTable.$converteraTextWithConvertern.toSql(
          aTextWithConverter,
        ),
        BuiltinDriftType.text,
      );
    }
    return map;
  }

  TableWithEveryColumnTypeCompanion toCompanion(bool nullToAbsent) {
    return TableWithEveryColumnTypeCompanion(
      id: Value(id),
      aBool: aBool == null && nullToAbsent
          ? const Value.absent()
          : Value(aBool),
      aDateTime: aDateTime == null && nullToAbsent
          ? const Value.absent()
          : Value(aDateTime),
      aText: aText == null && nullToAbsent
          ? const Value.absent()
          : Value(aText),
      anInt: anInt == null && nullToAbsent
          ? const Value.absent()
          : Value(anInt),
      anInt64: anInt64 == null && nullToAbsent
          ? const Value.absent()
          : Value(anInt64),
      aReal: aReal == null && nullToAbsent
          ? const Value.absent()
          : Value(aReal),
      aBlob: aBlob == null && nullToAbsent
          ? const Value.absent()
          : Value(aBlob),
      anIntEnum: anIntEnum == null && nullToAbsent
          ? const Value.absent()
          : Value(anIntEnum),
      aTextWithConverter: aTextWithConverter == null && nullToAbsent
          ? const Value.absent()
          : Value(aTextWithConverter),
    );
  }

  factory TableWithEveryColumnTypeData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TableWithEveryColumnTypeData(
      id: $TableWithEveryColumnTypeTable.$converterid.fromJson(
        serializer.fromJson<int>(json['id']),
      ),
      aBool: serializer.fromJson<bool?>(json['aBool']),
      aDateTime: serializer.fromJson<DateTime?>(json['aDateTime']),
      aText: serializer.fromJson<String?>(json['aText']),
      anInt: serializer.fromJson<int?>(json['anInt']),
      anInt64: serializer.fromJson<BigInt?>(json['anInt64']),
      aReal: serializer.fromJson<double?>(json['aReal']),
      aBlob: serializer.fromJson<Uint8List?>(json['aBlob']),
      anIntEnum: $TableWithEveryColumnTypeTable.$converteranIntEnumn.fromJson(
        serializer.fromJson<int?>(json['anIntEnum']),
      ),
      aTextWithConverter: $TableWithEveryColumnTypeTable
          .$converteraTextWithConvertern
          .fromJson(
            serializer.fromJson<Map<String, Object?>?>(
              json['aTextWithConverter'],
            ),
          ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(
        $TableWithEveryColumnTypeTable.$converterid.toJson(id),
      ),
      'aBool': serializer.toJson<bool?>(aBool),
      'aDateTime': serializer.toJson<DateTime?>(aDateTime),
      'aText': serializer.toJson<String?>(aText),
      'anInt': serializer.toJson<int?>(anInt),
      'anInt64': serializer.toJson<BigInt?>(anInt64),
      'aReal': serializer.toJson<double?>(aReal),
      'aBlob': serializer.toJson<Uint8List?>(aBlob),
      'anIntEnum': serializer.toJson<int?>(
        $TableWithEveryColumnTypeTable.$converteranIntEnumn.toJson(anIntEnum),
      ),
      'aTextWithConverter': serializer.toJson<Map<String, Object?>?>(
        $TableWithEveryColumnTypeTable.$converteraTextWithConvertern.toJson(
          aTextWithConverter,
        ),
      ),
    };
  }

  TableWithEveryColumnTypeData copyWith({
    RowId? id,
    Value<bool?> aBool = const Value.absent(),
    Value<DateTime?> aDateTime = const Value.absent(),
    Value<String?> aText = const Value.absent(),
    Value<int?> anInt = const Value.absent(),
    Value<BigInt?> anInt64 = const Value.absent(),
    Value<double?> aReal = const Value.absent(),
    Value<Uint8List?> aBlob = const Value.absent(),
    Value<TodoStatus?> anIntEnum = const Value.absent(),
    Value<MyCustomObject?> aTextWithConverter = const Value.absent(),
  }) => TableWithEveryColumnTypeData(
    id: id ?? this.id,
    aBool: aBool.present ? aBool.value : this.aBool,
    aDateTime: aDateTime.present ? aDateTime.value : this.aDateTime,
    aText: aText.present ? aText.value : this.aText,
    anInt: anInt.present ? anInt.value : this.anInt,
    anInt64: anInt64.present ? anInt64.value : this.anInt64,
    aReal: aReal.present ? aReal.value : this.aReal,
    aBlob: aBlob.present ? aBlob.value : this.aBlob,
    anIntEnum: anIntEnum.present ? anIntEnum.value : this.anIntEnum,
    aTextWithConverter: aTextWithConverter.present
        ? aTextWithConverter.value
        : this.aTextWithConverter,
  );
  TableWithEveryColumnTypeData copyWithCompanion(
    TableWithEveryColumnTypeCompanion data,
  ) {
    return TableWithEveryColumnTypeData(
      id: data.id.present ? data.id.value : this.id,
      aBool: data.aBool.present ? data.aBool.value : this.aBool,
      aDateTime: data.aDateTime.present ? data.aDateTime.value : this.aDateTime,
      aText: data.aText.present ? data.aText.value : this.aText,
      anInt: data.anInt.present ? data.anInt.value : this.anInt,
      anInt64: data.anInt64.present ? data.anInt64.value : this.anInt64,
      aReal: data.aReal.present ? data.aReal.value : this.aReal,
      aBlob: data.aBlob.present ? data.aBlob.value : this.aBlob,
      anIntEnum: data.anIntEnum.present ? data.anIntEnum.value : this.anIntEnum,
      aTextWithConverter: data.aTextWithConverter.present
          ? data.aTextWithConverter.value
          : this.aTextWithConverter,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TableWithEveryColumnTypeData(')
          ..write('id: $id, ')
          ..write('aBool: $aBool, ')
          ..write('aDateTime: $aDateTime, ')
          ..write('aText: $aText, ')
          ..write('anInt: $anInt, ')
          ..write('anInt64: $anInt64, ')
          ..write('aReal: $aReal, ')
          ..write('aBlob: $aBlob, ')
          ..write('anIntEnum: $anIntEnum, ')
          ..write('aTextWithConverter: $aTextWithConverter')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    aBool,
    aDateTime,
    aText,
    anInt,
    anInt64,
    aReal,
    $driftBlobEquality.hash(aBlob),
    anIntEnum,
    aTextWithConverter,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TableWithEveryColumnTypeData &&
          other.id == this.id &&
          other.aBool == this.aBool &&
          other.aDateTime == this.aDateTime &&
          other.aText == this.aText &&
          other.anInt == this.anInt &&
          other.anInt64 == this.anInt64 &&
          other.aReal == this.aReal &&
          $driftBlobEquality.equals(other.aBlob, this.aBlob) &&
          other.anIntEnum == this.anIntEnum &&
          other.aTextWithConverter == this.aTextWithConverter);
}

class TableWithEveryColumnTypeCompanion
    extends UpdateCompanion<TableWithEveryColumnTypeData> {
  final Value<RowId> id;
  final Value<bool?> aBool;
  final Value<DateTime?> aDateTime;
  final Value<String?> aText;
  final Value<int?> anInt;
  final Value<BigInt?> anInt64;
  final Value<double?> aReal;
  final Value<Uint8List?> aBlob;
  final Value<TodoStatus?> anIntEnum;
  final Value<MyCustomObject?> aTextWithConverter;
  const TableWithEveryColumnTypeCompanion({
    this.id = const Value.absent(),
    this.aBool = const Value.absent(),
    this.aDateTime = const Value.absent(),
    this.aText = const Value.absent(),
    this.anInt = const Value.absent(),
    this.anInt64 = const Value.absent(),
    this.aReal = const Value.absent(),
    this.aBlob = const Value.absent(),
    this.anIntEnum = const Value.absent(),
    this.aTextWithConverter = const Value.absent(),
  });
  TableWithEveryColumnTypeCompanion.insert({
    this.id = const Value.absent(),
    this.aBool = const Value.absent(),
    this.aDateTime = const Value.absent(),
    this.aText = const Value.absent(),
    this.anInt = const Value.absent(),
    this.anInt64 = const Value.absent(),
    this.aReal = const Value.absent(),
    this.aBlob = const Value.absent(),
    this.anIntEnum = const Value.absent(),
    this.aTextWithConverter = const Value.absent(),
  });
  static Insertable<TableWithEveryColumnTypeData> custom({
    Expression<int>? id,
    Expression<bool>? aBool,
    Expression<DateTime>? aDateTime,
    Expression<String>? aText,
    Expression<int>? anInt,
    Expression<BigInt>? anInt64,
    Expression<double>? aReal,
    Expression<Uint8List>? aBlob,
    Expression<int>? anIntEnum,
    Expression<String>? aTextWithConverter,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (aBool != null) 'a_bool': aBool,
      if (aDateTime != null) 'a_date_time': aDateTime,
      if (aText != null) 'a_text': aText,
      if (anInt != null) 'an_int': anInt,
      if (anInt64 != null) 'an_int64': anInt64,
      if (aReal != null) 'a_real': aReal,
      if (aBlob != null) 'a_blob': aBlob,
      if (anIntEnum != null) 'an_int_enum': anIntEnum,
      if (aTextWithConverter != null) 'insert': aTextWithConverter,
    });
  }

  TableWithEveryColumnTypeCompanion copyWith({
    Value<RowId>? id,
    Value<bool?>? aBool,
    Value<DateTime?>? aDateTime,
    Value<String?>? aText,
    Value<int?>? anInt,
    Value<BigInt?>? anInt64,
    Value<double?>? aReal,
    Value<Uint8List?>? aBlob,
    Value<TodoStatus?>? anIntEnum,
    Value<MyCustomObject?>? aTextWithConverter,
  }) {
    return TableWithEveryColumnTypeCompanion(
      id: id ?? this.id,
      aBool: aBool ?? this.aBool,
      aDateTime: aDateTime ?? this.aDateTime,
      aText: aText ?? this.aText,
      anInt: anInt ?? this.anInt,
      anInt64: anInt64 ?? this.anInt64,
      aReal: aReal ?? this.aReal,
      aBlob: aBlob ?? this.aBlob,
      anIntEnum: anIntEnum ?? this.anIntEnum,
      aTextWithConverter: aTextWithConverter ?? this.aTextWithConverter,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(
        $TableWithEveryColumnTypeTable.$converterid.toSql(id.value),
        BuiltinDriftType.int,
      );
    }
    if (aBool.present) {
      map['a_bool'] = Variable<bool>(aBool.value, BuiltinDriftType.bool);
    }
    if (aDateTime.present) {
      map['a_date_time'] = Variable<DateTime>(
        aDateTime.value,
        BuiltinDriftType.dateTime,
      );
    }
    if (aText.present) {
      map['a_text'] = Variable<String>(aText.value, BuiltinDriftType.text);
    }
    if (anInt.present) {
      map['an_int'] = Variable<int>(anInt.value, BuiltinDriftType.int);
    }
    if (anInt64.present) {
      map['an_int64'] = Variable<BigInt>(anInt64.value, BuiltinDriftType.int64);
    }
    if (aReal.present) {
      map['a_real'] = Variable<double>(aReal.value, BuiltinDriftType.double);
    }
    if (aBlob.present) {
      map['a_blob'] = Variable<Uint8List>(
        aBlob.value,
        BuiltinDriftType.byteArray,
      );
    }
    if (anIntEnum.present) {
      map['an_int_enum'] = Variable<int>(
        $TableWithEveryColumnTypeTable.$converteranIntEnumn.toSql(
          anIntEnum.value,
        ),
        BuiltinDriftType.int,
      );
    }
    if (aTextWithConverter.present) {
      map['insert'] = Variable<String>(
        $TableWithEveryColumnTypeTable.$converteraTextWithConvertern.toSql(
          aTextWithConverter.value,
        ),
        BuiltinDriftType.text,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TableWithEveryColumnTypeCompanion(')
          ..write('id: $id, ')
          ..write('aBool: $aBool, ')
          ..write('aDateTime: $aDateTime, ')
          ..write('aText: $aText, ')
          ..write('anInt: $anInt, ')
          ..write('anInt64: $anInt64, ')
          ..write('aReal: $aReal, ')
          ..write('aBlob: $aBlob, ')
          ..write('anIntEnum: $anIntEnum, ')
          ..write('aTextWithConverter: $aTextWithConverter')
          ..write(')'))
        .toString();
  }
}

class $TableWithoutPKTable extends TableWithoutPK
    with ResultSet<CustomRowClass, $TableWithoutPKTable>
    implements GeneratedTable<CustomRowClass, $TableWithoutPKTable> {
  @override
  final String? alias;
  $TableWithoutPKTable([this.alias]);
  @override
  late final TableColumn<int> notReallyAnId = TableColumn<int>(
    name: 'not_really_an_id',
    sqlType: BuiltinDriftType.int,
    requiredDuringInsert: true,
    constraints: () => [const ColumnNotNullConstraint()],
  )..owningResultSet = this;
  @override
  late final TableColumn<double> someFloat = TableColumn<double>(
    name: 'some_float',
    sqlType: BuiltinDriftType.double,
    requiredDuringInsert: true,
    constraints: () => [const ColumnNotNullConstraint()],
  )..owningResultSet = this;
  @override
  late final TableColumn<BigInt> webSafeInt = TableColumn<BigInt>(
    name: 'web_safe_int',
    sqlType: BuiltinDriftType.int64,
    requiredDuringInsert: false,
  )..owningResultSet = this;
  @override
  late final TableColumnWithTypeConverter<MyCustomObject, String> custom =
      TableColumn<String>(
          name: 'custom',
          sqlType: BuiltinDriftType.text,
          requiredDuringInsert: false,
          constraints: () => [const ColumnNotNullConstraint()],
          clientDefault: _uuid.v4,
        ).withConverter<MyCustomObject>($TableWithoutPKTable.$convertercustom)
        ..owningResultSet = this;
  @override
  List<TableColumn> get columns => [
    notReallyAnId,
    someFloat,
    webSafeInt,
    custom,
  ];
  @override
  String get entityName => $name;
  static const String $name = 'table_without_p_k';
  @override
  $TableWithoutPKTable asSelfType() => this;

  @override
  CustomRowClass? Function(RawRow) createMapperFromPositions(
    DriftDialect dialect,
    List<ColumnPosition> positions,
  ) {
    final pos$notReallyAnId = positions[0].index;
    final type$0 = BuiltinDriftType.int.resolveIn(dialect);
    final pos$someFloat = positions[1].index;
    final type$1 = BuiltinDriftType.double.resolveIn(dialect);
    final pos$webSafeInt = positions[2].index;
    final type$2 = BuiltinDriftType.int64.resolveIn(dialect);
    final pos$custom = positions[3].index;
    final type$3 = BuiltinDriftType.text.resolveIn(dialect);
    return (RawRow row) {
      // Not part of row if non-nullable column "notReallyAnId" is missing
      if (row[pos$notReallyAnId] == null) {
        return null;
      }
      return CustomRowClass.map(
        type$0.dartValue(row[pos$notReallyAnId]!),
        type$1.dartValue(row[pos$someFloat]!),
        custom: $TableWithoutPKTable.$convertercustom.fromSql(
          type$3.dartValue(row[pos$custom]!),
        ),
        webSafeInt: type$2.nullableDartValue(row[pos$webSafeInt]),
      );
    };
  }

  @override
  $TableWithoutPKTable withAlias(String alias) {
    return $TableWithoutPKTable(alias);
  }

  static TypeConverter<MyCustomObject, String> $convertercustom =
      const CustomConverter();
}

class TableWithoutPKCompanion extends UpdateCompanion<CustomRowClass> {
  final Value<int> notReallyAnId;
  final Value<double> someFloat;
  final Value<BigInt?> webSafeInt;
  final Value<MyCustomObject> custom;
  final Value<int> rowid;
  const TableWithoutPKCompanion({
    this.notReallyAnId = const Value.absent(),
    this.someFloat = const Value.absent(),
    this.webSafeInt = const Value.absent(),
    this.custom = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TableWithoutPKCompanion.insert({
    required int notReallyAnId,
    required double someFloat,
    this.webSafeInt = const Value.absent(),
    this.custom = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : notReallyAnId = Value(notReallyAnId),
       someFloat = Value(someFloat);
  static Insertable<CustomRowClass> createCustom({
    Expression<int>? notReallyAnId,
    Expression<double>? someFloat,
    Expression<BigInt>? webSafeInt,
    Expression<String>? custom,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (notReallyAnId != null) 'not_really_an_id': notReallyAnId,
      if (someFloat != null) 'some_float': someFloat,
      if (webSafeInt != null) 'web_safe_int': webSafeInt,
      if (custom != null) 'custom': custom,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TableWithoutPKCompanion copyWith({
    Value<int>? notReallyAnId,
    Value<double>? someFloat,
    Value<BigInt?>? webSafeInt,
    Value<MyCustomObject>? custom,
    Value<int>? rowid,
  }) {
    return TableWithoutPKCompanion(
      notReallyAnId: notReallyAnId ?? this.notReallyAnId,
      someFloat: someFloat ?? this.someFloat,
      webSafeInt: webSafeInt ?? this.webSafeInt,
      custom: custom ?? this.custom,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (notReallyAnId.present) {
      map['not_really_an_id'] = Variable<int>(
        notReallyAnId.value,
        BuiltinDriftType.int,
      );
    }
    if (someFloat.present) {
      map['some_float'] = Variable<double>(
        someFloat.value,
        BuiltinDriftType.double,
      );
    }
    if (webSafeInt.present) {
      map['web_safe_int'] = Variable<BigInt>(
        webSafeInt.value,
        BuiltinDriftType.int64,
      );
    }
    if (custom.present) {
      map['custom'] = Variable<String>(
        $TableWithoutPKTable.$convertercustom.toSql(custom.value),
        BuiltinDriftType.text,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value, BuiltinDriftType.int);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TableWithoutPKCompanion(')
          ..write('notReallyAnId: $notReallyAnId, ')
          ..write('someFloat: $someFloat, ')
          ..write('webSafeInt: $webSafeInt, ')
          ..write('custom: $custom, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class _$CustomRowClassInsertable implements Insertable<CustomRowClass> {
  CustomRowClass _object;
  _$CustomRowClassInsertable(this._object);
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    return TableWithoutPKCompanion(
      notReallyAnId: Value(_object.notReallyAnId),
      someFloat: Value(_object.someFloat),
      webSafeInt: Value(_object.webSafeInt),
      custom: Value(_object.custom),
    ).toColumns(false);
  }
}

extension CustomRowClassToInsertable on CustomRowClass {
  _$CustomRowClassInsertable toInsertable() {
    return _$CustomRowClassInsertable(this);
  }
}

class $PureDefaultsTable extends PureDefaults
    with ResultSet<PureDefault, $PureDefaultsTable>
    implements GeneratedTable<PureDefault, $PureDefaultsTable> {
  @override
  final String? alias;
  $PureDefaultsTable([this.alias]);
  @override
  late final TableColumnWithTypeConverter<MyCustomObject?, String> txt =
      TableColumn<String>(
          name: 'insert',
          sqlType: BuiltinDriftType.text,
          requiredDuringInsert: false,
        ).withConverter<MyCustomObject?>($PureDefaultsTable.$convertertxtn)
        ..owningResultSet = this;
  @override
  List<TableColumn> get columns => [txt];
  @override
  String get entityName => $name;
  static const String $name = 'pure_defaults';
  @override
  $PureDefaultsTable asSelfType() => this;

  @override
  Set<TableColumn> get primaryKey => {txt};
  @override
  PureDefault? Function(RawRow) createMapperFromPositions(
    DriftDialect dialect,
    List<ColumnPosition> positions,
  ) {
    final pos$txt = positions[0].index;
    final type$0 = BuiltinDriftType.text.resolveIn(dialect);
    return (RawRow row) {
      return PureDefault(
        txt: $PureDefaultsTable.$convertertxtn.fromSql(
          type$0.nullableDartValue(row[pos$txt]),
        ),
      );
    };
  }

  @override
  $PureDefaultsTable withAlias(String alias) {
    return $PureDefaultsTable(alias);
  }

  static JsonTypeConverter2<MyCustomObject, String, Map<String, Object?>>
  $convertertxt = const CustomJsonConverter();
  static JsonTypeConverter2<MyCustomObject?, String?, Map<String, Object?>?>
  $convertertxtn = JsonTypeConverter2.asNullable($convertertxt);
}

class PureDefault extends LegacyDataClass implements Insertable<PureDefault> {
  final MyCustomObject? txt;
  const PureDefault({this.txt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || txt != null) {
      map['insert'] = Variable<String>(
        $PureDefaultsTable.$convertertxtn.toSql(txt),
        BuiltinDriftType.text,
      );
    }
    return map;
  }

  PureDefaultsCompanion toCompanion(bool nullToAbsent) {
    return PureDefaultsCompanion(
      txt: txt == null && nullToAbsent ? const Value.absent() : Value(txt),
    );
  }

  factory PureDefault.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PureDefault(
      txt: $PureDefaultsTable.$convertertxtn.fromJson(
        serializer.fromJson<Map<String, Object?>?>(json['txt']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'txt': serializer.toJson<Map<String, Object?>?>(
        $PureDefaultsTable.$convertertxtn.toJson(txt),
      ),
    };
  }

  PureDefault copyWith({Value<MyCustomObject?> txt = const Value.absent()}) =>
      PureDefault(txt: txt.present ? txt.value : this.txt);
  PureDefault copyWithCompanion(PureDefaultsCompanion data) {
    return PureDefault(txt: data.txt.present ? data.txt.value : this.txt);
  }

  @override
  String toString() {
    return (StringBuffer('PureDefault(')
          ..write('txt: $txt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => txt.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is PureDefault && other.txt == this.txt);
}

class PureDefaultsCompanion extends UpdateCompanion<PureDefault> {
  final Value<MyCustomObject?> txt;
  final Value<int> rowid;
  const PureDefaultsCompanion({
    this.txt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PureDefaultsCompanion.insert({
    this.txt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  static Insertable<PureDefault> custom({
    Expression<String>? txt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (txt != null) 'insert': txt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PureDefaultsCompanion copyWith({
    Value<MyCustomObject?>? txt,
    Value<int>? rowid,
  }) {
    return PureDefaultsCompanion(
      txt: txt ?? this.txt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (txt.present) {
      map['insert'] = Variable<String>(
        $PureDefaultsTable.$convertertxtn.toSql(txt.value),
        BuiltinDriftType.text,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value, BuiltinDriftType.int);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PureDefaultsCompanion(')
          ..write('txt: $txt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WithCustomTypeTable extends WithCustomType
    with ResultSet<WithCustomTypeData, $WithCustomTypeTable>
    implements GeneratedTable<WithCustomTypeData, $WithCustomTypeTable> {
  @override
  final String? alias;
  $WithCustomTypeTable([this.alias]);
  @override
  late final TableColumn<UuidValue> id = TableColumn<UuidValue>(
    name: 'id',
    sqlType: uuidType,
    requiredDuringInsert: true,
    constraints: () => [const ColumnNotNullConstraint()],
  )..owningResultSet = this;
  @override
  List<TableColumn> get columns => [id];
  @override
  String get entityName => $name;
  static const String $name = 'with_custom_type';
  @override
  $WithCustomTypeTable asSelfType() => this;

  @override
  WithCustomTypeData? Function(RawRow) createMapperFromPositions(
    DriftDialect dialect,
    List<ColumnPosition> positions,
  ) {
    final pos$id = positions[0].index;
    final type$0 = uuidType.resolveIn(dialect);
    return (RawRow row) {
      // Not part of row if non-nullable column "id" is missing
      if (row[pos$id] == null) {
        return null;
      }
      return WithCustomTypeData(id: type$0.dartValue(row[pos$id]!));
    };
  }

  @override
  $WithCustomTypeTable withAlias(String alias) {
    return $WithCustomTypeTable(alias);
  }
}

class WithCustomTypeData extends LegacyDataClass
    implements Insertable<WithCustomTypeData> {
  final UuidValue id;
  const WithCustomTypeData({required this.id});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<UuidValue>(id, uuidType);
    return map;
  }

  WithCustomTypeCompanion toCompanion(bool nullToAbsent) {
    return WithCustomTypeCompanion(id: Value(id));
  }

  factory WithCustomTypeData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WithCustomTypeData(id: serializer.fromJson<UuidValue>(json['id']));
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'id': serializer.toJson<UuidValue>(id)};
  }

  WithCustomTypeData copyWith({UuidValue? id}) =>
      WithCustomTypeData(id: id ?? this.id);
  WithCustomTypeData copyWithCompanion(WithCustomTypeCompanion data) {
    return WithCustomTypeData(id: data.id.present ? data.id.value : this.id);
  }

  @override
  String toString() {
    return (StringBuffer('WithCustomTypeData(')
          ..write('id: $id')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => id.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WithCustomTypeData && other.id == this.id);
}

class WithCustomTypeCompanion extends UpdateCompanion<WithCustomTypeData> {
  final Value<UuidValue> id;
  final Value<int> rowid;
  const WithCustomTypeCompanion({
    this.id = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WithCustomTypeCompanion.insert({
    required UuidValue id,
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<WithCustomTypeData> custom({
    Expression<UuidValue>? id,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WithCustomTypeCompanion copyWith({Value<UuidValue>? id, Value<int>? rowid}) {
    return WithCustomTypeCompanion(
      id: id ?? this.id,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<UuidValue>(id.value, uuidType);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value, BuiltinDriftType.int);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WithCustomTypeCompanion(')
          ..write('id: $id, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DepartmentTable extends Department
    with ResultSet<DepartmentData, $DepartmentTable>
    implements GeneratedTable<DepartmentData, $DepartmentTable> {
  @override
  final String? alias;
  $DepartmentTable([this.alias]);
  @override
  late final TableColumn<int> id = TableColumn<int>(
    name: 'id',
    sqlType: BuiltinDriftType.int,
    requiredDuringInsert: false,
    constraints: () => [
      const ColumnPrimaryKeyConstraint(isAutoIncrementing: true),
      const ColumnNotNullConstraint(),
    ],
  )..owningResultSet = this;
  @override
  late final TableColumn<String> name = TableColumn<String>(
    name: 'name',
    sqlType: BuiltinDriftType.text,
    requiredDuringInsert: false,
  )..owningResultSet = this;
  @override
  List<TableColumn> get columns => [id, name];
  @override
  String get entityName => $name;
  static const String $name = 'department';
  @override
  $DepartmentTable asSelfType() => this;

  @override
  DepartmentData? Function(RawRow) createMapperFromPositions(
    DriftDialect dialect,
    List<ColumnPosition> positions,
  ) {
    final pos$id = positions[0].index;
    final type$0 = BuiltinDriftType.int.resolveIn(dialect);
    final pos$name = positions[1].index;
    final type$1 = BuiltinDriftType.text.resolveIn(dialect);
    return (RawRow row) {
      // Not part of row if non-nullable column "id" is missing
      if (row[pos$id] == null) {
        return null;
      }
      return DepartmentData(
        id: type$0.dartValue(row[pos$id]!),
        name: type$1.nullableDartValue(row[pos$name]),
      );
    };
  }

  @override
  $DepartmentTable withAlias(String alias) {
    return $DepartmentTable(alias);
  }
}

class DepartmentData extends LegacyDataClass
    implements Insertable<DepartmentData> {
  final int id;
  final String? name;
  const DepartmentData({required this.id, this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id, BuiltinDriftType.int);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name, BuiltinDriftType.text);
    }
    return map;
  }

  DepartmentCompanion toCompanion(bool nullToAbsent) {
    return DepartmentCompanion(
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
    );
  }

  factory DepartmentData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DepartmentData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String?>(name),
    };
  }

  DepartmentData copyWith({
    int? id,
    Value<String?> name = const Value.absent(),
  }) => DepartmentData(
    id: id ?? this.id,
    name: name.present ? name.value : this.name,
  );
  DepartmentData copyWithCompanion(DepartmentCompanion data) {
    return DepartmentData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DepartmentData(')
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
      (other is DepartmentData &&
          other.id == this.id &&
          other.name == this.name);
}

class DepartmentCompanion extends UpdateCompanion<DepartmentData> {
  final Value<int> id;
  final Value<String?> name;
  const DepartmentCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  DepartmentCompanion.insert({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  static Insertable<DepartmentData> custom({
    Expression<int>? id,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  DepartmentCompanion copyWith({Value<int>? id, Value<String?>? name}) {
    return DepartmentCompanion(id: id ?? this.id, name: name ?? this.name);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value, BuiltinDriftType.int);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value, BuiltinDriftType.text);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DepartmentCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class CategoryTodoCountViewData extends LegacyDataClass {
  final RowId categoryId;
  final String? description;
  final int? itemCount;
  const CategoryTodoCountViewData({
    required this.categoryId,
    this.description,
    this.itemCount,
  });
  factory CategoryTodoCountViewData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryTodoCountViewData(
      categoryId: $CategoriesTable.$converterid.fromJson(
        serializer.fromJson<int>(json['categoryId']),
      ),
      description: serializer.fromJson<String?>(json['description']),
      itemCount: serializer.fromJson<int?>(json['itemCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'categoryId': serializer.toJson<int>(
        $CategoriesTable.$converterid.toJson(categoryId),
      ),
      'description': serializer.toJson<String?>(description),
      'itemCount': serializer.toJson<int?>(itemCount),
    };
  }

  CategoryTodoCountViewData copyWith({
    RowId? categoryId,
    Value<String?> description = const Value.absent(),
    Value<int?> itemCount = const Value.absent(),
  }) => CategoryTodoCountViewData(
    categoryId: categoryId ?? this.categoryId,
    description: description.present ? description.value : this.description,
    itemCount: itemCount.present ? itemCount.value : this.itemCount,
  );
  @override
  String toString() {
    return (StringBuffer('CategoryTodoCountViewData(')
          ..write('categoryId: $categoryId, ')
          ..write('description: $description, ')
          ..write('itemCount: $itemCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(categoryId, description, itemCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryTodoCountViewData &&
          other.categoryId == this.categoryId &&
          other.description == this.description &&
          other.itemCount == this.itemCount);
}

class $CategoryTodoCountViewView extends CategoryTodoCountView
    with ResultSet<CategoryTodoCountViewData, $CategoryTodoCountViewView>
    implements
        GeneratedView<CategoryTodoCountViewData, $CategoryTodoCountViewView> {
  @override
  final String? alias;
  $CategoryTodoCountViewView([this.alias]);
  $TodosTableTable get todos => $TodosTableTable().withAlias('t0');
  $CategoriesTable get categories => $CategoriesTable().withAlias('t1');
  @override
  List<SchemaColumn> get columns => [categoryId, description, itemCount];
  @override
  String get entityName => 'category_todo_count_view';
  @override
  Null get sqlDefinition => null;
  @override
  $CategoryTodoCountViewView asSelfType() => this;

  @override
  CategoryTodoCountViewData? Function(RawRow) createMapperFromPositions(
    DriftDialect dialect,
    List<ColumnPosition> positions,
  ) {
    final pos$categoryId = positions[0].index;
    final type$0 = BuiltinDriftType.int.resolveIn(dialect);
    final pos$description = positions[1].index;
    final type$1 = BuiltinDriftType.text.resolveIn(dialect);
    final pos$itemCount = positions[2].index;
    return (RawRow row) {
      // Not part of row if non-nullable column "categoryId" is missing
      if (row[pos$categoryId] == null) {
        return null;
      }
      return CategoryTodoCountViewData(
        categoryId: $CategoriesTable.$converterid.fromSql(
          type$0.dartValue(row[pos$categoryId]!),
        ),
        description: type$1.nullableDartValue(row[pos$description]),
        itemCount: type$0.nullableDartValue(row[pos$itemCount]),
      );
    };
  }

  late final ViewColumnWithTypeConverter<RowId, int> categoryId =
      ViewColumn<int>(
          name: 'category_id',
          sqlType: BuiltinDriftType.int,
          expression: categories.id,
        ).withConverter<RowId>($CategoriesTable.$converterid)
        ..owningResultSet = this;
  late final ViewColumn<String> description = ViewColumn<String>(
    name: 'description',
    sqlType: BuiltinDriftType.text,
    expression: categories.description + const Variable('!'),
  )..owningResultSet = this;
  late final ViewColumn<int> itemCount = ViewColumn<int>(
    name: 'item_count',
    sqlType: BuiltinDriftType.int,
    expression: BaseAggregate(todos.id).count(),
  )..owningResultSet = this;
  @override
  $CategoryTodoCountViewView withAlias(String alias) {
    return $CategoryTodoCountViewView(alias);
  }

  @override
  SelectStatement? get query =>
      (GeneratedView.defineStatementForView(categories)..addColumns(columns))
          .innerJoin(todos, on: todos.category.equalsExp(categories.id))
          .groupBy([categories.id]);
  @override
  Set<String> get readsFrom => const {'todos', 'categories'};
}

class TodoWithCategoryViewData extends LegacyDataClass {
  final String? title;
  final String? description;
  const TodoWithCategoryViewData({this.title, this.description});
  factory TodoWithCategoryViewData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TodoWithCategoryViewData(
      title: serializer.fromJson<String?>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'title': serializer.toJson<String?>(title),
      'description': serializer.toJson<String?>(description),
    };
  }

  TodoWithCategoryViewData copyWith({
    Value<String?> title = const Value.absent(),
    Value<String?> description = const Value.absent(),
  }) => TodoWithCategoryViewData(
    title: title.present ? title.value : this.title,
    description: description.present ? description.value : this.description,
  );
  @override
  String toString() {
    return (StringBuffer('TodoWithCategoryViewData(')
          ..write('title: $title, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(title, description);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TodoWithCategoryViewData &&
          other.title == this.title &&
          other.description == this.description);
}

class $TodoWithCategoryViewView extends TodoWithCategoryView
    with ResultSet<TodoWithCategoryViewData, $TodoWithCategoryViewView>
    implements
        GeneratedView<TodoWithCategoryViewData, $TodoWithCategoryViewView> {
  @override
  final String? alias;
  $TodoWithCategoryViewView([this.alias]);
  $TodosTableTable get todos => $TodosTableTable().withAlias('t0');
  $CategoriesTable get categories => $CategoriesTable().withAlias('t1');
  @override
  List<SchemaColumn> get columns => [title, description];
  @override
  String get entityName => 'todo_with_category_view';
  @override
  Null get sqlDefinition => null;
  @override
  $TodoWithCategoryViewView asSelfType() => this;

  @override
  TodoWithCategoryViewData? Function(RawRow) createMapperFromPositions(
    DriftDialect dialect,
    List<ColumnPosition> positions,
  ) {
    final pos$title = positions[0].index;
    final type$0 = BuiltinDriftType.text.resolveIn(dialect);
    final pos$description = positions[1].index;
    return (RawRow row) {
      return TodoWithCategoryViewData(
        title: type$0.nullableDartValue(row[pos$title]),
        description: type$0.nullableDartValue(row[pos$description]),
      );
    };
  }

  late final ViewColumn<String> title = ViewColumn<String>(
    name: 'title',
    sqlType: BuiltinDriftType.text,
    expression: todos.title,
  )..owningResultSet = this;
  late final ViewColumn<String> description = ViewColumn<String>(
    name: 'desc',
    sqlType: BuiltinDriftType.text,
    expression: categories.description,
  )..owningResultSet = this;
  @override
  $TodoWithCategoryViewView withAlias(String alias) {
    return $TodoWithCategoryViewView(alias);
  }

  @override
  SelectStatement? get query =>
      (GeneratedView.defineStatementForView(todos)..addColumns(columns))
          .innerJoin(categories, on: categories.id.equalsExp(todos.category));
  @override
  Set<String> get readsFrom => const {'todos', 'categories'};
}

abstract base class _$TodoDb extends GeneratedDatabase {
  _$TodoDb(super.implementation);
  $CategoriesTable get categories => $CategoriesTable();
  $TodosTableTable get todosTable => $TodosTableTable();
  $UsersTable get users => $UsersTable();
  $SharedTodosTable get sharedTodos => $SharedTodosTable();
  $TableWithEveryColumnTypeTable get tableWithEveryColumnType =>
      $TableWithEveryColumnTypeTable();
  $TableWithoutPKTable get tableWithoutPK => $TableWithoutPKTable();
  $PureDefaultsTable get pureDefaults => $PureDefaultsTable();
  $WithCustomTypeTable get withCustomType => $WithCustomTypeTable();
  $DepartmentTable get department => $DepartmentTable();
  $CategoryTodoCountViewView get categoryTodoCountView =>
      $CategoryTodoCountViewView();
  $TodoWithCategoryViewView get todoWithCategoryView =>
      $TodoWithCategoryViewView();
  Index get categoriesDesc => _$categoriesDesc;
  @override
  Map<KnownSqlDialect, Object> get dialectOptions => {
    KnownSqlDialect.sqlite: const SqliteOptions(
      strictTablesByDefault: true,
      storeDateTimesAsText: true,
      useBinaryJsonRepresentation: true,
    ),
  };
  late final SomeDao someDao = SomeDao(this as TodoDb);
  Selectable<TodoEntry> withIn(String? var1, String? var2, List<RowId> var3) {
    var $arrayStartIndex = 2;
    final expandedvar3 = $expandVar($arrayStartIndex, var3.length);
    $arrayStartIndex += var3.length;
    return customSelectMapped<TodoEntry>(
      query: switch (dialect.known) {
        KnownSqlDialect.sqlite =>
          'SELECT "_s:0".id, "_s:0".title, "_s:0".content, "_s:0".target_date, "_s:0".category, "_s:0".status FROM todos AS "_s:0" WHERE "_s:0".title = ?2 OR "_s:0".id IN ($expandedvar3) OR "_s:0".title = ?1',
        KnownSqlDialect.postgres || _ =>
          'SELECT "_s:0".id, "_s:0".title, "_s:0".content, "_s:0".target_date, "_s:0".category, "_s:0".status FROM todos AS "_s:0" WHERE "_s:0".title = \$2 OR "_s:0".id IN ($expandedvar3) OR "_s:0".title = \$1',
      },
      variables: [
        mapValue(BuiltinDriftType.text, var1),
        mapValue(BuiltinDriftType.text, var2),
        for (var $ in var3)
          mapValue(
            BuiltinDriftType.int,
            $TodosTableTable.$converterid.toSql($),
          ),
      ],
      readsFrom: {$TodosTableTable()},
      createMapper: (RawResultSet _) {
        final map_0 = $TodosTableTable()
            .createMapperFromPositions(dialect, const [
              ColumnPosition(0),
              ColumnPosition(1),
              ColumnPosition(2),
              ColumnPosition(3),
              ColumnPosition(4),
              ColumnPosition(5),
            ]);

        return (RawRow row) => map_0(row)!;
      },
    );
  }

  @override
  DatabaseSchema get schema => _$schema;
  static final _$categoriesDesc = Index(
    'categories_desc',
    CustomComponent(
      'CREATE INDEX categories_desc ON categories ("desc" DESC, priority)',
      dialectSpecificSql: {},
    ),
  );
  static final DatabaseSchema _$schema = DatabaseSchema([
    $CategoriesTable(),
    $TodosTableTable(),
    $UsersTable(),
    $SharedTodosTable(),
    $TableWithEveryColumnTypeTable(),
    $TableWithoutPKTable(),
    $PureDefaultsTable(),
    $WithCustomTypeTable(),
    $DepartmentTable(),
    $CategoryTodoCountViewView(),
    $TodoWithCategoryViewView(),
    _$categoriesDesc,
  ]);
}

base mixin _$SomeDaoMixin on DatabaseAccessor<TodoDb> {
  $UsersTable get users => attachedDatabase.users;
  $CategoriesTable get categories => attachedDatabase.categories;
  $TodosTableTable get todosTable => attachedDatabase.todosTable;
  $SharedTodosTable get sharedTodos => attachedDatabase.sharedTodos;
  $TodoWithCategoryViewView get todoWithCategoryView =>
      attachedDatabase.todoWithCategoryView;
  Selectable<TodoEntry> todosForUser({required RowId user}) {
    return customSelectMapped<TodoEntry>(
      query: switch (dialect.known) {
        KnownSqlDialect.sqlite =>
          'SELECT t.id, t.title, t.content, t.target_date, t.category, t.status FROM todos AS t INNER JOIN shared_todos AS st ON st.todo = t.id INNER JOIN users AS u ON u.id = st.user WHERE u.id = ?1',
        KnownSqlDialect.postgres || _ =>
          'SELECT t.id, t.title, t.content, t.target_date, t.category, t.status FROM todos AS t INNER JOIN shared_todos AS st ON st.todo = t.id INNER JOIN users AS u ON u.id = st."user" WHERE u.id = \$1',
      },
      variables: [
        mapValue(BuiltinDriftType.int, $UsersTable.$converterid.toSql(user)),
      ],
      readsFrom: {$TodosTableTable(), $SharedTodosTable(), $UsersTable()},
      createMapper: (RawResultSet _) {
        final map_0 = $TodosTableTable()
            .createMapperFromPositions(dialect, const [
              ColumnPosition(0),
              ColumnPosition(1),
              ColumnPosition(2),
              ColumnPosition(3),
              ColumnPosition(4),
              ColumnPosition(5),
            ]);

        return (RawRow row) => map_0(row)!;
      },
    );
  }
}
