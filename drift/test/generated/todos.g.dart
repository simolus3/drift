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
      type: BuiltinDriftType.int,
      isNullable: false,
      requiredDuringInsert: false,
      constraints: () => [
            const ColumnPrimaryKeyConstraint(isAutoIncrementing: true)
          ]).withConverter<RowId>($CategoriesTable.$converterid)
    ..owningResultSet = this;
  @override
  late final TableColumn<String> description = TableColumn<String>(
      name: 'desc',
      type: BuiltinDriftType.text,
      isNullable: false,
      requiredDuringInsert: true,
      constraints: () => [ColumnConstraint.customSql('NOT NULL UNIQUE')])
    ..owningResultSet = this;
  @override
  late final TableColumnWithTypeConverter<CategoryPriority, int> priority =
      TableColumn<int>(
              name: 'priority',
              type: BuiltinDriftType.int,
              isNullable: false,
              requiredDuringInsert: false,
              constraints: () =>
                  [ColumnDefaultConstraint<int>(const Literal(0))])
          .withConverter<CategoryPriority>($CategoriesTable.$converterpriority)
        ..owningResultSet = this;
  @override
  late final TableColumn<String> descriptionInUpperCase = TableColumn<String>(
      name: 'description_in_upper_case',
      type: BuiltinDriftType.text,
      isNullable: false,
      requiredDuringInsert: false,
      constraints: () => [
            ColumnGeneratedAs(StringExpressionOperators(description).upper(),
                stored: false)
          ])
    ..owningResultSet = this;
  @override
  List<TableColumn> get columns =>
      [id, description, priority, descriptionInUpperCase];
  @override
  String get entityName => $name;
  static const String $name = 'categories';
  @override
  $CategoriesTable asSelfType() => this;

  @override
  Set<TableColumn> get primaryKey => {id};
  @override
  Category? Function(DriftRow) createMapperFromPositions(
      List<ColumnPosition> positions) {
    return (DriftRow row) {
      // Not part of row if non-nullable column "id" is missing
      if (row.raw.rawValue(positions[0]) == null) {
        return null;
      }
      return Category(
        id: $CategoriesTable.$converterid
            .fromSql(row.readWithType(positions[0], BuiltinDriftType.int)!),
        description: row.readWithType(positions[1], BuiltinDriftType.text)!,
        priority: $CategoriesTable.$converterpriority
            .fromSql(row.readWithType(positions[2], BuiltinDriftType.int)!),
        descriptionInUpperCase:
            row.readWithType(positions[3], BuiltinDriftType.text)!,
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
  const Category(
      {required this.id,
      required this.description,
      required this.priority,
      required this.descriptionInUpperCase});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['id'] = Variable<int>($CategoriesTable.$converterid.toSql(id));
    }
    map['desc'] = Variable<String>(description);
    {
      map['priority'] =
          Variable<int>($CategoriesTable.$converterpriority.toSql(priority));
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

  factory Category.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: $CategoriesTable.$converterid
          .fromJson(serializer.fromJson<int>(json['id'])),
      description: serializer.fromJson<String>(json['description']),
      priority: $CategoriesTable.$converterpriority
          .fromJson(serializer.fromJson<int>(json['priority'])),
      descriptionInUpperCase:
          serializer.fromJson<String>(json['descriptionInUpperCase']),
    );
  }
  factory Category.fromJsonString(String encodedJson,
          {ValueSerializer? serializer}) =>
      Category.fromJson(
          LegacyDataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>($CategoriesTable.$converterid.toJson(id)),
      'description': serializer.toJson<String>(description),
      'priority': serializer
          .toJson<int>($CategoriesTable.$converterpriority.toJson(priority)),
      'descriptionInUpperCase':
          serializer.toJson<String>(descriptionInUpperCase),
    };
  }

  Category copyWith(
          {RowId? id,
          String? description,
          CategoryPriority? priority,
          String? descriptionInUpperCase}) =>
      Category(
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

  CategoriesCompanion copyWith(
      {Value<RowId>? id,
      Value<String>? description,
      Value<CategoryPriority>? priority}) {
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
      map['id'] = Variable<int>($CategoriesTable.$converterid.toSql(id.value));
    }
    if (description.present) {
      map['desc'] = Variable<String>(description.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(
          $CategoriesTable.$converterpriority.toSql(priority.value));
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
      type: BuiltinDriftType.int,
      isNullable: false,
      requiredDuringInsert: false,
      constraints: () => [
            const ColumnPrimaryKeyConstraint(isAutoIncrementing: true)
          ]).withConverter<RowId>($TodosTableTable.$converterid)
    ..owningResultSet = this;
  @override
  late final TableColumn<String> title = TableColumn<String>(
      name: 'title',
      type: BuiltinDriftType.text,
      isNullable: true,
      requiredDuringInsert: false)
    ..owningResultSet = this;
  @override
  late final TableColumn<String> content = TableColumn<String>(
      name: 'content',
      type: BuiltinDriftType.text,
      isNullable: false,
      requiredDuringInsert: true)
    ..owningResultSet = this;
  @override
  late final TableColumn<DateTime> targetDate = TableColumn<DateTime>(
      name: 'target_date',
      type: BuiltinDriftType.dateTime,
      isNullable: true,
      requiredDuringInsert: false,
      constraints: () => [const ColumnUniqueConstraint()])
    ..owningResultSet = this;
  @override
  late final TableColumnWithTypeConverter<RowId?, int> category =
      TableColumn<int>(
          name: 'category',
          type: BuiltinDriftType.int,
          isNullable: true,
          requiredDuringInsert: false,
          constraints: () => [
                const ColumnForeignKeyConstraint(
                  otherTableName: 'categories',
                  otherColumnName: 'id',
                  initiallyDeferred: true,
                )
              ]).withConverter<RowId?>($TodosTableTable.$convertercategoryn)
        ..owningResultSet = this;
  @override
  late final TableColumnWithTypeConverter<TodoStatus?, String> status =
      TableColumn<String>(
              name: 'status',
              type: BuiltinDriftType.text,
              isNullable: true,
              requiredDuringInsert: false)
          .withConverter<TodoStatus?>($TodosTableTable.$converterstatusn)
        ..owningResultSet = this;
  @override
  List<TableColumn> get columns =>
      [id, title, content, targetDate, category, status];
  @override
  String get entityName => $name;
  static const String $name = 'todos';
  @override
  $TodosTableTable asSelfType() => this;

  @override
  Set<TableColumn> get primaryKey => {id};
  @override
  List<Set<TableColumn>> get uniqueKeys => [
        {title, category},
        {title, targetDate},
      ];
  @override
  TodoEntry? Function(DriftRow) createMapperFromPositions(
      List<ColumnPosition> positions) {
    return (DriftRow row) {
      // Not part of row if non-nullable column "id" is missing
      if (row.raw.rawValue(positions[0]) == null) {
        return null;
      }
      return TodoEntry(
        id: $TodosTableTable.$converterid
            .fromSql(row.readWithType(positions[0], BuiltinDriftType.int)!),
        title: row.readWithType(positions[1], BuiltinDriftType.text),
        content: row.readWithType(positions[2], BuiltinDriftType.text)!,
        targetDate: row.readWithType(positions[3], BuiltinDriftType.dateTime),
        category: $TodosTableTable.$convertercategoryn
            .fromSql(row.readWithType(positions[4], BuiltinDriftType.int)),
        status: $TodosTableTable.$converterstatusn
            .fromSql(row.readWithType(positions[5], BuiltinDriftType.text)),
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
  const TodoEntry(
      {required this.id,
      this.title,
      required this.content,
      this.targetDate,
      this.category,
      this.status});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['id'] = Variable<int>($TodosTableTable.$converterid.toSql(id));
    }
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || targetDate != null) {
      map['target_date'] = Variable<DateTime>(targetDate);
    }
    if (!nullToAbsent || category != null) {
      map['category'] =
          Variable<int>($TodosTableTable.$convertercategoryn.toSql(category));
    }
    if (!nullToAbsent || status != null) {
      map['status'] =
          Variable<String>($TodosTableTable.$converterstatusn.toSql(status));
    }
    return map;
  }

  TodosTableCompanion toCompanion(bool nullToAbsent) {
    return TodosTableCompanion(
      id: Value(id),
      title:
          title == null && nullToAbsent ? const Value.absent() : Value(title),
      content: Value(content),
      targetDate: targetDate == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDate),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      status:
          status == null && nullToAbsent ? const Value.absent() : Value(status),
    );
  }

  factory TodoEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TodoEntry(
      id: $TodosTableTable.$converterid
          .fromJson(serializer.fromJson<int>(json['id'])),
      title: serializer.fromJson<String?>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      targetDate: serializer.fromJson<DateTime?>(json['targetDate']),
      category: $TodosTableTable.$convertercategoryn
          .fromJson(serializer.fromJson<int?>(json['category'])),
      status: $TodosTableTable.$converterstatusn
          .fromJson(serializer.fromJson<String?>(json['status'])),
    );
  }
  factory TodoEntry.fromJsonString(String encodedJson,
          {ValueSerializer? serializer}) =>
      TodoEntry.fromJson(
          LegacyDataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>($TodosTableTable.$converterid.toJson(id)),
      'title': serializer.toJson<String?>(title),
      'content': serializer.toJson<String>(content),
      'targetDate': serializer.toJson<DateTime?>(targetDate),
      'category': serializer
          .toJson<int?>($TodosTableTable.$convertercategoryn.toJson(category)),
      'status': serializer
          .toJson<String?>($TodosTableTable.$converterstatusn.toJson(status)),
    };
  }

  TodoEntry copyWith(
          {RowId? id,
          Value<String?> title = const Value.absent(),
          String? content,
          Value<DateTime?> targetDate = const Value.absent(),
          Value<RowId?> category = const Value.absent(),
          Value<TodoStatus?> status = const Value.absent()}) =>
      TodoEntry(
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
      targetDate:
          data.targetDate.present ? data.targetDate.value : this.targetDate,
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

  TodosTableCompanion copyWith(
      {Value<RowId>? id,
      Value<String?>? title,
      Value<String>? content,
      Value<DateTime?>? targetDate,
      Value<RowId?>? category,
      Value<TodoStatus?>? status}) {
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
      map['id'] = Variable<int>($TodosTableTable.$converterid.toSql(id.value));
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (targetDate.present) {
      map['target_date'] = Variable<DateTime>(targetDate.value);
    }
    if (category.present) {
      map['category'] = Variable<int>(
          $TodosTableTable.$convertercategoryn.toSql(category.value));
    }
    if (status.present) {
      map['status'] = Variable<String>(
          $TodosTableTable.$converterstatusn.toSql(status.value));
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
      type: BuiltinDriftType.int,
      isNullable: false,
      requiredDuringInsert: false,
      constraints: () => [
            const ColumnPrimaryKeyConstraint(isAutoIncrementing: true)
          ]).withConverter<RowId>($UsersTable.$converterid)
    ..owningResultSet = this;
  @override
  late final TableColumn<DateTime> creationTime = TableColumn<DateTime>(
      name: 'creation_time',
      type: BuiltinDriftType.dateTime,
      isNullable: false,
      requiredDuringInsert: false,
      constraints: () => [
            ColumnDefaultConstraint<DateTime>(currentDateAndTime),
            ColumnCheckConstraint(ComparableExpr(creationTime)
                .isGreaterThan(Literal(DateTime.utc(1950))))
          ])
    ..owningResultSet = this;
  @override
  late final TableColumn<String> name = TableColumn<String>(
      name: 'name',
      type: BuiltinDriftType.text,
      isNullable: false,
      requiredDuringInsert: true,
      constraints: () => [const ColumnUniqueConstraint()])
    ..owningResultSet = this;
  @override
  late final TableColumn<bool> isAwesome = TableColumn<bool>(
      name: 'is_awesome',
      type: BuiltinDriftType.bool,
      isNullable: false,
      requiredDuringInsert: false,
      constraints: () => [
            ColumnDefaultConstraint<bool>(const Literal(true)),
            ColumnConstraint.custom(
                CustomComponent('CHECK ("is_awesome" IN (0, 1))'),
                onlyOnDialect: KnownSqlDialect.sqlite)
          ])
    ..owningResultSet = this;
  @override
  late final TableColumn<Uint8List> profilePicture = TableColumn<Uint8List>(
      name: 'profile_picture',
      type: BuiltinDriftType.byteArray,
      isNullable: false,
      requiredDuringInsert: true)
    ..owningResultSet = this;
  @override
  List<TableColumn> get columns =>
      [id, creationTime, name, isAwesome, profilePicture];
  @override
  String get entityName => $name;
  static const String $name = 'users';
  @override
  $UsersTable asSelfType() => this;

  @override
  Set<TableColumn> get primaryKey => {id};
  @override
  User? Function(DriftRow) createMapperFromPositions(
      List<ColumnPosition> positions) {
    return (DriftRow row) {
      // Not part of row if non-nullable column "id" is missing
      if (row.raw.rawValue(positions[0]) == null) {
        return null;
      }
      return User(
        id: $UsersTable.$converterid
            .fromSql(row.readWithType(positions[0], BuiltinDriftType.int)!),
        creationTime:
            row.readWithType(positions[1], BuiltinDriftType.dateTime)!,
        name: row.readWithType(positions[2], BuiltinDriftType.text)!,
        isAwesome: row.readWithType(positions[3], BuiltinDriftType.bool)!,
        profilePicture:
            row.readWithType(positions[4], BuiltinDriftType.byteArray)!,
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
  final DateTime creationTime;
  final String name;
  final bool isAwesome;
  final Uint8List profilePicture;
  const User(
      {required this.id,
      required this.creationTime,
      required this.name,
      required this.isAwesome,
      required this.profilePicture});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['id'] = Variable<int>($UsersTable.$converterid.toSql(id));
    }
    map['creation_time'] = Variable<DateTime>(creationTime);
    map['name'] = Variable<String>(name);
    map['is_awesome'] = Variable<bool>(isAwesome);
    map['profile_picture'] = Variable<Uint8List>(profilePicture);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      creationTime: Value(creationTime),
      name: Value(name),
      isAwesome: Value(isAwesome),
      profilePicture: Value(profilePicture),
    );
  }

  factory User.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: $UsersTable.$converterid
          .fromJson(serializer.fromJson<int>(json['id'])),
      creationTime: serializer.fromJson<DateTime>(json['creationTime']),
      name: serializer.fromJson<String>(json['name']),
      isAwesome: serializer.fromJson<bool>(json['isAwesome']),
      profilePicture: serializer.fromJson<Uint8List>(json['profilePicture']),
    );
  }
  factory User.fromJsonString(String encodedJson,
          {ValueSerializer? serializer}) =>
      User.fromJson(
          LegacyDataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>($UsersTable.$converterid.toJson(id)),
      'creationTime': serializer.toJson<DateTime>(creationTime),
      'name': serializer.toJson<String>(name),
      'isAwesome': serializer.toJson<bool>(isAwesome),
      'profilePicture': serializer.toJson<Uint8List>(profilePicture),
    };
  }

  User copyWith(
          {RowId? id,
          DateTime? creationTime,
          String? name,
          bool? isAwesome,
          Uint8List? profilePicture}) =>
      User(
        id: id ?? this.id,
        creationTime: creationTime ?? this.creationTime,
        name: name ?? this.name,
        isAwesome: isAwesome ?? this.isAwesome,
        profilePicture: profilePicture ?? this.profilePicture,
      );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      creationTime: data.creationTime.present
          ? data.creationTime.value
          : this.creationTime,
      name: data.name.present ? data.name.value : this.name,
      isAwesome: data.isAwesome.present ? data.isAwesome.value : this.isAwesome,
      profilePicture: data.profilePicture.present
          ? data.profilePicture.value
          : this.profilePicture,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('creationTime: $creationTime, ')
          ..write('name: $name, ')
          ..write('isAwesome: $isAwesome, ')
          ..write('profilePicture: $profilePicture')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, creationTime, name, isAwesome,
      $driftBlobEquality.hash(profilePicture));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.creationTime == this.creationTime &&
          other.name == this.name &&
          other.isAwesome == this.isAwesome &&
          $driftBlobEquality.equals(other.profilePicture, this.profilePicture));
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<RowId> id;
  final Value<DateTime> creationTime;
  final Value<String> name;
  final Value<bool> isAwesome;
  final Value<Uint8List> profilePicture;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.creationTime = const Value.absent(),
    this.name = const Value.absent(),
    this.isAwesome = const Value.absent(),
    this.profilePicture = const Value.absent(),
  });
  UsersCompanion.insert({
    this.id = const Value.absent(),
    this.creationTime = const Value.absent(),
    required String name,
    this.isAwesome = const Value.absent(),
    required Uint8List profilePicture,
  })  : name = Value(name),
        profilePicture = Value(profilePicture);
  static Insertable<User> custom({
    Expression<int>? id,
    Expression<DateTime>? creationTime,
    Expression<String>? name,
    Expression<bool>? isAwesome,
    Expression<Uint8List>? profilePicture,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (creationTime != null) 'creation_time': creationTime,
      if (name != null) 'name': name,
      if (isAwesome != null) 'is_awesome': isAwesome,
      if (profilePicture != null) 'profile_picture': profilePicture,
    });
  }

  UsersCompanion copyWith(
      {Value<RowId>? id,
      Value<DateTime>? creationTime,
      Value<String>? name,
      Value<bool>? isAwesome,
      Value<Uint8List>? profilePicture}) {
    return UsersCompanion(
      id: id ?? this.id,
      creationTime: creationTime ?? this.creationTime,
      name: name ?? this.name,
      isAwesome: isAwesome ?? this.isAwesome,
      profilePicture: profilePicture ?? this.profilePicture,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>($UsersTable.$converterid.toSql(id.value));
    }
    if (creationTime.present) {
      map['creation_time'] = Variable<DateTime>(creationTime.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isAwesome.present) {
      map['is_awesome'] = Variable<bool>(isAwesome.value);
    }
    if (profilePicture.present) {
      map['profile_picture'] = Variable<Uint8List>(profilePicture.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('creationTime: $creationTime, ')
          ..write('name: $name, ')
          ..write('isAwesome: $isAwesome, ')
          ..write('profilePicture: $profilePicture')
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
      type: BuiltinDriftType.int,
      isNullable: false,
      requiredDuringInsert: true)
    ..owningResultSet = this;
  @override
  late final TableColumn<int> user = TableColumn<int>(
      name: 'user',
      type: BuiltinDriftType.int,
      isNullable: false,
      requiredDuringInsert: true)
    ..owningResultSet = this;
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
  SharedTodo? Function(DriftRow) createMapperFromPositions(
      List<ColumnPosition> positions) {
    return (DriftRow row) {
      // Not part of row if non-nullable column "todo" is missing
      if (row.raw.rawValue(positions[0]) == null) {
        return null;
      }
      return SharedTodo(
        todo: row.readWithType(positions[0], BuiltinDriftType.int)!,
        user: row.readWithType(positions[1], BuiltinDriftType.int)!,
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
    map['todo'] = Variable<int>(todo);
    map['user'] = Variable<int>(user);
    return map;
  }

  SharedTodosCompanion toCompanion(bool nullToAbsent) {
    return SharedTodosCompanion(
      todo: Value(todo),
      user: Value(user),
    );
  }

  factory SharedTodo.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SharedTodo(
      todo: serializer.fromJson<int>(json['todo']),
      user: serializer.fromJson<int>(json['user']),
    );
  }
  factory SharedTodo.fromJsonString(String encodedJson,
          {ValueSerializer? serializer}) =>
      SharedTodo.fromJson(
          LegacyDataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'todo': serializer.toJson<int>(todo),
      'user': serializer.toJson<int>(user),
    };
  }

  SharedTodo copyWith({int? todo, int? user}) => SharedTodo(
        todo: todo ?? this.todo,
        user: user ?? this.user,
      );
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
  })  : todo = Value(todo),
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

  SharedTodosCompanion copyWith(
      {Value<int>? todo, Value<int>? user, Value<int>? rowid}) {
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
      map['todo'] = Variable<int>(todo.value);
    }
    if (user.present) {
      map['user'] = Variable<int>(user.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
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

class $TableWithoutPKTable extends TableWithoutPK
    with ResultSet<CustomRowClass, $TableWithoutPKTable>
    implements GeneratedTable<CustomRowClass, $TableWithoutPKTable> {
  @override
  final String? alias;
  $TableWithoutPKTable([this.alias]);
  @override
  late final TableColumn<int> notReallyAnId = TableColumn<int>(
      name: 'not_really_an_id',
      type: BuiltinDriftType.int,
      isNullable: false,
      requiredDuringInsert: true)
    ..owningResultSet = this;
  @override
  late final TableColumn<double> someFloat = TableColumn<double>(
      name: 'some_float',
      type: BuiltinDriftType.double,
      isNullable: false,
      requiredDuringInsert: true)
    ..owningResultSet = this;
  @override
  late final TableColumn<BigInt> webSafeInt = TableColumn<BigInt>(
      name: 'web_safe_int',
      type: BuiltinDriftType.int64,
      isNullable: true,
      requiredDuringInsert: false)
    ..owningResultSet = this;
  @override
  late final TableColumnWithTypeConverter<MyCustomObject, String> custom =
      TableColumn<String>(
              name: 'custom',
              type: BuiltinDriftType.text,
              isNullable: false,
              requiredDuringInsert: false,
              clientDefault: _uuid.v4)
          .withConverter<MyCustomObject>($TableWithoutPKTable.$convertercustom)
        ..owningResultSet = this;
  @override
  List<TableColumn> get columns =>
      [notReallyAnId, someFloat, webSafeInt, custom];
  @override
  String get entityName => $name;
  static const String $name = 'table_without_p_k';
  @override
  $TableWithoutPKTable asSelfType() => this;

  @override
  Set<TableColumn> get primaryKey => const {};
  @override
  CustomRowClass? Function(DriftRow) createMapperFromPositions(
      List<ColumnPosition> positions) {
    return (DriftRow row) {
      // Not part of row if non-nullable column "notReallyAnId" is missing
      if (row.raw.rawValue(positions[0]) == null) {
        return null;
      }
      return CustomRowClass.map(
        row.readWithType(positions[0], BuiltinDriftType.int)!,
        row.readWithType(positions[1], BuiltinDriftType.double)!,
        custom: $TableWithoutPKTable.$convertercustom
            .fromSql(row.readWithType(positions[3], BuiltinDriftType.text)!),
        webSafeInt: row.readWithType(positions[2], BuiltinDriftType.int64),
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
  })  : notReallyAnId = Value(notReallyAnId),
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

  TableWithoutPKCompanion copyWith(
      {Value<int>? notReallyAnId,
      Value<double>? someFloat,
      Value<BigInt?>? webSafeInt,
      Value<MyCustomObject>? custom,
      Value<int>? rowid}) {
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
      map['not_really_an_id'] = Variable<int>(notReallyAnId.value);
    }
    if (someFloat.present) {
      map['some_float'] = Variable<double>(someFloat.value);
    }
    if (webSafeInt.present) {
      map['web_safe_int'] = Variable<BigInt>(webSafeInt.value);
    }
    if (custom.present) {
      map['custom'] = Variable<String>(
          $TableWithoutPKTable.$convertercustom.toSql(custom.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
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
              type: BuiltinDriftType.text,
              isNullable: true,
              requiredDuringInsert: false)
          .withConverter<MyCustomObject?>($PureDefaultsTable.$convertertxtn)
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
  PureDefault? Function(DriftRow) createMapperFromPositions(
      List<ColumnPosition> positions) {
    return (DriftRow row) {
      return PureDefault(
        txt: $PureDefaultsTable.$convertertxtn
            .fromSql(row.readWithType(positions[0], BuiltinDriftType.text)),
      );
    };
  }

  @override
  $PureDefaultsTable withAlias(String alias) {
    return $PureDefaultsTable(alias);
  }

  static JsonTypeConverter2<MyCustomObject, String, Map<dynamic, dynamic>>
      $convertertxt = const CustomJsonConverter();
  static JsonTypeConverter2<MyCustomObject?, String?, Map<dynamic, dynamic>?>
      $convertertxtn = JsonTypeConverter2.asNullable($convertertxt);
}

class PureDefault extends LegacyDataClass implements Insertable<PureDefault> {
  final MyCustomObject? txt;
  const PureDefault({this.txt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || txt != null) {
      map['insert'] =
          Variable<String>($PureDefaultsTable.$convertertxtn.toSql(txt));
    }
    return map;
  }

  PureDefaultsCompanion toCompanion(bool nullToAbsent) {
    return PureDefaultsCompanion(
      txt: txt == null && nullToAbsent ? const Value.absent() : Value(txt),
    );
  }

  factory PureDefault.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PureDefault(
      txt: $PureDefaultsTable.$convertertxtn
          .fromJson(serializer.fromJson<Map<dynamic, dynamic>?>(json['txt'])),
    );
  }
  factory PureDefault.fromJsonString(String encodedJson,
          {ValueSerializer? serializer}) =>
      PureDefault.fromJson(
          LegacyDataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'txt': serializer.toJson<Map<dynamic, dynamic>?>(
          $PureDefaultsTable.$convertertxtn.toJson(txt)),
    };
  }

  PureDefault copyWith({Value<MyCustomObject?> txt = const Value.absent()}) =>
      PureDefault(
        txt: txt.present ? txt.value : this.txt,
      );
  PureDefault copyWithCompanion(PureDefaultsCompanion data) {
    return PureDefault(
      txt: data.txt.present ? data.txt.value : this.txt,
    );
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

  PureDefaultsCompanion copyWith(
      {Value<MyCustomObject?>? txt, Value<int>? rowid}) {
    return PureDefaultsCompanion(
      txt: txt ?? this.txt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (txt.present) {
      map['insert'] =
          Variable<String>($PureDefaultsTable.$convertertxtn.toSql(txt.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
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
      type: const UuidType(),
      isNullable: false,
      requiredDuringInsert: true)
    ..owningResultSet = this;
  @override
  List<TableColumn> get columns => [id];
  @override
  String get entityName => $name;
  static const String $name = 'with_custom_type';
  @override
  $WithCustomTypeTable asSelfType() => this;

  @override
  Set<TableColumn> get primaryKey => const {};
  @override
  WithCustomTypeData? Function(DriftRow) createMapperFromPositions(
      List<ColumnPosition> positions) {
    return (DriftRow row) {
      // Not part of row if non-nullable column "id" is missing
      if (row.raw.rawValue(positions[0]) == null) {
        return null;
      }
      return WithCustomTypeData(
        id: row.readWithType(positions[0], const UuidType())!,
      );
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
    map['id'] = Variable<UuidValue>(id, (_) => const UuidType());
    return map;
  }

  WithCustomTypeCompanion toCompanion(bool nullToAbsent) {
    return WithCustomTypeCompanion(
      id: Value(id),
    );
  }

  factory WithCustomTypeData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WithCustomTypeData(
      id: serializer.fromJson<UuidValue>(json['id']),
    );
  }
  factory WithCustomTypeData.fromJsonString(String encodedJson,
          {ValueSerializer? serializer}) =>
      WithCustomTypeData.fromJson(
          LegacyDataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<UuidValue>(id),
    };
  }

  WithCustomTypeData copyWith({UuidValue? id}) => WithCustomTypeData(
        id: id ?? this.id,
      );
  WithCustomTypeData copyWithCompanion(WithCustomTypeCompanion data) {
    return WithCustomTypeData(
      id: data.id.present ? data.id.value : this.id,
    );
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
      map['id'] = Variable<UuidValue>(id.value, (_) => const UuidType());
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
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

class $TableWithEveryColumnTypeTable extends TableWithEveryColumnType
    with
        ResultSet<TableWithEveryColumnTypeData, $TableWithEveryColumnTypeTable>
    implements
        GeneratedTable<TableWithEveryColumnTypeData,
            $TableWithEveryColumnTypeTable> {
  @override
  final String? alias;
  $TableWithEveryColumnTypeTable([this.alias]);
  @override
  late final TableColumnWithTypeConverter<RowId, int> id = TableColumn<int>(
      name: 'id',
      type: BuiltinDriftType.int,
      isNullable: false,
      requiredDuringInsert: false,
      constraints: () => [
            const ColumnPrimaryKeyConstraint(isAutoIncrementing: true)
          ]).withConverter<RowId>($TableWithEveryColumnTypeTable.$converterid)
    ..owningResultSet = this;
  @override
  late final TableColumn<bool> aBool = TableColumn<bool>(
      name: 'a_bool',
      type: BuiltinDriftType.bool,
      isNullable: true,
      requiredDuringInsert: false,
      constraints: () => [
            ColumnConstraint.custom(
                CustomComponent('CHECK ("a_bool" IN (0, 1))'),
                onlyOnDialect: KnownSqlDialect.sqlite)
          ])
    ..owningResultSet = this;
  @override
  late final TableColumn<DateTime> aDateTime = TableColumn<DateTime>(
      name: 'a_date_time',
      type: BuiltinDriftType.dateTime,
      isNullable: true,
      requiredDuringInsert: false)
    ..owningResultSet = this;
  @override
  late final TableColumn<String> aText = TableColumn<String>(
      name: 'a_text',
      type: BuiltinDriftType.text,
      isNullable: true,
      requiredDuringInsert: false)
    ..owningResultSet = this;
  @override
  late final TableColumn<int> anInt = TableColumn<int>(
      name: 'an_int',
      type: BuiltinDriftType.int,
      isNullable: true,
      requiredDuringInsert: false)
    ..owningResultSet = this;
  @override
  late final TableColumn<BigInt> anInt64 = TableColumn<BigInt>(
      name: 'an_int64',
      type: BuiltinDriftType.int64,
      isNullable: true,
      requiredDuringInsert: false)
    ..owningResultSet = this;
  @override
  late final TableColumn<double> aReal = TableColumn<double>(
      name: 'a_real',
      type: BuiltinDriftType.double,
      isNullable: true,
      requiredDuringInsert: false)
    ..owningResultSet = this;
  @override
  late final TableColumn<Uint8List> aBlob = TableColumn<Uint8List>(
      name: 'a_blob',
      type: BuiltinDriftType.byteArray,
      isNullable: true,
      requiredDuringInsert: false)
    ..owningResultSet = this;
  @override
  late final TableColumnWithTypeConverter<TodoStatus?, int> anIntEnum =
      TableColumn<int>(
              name: 'an_int_enum',
              type: BuiltinDriftType.int,
              isNullable: true,
              requiredDuringInsert: false)
          .withConverter<TodoStatus?>(
              $TableWithEveryColumnTypeTable.$converteranIntEnumn)
        ..owningResultSet = this;
  @override
  late final TableColumnWithTypeConverter<MyCustomObject?, String>
      aTextWithConverter = TableColumn<String>(
              name: 'insert',
              type: BuiltinDriftType.text,
              isNullable: true,
              requiredDuringInsert: false)
          .withConverter<MyCustomObject?>(
              $TableWithEveryColumnTypeTable.$converteraTextWithConvertern)
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
        aTextWithConverter
      ];
  @override
  String get entityName => $name;
  static const String $name = 'table_with_every_column_type';
  @override
  $TableWithEveryColumnTypeTable asSelfType() => this;

  @override
  Set<TableColumn> get primaryKey => {id};
  @override
  TableWithEveryColumnTypeData? Function(DriftRow) createMapperFromPositions(
      List<ColumnPosition> positions) {
    return (DriftRow row) {
      // Not part of row if non-nullable column "id" is missing
      if (row.raw.rawValue(positions[0]) == null) {
        return null;
      }
      return TableWithEveryColumnTypeData(
        id: $TableWithEveryColumnTypeTable.$converterid
            .fromSql(row.readWithType(positions[0], BuiltinDriftType.int)!),
        aBool: row.readWithType(positions[1], BuiltinDriftType.bool),
        aDateTime: row.readWithType(positions[2], BuiltinDriftType.dateTime),
        aText: row.readWithType(positions[3], BuiltinDriftType.text),
        anInt: row.readWithType(positions[4], BuiltinDriftType.int),
        anInt64: row.readWithType(positions[5], BuiltinDriftType.int64),
        aReal: row.readWithType(positions[6], BuiltinDriftType.double),
        aBlob: row.readWithType(positions[7], BuiltinDriftType.byteArray),
        anIntEnum: $TableWithEveryColumnTypeTable.$converteranIntEnumn
            .fromSql(row.readWithType(positions[8], BuiltinDriftType.int)),
        aTextWithConverter: $TableWithEveryColumnTypeTable
            .$converteraTextWithConvertern
            .fromSql(row.readWithType(positions[9], BuiltinDriftType.text)),
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
  static JsonTypeConverter2<MyCustomObject, String, Map<dynamic, dynamic>>
      $converteraTextWithConverter = const CustomJsonConverter();
  static JsonTypeConverter2<MyCustomObject?, String?, Map<dynamic, dynamic>?>
      $converteraTextWithConvertern =
      JsonTypeConverter2.asNullable($converteraTextWithConverter);
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
  const TableWithEveryColumnTypeData(
      {required this.id,
      this.aBool,
      this.aDateTime,
      this.aText,
      this.anInt,
      this.anInt64,
      this.aReal,
      this.aBlob,
      this.anIntEnum,
      this.aTextWithConverter});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['id'] =
          Variable<int>($TableWithEveryColumnTypeTable.$converterid.toSql(id));
    }
    if (!nullToAbsent || aBool != null) {
      map['a_bool'] = Variable<bool>(aBool);
    }
    if (!nullToAbsent || aDateTime != null) {
      map['a_date_time'] = Variable<DateTime>(aDateTime);
    }
    if (!nullToAbsent || aText != null) {
      map['a_text'] = Variable<String>(aText);
    }
    if (!nullToAbsent || anInt != null) {
      map['an_int'] = Variable<int>(anInt);
    }
    if (!nullToAbsent || anInt64 != null) {
      map['an_int64'] = Variable<BigInt>(anInt64);
    }
    if (!nullToAbsent || aReal != null) {
      map['a_real'] = Variable<double>(aReal);
    }
    if (!nullToAbsent || aBlob != null) {
      map['a_blob'] = Variable<Uint8List>(aBlob);
    }
    if (!nullToAbsent || anIntEnum != null) {
      map['an_int_enum'] = Variable<int>(
          $TableWithEveryColumnTypeTable.$converteranIntEnumn.toSql(anIntEnum));
    }
    if (!nullToAbsent || aTextWithConverter != null) {
      map['insert'] = Variable<String>($TableWithEveryColumnTypeTable
          .$converteraTextWithConvertern
          .toSql(aTextWithConverter));
    }
    return map;
  }

  TableWithEveryColumnTypeCompanion toCompanion(bool nullToAbsent) {
    return TableWithEveryColumnTypeCompanion(
      id: Value(id),
      aBool:
          aBool == null && nullToAbsent ? const Value.absent() : Value(aBool),
      aDateTime: aDateTime == null && nullToAbsent
          ? const Value.absent()
          : Value(aDateTime),
      aText:
          aText == null && nullToAbsent ? const Value.absent() : Value(aText),
      anInt:
          anInt == null && nullToAbsent ? const Value.absent() : Value(anInt),
      anInt64: anInt64 == null && nullToAbsent
          ? const Value.absent()
          : Value(anInt64),
      aReal:
          aReal == null && nullToAbsent ? const Value.absent() : Value(aReal),
      aBlob:
          aBlob == null && nullToAbsent ? const Value.absent() : Value(aBlob),
      anIntEnum: anIntEnum == null && nullToAbsent
          ? const Value.absent()
          : Value(anIntEnum),
      aTextWithConverter: aTextWithConverter == null && nullToAbsent
          ? const Value.absent()
          : Value(aTextWithConverter),
    );
  }

  factory TableWithEveryColumnTypeData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TableWithEveryColumnTypeData(
      id: $TableWithEveryColumnTypeTable.$converterid
          .fromJson(serializer.fromJson<int>(json['id'])),
      aBool: serializer.fromJson<bool?>(json['aBool']),
      aDateTime: serializer.fromJson<DateTime?>(json['aDateTime']),
      aText: serializer.fromJson<String?>(json['aText']),
      anInt: serializer.fromJson<int?>(json['anInt']),
      anInt64: serializer.fromJson<BigInt?>(json['anInt64']),
      aReal: serializer.fromJson<double?>(json['aReal']),
      aBlob: serializer.fromJson<Uint8List?>(json['aBlob']),
      anIntEnum: $TableWithEveryColumnTypeTable.$converteranIntEnumn
          .fromJson(serializer.fromJson<int?>(json['anIntEnum'])),
      aTextWithConverter: $TableWithEveryColumnTypeTable
          .$converteraTextWithConvertern
          .fromJson(serializer
              .fromJson<Map<dynamic, dynamic>?>(json['aTextWithConverter'])),
    );
  }
  factory TableWithEveryColumnTypeData.fromJsonString(String encodedJson,
          {ValueSerializer? serializer}) =>
      TableWithEveryColumnTypeData.fromJson(
          LegacyDataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer
          .toJson<int>($TableWithEveryColumnTypeTable.$converterid.toJson(id)),
      'aBool': serializer.toJson<bool?>(aBool),
      'aDateTime': serializer.toJson<DateTime?>(aDateTime),
      'aText': serializer.toJson<String?>(aText),
      'anInt': serializer.toJson<int?>(anInt),
      'anInt64': serializer.toJson<BigInt?>(anInt64),
      'aReal': serializer.toJson<double?>(aReal),
      'aBlob': serializer.toJson<Uint8List?>(aBlob),
      'anIntEnum': serializer.toJson<int?>($TableWithEveryColumnTypeTable
          .$converteranIntEnumn
          .toJson(anIntEnum)),
      'aTextWithConverter': serializer.toJson<Map<dynamic, dynamic>?>(
          $TableWithEveryColumnTypeTable.$converteraTextWithConvertern
              .toJson(aTextWithConverter)),
    };
  }

  TableWithEveryColumnTypeData copyWith(
          {RowId? id,
          Value<bool?> aBool = const Value.absent(),
          Value<DateTime?> aDateTime = const Value.absent(),
          Value<String?> aText = const Value.absent(),
          Value<int?> anInt = const Value.absent(),
          Value<BigInt?> anInt64 = const Value.absent(),
          Value<double?> aReal = const Value.absent(),
          Value<Uint8List?> aBlob = const Value.absent(),
          Value<TodoStatus?> anIntEnum = const Value.absent(),
          Value<MyCustomObject?> aTextWithConverter = const Value.absent()}) =>
      TableWithEveryColumnTypeData(
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
      TableWithEveryColumnTypeCompanion data) {
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
  int get hashCode => Object.hash(id, aBool, aDateTime, aText, anInt, anInt64,
      aReal, $driftBlobEquality.hash(aBlob), anIntEnum, aTextWithConverter);
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

  TableWithEveryColumnTypeCompanion copyWith(
      {Value<RowId>? id,
      Value<bool?>? aBool,
      Value<DateTime?>? aDateTime,
      Value<String?>? aText,
      Value<int?>? anInt,
      Value<BigInt?>? anInt64,
      Value<double?>? aReal,
      Value<Uint8List?>? aBlob,
      Value<TodoStatus?>? anIntEnum,
      Value<MyCustomObject?>? aTextWithConverter}) {
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
          $TableWithEveryColumnTypeTable.$converterid.toSql(id.value));
    }
    if (aBool.present) {
      map['a_bool'] = Variable<bool>(aBool.value);
    }
    if (aDateTime.present) {
      map['a_date_time'] = Variable<DateTime>(aDateTime.value);
    }
    if (aText.present) {
      map['a_text'] = Variable<String>(aText.value);
    }
    if (anInt.present) {
      map['an_int'] = Variable<int>(anInt.value);
    }
    if (anInt64.present) {
      map['an_int64'] = Variable<BigInt>(anInt64.value);
    }
    if (aReal.present) {
      map['a_real'] = Variable<double>(aReal.value);
    }
    if (aBlob.present) {
      map['a_blob'] = Variable<Uint8List>(aBlob.value);
    }
    if (anIntEnum.present) {
      map['an_int_enum'] = Variable<int>($TableWithEveryColumnTypeTable
          .$converteranIntEnumn
          .toSql(anIntEnum.value));
    }
    if (aTextWithConverter.present) {
      map['insert'] = Variable<String>($TableWithEveryColumnTypeTable
          .$converteraTextWithConvertern
          .toSql(aTextWithConverter.value));
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

class $DepartmentTable extends Department
    with ResultSet<DepartmentData, $DepartmentTable>
    implements GeneratedTable<DepartmentData, $DepartmentTable> {
  @override
  final String? alias;
  $DepartmentTable([this.alias]);
  @override
  late final TableColumn<int> id = TableColumn<int>(
      name: 'id',
      type: BuiltinDriftType.int,
      isNullable: false,
      requiredDuringInsert: false,
      constraints: () =>
          [const ColumnPrimaryKeyConstraint(isAutoIncrementing: true)])
    ..owningResultSet = this;
  @override
  late final TableColumn<String> name = TableColumn<String>(
      name: 'name',
      type: BuiltinDriftType.text,
      isNullable: true,
      requiredDuringInsert: false)
    ..owningResultSet = this;
  @override
  List<TableColumn> get columns => [id, name];
  @override
  String get entityName => $name;
  static const String $name = 'department';
  @override
  $DepartmentTable asSelfType() => this;

  @override
  Set<TableColumn> get primaryKey => {id};
  @override
  DepartmentData? Function(DriftRow) createMapperFromPositions(
      List<ColumnPosition> positions) {
    return (DriftRow row) {
      // Not part of row if non-nullable column "id" is missing
      if (row.raw.rawValue(positions[0]) == null) {
        return null;
      }
      return DepartmentData(
        id: row.readWithType(positions[0], BuiltinDriftType.int)!,
        name: row.readWithType(positions[1], BuiltinDriftType.text),
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
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    return map;
  }

  DepartmentCompanion toCompanion(bool nullToAbsent) {
    return DepartmentCompanion(
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
    );
  }

  factory DepartmentData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DepartmentData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
    );
  }
  factory DepartmentData.fromJsonString(String encodedJson,
          {ValueSerializer? serializer}) =>
      DepartmentData.fromJson(
          LegacyDataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String?>(name),
    };
  }

  DepartmentData copyWith(
          {int? id, Value<String?> name = const Value.absent()}) =>
      DepartmentData(
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
    return DepartmentCompanion(
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
    return (StringBuffer('DepartmentCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $ProductTable extends Product
    with ResultSet<ProductData, $ProductTable>
    implements GeneratedTable<ProductData, $ProductTable> {
  @override
  final String? alias;
  $ProductTable([this.alias]);
  @override
  late final TableColumn<String> sku = TableColumn<String>(
      name: 'sku',
      type: BuiltinDriftType.text,
      isNullable: false,
      requiredDuringInsert: true)
    ..owningResultSet = this;
  @override
  late final TableColumn<String> name = TableColumn<String>(
      name: 'name',
      type: BuiltinDriftType.text,
      isNullable: true,
      requiredDuringInsert: false)
    ..owningResultSet = this;
  @override
  late final TableColumn<int> department = TableColumn<int>(
      name: 'department',
      type: BuiltinDriftType.int,
      isNullable: true,
      requiredDuringInsert: false,
      constraints: () => [
            const ColumnForeignKeyConstraint(
              otherTableName: 'department',
              otherColumnName: 'id',
            )
          ])
    ..owningResultSet = this;
  @override
  List<TableColumn> get columns => [sku, name, department];
  @override
  String get entityName => $name;
  static const String $name = 'product';
  @override
  $ProductTable asSelfType() => this;

  @override
  Set<TableColumn> get primaryKey => const {};
  @override
  ProductData? Function(DriftRow) createMapperFromPositions(
      List<ColumnPosition> positions) {
    return (DriftRow row) {
      // Not part of row if non-nullable column "sku" is missing
      if (row.raw.rawValue(positions[0]) == null) {
        return null;
      }
      return ProductData(
        sku: row.readWithType(positions[0], BuiltinDriftType.text)!,
        name: row.readWithType(positions[1], BuiltinDriftType.text),
        department: row.readWithType(positions[2], BuiltinDriftType.int),
      );
    };
  }

  @override
  $ProductTable withAlias(String alias) {
    return $ProductTable(alias);
  }
}

class ProductData extends LegacyDataClass implements Insertable<ProductData> {
  final String sku;
  final String? name;
  final int? department;
  const ProductData({required this.sku, this.name, this.department});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['sku'] = Variable<String>(sku);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || department != null) {
      map['department'] = Variable<int>(department);
    }
    return map;
  }

  ProductCompanion toCompanion(bool nullToAbsent) {
    return ProductCompanion(
      sku: Value(sku),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      department: department == null && nullToAbsent
          ? const Value.absent()
          : Value(department),
    );
  }

  factory ProductData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductData(
      sku: serializer.fromJson<String>(json['sku']),
      name: serializer.fromJson<String?>(json['name']),
      department: serializer.fromJson<int?>(json['department']),
    );
  }
  factory ProductData.fromJsonString(String encodedJson,
          {ValueSerializer? serializer}) =>
      ProductData.fromJson(
          LegacyDataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sku': serializer.toJson<String>(sku),
      'name': serializer.toJson<String?>(name),
      'department': serializer.toJson<int?>(department),
    };
  }

  ProductData copyWith(
          {String? sku,
          Value<String?> name = const Value.absent(),
          Value<int?> department = const Value.absent()}) =>
      ProductData(
        sku: sku ?? this.sku,
        name: name.present ? name.value : this.name,
        department: department.present ? department.value : this.department,
      );
  ProductData copyWithCompanion(ProductCompanion data) {
    return ProductData(
      sku: data.sku.present ? data.sku.value : this.sku,
      name: data.name.present ? data.name.value : this.name,
      department:
          data.department.present ? data.department.value : this.department,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductData(')
          ..write('sku: $sku, ')
          ..write('name: $name, ')
          ..write('department: $department')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sku, name, department);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductData &&
          other.sku == this.sku &&
          other.name == this.name &&
          other.department == this.department);
}

class ProductCompanion extends UpdateCompanion<ProductData> {
  final Value<String> sku;
  final Value<String?> name;
  final Value<int?> department;
  final Value<int> rowid;
  const ProductCompanion({
    this.sku = const Value.absent(),
    this.name = const Value.absent(),
    this.department = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductCompanion.insert({
    required String sku,
    this.name = const Value.absent(),
    this.department = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sku = Value(sku);
  static Insertable<ProductData> custom({
    Expression<String>? sku,
    Expression<String>? name,
    Expression<int>? department,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sku != null) 'sku': sku,
      if (name != null) 'name': name,
      if (department != null) 'department': department,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductCompanion copyWith(
      {Value<String>? sku,
      Value<String?>? name,
      Value<int?>? department,
      Value<int>? rowid}) {
    return ProductCompanion(
      sku: sku ?? this.sku,
      name: name ?? this.name,
      department: department ?? this.department,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (department.present) {
      map['department'] = Variable<int>(department.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductCompanion(')
          ..write('sku: $sku, ')
          ..write('name: $name, ')
          ..write('department: $department, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StoreTable extends Store
    with ResultSet<StoreData, $StoreTable>
    implements GeneratedTable<StoreData, $StoreTable> {
  @override
  final String? alias;
  $StoreTable([this.alias]);
  @override
  late final TableColumn<int> id = TableColumn<int>(
      name: 'id',
      type: BuiltinDriftType.int,
      isNullable: false,
      requiredDuringInsert: false,
      constraints: () =>
          [const ColumnPrimaryKeyConstraint(isAutoIncrementing: true)])
    ..owningResultSet = this;
  @override
  late final TableColumn<String> name = TableColumn<String>(
      name: 'name',
      type: BuiltinDriftType.text,
      isNullable: true,
      requiredDuringInsert: false)
    ..owningResultSet = this;
  @override
  List<TableColumn> get columns => [id, name];
  @override
  String get entityName => $name;
  static const String $name = 'store';
  @override
  $StoreTable asSelfType() => this;

  @override
  Set<TableColumn> get primaryKey => {id};
  @override
  StoreData? Function(DriftRow) createMapperFromPositions(
      List<ColumnPosition> positions) {
    return (DriftRow row) {
      // Not part of row if non-nullable column "id" is missing
      if (row.raw.rawValue(positions[0]) == null) {
        return null;
      }
      return StoreData(
        id: row.readWithType(positions[0], BuiltinDriftType.int)!,
        name: row.readWithType(positions[1], BuiltinDriftType.text),
      );
    };
  }

  @override
  $StoreTable withAlias(String alias) {
    return $StoreTable(alias);
  }
}

class StoreData extends LegacyDataClass implements Insertable<StoreData> {
  final int id;
  final String? name;
  const StoreData({required this.id, this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    return map;
  }

  StoreCompanion toCompanion(bool nullToAbsent) {
    return StoreCompanion(
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
    );
  }

  factory StoreData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoreData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
    );
  }
  factory StoreData.fromJsonString(String encodedJson,
          {ValueSerializer? serializer}) =>
      StoreData.fromJson(
          LegacyDataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String?>(name),
    };
  }

  StoreData copyWith({int? id, Value<String?> name = const Value.absent()}) =>
      StoreData(
        id: id ?? this.id,
        name: name.present ? name.value : this.name,
      );
  StoreData copyWithCompanion(StoreCompanion data) {
    return StoreData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoreData(')
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
      (other is StoreData && other.id == this.id && other.name == this.name);
}

class StoreCompanion extends UpdateCompanion<StoreData> {
  final Value<int> id;
  final Value<String?> name;
  const StoreCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  StoreCompanion.insert({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  static Insertable<StoreData> custom({
    Expression<int>? id,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  StoreCompanion copyWith({Value<int>? id, Value<String?>? name}) {
    return StoreCompanion(
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
    return (StringBuffer('StoreCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $ListingTable extends Listing
    with ResultSet<ListingData, $ListingTable>
    implements GeneratedTable<ListingData, $ListingTable> {
  @override
  final String? alias;
  $ListingTable([this.alias]);
  @override
  late final TableColumn<int> id = TableColumn<int>(
      name: 'id',
      type: BuiltinDriftType.int,
      isNullable: false,
      requiredDuringInsert: false,
      constraints: () =>
          [const ColumnPrimaryKeyConstraint(isAutoIncrementing: true)])
    ..owningResultSet = this;
  @override
  late final TableColumn<String> product = TableColumn<String>(
      name: 'product',
      type: BuiltinDriftType.text,
      isNullable: false,
      requiredDuringInsert: true,
      constraints: () => [
            const ColumnForeignKeyConstraint(
              otherTableName: 'product',
              otherColumnName: 'sku',
            )
          ])
    ..owningResultSet = this;
  @override
  late final TableColumn<int> store = TableColumn<int>(
      name: 'store',
      type: BuiltinDriftType.int,
      isNullable: true,
      requiredDuringInsert: false,
      constraints: () => [
            const ColumnForeignKeyConstraint(
              otherTableName: 'store',
              otherColumnName: 'id',
            )
          ])
    ..owningResultSet = this;
  @override
  late final TableColumn<double> price = TableColumn<double>(
      name: 'price',
      type: BuiltinDriftType.double,
      isNullable: true,
      requiredDuringInsert: false)
    ..owningResultSet = this;
  @override
  List<TableColumn> get columns => [id, product, store, price];
  @override
  String get entityName => $name;
  static const String $name = 'listing';
  @override
  $ListingTable asSelfType() => this;

  @override
  Set<TableColumn> get primaryKey => {id};
  @override
  ListingData? Function(DriftRow) createMapperFromPositions(
      List<ColumnPosition> positions) {
    return (DriftRow row) {
      // Not part of row if non-nullable column "id" is missing
      if (row.raw.rawValue(positions[0]) == null) {
        return null;
      }
      return ListingData(
        id: row.readWithType(positions[0], BuiltinDriftType.int)!,
        product: row.readWithType(positions[1], BuiltinDriftType.text)!,
        store: row.readWithType(positions[2], BuiltinDriftType.int),
        price: row.readWithType(positions[3], BuiltinDriftType.double),
      );
    };
  }

  @override
  $ListingTable withAlias(String alias) {
    return $ListingTable(alias);
  }
}

class ListingData extends LegacyDataClass implements Insertable<ListingData> {
  final int id;
  final String product;
  final int? store;
  final double? price;
  const ListingData(
      {required this.id, required this.product, this.store, this.price});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['product'] = Variable<String>(product);
    if (!nullToAbsent || store != null) {
      map['store'] = Variable<int>(store);
    }
    if (!nullToAbsent || price != null) {
      map['price'] = Variable<double>(price);
    }
    return map;
  }

  ListingCompanion toCompanion(bool nullToAbsent) {
    return ListingCompanion(
      id: Value(id),
      product: Value(product),
      store:
          store == null && nullToAbsent ? const Value.absent() : Value(store),
      price:
          price == null && nullToAbsent ? const Value.absent() : Value(price),
    );
  }

  factory ListingData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ListingData(
      id: serializer.fromJson<int>(json['id']),
      product: serializer.fromJson<String>(json['product']),
      store: serializer.fromJson<int?>(json['store']),
      price: serializer.fromJson<double?>(json['price']),
    );
  }
  factory ListingData.fromJsonString(String encodedJson,
          {ValueSerializer? serializer}) =>
      ListingData.fromJson(
          LegacyDataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'product': serializer.toJson<String>(product),
      'store': serializer.toJson<int?>(store),
      'price': serializer.toJson<double?>(price),
    };
  }

  ListingData copyWith(
          {int? id,
          String? product,
          Value<int?> store = const Value.absent(),
          Value<double?> price = const Value.absent()}) =>
      ListingData(
        id: id ?? this.id,
        product: product ?? this.product,
        store: store.present ? store.value : this.store,
        price: price.present ? price.value : this.price,
      );
  ListingData copyWithCompanion(ListingCompanion data) {
    return ListingData(
      id: data.id.present ? data.id.value : this.id,
      product: data.product.present ? data.product.value : this.product,
      store: data.store.present ? data.store.value : this.store,
      price: data.price.present ? data.price.value : this.price,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ListingData(')
          ..write('id: $id, ')
          ..write('product: $product, ')
          ..write('store: $store, ')
          ..write('price: $price')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, product, store, price);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ListingData &&
          other.id == this.id &&
          other.product == this.product &&
          other.store == this.store &&
          other.price == this.price);
}

class ListingCompanion extends UpdateCompanion<ListingData> {
  final Value<int> id;
  final Value<String> product;
  final Value<int?> store;
  final Value<double?> price;
  const ListingCompanion({
    this.id = const Value.absent(),
    this.product = const Value.absent(),
    this.store = const Value.absent(),
    this.price = const Value.absent(),
  });
  ListingCompanion.insert({
    this.id = const Value.absent(),
    required String product,
    this.store = const Value.absent(),
    this.price = const Value.absent(),
  }) : product = Value(product);
  static Insertable<ListingData> custom({
    Expression<int>? id,
    Expression<String>? product,
    Expression<int>? store,
    Expression<double>? price,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (product != null) 'product': product,
      if (store != null) 'store': store,
      if (price != null) 'price': price,
    });
  }

  ListingCompanion copyWith(
      {Value<int>? id,
      Value<String>? product,
      Value<int?>? store,
      Value<double?>? price}) {
    return ListingCompanion(
      id: id ?? this.id,
      product: product ?? this.product,
      store: store ?? this.store,
      price: price ?? this.price,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (product.present) {
      map['product'] = Variable<String>(product.value);
    }
    if (store.present) {
      map['store'] = Variable<int>(store.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ListingCompanion(')
          ..write('id: $id, ')
          ..write('product: $product, ')
          ..write('store: $store, ')
          ..write('price: $price')
          ..write(')'))
        .toString();
  }
}

class CategoryTodoCountViewData extends LegacyDataClass {
  final int? categoryId;
  final String? description;
  final int? itemCount;
  const CategoryTodoCountViewData(
      {this.categoryId, this.description, this.itemCount});
  factory CategoryTodoCountViewData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryTodoCountViewData(
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      description: serializer.fromJson<String?>(json['description']),
      itemCount: serializer.fromJson<int?>(json['itemCount']),
    );
  }
  factory CategoryTodoCountViewData.fromJsonString(String encodedJson,
          {ValueSerializer? serializer}) =>
      CategoryTodoCountViewData.fromJson(
          LegacyDataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'categoryId': serializer.toJson<int?>(categoryId),
      'description': serializer.toJson<String?>(description),
      'itemCount': serializer.toJson<int?>(itemCount),
    };
  }

  CategoryTodoCountViewData copyWith(
          {Value<int?> categoryId = const Value.absent(),
          Value<String?> description = const Value.absent(),
          Value<int?> itemCount = const Value.absent()}) =>
      CategoryTodoCountViewData(
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
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
  final _$TodoDb _attachedDatabase;
  $CategoryTodoCountViewView(this._attachedDatabase, [this.alias]);
  $TodosTableTable get todos => _attachedDatabase.todosTable.withAlias('t0');
  $CategoriesTable get categories =>
      _attachedDatabase.categories.withAlias('t1');
  @override
  List<SchemaColumn> get columns => [categoryId, description, itemCount];
  @override
  String get entityName => 'category_todo_count_view';
  @override
  $CategoryTodoCountViewView asSelfType() => this;

  @override
  CategoryTodoCountViewData? Function(DriftRow) createMapperFromPositions(
      List<ColumnPosition> positions) {
    return (DriftRow row) {
      return CategoryTodoCountViewData(
        categoryId: row.readWithType(positions[0], BuiltinDriftType.int),
        description: row.readWithType(positions[1], BuiltinDriftType.text),
        itemCount: row.readWithType(positions[2], BuiltinDriftType.int),
      );
    };
  }

  late final ViewColumn<int> categoryId = ViewColumn<int>(
      name: 'category_id',
      type: BuiltinDriftType.int,
      isNullable: true,
      expression: categories.id)
    ..owningResultSet = this;
  late final ViewColumn<String> description = ViewColumn<String>(
      name: 'description',
      type: BuiltinDriftType.text,
      isNullable: true,
      expression: categories.description + const Variable('!'))
    ..owningResultSet = this;
  late final ViewColumn<int> itemCount = ViewColumn<int>(
      name: 'item_count',
      type: BuiltinDriftType.int,
      isNullable: true,
      expression: BaseAggregate(todos.id).count())
    ..owningResultSet = this;
  @override
  $CategoryTodoCountViewView withAlias(String alias) {
    return $CategoryTodoCountViewView(_attachedDatabase, alias);
  }

  @override
  SelectStatement? get query =>
      (_attachedDatabase.selectOnly(categories)..addColumns(columns))
          .innerJoin(todos, on: todos.category.equalsExp(categories.id));
  @override
  CustomComponent? get sqlDefinition => null;
  @override
  Set<String> get readsFrom => const {'todos', 'categories'};
}

class TodoWithCategoryViewData extends LegacyDataClass {
  final String? title;
  final String? description;
  const TodoWithCategoryViewData({this.title, this.description});
  factory TodoWithCategoryViewData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TodoWithCategoryViewData(
      title: serializer.fromJson<String?>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
    );
  }
  factory TodoWithCategoryViewData.fromJsonString(String encodedJson,
          {ValueSerializer? serializer}) =>
      TodoWithCategoryViewData.fromJson(
          LegacyDataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'title': serializer.toJson<String?>(title),
      'description': serializer.toJson<String?>(description),
    };
  }

  TodoWithCategoryViewData copyWith(
          {Value<String?> title = const Value.absent(),
          Value<String?> description = const Value.absent()}) =>
      TodoWithCategoryViewData(
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
  final _$TodoDb _attachedDatabase;
  $TodoWithCategoryViewView(this._attachedDatabase, [this.alias]);
  $TodosTableTable get todos => _attachedDatabase.todosTable.withAlias('t0');
  $CategoriesTable get categories =>
      _attachedDatabase.categories.withAlias('t1');
  @override
  List<SchemaColumn> get columns => [title, description];
  @override
  String get entityName => 'todo_with_category_view';
  @override
  $TodoWithCategoryViewView asSelfType() => this;

  @override
  TodoWithCategoryViewData? Function(DriftRow) createMapperFromPositions(
      List<ColumnPosition> positions) {
    return (DriftRow row) {
      return TodoWithCategoryViewData(
        title: row.readWithType(positions[0], BuiltinDriftType.text),
        description: row.readWithType(positions[1], BuiltinDriftType.text),
      );
    };
  }

  late final ViewColumn<String> title = ViewColumn<String>(
      name: 'title',
      type: BuiltinDriftType.text,
      isNullable: true,
      expression: todos.title)
    ..owningResultSet = this;
  late final ViewColumn<String> description = ViewColumn<String>(
      name: 'desc',
      type: BuiltinDriftType.text,
      isNullable: true,
      expression: categories.description)
    ..owningResultSet = this;
  @override
  $TodoWithCategoryViewView withAlias(String alias) {
    return $TodoWithCategoryViewView(_attachedDatabase, alias);
  }

  @override
  SelectStatement? get query =>
      (_attachedDatabase.selectOnly(todos)..addColumns(columns))
          .innerJoin(categories, on: categories.id.equalsExp(todos.category));
  @override
  CustomComponent? get sqlDefinition => null;
  @override
  Set<String> get readsFrom => const {'todos', 'categories'};
}

abstract base class _$TodoDb extends GeneratedDatabase {
  _$TodoDb(super.implementation);
  late final $CategoriesTable categories = $CategoriesTable();
  late final $TodosTableTable todosTable = $TodosTableTable();
  late final $UsersTable users = $UsersTable();
  late final $SharedTodosTable sharedTodos = $SharedTodosTable();
  late final $TableWithoutPKTable tableWithoutPK = $TableWithoutPKTable();
  late final $PureDefaultsTable pureDefaults = $PureDefaultsTable();
  late final $WithCustomTypeTable withCustomType = $WithCustomTypeTable();
  late final $TableWithEveryColumnTypeTable tableWithEveryColumnType =
      $TableWithEveryColumnTypeTable();
  late final $DepartmentTable department = $DepartmentTable();
  late final $ProductTable product = $ProductTable();
  late final $StoreTable store = $StoreTable();
  late final $ListingTable listing = $ListingTable();
  late final $CategoryTodoCountViewView categoryTodoCountView =
      $CategoryTodoCountViewView(this);
  late final $TodoWithCategoryViewView todoWithCategoryView =
      $TodoWithCategoryViewView(this);
  Selectable<AllTodosWithCategoryResult> allTodosWithCategory() {
    return customSelectMapped<AllTodosWithCategoryResult>(
        query:
            'SELECT t.id AS _c0, t.title AS _c1, t.content AS _c2, t.target_date AS _c3, t.category AS _c4, t.status AS _c5, c.id AS catId, c."desc" AS catDesc FROM todos AS t INNER JOIN categories AS c ON c.id = t.category',
        variables: [],
        readsFrom: {
          categories,
          todosTable,
        },
        createMapper: (DriftResultSet resultSet) {
          final type$int = dialect.intType;
          final type$text = dialect.textType;
          final type$dateTime = dialect.dateTimeType;

          return (DriftRow row) => AllTodosWithCategoryResult(
                row: row,
                id: $TodosTableTable.$converterid.fromSql(
                    row.readWithType(const (index: 0, name: '_c0'), type$int)!),
                title:
                    row.readWithType(const (index: 1, name: '_c1'), type$text),
                content:
                    row.readWithType(const (index: 2, name: '_c2'), type$text)!,
                targetDate: row
                    .readWithType(const (index: 3, name: '_c3'), type$dateTime),
                category: NullAwareTypeConverter.wrapFromSql(
                    $TodosTableTable.$convertercategory,
                    row.readWithType(const (index: 4, name: '_c4'), type$int)),
                status: NullAwareTypeConverter.wrapFromSql(
                    $TodosTableTable.$converterstatus,
                    row.readWithType(const (index: 5, name: '_c5'), type$text)),
                catId: $CategoriesTable.$converterid.fromSql(row
                    .readWithType(const (index: 6, name: 'catId'), type$int)!),
                catDesc: row.readWithType(
                    const (index: 7, name: 'catDesc'), type$text)!,
              );
        });
  }

  Future<int> deleteTodoById(RowId var1) {
    return customUpdate(
      'DELETE FROM todos WHERE id = ?1',
      variables: [(dialect.intType, $TodosTableTable.$converterid.toSql(var1))],
      updates: {todosTable},
      updateKind: UpdateKind.delete,
    );
  }

  Selectable<TodoEntry> withIn(String? var1, String? var2, List<RowId> var3) {
    var $arrayStartIndex = 3;
    final expandedvar3 = $expandVar($arrayStartIndex, var3.length);
    $arrayStartIndex += var3.length;
    return customSelectMapped<TodoEntry>(
        query:
            'SELECT id AS _c0, title AS _c1, content AS _c2, target_date AS _c3, category AS _c4, status AS _c5 FROM todos WHERE title = ?2 OR id IN ($expandedvar3) OR title = ?1',
        variables: [
          (dialect.textType, var1),
          (dialect.textType, var2),
          for (var $ in var3)
            (dialect.intType, $TodosTableTable.$converterid.toSql($))
        ],
        readsFrom: {
          todosTable,
        },
        createMapper: (DriftResultSet resultSet) {
          final map_0 = todosTable.createMapperFromPositions(const [
            (index: 0, name: '_c0'),
            (index: 1, name: '_c1'),
            (index: 2, name: '_c2'),
            (index: 3, name: '_c3'),
            (index: 4, name: '_c4'),
            (index: 5, name: '_c5'),
          ]);

          return (DriftRow row) => map_0(row)!;
        });
  }

  Selectable<TodoEntry> search({required RowId id}) {
    return customSelectMapped<TodoEntry>(
        query:
            'SELECT id AS _c0, title AS _c1, content AS _c2, target_date AS _c3, category AS _c4, status AS _c5 FROM todos WHERE CASE WHEN -1 = ?1 THEN 1 ELSE id = ?1 END',
        variables: [(dialect.intType, $TodosTableTable.$converterid.toSql(id))],
        readsFrom: {
          todosTable,
        },
        createMapper: (DriftResultSet resultSet) {
          final map_0 = todosTable.createMapperFromPositions(const [
            (index: 0, name: '_c0'),
            (index: 1, name: '_c1'),
            (index: 2, name: '_c2'),
            (index: 3, name: '_c3'),
            (index: 4, name: '_c4'),
            (index: 5, name: '_c5'),
          ]);

          return (DriftRow row) => map_0(row)!;
        });
  }

  Selectable<MyCustomObject> findCustom() {
    return customSelectMapped<MyCustomObject>(
        query: 'SELECT custom FROM table_without_p_k WHERE some_float < 10',
        variables: [],
        readsFrom: {
          tableWithoutPK,
        },
        createMapper: (DriftResultSet resultSet) {
          final type$text = dialect.textType;

          return (DriftRow row) => $TableWithoutPKTable.$convertercustom
              .fromSql(row
                  .readWithType(const (index: 0, name: 'custom'), type$text)!);
        });
  }

  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        categories,
        todosTable,
        users,
        sharedTodos,
        tableWithoutPK,
        pureDefaults,
        withCustomType,
        tableWithEveryColumnType,
        department,
        product,
        store,
        listing,
        categoryTodoCountView,
        todoWithCategoryView
      ];
}

final class AllTodosWithCategoryResult extends CustomResultSet {
  final RowId id;
  final String? title;
  final String content;
  final DateTime? targetDate;
  final RowId? category;
  final TodoStatus? status;
  final RowId catId;
  final String catDesc;
  AllTodosWithCategoryResult({
    required DriftRow row,
    required this.id,
    this.title,
    required this.content,
    this.targetDate,
    this.category,
    this.status,
    required this.catId,
    required this.catDesc,
  }) : super(row);
  @override
  int get hashCode => Object.hash(
      id, title, content, targetDate, category, status, catId, catDesc);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AllTodosWithCategoryResult &&
          other.id == this.id &&
          other.title == this.title &&
          other.content == this.content &&
          other.targetDate == this.targetDate &&
          other.category == this.category &&
          other.status == this.status &&
          other.catId == this.catId &&
          other.catDesc == this.catDesc);
  @override
  String toString() {
    return (StringBuffer('AllTodosWithCategoryResult(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('targetDate: $targetDate, ')
          ..write('category: $category, ')
          ..write('status: $status, ')
          ..write('catId: $catId, ')
          ..write('catDesc: $catDesc')
          ..write(')'))
        .toString();
  }
}
