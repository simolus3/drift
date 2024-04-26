// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todos.dart';

// ignore_for_file: type=lint
class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumnWithTypeConverter<RowId, int> id = GeneratedColumn<
              int>('id', aliasedName, false,
          hasAutoIncrement: true,
          type: DriftSqlType.int,
          requiredDuringInsert: false,
          defaultConstraints:
              GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'))
      .withConverter<RowId>($CategoriesTable.$converterid);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'desc', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL UNIQUE');
  static const VerificationMeta _priorityMeta =
      const VerificationMeta('priority');
  @override
  late final GeneratedColumnWithTypeConverter<CategoryPriority, int> priority =
      GeneratedColumn<int>('priority', aliasedName, false,
              type: DriftSqlType.int,
              requiredDuringInsert: false,
              defaultValue: const Constant(0))
          .withConverter<CategoryPriority>($CategoriesTable.$converterpriority);
  static const VerificationMeta _descriptionInUpperCaseMeta =
      const VerificationMeta('descriptionInUpperCase');
  @override
  late final GeneratedColumn<String> descriptionInUpperCase =
      GeneratedColumn<String>('description_in_upper_case', aliasedName, false,
          generatedAs: GeneratedAs(description.upper(), false),
          type: DriftSqlType.string,
          requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, description, priority, descriptionInUpperCase];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(Insertable<Category> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    context.handle(_idMeta, const VerificationResult.success());
    if (data.containsKey('desc')) {
      context.handle(_descriptionMeta,
          description.isAcceptableOrUnknown(data['desc']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    context.handle(_priorityMeta, const VerificationResult.success());
    if (data.containsKey('description_in_upper_case')) {
      context.handle(
          _descriptionInUpperCaseMeta,
          descriptionInUpperCase.isAcceptableOrUnknown(
              data['description_in_upper_case']!, _descriptionInUpperCaseMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: $CategoriesTable.$converterid.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!),
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}desc'])!,
      priority: $CategoriesTable.$converterpriority.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}priority'])!),
      descriptionInUpperCase: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}description_in_upper_case'])!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<RowId, int, int> $converterid =
      TypeConverter.extensionType<RowId, int>();
  static JsonTypeConverter2<CategoryPriority, int, int> $converterpriority =
      const EnumIndexConverter<CategoryPriority>(CategoryPriority.values);
}

class Category extends DataClass implements Insertable<Category> {
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
          DataClass.parseJson(encodedJson) as Map<String, dynamic>,
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
    with TableInfo<$TodosTableTable, TodoEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TodosTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumnWithTypeConverter<RowId, int> id = GeneratedColumn<
              int>('id', aliasedName, false,
          hasAutoIncrement: true,
          type: DriftSqlType.int,
          requiredDuringInsert: false,
          defaultConstraints:
              GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'))
      .withConverter<RowId>($TodosTableTable.$converterid);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, true,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 4, maxTextLength: 16),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _targetDateMeta =
      const VerificationMeta('targetDate');
  @override
  late final GeneratedColumn<DateTime> targetDate = GeneratedColumn<DateTime>(
      'target_date', aliasedName, true,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<int> category = GeneratedColumn<int>(
      'category', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES categories (id)'));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumnWithTypeConverter<TodoStatus?, String> status =
      GeneratedColumn<String>('status', aliasedName, true,
              type: DriftSqlType.string, requiredDuringInsert: false)
          .withConverter<TodoStatus?>($TodosTableTable.$converterstatusn);
  @override
  List<GeneratedColumn> get $columns =>
      [id, title, content, targetDate, category, status];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'todos';
  @override
  VerificationContext validateIntegrity(Insertable<TodoEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    context.handle(_idMeta, const VerificationResult.success());
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('target_date')) {
      context.handle(
          _targetDateMeta,
          targetDate.isAcceptableOrUnknown(
              data['target_date']!, _targetDateMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    context.handle(_statusMeta, const VerificationResult.success());
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {title, category},
        {title, targetDate},
      ];
  @override
  TodoEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TodoEntry(
      id: $TodosTableTable.$converterid.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!),
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title']),
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      targetDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}target_date']),
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}category']),
      status: $TodosTableTable.$converterstatusn.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])),
    );
  }

  @override
  $TodosTableTable createAlias(String alias) {
    return $TodosTableTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<RowId, int, int> $converterid =
      TypeConverter.extensionType<RowId, int>();
  static JsonTypeConverter2<TodoStatus, String, String> $converterstatus =
      const EnumNameConverter<TodoStatus>(TodoStatus.values);
  static JsonTypeConverter2<TodoStatus?, String?, String?> $converterstatusn =
      JsonTypeConverter2.asNullable($converterstatus);
}

class TodoEntry extends DataClass implements Insertable<TodoEntry> {
  final RowId id;
  final String? title;
  final String content;
  final DateTime? targetDate;
  final int? category;
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
      map['category'] = Variable<int>(category);
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
      targetDate: serializer.fromJson<DateTime?>(json['target_date']),
      category: serializer.fromJson<int?>(json['category']),
      status: $TodosTableTable.$converterstatusn
          .fromJson(serializer.fromJson<String?>(json['status'])),
    );
  }
  factory TodoEntry.fromJsonString(String encodedJson,
          {ValueSerializer? serializer}) =>
      TodoEntry.fromJson(
          DataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>($TodosTableTable.$converterid.toJson(id)),
      'title': serializer.toJson<String?>(title),
      'content': serializer.toJson<String>(content),
      'target_date': serializer.toJson<DateTime?>(targetDate),
      'category': serializer.toJson<int?>(category),
      'status': serializer
          .toJson<String?>($TodosTableTable.$converterstatusn.toJson(status)),
    };
  }

  TodoEntry copyWith(
          {RowId? id,
          Value<String?> title = const Value.absent(),
          String? content,
          Value<DateTime?> targetDate = const Value.absent(),
          Value<int?> category = const Value.absent(),
          Value<TodoStatus?> status = const Value.absent()}) =>
      TodoEntry(
        id: id ?? this.id,
        title: title.present ? title.value : this.title,
        content: content ?? this.content,
        targetDate: targetDate.present ? targetDate.value : this.targetDate,
        category: category.present ? category.value : this.category,
        status: status.present ? status.value : this.status,
      );
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
  final Value<int?> category;
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
      Value<int?>? category,
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
      map['category'] = Variable<int>(category.value);
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

class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumnWithTypeConverter<RowId, int> id = GeneratedColumn<
              int>('id', aliasedName, false,
          hasAutoIncrement: true,
          type: DriftSqlType.int,
          requiredDuringInsert: false,
          defaultConstraints:
              GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'))
      .withConverter<RowId>($UsersTable.$converterid);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 6, maxTextLength: 32),
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _isAwesomeMeta =
      const VerificationMeta('isAwesome');
  @override
  late final GeneratedColumn<bool> isAwesome = GeneratedColumn<bool>(
      'is_awesome', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_awesome" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _profilePictureMeta =
      const VerificationMeta('profilePicture');
  @override
  late final GeneratedColumn<Uint8List> profilePicture =
      GeneratedColumn<Uint8List>('profile_picture', aliasedName, false,
          type: DriftSqlType.blob, requiredDuringInsert: true);
  static const VerificationMeta _creationTimeMeta =
      const VerificationMeta('creationTime');
  @override
  late final GeneratedColumn<DateTime> creationTime = GeneratedColumn<DateTime>(
      'creation_time', aliasedName, false,
      check: () => creationTime.isBiggerThan(Constant(DateTime.utc(1950))),
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, isAwesome, profilePicture, creationTime];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(Insertable<User> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    context.handle(_idMeta, const VerificationResult.success());
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_awesome')) {
      context.handle(_isAwesomeMeta,
          isAwesome.isAcceptableOrUnknown(data['is_awesome']!, _isAwesomeMeta));
    }
    if (data.containsKey('profile_picture')) {
      context.handle(
          _profilePictureMeta,
          profilePicture.isAcceptableOrUnknown(
              data['profile_picture']!, _profilePictureMeta));
    } else if (isInserting) {
      context.missing(_profilePictureMeta);
    }
    if (data.containsKey('creation_time')) {
      context.handle(
          _creationTimeMeta,
          creationTime.isAcceptableOrUnknown(
              data['creation_time']!, _creationTimeMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: $UsersTable.$converterid.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      isAwesome: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_awesome'])!,
      profilePicture: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}profile_picture'])!,
      creationTime: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}creation_time'])!,
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<RowId, int, int> $converterid =
      TypeConverter.extensionType<RowId, int>();
}

class User extends DataClass implements Insertable<User> {
  final RowId id;
  final String name;
  final bool isAwesome;
  final Uint8List profilePicture;
  final DateTime creationTime;
  const User(
      {required this.id,
      required this.name,
      required this.isAwesome,
      required this.profilePicture,
      required this.creationTime});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['id'] = Variable<int>($UsersTable.$converterid.toSql(id));
    }
    map['name'] = Variable<String>(name);
    map['is_awesome'] = Variable<bool>(isAwesome);
    map['profile_picture'] = Variable<Uint8List>(profilePicture);
    map['creation_time'] = Variable<DateTime>(creationTime);
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

  factory User.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: $UsersTable.$converterid
          .fromJson(serializer.fromJson<int>(json['id'])),
      name: serializer.fromJson<String>(json['name']),
      isAwesome: serializer.fromJson<bool>(json['isAwesome']),
      profilePicture: serializer.fromJson<Uint8List>(json['profilePicture']),
      creationTime: serializer.fromJson<DateTime>(json['creationTime']),
    );
  }
  factory User.fromJsonString(String encodedJson,
          {ValueSerializer? serializer}) =>
      User.fromJson(DataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
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

  User copyWith(
          {RowId? id,
          String? name,
          bool? isAwesome,
          Uint8List? profilePicture,
          DateTime? creationTime}) =>
      User(
        id: id ?? this.id,
        name: name ?? this.name,
        isAwesome: isAwesome ?? this.isAwesome,
        profilePicture: profilePicture ?? this.profilePicture,
        creationTime: creationTime ?? this.creationTime,
      );
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
  int get hashCode => Object.hash(id, name, isAwesome,
      $driftBlobEquality.hash(profilePicture), creationTime);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.name == this.name &&
          other.isAwesome == this.isAwesome &&
          $driftBlobEquality.equals(
              other.profilePicture, this.profilePicture) &&
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
  })  : name = Value(name),
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

  UsersCompanion copyWith(
      {Value<RowId>? id,
      Value<String>? name,
      Value<bool>? isAwesome,
      Value<Uint8List>? profilePicture,
      Value<DateTime>? creationTime}) {
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
      map['id'] = Variable<int>($UsersTable.$converterid.toSql(id.value));
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
    if (creationTime.present) {
      map['creation_time'] = Variable<DateTime>(creationTime.value);
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
    with TableInfo<$SharedTodosTable, SharedTodo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SharedTodosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _todoMeta = const VerificationMeta('todo');
  @override
  late final GeneratedColumn<int> todo = GeneratedColumn<int>(
      'todo', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _userMeta = const VerificationMeta('user');
  @override
  late final GeneratedColumn<int> user = GeneratedColumn<int>(
      'user', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [todo, user];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shared_todos';
  @override
  VerificationContext validateIntegrity(Insertable<SharedTodo> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('todo')) {
      context.handle(
          _todoMeta, todo.isAcceptableOrUnknown(data['todo']!, _todoMeta));
    } else if (isInserting) {
      context.missing(_todoMeta);
    }
    if (data.containsKey('user')) {
      context.handle(
          _userMeta, user.isAcceptableOrUnknown(data['user']!, _userMeta));
    } else if (isInserting) {
      context.missing(_userMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {todo, user};
  @override
  SharedTodo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SharedTodo(
      todo: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}todo'])!,
      user: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}user'])!,
    );
  }

  @override
  $SharedTodosTable createAlias(String alias) {
    return $SharedTodosTable(attachedDatabase, alias);
  }
}

class SharedTodo extends DataClass implements Insertable<SharedTodo> {
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
          DataClass.parseJson(encodedJson) as Map<String, dynamic>,
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
    with TableInfo<$TableWithoutPKTable, CustomRowClass> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TableWithoutPKTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _notReallyAnIdMeta =
      const VerificationMeta('notReallyAnId');
  @override
  late final GeneratedColumn<int> notReallyAnId = GeneratedColumn<int>(
      'not_really_an_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _someFloatMeta =
      const VerificationMeta('someFloat');
  @override
  late final GeneratedColumn<double> someFloat = GeneratedColumn<double>(
      'some_float', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _webSafeIntMeta =
      const VerificationMeta('webSafeInt');
  @override
  late final GeneratedColumn<BigInt> webSafeInt = GeneratedColumn<BigInt>(
      'web_safe_int', aliasedName, true,
      type: DriftSqlType.bigInt, requiredDuringInsert: false);
  static const VerificationMeta _customMeta = const VerificationMeta('custom');
  @override
  late final GeneratedColumnWithTypeConverter<MyCustomObject, String> custom =
      GeneratedColumn<String>('custom', aliasedName, false,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              clientDefault: _uuid.v4)
          .withConverter<MyCustomObject>($TableWithoutPKTable.$convertercustom);
  @override
  List<GeneratedColumn> get $columns =>
      [notReallyAnId, someFloat, webSafeInt, custom];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'table_without_p_k';
  @override
  VerificationContext validateIntegrity(Insertable<CustomRowClass> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('not_really_an_id')) {
      context.handle(
          _notReallyAnIdMeta,
          notReallyAnId.isAcceptableOrUnknown(
              data['not_really_an_id']!, _notReallyAnIdMeta));
    } else if (isInserting) {
      context.missing(_notReallyAnIdMeta);
    }
    if (data.containsKey('some_float')) {
      context.handle(_someFloatMeta,
          someFloat.isAcceptableOrUnknown(data['some_float']!, _someFloatMeta));
    } else if (isInserting) {
      context.missing(_someFloatMeta);
    }
    if (data.containsKey('web_safe_int')) {
      context.handle(
          _webSafeIntMeta,
          webSafeInt.isAcceptableOrUnknown(
              data['web_safe_int']!, _webSafeIntMeta));
    }
    context.handle(_customMeta, const VerificationResult.success());
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  CustomRowClass map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomRowClass.map(
      attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}not_really_an_id'])!,
      attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}some_float'])!,
      custom: $TableWithoutPKTable.$convertercustom.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}custom'])!),
      webSafeInt: attachedDatabase.typeMapping
          .read(DriftSqlType.bigInt, data['${effectivePrefix}web_safe_int']),
    );
  }

  @override
  $TableWithoutPKTable createAlias(String alias) {
    return $TableWithoutPKTable(attachedDatabase, alias);
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
      custom: Value(_object.custom),
      webSafeInt: Value(_object.webSafeInt),
    ).toColumns(false);
  }
}

extension CustomRowClassToInsertable on CustomRowClass {
  _$CustomRowClassInsertable toInsertable() {
    return _$CustomRowClassInsertable(this);
  }
}

class $PureDefaultsTable extends PureDefaults
    with TableInfo<$PureDefaultsTable, PureDefault> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PureDefaultsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _txtMeta = const VerificationMeta('txt');
  @override
  late final GeneratedColumnWithTypeConverter<MyCustomObject?, String> txt =
      GeneratedColumn<String>('insert', aliasedName, true,
              type: DriftSqlType.string, requiredDuringInsert: false)
          .withConverter<MyCustomObject?>($PureDefaultsTable.$convertertxtn);
  @override
  List<GeneratedColumn> get $columns => [txt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pure_defaults';
  @override
  VerificationContext validateIntegrity(Insertable<PureDefault> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    context.handle(_txtMeta, const VerificationResult.success());
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {txt};
  @override
  PureDefault map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PureDefault(
      txt: $PureDefaultsTable.$convertertxtn.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}insert'])),
    );
  }

  @override
  $PureDefaultsTable createAlias(String alias) {
    return $PureDefaultsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MyCustomObject, String, Map<dynamic, dynamic>>
      $convertertxt = const CustomJsonConverter();
  static JsonTypeConverter2<MyCustomObject?, String?, Map<dynamic, dynamic>?>
      $convertertxtn = JsonTypeConverter2.asNullable($convertertxt);
}

class PureDefault extends DataClass implements Insertable<PureDefault> {
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
          DataClass.parseJson(encodedJson) as Map<String, dynamic>,
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
    with TableInfo<$WithCustomTypeTable, WithCustomTypeData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WithCustomTypeTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<UuidValue> id = GeneratedColumn<UuidValue>(
      'id', aliasedName, false,
      type: uuidType, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'with_custom_type';
  @override
  VerificationContext validateIntegrity(Insertable<WithCustomTypeData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  WithCustomTypeData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WithCustomTypeData(
      id: attachedDatabase.typeMapping
          .read(uuidType, data['${effectivePrefix}id'])!,
    );
  }

  @override
  $WithCustomTypeTable createAlias(String alias) {
    return $WithCustomTypeTable(attachedDatabase, alias);
  }
}

class WithCustomTypeData extends DataClass
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
          DataClass.parseJson(encodedJson) as Map<String, dynamic>,
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
        TableInfo<$TableWithEveryColumnTypeTable,
            TableWithEveryColumnTypeData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TableWithEveryColumnTypeTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumnWithTypeConverter<RowId, int> id = GeneratedColumn<
              int>('id', aliasedName, false,
          hasAutoIncrement: true,
          type: DriftSqlType.int,
          requiredDuringInsert: false,
          defaultConstraints:
              GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'))
      .withConverter<RowId>($TableWithEveryColumnTypeTable.$converterid);
  static const VerificationMeta _aBoolMeta = const VerificationMeta('aBool');
  @override
  late final GeneratedColumn<bool> aBool = GeneratedColumn<bool>(
      'a_bool', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("a_bool" IN (0, 1))'));
  static const VerificationMeta _aDateTimeMeta =
      const VerificationMeta('aDateTime');
  @override
  late final GeneratedColumn<DateTime> aDateTime = GeneratedColumn<DateTime>(
      'a_date_time', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _aTextMeta = const VerificationMeta('aText');
  @override
  late final GeneratedColumn<String> aText = GeneratedColumn<String>(
      'a_text', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _anIntMeta = const VerificationMeta('anInt');
  @override
  late final GeneratedColumn<int> anInt = GeneratedColumn<int>(
      'an_int', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _anInt64Meta =
      const VerificationMeta('anInt64');
  @override
  late final GeneratedColumn<BigInt> anInt64 = GeneratedColumn<BigInt>(
      'an_int64', aliasedName, true,
      type: DriftSqlType.bigInt, requiredDuringInsert: false);
  static const VerificationMeta _aRealMeta = const VerificationMeta('aReal');
  @override
  late final GeneratedColumn<double> aReal = GeneratedColumn<double>(
      'a_real', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _aBlobMeta = const VerificationMeta('aBlob');
  @override
  late final GeneratedColumn<Uint8List> aBlob = GeneratedColumn<Uint8List>(
      'a_blob', aliasedName, true,
      type: DriftSqlType.blob, requiredDuringInsert: false);
  static const VerificationMeta _anIntEnumMeta =
      const VerificationMeta('anIntEnum');
  @override
  late final GeneratedColumnWithTypeConverter<TodoStatus?, int> anIntEnum =
      GeneratedColumn<int>('an_int_enum', aliasedName, true,
              type: DriftSqlType.int, requiredDuringInsert: false)
          .withConverter<TodoStatus?>(
              $TableWithEveryColumnTypeTable.$converteranIntEnumn);
  static const VerificationMeta _aTextWithConverterMeta =
      const VerificationMeta('aTextWithConverter');
  @override
  late final GeneratedColumnWithTypeConverter<MyCustomObject?, String>
      aTextWithConverter = GeneratedColumn<String>('insert', aliasedName, true,
              type: DriftSqlType.string, requiredDuringInsert: false)
          .withConverter<MyCustomObject?>(
              $TableWithEveryColumnTypeTable.$converteraTextWithConvertern);
  @override
  List<GeneratedColumn> get $columns => [
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
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'table_with_every_column_type';
  @override
  VerificationContext validateIntegrity(
      Insertable<TableWithEveryColumnTypeData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    context.handle(_idMeta, const VerificationResult.success());
    if (data.containsKey('a_bool')) {
      context.handle(
          _aBoolMeta, aBool.isAcceptableOrUnknown(data['a_bool']!, _aBoolMeta));
    }
    if (data.containsKey('a_date_time')) {
      context.handle(
          _aDateTimeMeta,
          aDateTime.isAcceptableOrUnknown(
              data['a_date_time']!, _aDateTimeMeta));
    }
    if (data.containsKey('a_text')) {
      context.handle(
          _aTextMeta, aText.isAcceptableOrUnknown(data['a_text']!, _aTextMeta));
    }
    if (data.containsKey('an_int')) {
      context.handle(
          _anIntMeta, anInt.isAcceptableOrUnknown(data['an_int']!, _anIntMeta));
    }
    if (data.containsKey('an_int64')) {
      context.handle(_anInt64Meta,
          anInt64.isAcceptableOrUnknown(data['an_int64']!, _anInt64Meta));
    }
    if (data.containsKey('a_real')) {
      context.handle(
          _aRealMeta, aReal.isAcceptableOrUnknown(data['a_real']!, _aRealMeta));
    }
    if (data.containsKey('a_blob')) {
      context.handle(
          _aBlobMeta, aBlob.isAcceptableOrUnknown(data['a_blob']!, _aBlobMeta));
    }
    context.handle(_anIntEnumMeta, const VerificationResult.success());
    context.handle(_aTextWithConverterMeta, const VerificationResult.success());
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TableWithEveryColumnTypeData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TableWithEveryColumnTypeData(
      id: $TableWithEveryColumnTypeTable.$converterid.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!),
      aBool: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}a_bool']),
      aDateTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}a_date_time']),
      aText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}a_text']),
      anInt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}an_int']),
      anInt64: attachedDatabase.typeMapping
          .read(DriftSqlType.bigInt, data['${effectivePrefix}an_int64']),
      aReal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}a_real']),
      aBlob: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}a_blob']),
      anIntEnum: $TableWithEveryColumnTypeTable.$converteranIntEnumn.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.int, data['${effectivePrefix}an_int_enum'])),
      aTextWithConverter: $TableWithEveryColumnTypeTable
          .$converteraTextWithConvertern
          .fromSql(attachedDatabase.typeMapping
              .read(DriftSqlType.string, data['${effectivePrefix}insert'])),
    );
  }

  @override
  $TableWithEveryColumnTypeTable createAlias(String alias) {
    return $TableWithEveryColumnTypeTable(attachedDatabase, alias);
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

class TableWithEveryColumnTypeData extends DataClass
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
          DataClass.parseJson(encodedJson) as Map<String, dynamic>,
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

class $BookClubTable extends BookClub
    with TableInfo<$BookClubTable, BookClubData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookClubTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, true,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 6, maxTextLength: 32),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'book_club';
  @override
  VerificationContext validateIntegrity(Insertable<BookClubData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BookClubData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookClubData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name']),
    );
  }

  @override
  $BookClubTable createAlias(String alias) {
    return $BookClubTable(attachedDatabase, alias);
  }
}

class BookClubData extends DataClass implements Insertable<BookClubData> {
  final int id;
  final String? name;
  const BookClubData({required this.id, this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    return map;
  }

  BookClubCompanion toCompanion(bool nullToAbsent) {
    return BookClubCompanion(
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
    );
  }

  factory BookClubData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookClubData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
    );
  }
  factory BookClubData.fromJsonString(String encodedJson,
          {ValueSerializer? serializer}) =>
      BookClubData.fromJson(
          DataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String?>(name),
    };
  }

  BookClubData copyWith(
          {int? id, Value<String?> name = const Value.absent()}) =>
      BookClubData(
        id: id ?? this.id,
        name: name.present ? name.value : this.name,
      );
  @override
  String toString() {
    return (StringBuffer('BookClubData(')
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
      (other is BookClubData && other.id == this.id && other.name == this.name);
}

class BookClubCompanion extends UpdateCompanion<BookClubData> {
  final Value<int> id;
  final Value<String?> name;
  const BookClubCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  BookClubCompanion.insert({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  static Insertable<BookClubData> custom({
    Expression<int>? id,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  BookClubCompanion copyWith({Value<int>? id, Value<String?>? name}) {
    return BookClubCompanion(
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
    return (StringBuffer('BookClubCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $PersonTable extends Person with TableInfo<$PersonTable, PersonData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PersonTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, true,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 6, maxTextLength: 32),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _clubMeta = const VerificationMeta('club');
  @override
  late final GeneratedColumn<int> club = GeneratedColumn<int>(
      'club', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES book_club (id)'));
  @override
  List<GeneratedColumn> get $columns => [id, name, club];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'person';
  @override
  VerificationContext validateIntegrity(Insertable<PersonData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('club')) {
      context.handle(
          _clubMeta, club.isAcceptableOrUnknown(data['club']!, _clubMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PersonData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PersonData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name']),
      club: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}club']),
    );
  }

  @override
  $PersonTable createAlias(String alias) {
    return $PersonTable(attachedDatabase, alias);
  }
}

class PersonData extends DataClass implements Insertable<PersonData> {
  final int id;
  final String? name;
  final int? club;
  const PersonData({required this.id, this.name, this.club});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || club != null) {
      map['club'] = Variable<int>(club);
    }
    return map;
  }

  PersonCompanion toCompanion(bool nullToAbsent) {
    return PersonCompanion(
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      club: club == null && nullToAbsent ? const Value.absent() : Value(club),
    );
  }

  factory PersonData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PersonData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
      club: serializer.fromJson<int?>(json['club']),
    );
  }
  factory PersonData.fromJsonString(String encodedJson,
          {ValueSerializer? serializer}) =>
      PersonData.fromJson(
          DataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String?>(name),
      'club': serializer.toJson<int?>(club),
    };
  }

  PersonData copyWith(
          {int? id,
          Value<String?> name = const Value.absent(),
          Value<int?> club = const Value.absent()}) =>
      PersonData(
        id: id ?? this.id,
        name: name.present ? name.value : this.name,
        club: club.present ? club.value : this.club,
      );
  @override
  String toString() {
    return (StringBuffer('PersonData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('club: $club')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, club);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PersonData &&
          other.id == this.id &&
          other.name == this.name &&
          other.club == this.club);
}

class PersonCompanion extends UpdateCompanion<PersonData> {
  final Value<int> id;
  final Value<String?> name;
  final Value<int?> club;
  const PersonCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.club = const Value.absent(),
  });
  PersonCompanion.insert({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.club = const Value.absent(),
  });
  static Insertable<PersonData> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? club,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (club != null) 'club': club,
    });
  }

  PersonCompanion copyWith(
      {Value<int>? id, Value<String?>? name, Value<int?>? club}) {
    return PersonCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      club: club ?? this.club,
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
    if (club.present) {
      map['club'] = Variable<int>(club.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PersonCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('club: $club')
          ..write(')'))
        .toString();
  }
}

class $BookTable extends Book with TableInfo<$BookTable, BookData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, true,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 6, maxTextLength: 32),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<int> author = GeneratedColumn<int>(
      'author', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES person (id)'));
  static const VerificationMeta _publisherMeta =
      const VerificationMeta('publisher');
  @override
  late final GeneratedColumn<int> publisher = GeneratedColumn<int>(
      'publisher', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES person (id)'));
  @override
  List<GeneratedColumn> get $columns => [id, title, author, publisher];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'book';
  @override
  VerificationContext validateIntegrity(Insertable<BookData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('author')) {
      context.handle(_authorMeta,
          author.isAcceptableOrUnknown(data['author']!, _authorMeta));
    }
    if (data.containsKey('publisher')) {
      context.handle(_publisherMeta,
          publisher.isAcceptableOrUnknown(data['publisher']!, _publisherMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BookData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title']),
      author: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}author']),
      publisher: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}publisher']),
    );
  }

  @override
  $BookTable createAlias(String alias) {
    return $BookTable(attachedDatabase, alias);
  }
}

class BookData extends DataClass implements Insertable<BookData> {
  final int id;
  final String? title;
  final int? author;
  final int? publisher;
  const BookData({required this.id, this.title, this.author, this.publisher});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || author != null) {
      map['author'] = Variable<int>(author);
    }
    if (!nullToAbsent || publisher != null) {
      map['publisher'] = Variable<int>(publisher);
    }
    return map;
  }

  BookCompanion toCompanion(bool nullToAbsent) {
    return BookCompanion(
      id: Value(id),
      title:
          title == null && nullToAbsent ? const Value.absent() : Value(title),
      author:
          author == null && nullToAbsent ? const Value.absent() : Value(author),
      publisher: publisher == null && nullToAbsent
          ? const Value.absent()
          : Value(publisher),
    );
  }

  factory BookData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookData(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String?>(json['title']),
      author: serializer.fromJson<int?>(json['author']),
      publisher: serializer.fromJson<int?>(json['publisher']),
    );
  }
  factory BookData.fromJsonString(String encodedJson,
          {ValueSerializer? serializer}) =>
      BookData.fromJson(
          DataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String?>(title),
      'author': serializer.toJson<int?>(author),
      'publisher': serializer.toJson<int?>(publisher),
    };
  }

  BookData copyWith(
          {int? id,
          Value<String?> title = const Value.absent(),
          Value<int?> author = const Value.absent(),
          Value<int?> publisher = const Value.absent()}) =>
      BookData(
        id: id ?? this.id,
        title: title.present ? title.value : this.title,
        author: author.present ? author.value : this.author,
        publisher: publisher.present ? publisher.value : this.publisher,
      );
  @override
  String toString() {
    return (StringBuffer('BookData(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('publisher: $publisher')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, author, publisher);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookData &&
          other.id == this.id &&
          other.title == this.title &&
          other.author == this.author &&
          other.publisher == this.publisher);
}

class BookCompanion extends UpdateCompanion<BookData> {
  final Value<int> id;
  final Value<String?> title;
  final Value<int?> author;
  final Value<int?> publisher;
  const BookCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.publisher = const Value.absent(),
  });
  BookCompanion.insert({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.publisher = const Value.absent(),
  });
  static Insertable<BookData> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<int>? author,
    Expression<int>? publisher,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (author != null) 'author': author,
      if (publisher != null) 'publisher': publisher,
    });
  }

  BookCompanion copyWith(
      {Value<int>? id,
      Value<String?>? title,
      Value<int?>? author,
      Value<int?>? publisher}) {
    return BookCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      publisher: publisher ?? this.publisher,
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
    if (author.present) {
      map['author'] = Variable<int>(author.value);
    }
    if (publisher.present) {
      map['publisher'] = Variable<int>(publisher.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('publisher: $publisher')
          ..write(')'))
        .toString();
  }
}

class CategoryTodoCountViewData extends DataClass {
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
          DataClass.parseJson(encodedJson) as Map<String, dynamic>,
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

class $CategoryTodoCountViewView
    extends ViewInfo<$CategoryTodoCountViewView, CategoryTodoCountViewData>
    implements HasResultSet {
  final String? _alias;
  @override
  final _$TodoDb attachedDatabase;
  $CategoryTodoCountViewView(this.attachedDatabase, [this._alias]);
  $TodosTableTable get todos => attachedDatabase.todosTable.createAlias('t0');
  $CategoriesTable get categories =>
      attachedDatabase.categories.createAlias('t1');
  @override
  List<GeneratedColumn> get $columns => [categoryId, description, itemCount];
  @override
  String get aliasedName => _alias ?? entityName;
  @override
  String get entityName => 'category_todo_count_view';
  @override
  Map<SqlDialect, String>? get createViewStatements => null;
  @override
  $CategoryTodoCountViewView get asDslTable => this;
  @override
  CategoryTodoCountViewData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryTodoCountViewData(
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}category_id']),
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      itemCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}item_count']),
    );
  }

  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
      'category_id', aliasedName, true,
      generatedAs: GeneratedAs(categories.id, false), type: DriftSqlType.int);
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      generatedAs:
          GeneratedAs(categories.description + const Variable('!'), false),
      type: DriftSqlType.string);
  late final GeneratedColumn<int> itemCount = GeneratedColumn<int>(
      'item_count', aliasedName, true,
      generatedAs: GeneratedAs(todos.id.count(), false),
      type: DriftSqlType.int);
  @override
  $CategoryTodoCountViewView createAlias(String alias) {
    return $CategoryTodoCountViewView(attachedDatabase, alias);
  }

  @override
  Query? get query =>
      (attachedDatabase.selectOnly(categories)..addColumns($columns))
          .join([innerJoin(todos, todos.category.equalsExp(categories.id))])
        ..groupBy([categories.id]);
  @override
  Set<String> get readTables => const {'todos', 'categories'};
}

class TodoWithCategoryViewData extends DataClass {
  final String? title;
  final String description;
  const TodoWithCategoryViewData({this.title, required this.description});
  factory TodoWithCategoryViewData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TodoWithCategoryViewData(
      title: serializer.fromJson<String?>(json['title']),
      description: serializer.fromJson<String>(json['description']),
    );
  }
  factory TodoWithCategoryViewData.fromJsonString(String encodedJson,
          {ValueSerializer? serializer}) =>
      TodoWithCategoryViewData.fromJson(
          DataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'title': serializer.toJson<String?>(title),
      'description': serializer.toJson<String>(description),
    };
  }

  TodoWithCategoryViewData copyWith(
          {Value<String?> title = const Value.absent(), String? description}) =>
      TodoWithCategoryViewData(
        title: title.present ? title.value : this.title,
        description: description ?? this.description,
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

class $TodoWithCategoryViewView
    extends ViewInfo<$TodoWithCategoryViewView, TodoWithCategoryViewData>
    implements HasResultSet {
  final String? _alias;
  @override
  final _$TodoDb attachedDatabase;
  $TodoWithCategoryViewView(this.attachedDatabase, [this._alias]);
  $TodosTableTable get todos => attachedDatabase.todosTable.createAlias('t0');
  $CategoriesTable get categories =>
      attachedDatabase.categories.createAlias('t1');
  @override
  List<GeneratedColumn> get $columns => [title, description];
  @override
  String get aliasedName => _alias ?? entityName;
  @override
  String get entityName => 'todo_with_category_view';
  @override
  Map<SqlDialect, String>? get createViewStatements => null;
  @override
  $TodoWithCategoryViewView get asDslTable => this;
  @override
  TodoWithCategoryViewData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TodoWithCategoryViewData(
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title']),
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}desc'])!,
    );
  }

  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, true,
      generatedAs: GeneratedAs(todos.title, false), type: DriftSqlType.string);
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'desc', aliasedName, false,
      generatedAs: GeneratedAs(categories.description, false),
      type: DriftSqlType.string);
  @override
  $TodoWithCategoryViewView createAlias(String alias) {
    return $TodoWithCategoryViewView(attachedDatabase, alias);
  }

  @override
  Query? get query => (attachedDatabase.selectOnly(todos)..addColumns($columns))
      .join([innerJoin(categories, categories.id.equalsExp(todos.category))]);
  @override
  Set<String> get readTables => const {'todos', 'categories'};
}

abstract class _$TodoDb extends GeneratedDatabase {
  _$TodoDb(QueryExecutor e) : super(e);
  _$TodoDbManager get managers => _$TodoDbManager(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $TodosTableTable todosTable = $TodosTableTable(this);
  late final $UsersTable users = $UsersTable(this);
  late final $SharedTodosTable sharedTodos = $SharedTodosTable(this);
  late final $TableWithoutPKTable tableWithoutPK = $TableWithoutPKTable(this);
  late final $PureDefaultsTable pureDefaults = $PureDefaultsTable(this);
  late final $WithCustomTypeTable withCustomType = $WithCustomTypeTable(this);
  late final $TableWithEveryColumnTypeTable tableWithEveryColumnType =
      $TableWithEveryColumnTypeTable(this);
  late final $BookClubTable bookClub = $BookClubTable(this);
  late final $PersonTable person = $PersonTable(this);
  late final $BookTable book = $BookTable(this);
  late final $CategoryTodoCountViewView categoryTodoCountView =
      $CategoryTodoCountViewView(this);
  late final $TodoWithCategoryViewView todoWithCategoryView =
      $TodoWithCategoryViewView(this);
  late final SomeDao someDao = SomeDao(this as TodoDb);
  Selectable<AllTodosWithCategoryResult> allTodosWithCategory() {
    return customSelect(
        'SELECT t.*, c.id AS catId, c."desc" AS catDesc FROM todos AS t INNER JOIN categories AS c ON c.id = t.category',
        variables: [],
        readsFrom: {
          categories,
          todosTable,
        }).map((QueryRow row) => AllTodosWithCategoryResult(
          row: row,
          id: $TodosTableTable.$converterid.fromSql(row.read<int>('id')),
          title: row.readNullable<String>('title'),
          content: row.read<String>('content'),
          targetDate: row.readNullable<DateTime>('target_date'),
          category: row.readNullable<int>('category'),
          status: NullAwareTypeConverter.wrapFromSql(
              $TodosTableTable.$converterstatus,
              row.readNullable<String>('status')),
          catId: $CategoriesTable.$converterid.fromSql(row.read<int>('catId')),
          catDesc: row.read<String>('catDesc'),
        ));
  }

  Future<int> deleteTodoById(RowId var1) {
    return customUpdate(
      'DELETE FROM todos WHERE id = ?1',
      variables: [Variable<int>($TodosTableTable.$converterid.toSql(var1))],
      updates: {todosTable},
      updateKind: UpdateKind.delete,
    );
  }

  Selectable<TodoEntry> withIn(String? var1, String? var2, List<RowId> var3) {
    var $arrayStartIndex = 3;
    final expandedvar3 = $expandVar($arrayStartIndex, var3.length);
    $arrayStartIndex += var3.length;
    return customSelect(
        'SELECT * FROM todos WHERE title = ?2 OR id IN ($expandedvar3) OR title = ?1',
        variables: [
          Variable<String>(var1),
          Variable<String>(var2),
          for (var $ in var3)
            Variable<int>($TodosTableTable.$converterid.toSql($))
        ],
        readsFrom: {
          todosTable,
        }).asyncMap(todosTable.mapFromRow);
  }

  Selectable<TodoEntry> search({required RowId id}) {
    return customSelect(
        'SELECT * FROM todos WHERE CASE WHEN -1 = ?1 THEN 1 ELSE id = ?1 END',
        variables: [
          Variable<int>($TodosTableTable.$converterid.toSql(id))
        ],
        readsFrom: {
          todosTable,
        }).asyncMap(todosTable.mapFromRow);
  }

  Selectable<MyCustomObject> findCustom() {
    return customSelect(
        'SELECT custom FROM table_without_p_k WHERE some_float < 10',
        variables: [],
        readsFrom: {
          tableWithoutPK,
        }).map((QueryRow row) => $TableWithoutPKTable.$convertercustom
        .fromSql(row.read<String>('custom')));
  }

  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
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
        bookClub,
        person,
        book,
        categoryTodoCountView,
        todoWithCategoryView
      ];
}

class $$CategoriesTableFilterComposer
    extends FilterComposer<_$TodoDb, $CategoriesTable> {
  $$CategoriesTableFilterComposer(super.$db, super.$table,
      {super.$joinBuilder});
  ColumnWithTypeConverterFilters<RowId, RowId, int> get id =>
      $columnFilterWithTypeConverter($table.id);
  ColumnFilters<String> get description => $columnFilter($table.description);
  ColumnWithTypeConverterFilters<CategoryPriority, CategoryPriority, int>
      get priority => $columnFilterWithTypeConverter($table.priority);
  ColumnFilters<String> get descriptionInUpperCase =>
      $columnFilter($table.descriptionInUpperCase);
  ColumnAggregate todos(
      ComposableFilter Function($$TodosTableTableFilterComposer f) f) {
    final $$TodosTableTableFilterComposer composer =
        $$TodosTableTableFilterComposer($db, $db.todosTable,
            $joinBuilder: $buildJoinForTable(
                getCurrentColumn: (t) => t.id,
                referencedTable: $db.todosTable,
                getReferencedColumn: (t) => t.category));
    return ColumnAggregate(f(composer));
  }
}

class $$CategoriesTableOrderingComposer
    extends OrderingComposer<_$TodoDb, $CategoriesTable> {
  $$CategoriesTableOrderingComposer(super.$db, super.$table,
      {super.$joinBuilder});
  ColumnOrderings<int> get id => $columnOrdering($table.id);
  ColumnOrderings<String> get description =>
      $columnOrdering($table.description);
  ColumnOrderings<int> get priority => $columnOrdering($table.priority);
  ColumnOrderings<String> get descriptionInUpperCase =>
      $columnOrdering($table.descriptionInUpperCase);
}

class $$CategoriesTableProcessedTableManager extends ProcessedTableManager<
    _$TodoDb,
    $CategoriesTable,
    Category,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableProcessedTableManager,
    $$CategoriesTableInsertCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder> {
  const $$CategoriesTableProcessedTableManager(super.$state);
}

typedef $$CategoriesTableInsertCompanionBuilder = CategoriesCompanion Function({
  Value<RowId> id,
  required String description,
  Value<CategoryPriority> priority,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<RowId> id,
  Value<String> description,
  Value<CategoryPriority> priority,
});

class $$CategoriesTableTableManager extends RootTableManager<
    _$TodoDb,
    $CategoriesTable,
    Category,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableProcessedTableManager,
    $$CategoriesTableInsertCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder> {
  $$CategoriesTableTableManager(_$TodoDb db, $CategoriesTable table)
      : super(TableManagerState(
            db: db,
            table: table,
            filteringComposer: $$CategoriesTableFilterComposer(db, table),
            orderingComposer: $$CategoriesTableOrderingComposer(db, table),
            getChildManagerBuilder: (p0) =>
                $$CategoriesTableProcessedTableManager(p0),
            getUpdateCompanionBuilder: ({
              Value<RowId> id = const Value.absent(),
              Value<String> description = const Value.absent(),
              Value<CategoryPriority> priority = const Value.absent(),
            }) =>
                CategoriesCompanion(
                  id: id,
                  description: description,
                  priority: priority,
                ),
            getInsertCompanionBuilder: ({
              Value<RowId> id = const Value.absent(),
              required String description,
              Value<CategoryPriority> priority = const Value.absent(),
            }) =>
                CategoriesCompanion.insert(
                  id: id,
                  description: description,
                  priority: priority,
                )));
}

class $$TodosTableTableFilterComposer
    extends FilterComposer<_$TodoDb, $TodosTableTable> {
  $$TodosTableTableFilterComposer(super.$db, super.$table,
      {super.$joinBuilder});
  ColumnWithTypeConverterFilters<RowId, RowId, int> get id =>
      $columnFilterWithTypeConverter($table.id);
  ColumnFilters<String> get title => $columnFilter($table.title);
  ColumnFilters<String> get content => $columnFilter($table.content);
  ColumnFilters<DateTime> get targetDate => $columnFilter($table.targetDate);
  $$CategoriesTableFilterComposer get category {
    final $$CategoriesTableFilterComposer composer =
        $$CategoriesTableFilterComposer($db, $db.categories,
            $joinBuilder: $buildJoinForTable(
                getCurrentColumn: (t) => t.category,
                referencedTable: $db.categories,
                getReferencedColumn: (t) => t.id));
    return composer;
  }

  ColumnWithTypeConverterFilters<TodoStatus?, TodoStatus, String> get status =>
      $columnFilterWithTypeConverter($table.status);
}

class $$TodosTableTableOrderingComposer
    extends OrderingComposer<_$TodoDb, $TodosTableTable> {
  $$TodosTableTableOrderingComposer(super.$db, super.$table,
      {super.$joinBuilder});
  ColumnOrderings<int> get id => $columnOrdering($table.id);
  ColumnOrderings<String> get title => $columnOrdering($table.title);
  ColumnOrderings<String> get content => $columnOrdering($table.content);
  ColumnOrderings<DateTime> get targetDate =>
      $columnOrdering($table.targetDate);
  $$CategoriesTableOrderingComposer get category =>
      $$CategoriesTableOrderingComposer($db, $db.categories,
          $joinBuilder: $buildJoinForTable(
              getCurrentColumn: (t) => t.category,
              referencedTable: $db.categories,
              getReferencedColumn: (t) => t.id));
  ColumnOrderings<String> get status => $columnOrdering($table.status);
}

class $$TodosTableTableProcessedTableManager extends ProcessedTableManager<
    _$TodoDb,
    $TodosTableTable,
    TodoEntry,
    $$TodosTableTableFilterComposer,
    $$TodosTableTableOrderingComposer,
    $$TodosTableTableProcessedTableManager,
    $$TodosTableTableInsertCompanionBuilder,
    $$TodosTableTableUpdateCompanionBuilder> {
  const $$TodosTableTableProcessedTableManager(super.$state);
}

typedef $$TodosTableTableInsertCompanionBuilder = TodosTableCompanion Function({
  Value<RowId> id,
  Value<String?> title,
  required String content,
  Value<DateTime?> targetDate,
  Value<int?> category,
  Value<TodoStatus?> status,
});
typedef $$TodosTableTableUpdateCompanionBuilder = TodosTableCompanion Function({
  Value<RowId> id,
  Value<String?> title,
  Value<String> content,
  Value<DateTime?> targetDate,
  Value<int?> category,
  Value<TodoStatus?> status,
});

class $$TodosTableTableTableManager extends RootTableManager<
    _$TodoDb,
    $TodosTableTable,
    TodoEntry,
    $$TodosTableTableFilterComposer,
    $$TodosTableTableOrderingComposer,
    $$TodosTableTableProcessedTableManager,
    $$TodosTableTableInsertCompanionBuilder,
    $$TodosTableTableUpdateCompanionBuilder> {
  $$TodosTableTableTableManager(_$TodoDb db, $TodosTableTable table)
      : super(TableManagerState(
            db: db,
            table: table,
            filteringComposer: $$TodosTableTableFilterComposer(db, table),
            orderingComposer: $$TodosTableTableOrderingComposer(db, table),
            getChildManagerBuilder: (p0) =>
                $$TodosTableTableProcessedTableManager(p0),
            getUpdateCompanionBuilder: ({
              Value<RowId> id = const Value.absent(),
              Value<String?> title = const Value.absent(),
              Value<String> content = const Value.absent(),
              Value<DateTime?> targetDate = const Value.absent(),
              Value<int?> category = const Value.absent(),
              Value<TodoStatus?> status = const Value.absent(),
            }) =>
                TodosTableCompanion(
                  id: id,
                  title: title,
                  content: content,
                  targetDate: targetDate,
                  category: category,
                  status: status,
                ),
            getInsertCompanionBuilder: ({
              Value<RowId> id = const Value.absent(),
              Value<String?> title = const Value.absent(),
              required String content,
              Value<DateTime?> targetDate = const Value.absent(),
              Value<int?> category = const Value.absent(),
              Value<TodoStatus?> status = const Value.absent(),
            }) =>
                TodosTableCompanion.insert(
                  id: id,
                  title: title,
                  content: content,
                  targetDate: targetDate,
                  category: category,
                  status: status,
                )));
}

class $$UsersTableFilterComposer extends FilterComposer<_$TodoDb, $UsersTable> {
  $$UsersTableFilterComposer(super.$db, super.$table, {super.$joinBuilder});
  ColumnWithTypeConverterFilters<RowId, RowId, int> get id =>
      $columnFilterWithTypeConverter($table.id);
  ColumnFilters<String> get name => $columnFilter($table.name);
  ColumnFilters<bool> get isAwesome => $columnFilter($table.isAwesome);
  ColumnFilters<Uint8List> get profilePicture =>
      $columnFilter($table.profilePicture);
  ColumnFilters<DateTime> get creationTime =>
      $columnFilter($table.creationTime);
}

class $$UsersTableOrderingComposer
    extends OrderingComposer<_$TodoDb, $UsersTable> {
  $$UsersTableOrderingComposer(super.$db, super.$table, {super.$joinBuilder});
  ColumnOrderings<int> get id => $columnOrdering($table.id);
  ColumnOrderings<String> get name => $columnOrdering($table.name);
  ColumnOrderings<bool> get isAwesome => $columnOrdering($table.isAwesome);
  ColumnOrderings<Uint8List> get profilePicture =>
      $columnOrdering($table.profilePicture);
  ColumnOrderings<DateTime> get creationTime =>
      $columnOrdering($table.creationTime);
}

class $$UsersTableProcessedTableManager extends ProcessedTableManager<
    _$TodoDb,
    $UsersTable,
    User,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableProcessedTableManager,
    $$UsersTableInsertCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder> {
  const $$UsersTableProcessedTableManager(super.$state);
}

typedef $$UsersTableInsertCompanionBuilder = UsersCompanion Function({
  Value<RowId> id,
  required String name,
  Value<bool> isAwesome,
  required Uint8List profilePicture,
  Value<DateTime> creationTime,
});
typedef $$UsersTableUpdateCompanionBuilder = UsersCompanion Function({
  Value<RowId> id,
  Value<String> name,
  Value<bool> isAwesome,
  Value<Uint8List> profilePicture,
  Value<DateTime> creationTime,
});

class $$UsersTableTableManager extends RootTableManager<
    _$TodoDb,
    $UsersTable,
    User,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableProcessedTableManager,
    $$UsersTableInsertCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder> {
  $$UsersTableTableManager(_$TodoDb db, $UsersTable table)
      : super(TableManagerState(
            db: db,
            table: table,
            filteringComposer: $$UsersTableFilterComposer(db, table),
            orderingComposer: $$UsersTableOrderingComposer(db, table),
            getChildManagerBuilder: (p0) =>
                $$UsersTableProcessedTableManager(p0),
            getUpdateCompanionBuilder: ({
              Value<RowId> id = const Value.absent(),
              Value<String> name = const Value.absent(),
              Value<bool> isAwesome = const Value.absent(),
              Value<Uint8List> profilePicture = const Value.absent(),
              Value<DateTime> creationTime = const Value.absent(),
            }) =>
                UsersCompanion(
                  id: id,
                  name: name,
                  isAwesome: isAwesome,
                  profilePicture: profilePicture,
                  creationTime: creationTime,
                ),
            getInsertCompanionBuilder: ({
              Value<RowId> id = const Value.absent(),
              required String name,
              Value<bool> isAwesome = const Value.absent(),
              required Uint8List profilePicture,
              Value<DateTime> creationTime = const Value.absent(),
            }) =>
                UsersCompanion.insert(
                  id: id,
                  name: name,
                  isAwesome: isAwesome,
                  profilePicture: profilePicture,
                  creationTime: creationTime,
                )));
}

class $$SharedTodosTableFilterComposer
    extends FilterComposer<_$TodoDb, $SharedTodosTable> {
  $$SharedTodosTableFilterComposer(super.$db, super.$table,
      {super.$joinBuilder});
  ColumnFilters<int> get todo => $columnFilter($table.todo);
  ColumnFilters<int> get user => $columnFilter($table.user);
}

class $$SharedTodosTableOrderingComposer
    extends OrderingComposer<_$TodoDb, $SharedTodosTable> {
  $$SharedTodosTableOrderingComposer(super.$db, super.$table,
      {super.$joinBuilder});
  ColumnOrderings<int> get todo => $columnOrdering($table.todo);
  ColumnOrderings<int> get user => $columnOrdering($table.user);
}

class $$SharedTodosTableProcessedTableManager extends ProcessedTableManager<
    _$TodoDb,
    $SharedTodosTable,
    SharedTodo,
    $$SharedTodosTableFilterComposer,
    $$SharedTodosTableOrderingComposer,
    $$SharedTodosTableProcessedTableManager,
    $$SharedTodosTableInsertCompanionBuilder,
    $$SharedTodosTableUpdateCompanionBuilder> {
  const $$SharedTodosTableProcessedTableManager(super.$state);
}

typedef $$SharedTodosTableInsertCompanionBuilder = SharedTodosCompanion
    Function({
  required int todo,
  required int user,
  Value<int> rowid,
});
typedef $$SharedTodosTableUpdateCompanionBuilder = SharedTodosCompanion
    Function({
  Value<int> todo,
  Value<int> user,
  Value<int> rowid,
});

class $$SharedTodosTableTableManager extends RootTableManager<
    _$TodoDb,
    $SharedTodosTable,
    SharedTodo,
    $$SharedTodosTableFilterComposer,
    $$SharedTodosTableOrderingComposer,
    $$SharedTodosTableProcessedTableManager,
    $$SharedTodosTableInsertCompanionBuilder,
    $$SharedTodosTableUpdateCompanionBuilder> {
  $$SharedTodosTableTableManager(_$TodoDb db, $SharedTodosTable table)
      : super(TableManagerState(
            db: db,
            table: table,
            filteringComposer: $$SharedTodosTableFilterComposer(db, table),
            orderingComposer: $$SharedTodosTableOrderingComposer(db, table),
            getChildManagerBuilder: (p0) =>
                $$SharedTodosTableProcessedTableManager(p0),
            getUpdateCompanionBuilder: ({
              Value<int> todo = const Value.absent(),
              Value<int> user = const Value.absent(),
              Value<int> rowid = const Value.absent(),
            }) =>
                SharedTodosCompanion(
                  todo: todo,
                  user: user,
                  rowid: rowid,
                ),
            getInsertCompanionBuilder: ({
              required int todo,
              required int user,
              Value<int> rowid = const Value.absent(),
            }) =>
                SharedTodosCompanion.insert(
                  todo: todo,
                  user: user,
                  rowid: rowid,
                )));
}

class $$PureDefaultsTableFilterComposer
    extends FilterComposer<_$TodoDb, $PureDefaultsTable> {
  $$PureDefaultsTableFilterComposer(super.$db, super.$table,
      {super.$joinBuilder});
  ColumnWithTypeConverterFilters<MyCustomObject?, MyCustomObject, String>
      get txt => $columnFilterWithTypeConverter($table.txt);
}

class $$PureDefaultsTableOrderingComposer
    extends OrderingComposer<_$TodoDb, $PureDefaultsTable> {
  $$PureDefaultsTableOrderingComposer(super.$db, super.$table,
      {super.$joinBuilder});
  ColumnOrderings<String> get txt => $columnOrdering($table.txt);
}

class $$PureDefaultsTableProcessedTableManager extends ProcessedTableManager<
    _$TodoDb,
    $PureDefaultsTable,
    PureDefault,
    $$PureDefaultsTableFilterComposer,
    $$PureDefaultsTableOrderingComposer,
    $$PureDefaultsTableProcessedTableManager,
    $$PureDefaultsTableInsertCompanionBuilder,
    $$PureDefaultsTableUpdateCompanionBuilder> {
  const $$PureDefaultsTableProcessedTableManager(super.$state);
}

typedef $$PureDefaultsTableInsertCompanionBuilder = PureDefaultsCompanion
    Function({
  Value<MyCustomObject?> txt,
  Value<int> rowid,
});
typedef $$PureDefaultsTableUpdateCompanionBuilder = PureDefaultsCompanion
    Function({
  Value<MyCustomObject?> txt,
  Value<int> rowid,
});

class $$PureDefaultsTableTableManager extends RootTableManager<
    _$TodoDb,
    $PureDefaultsTable,
    PureDefault,
    $$PureDefaultsTableFilterComposer,
    $$PureDefaultsTableOrderingComposer,
    $$PureDefaultsTableProcessedTableManager,
    $$PureDefaultsTableInsertCompanionBuilder,
    $$PureDefaultsTableUpdateCompanionBuilder> {
  $$PureDefaultsTableTableManager(_$TodoDb db, $PureDefaultsTable table)
      : super(TableManagerState(
            db: db,
            table: table,
            filteringComposer: $$PureDefaultsTableFilterComposer(db, table),
            orderingComposer: $$PureDefaultsTableOrderingComposer(db, table),
            getChildManagerBuilder: (p0) =>
                $$PureDefaultsTableProcessedTableManager(p0),
            getUpdateCompanionBuilder: ({
              Value<MyCustomObject?> txt = const Value.absent(),
              Value<int> rowid = const Value.absent(),
            }) =>
                PureDefaultsCompanion(
                  txt: txt,
                  rowid: rowid,
                ),
            getInsertCompanionBuilder: ({
              Value<MyCustomObject?> txt = const Value.absent(),
              Value<int> rowid = const Value.absent(),
            }) =>
                PureDefaultsCompanion.insert(
                  txt: txt,
                  rowid: rowid,
                )));
}

class $$WithCustomTypeTableFilterComposer
    extends FilterComposer<_$TodoDb, $WithCustomTypeTable> {
  $$WithCustomTypeTableFilterComposer(super.$db, super.$table,
      {super.$joinBuilder});
  ColumnFilters<UuidValue> get id => $columnFilter($table.id);
}

class $$WithCustomTypeTableOrderingComposer
    extends OrderingComposer<_$TodoDb, $WithCustomTypeTable> {
  $$WithCustomTypeTableOrderingComposer(super.$db, super.$table,
      {super.$joinBuilder});
  ColumnOrderings<UuidValue> get id => $columnOrdering($table.id);
}

class $$WithCustomTypeTableProcessedTableManager extends ProcessedTableManager<
    _$TodoDb,
    $WithCustomTypeTable,
    WithCustomTypeData,
    $$WithCustomTypeTableFilterComposer,
    $$WithCustomTypeTableOrderingComposer,
    $$WithCustomTypeTableProcessedTableManager,
    $$WithCustomTypeTableInsertCompanionBuilder,
    $$WithCustomTypeTableUpdateCompanionBuilder> {
  const $$WithCustomTypeTableProcessedTableManager(super.$state);
}

typedef $$WithCustomTypeTableInsertCompanionBuilder = WithCustomTypeCompanion
    Function({
  required UuidValue id,
  Value<int> rowid,
});
typedef $$WithCustomTypeTableUpdateCompanionBuilder = WithCustomTypeCompanion
    Function({
  Value<UuidValue> id,
  Value<int> rowid,
});

class $$WithCustomTypeTableTableManager extends RootTableManager<
    _$TodoDb,
    $WithCustomTypeTable,
    WithCustomTypeData,
    $$WithCustomTypeTableFilterComposer,
    $$WithCustomTypeTableOrderingComposer,
    $$WithCustomTypeTableProcessedTableManager,
    $$WithCustomTypeTableInsertCompanionBuilder,
    $$WithCustomTypeTableUpdateCompanionBuilder> {
  $$WithCustomTypeTableTableManager(_$TodoDb db, $WithCustomTypeTable table)
      : super(TableManagerState(
            db: db,
            table: table,
            filteringComposer: $$WithCustomTypeTableFilterComposer(db, table),
            orderingComposer: $$WithCustomTypeTableOrderingComposer(db, table),
            getChildManagerBuilder: (p0) =>
                $$WithCustomTypeTableProcessedTableManager(p0),
            getUpdateCompanionBuilder: ({
              Value<UuidValue> id = const Value.absent(),
              Value<int> rowid = const Value.absent(),
            }) =>
                WithCustomTypeCompanion(
                  id: id,
                  rowid: rowid,
                ),
            getInsertCompanionBuilder: ({
              required UuidValue id,
              Value<int> rowid = const Value.absent(),
            }) =>
                WithCustomTypeCompanion.insert(
                  id: id,
                  rowid: rowid,
                )));
}

class $$TableWithEveryColumnTypeTableFilterComposer
    extends FilterComposer<_$TodoDb, $TableWithEveryColumnTypeTable> {
  $$TableWithEveryColumnTypeTableFilterComposer(super.$db, super.$table,
      {super.$joinBuilder});
  ColumnWithTypeConverterFilters<RowId, RowId, int> get id =>
      $columnFilterWithTypeConverter($table.id);
  ColumnFilters<bool> get aBool => $columnFilter($table.aBool);
  ColumnFilters<DateTime> get aDateTime => $columnFilter($table.aDateTime);
  ColumnFilters<String> get aText => $columnFilter($table.aText);
  ColumnFilters<int> get anInt => $columnFilter($table.anInt);
  ColumnFilters<BigInt> get anInt64 => $columnFilter($table.anInt64);
  ColumnFilters<double> get aReal => $columnFilter($table.aReal);
  ColumnFilters<Uint8List> get aBlob => $columnFilter($table.aBlob);
  ColumnWithTypeConverterFilters<TodoStatus?, TodoStatus, int> get anIntEnum =>
      $columnFilterWithTypeConverter($table.anIntEnum);
  ColumnWithTypeConverterFilters<MyCustomObject?, MyCustomObject, String>
      get aTextWithConverter =>
          $columnFilterWithTypeConverter($table.aTextWithConverter);
}

class $$TableWithEveryColumnTypeTableOrderingComposer
    extends OrderingComposer<_$TodoDb, $TableWithEveryColumnTypeTable> {
  $$TableWithEveryColumnTypeTableOrderingComposer(super.$db, super.$table,
      {super.$joinBuilder});
  ColumnOrderings<int> get id => $columnOrdering($table.id);
  ColumnOrderings<bool> get aBool => $columnOrdering($table.aBool);
  ColumnOrderings<DateTime> get aDateTime => $columnOrdering($table.aDateTime);
  ColumnOrderings<String> get aText => $columnOrdering($table.aText);
  ColumnOrderings<int> get anInt => $columnOrdering($table.anInt);
  ColumnOrderings<BigInt> get anInt64 => $columnOrdering($table.anInt64);
  ColumnOrderings<double> get aReal => $columnOrdering($table.aReal);
  ColumnOrderings<Uint8List> get aBlob => $columnOrdering($table.aBlob);
  ColumnOrderings<int> get anIntEnum => $columnOrdering($table.anIntEnum);
  ColumnOrderings<String> get aTextWithConverter =>
      $columnOrdering($table.aTextWithConverter);
}

class $$TableWithEveryColumnTypeTableProcessedTableManager
    extends ProcessedTableManager<
        _$TodoDb,
        $TableWithEveryColumnTypeTable,
        TableWithEveryColumnTypeData,
        $$TableWithEveryColumnTypeTableFilterComposer,
        $$TableWithEveryColumnTypeTableOrderingComposer,
        $$TableWithEveryColumnTypeTableProcessedTableManager,
        $$TableWithEveryColumnTypeTableInsertCompanionBuilder,
        $$TableWithEveryColumnTypeTableUpdateCompanionBuilder> {
  const $$TableWithEveryColumnTypeTableProcessedTableManager(super.$state);
}

typedef $$TableWithEveryColumnTypeTableInsertCompanionBuilder
    = TableWithEveryColumnTypeCompanion Function({
  Value<RowId> id,
  Value<bool?> aBool,
  Value<DateTime?> aDateTime,
  Value<String?> aText,
  Value<int?> anInt,
  Value<BigInt?> anInt64,
  Value<double?> aReal,
  Value<Uint8List?> aBlob,
  Value<TodoStatus?> anIntEnum,
  Value<MyCustomObject?> aTextWithConverter,
});
typedef $$TableWithEveryColumnTypeTableUpdateCompanionBuilder
    = TableWithEveryColumnTypeCompanion Function({
  Value<RowId> id,
  Value<bool?> aBool,
  Value<DateTime?> aDateTime,
  Value<String?> aText,
  Value<int?> anInt,
  Value<BigInt?> anInt64,
  Value<double?> aReal,
  Value<Uint8List?> aBlob,
  Value<TodoStatus?> anIntEnum,
  Value<MyCustomObject?> aTextWithConverter,
});

class $$TableWithEveryColumnTypeTableTableManager extends RootTableManager<
    _$TodoDb,
    $TableWithEveryColumnTypeTable,
    TableWithEveryColumnTypeData,
    $$TableWithEveryColumnTypeTableFilterComposer,
    $$TableWithEveryColumnTypeTableOrderingComposer,
    $$TableWithEveryColumnTypeTableProcessedTableManager,
    $$TableWithEveryColumnTypeTableInsertCompanionBuilder,
    $$TableWithEveryColumnTypeTableUpdateCompanionBuilder> {
  $$TableWithEveryColumnTypeTableTableManager(
      _$TodoDb db, $TableWithEveryColumnTypeTable table)
      : super(TableManagerState(
            db: db,
            table: table,
            filteringComposer:
                $$TableWithEveryColumnTypeTableFilterComposer(db, table),
            orderingComposer:
                $$TableWithEveryColumnTypeTableOrderingComposer(db, table),
            getChildManagerBuilder: (p0) =>
                $$TableWithEveryColumnTypeTableProcessedTableManager(p0),
            getUpdateCompanionBuilder: ({
              Value<RowId> id = const Value.absent(),
              Value<bool?> aBool = const Value.absent(),
              Value<DateTime?> aDateTime = const Value.absent(),
              Value<String?> aText = const Value.absent(),
              Value<int?> anInt = const Value.absent(),
              Value<BigInt?> anInt64 = const Value.absent(),
              Value<double?> aReal = const Value.absent(),
              Value<Uint8List?> aBlob = const Value.absent(),
              Value<TodoStatus?> anIntEnum = const Value.absent(),
              Value<MyCustomObject?> aTextWithConverter = const Value.absent(),
            }) =>
                TableWithEveryColumnTypeCompanion(
                  id: id,
                  aBool: aBool,
                  aDateTime: aDateTime,
                  aText: aText,
                  anInt: anInt,
                  anInt64: anInt64,
                  aReal: aReal,
                  aBlob: aBlob,
                  anIntEnum: anIntEnum,
                  aTextWithConverter: aTextWithConverter,
                ),
            getInsertCompanionBuilder: ({
              Value<RowId> id = const Value.absent(),
              Value<bool?> aBool = const Value.absent(),
              Value<DateTime?> aDateTime = const Value.absent(),
              Value<String?> aText = const Value.absent(),
              Value<int?> anInt = const Value.absent(),
              Value<BigInt?> anInt64 = const Value.absent(),
              Value<double?> aReal = const Value.absent(),
              Value<Uint8List?> aBlob = const Value.absent(),
              Value<TodoStatus?> anIntEnum = const Value.absent(),
              Value<MyCustomObject?> aTextWithConverter = const Value.absent(),
            }) =>
                TableWithEveryColumnTypeCompanion.insert(
                  id: id,
                  aBool: aBool,
                  aDateTime: aDateTime,
                  aText: aText,
                  anInt: anInt,
                  anInt64: anInt64,
                  aReal: aReal,
                  aBlob: aBlob,
                  anIntEnum: anIntEnum,
                  aTextWithConverter: aTextWithConverter,
                )));
}

class $$BookClubTableFilterComposer
    extends FilterComposer<_$TodoDb, $BookClubTable> {
  $$BookClubTableFilterComposer(super.$db, super.$table, {super.$joinBuilder});
  ColumnFilters<int> get id => $columnFilter($table.id);
  ColumnFilters<String> get name => $columnFilter($table.name);
  ColumnAggregate personRefs(
      ComposableFilter Function($$PersonTableFilterComposer f) f) {
    final $$PersonTableFilterComposer composer = $$PersonTableFilterComposer(
        $db, $db.person,
        $joinBuilder: $buildJoinForTable(
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.person,
            getReferencedColumn: (t) => t.club));
    return ColumnAggregate(f(composer));
  }
}

class $$BookClubTableOrderingComposer
    extends OrderingComposer<_$TodoDb, $BookClubTable> {
  $$BookClubTableOrderingComposer(super.$db, super.$table,
      {super.$joinBuilder});
  ColumnOrderings<int> get id => $columnOrdering($table.id);
  ColumnOrderings<String> get name => $columnOrdering($table.name);
}

class $$BookClubTableProcessedTableManager extends ProcessedTableManager<
    _$TodoDb,
    $BookClubTable,
    BookClubData,
    $$BookClubTableFilterComposer,
    $$BookClubTableOrderingComposer,
    $$BookClubTableProcessedTableManager,
    $$BookClubTableInsertCompanionBuilder,
    $$BookClubTableUpdateCompanionBuilder> {
  const $$BookClubTableProcessedTableManager(super.$state);
}

typedef $$BookClubTableInsertCompanionBuilder = BookClubCompanion Function({
  Value<int> id,
  Value<String?> name,
});
typedef $$BookClubTableUpdateCompanionBuilder = BookClubCompanion Function({
  Value<int> id,
  Value<String?> name,
});

class $$BookClubTableTableManager extends RootTableManager<
    _$TodoDb,
    $BookClubTable,
    BookClubData,
    $$BookClubTableFilterComposer,
    $$BookClubTableOrderingComposer,
    $$BookClubTableProcessedTableManager,
    $$BookClubTableInsertCompanionBuilder,
    $$BookClubTableUpdateCompanionBuilder> {
  $$BookClubTableTableManager(_$TodoDb db, $BookClubTable table)
      : super(TableManagerState(
            db: db,
            table: table,
            filteringComposer: $$BookClubTableFilterComposer(db, table),
            orderingComposer: $$BookClubTableOrderingComposer(db, table),
            getChildManagerBuilder: (p0) =>
                $$BookClubTableProcessedTableManager(p0),
            getUpdateCompanionBuilder: ({
              Value<int> id = const Value.absent(),
              Value<String?> name = const Value.absent(),
            }) =>
                BookClubCompanion(
                  id: id,
                  name: name,
                ),
            getInsertCompanionBuilder: ({
              Value<int> id = const Value.absent(),
              Value<String?> name = const Value.absent(),
            }) =>
                BookClubCompanion.insert(
                  id: id,
                  name: name,
                )));
}

class $$PersonTableFilterComposer
    extends FilterComposer<_$TodoDb, $PersonTable> {
  $$PersonTableFilterComposer(super.$db, super.$table, {super.$joinBuilder});
  ColumnFilters<int> get id => $columnFilter($table.id);
  ColumnFilters<String> get name => $columnFilter($table.name);
  $$BookClubTableFilterComposer get club {
    final $$BookClubTableFilterComposer composer =
        $$BookClubTableFilterComposer($db, $db.bookClub,
            $joinBuilder: $buildJoinForTable(
                getCurrentColumn: (t) => t.club,
                referencedTable: $db.bookClub,
                getReferencedColumn: (t) => t.id));
    return composer;
  }

  ColumnAggregate writtenBooks(
      ComposableFilter Function($$BookTableFilterComposer f) f) {
    final $$BookTableFilterComposer composer = $$BookTableFilterComposer(
        $db, $db.book,
        $joinBuilder: $buildJoinForTable(
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.book,
            getReferencedColumn: (t) => t.author));
    return ColumnAggregate(f(composer));
  }

  ColumnAggregate publishedBooks(
      ComposableFilter Function($$BookTableFilterComposer f) f) {
    final $$BookTableFilterComposer composer = $$BookTableFilterComposer(
        $db, $db.book,
        $joinBuilder: $buildJoinForTable(
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.book,
            getReferencedColumn: (t) => t.publisher));
    return ColumnAggregate(f(composer));
  }
}

class $$PersonTableOrderingComposer
    extends OrderingComposer<_$TodoDb, $PersonTable> {
  $$PersonTableOrderingComposer(super.$db, super.$table, {super.$joinBuilder});
  ColumnOrderings<int> get id => $columnOrdering($table.id);
  ColumnOrderings<String> get name => $columnOrdering($table.name);
  $$BookClubTableOrderingComposer get club =>
      $$BookClubTableOrderingComposer($db, $db.bookClub,
          $joinBuilder: $buildJoinForTable(
              getCurrentColumn: (t) => t.club,
              referencedTable: $db.bookClub,
              getReferencedColumn: (t) => t.id));
}

class $$PersonTableProcessedTableManager extends ProcessedTableManager<
    _$TodoDb,
    $PersonTable,
    PersonData,
    $$PersonTableFilterComposer,
    $$PersonTableOrderingComposer,
    $$PersonTableProcessedTableManager,
    $$PersonTableInsertCompanionBuilder,
    $$PersonTableUpdateCompanionBuilder> {
  const $$PersonTableProcessedTableManager(super.$state);
}

typedef $$PersonTableInsertCompanionBuilder = PersonCompanion Function({
  Value<int> id,
  Value<String?> name,
  Value<int?> club,
});
typedef $$PersonTableUpdateCompanionBuilder = PersonCompanion Function({
  Value<int> id,
  Value<String?> name,
  Value<int?> club,
});

class $$PersonTableTableManager extends RootTableManager<
    _$TodoDb,
    $PersonTable,
    PersonData,
    $$PersonTableFilterComposer,
    $$PersonTableOrderingComposer,
    $$PersonTableProcessedTableManager,
    $$PersonTableInsertCompanionBuilder,
    $$PersonTableUpdateCompanionBuilder> {
  $$PersonTableTableManager(_$TodoDb db, $PersonTable table)
      : super(TableManagerState(
            db: db,
            table: table,
            filteringComposer: $$PersonTableFilterComposer(db, table),
            orderingComposer: $$PersonTableOrderingComposer(db, table),
            getChildManagerBuilder: (p0) =>
                $$PersonTableProcessedTableManager(p0),
            getUpdateCompanionBuilder: ({
              Value<int> id = const Value.absent(),
              Value<String?> name = const Value.absent(),
              Value<int?> club = const Value.absent(),
            }) =>
                PersonCompanion(
                  id: id,
                  name: name,
                  club: club,
                ),
            getInsertCompanionBuilder: ({
              Value<int> id = const Value.absent(),
              Value<String?> name = const Value.absent(),
              Value<int?> club = const Value.absent(),
            }) =>
                PersonCompanion.insert(
                  id: id,
                  name: name,
                  club: club,
                )));
}

class $$BookTableFilterComposer extends FilterComposer<_$TodoDb, $BookTable> {
  $$BookTableFilterComposer(super.$db, super.$table, {super.$joinBuilder});
  ColumnFilters<int> get id => $columnFilter($table.id);
  ColumnFilters<String> get title => $columnFilter($table.title);
  $$PersonTableFilterComposer get author {
    final $$PersonTableFilterComposer composer = $$PersonTableFilterComposer(
        $db, $db.person,
        $joinBuilder: $buildJoinForTable(
            getCurrentColumn: (t) => t.author,
            referencedTable: $db.person,
            getReferencedColumn: (t) => t.id));
    return composer;
  }

  $$PersonTableFilterComposer get publisher {
    final $$PersonTableFilterComposer composer = $$PersonTableFilterComposer(
        $db, $db.person,
        $joinBuilder: $buildJoinForTable(
            getCurrentColumn: (t) => t.publisher,
            referencedTable: $db.person,
            getReferencedColumn: (t) => t.id));
    return composer;
  }
}

class $$BookTableOrderingComposer
    extends OrderingComposer<_$TodoDb, $BookTable> {
  $$BookTableOrderingComposer(super.$db, super.$table, {super.$joinBuilder});
  ColumnOrderings<int> get id => $columnOrdering($table.id);
  ColumnOrderings<String> get title => $columnOrdering($table.title);
  $$PersonTableOrderingComposer get author =>
      $$PersonTableOrderingComposer($db, $db.person,
          $joinBuilder: $buildJoinForTable(
              getCurrentColumn: (t) => t.author,
              referencedTable: $db.person,
              getReferencedColumn: (t) => t.id));
  $$PersonTableOrderingComposer get publisher =>
      $$PersonTableOrderingComposer($db, $db.person,
          $joinBuilder: $buildJoinForTable(
              getCurrentColumn: (t) => t.publisher,
              referencedTable: $db.person,
              getReferencedColumn: (t) => t.id));
}

class $$BookTableProcessedTableManager extends ProcessedTableManager<
    _$TodoDb,
    $BookTable,
    BookData,
    $$BookTableFilterComposer,
    $$BookTableOrderingComposer,
    $$BookTableProcessedTableManager,
    $$BookTableInsertCompanionBuilder,
    $$BookTableUpdateCompanionBuilder> {
  const $$BookTableProcessedTableManager(super.$state);
}

typedef $$BookTableInsertCompanionBuilder = BookCompanion Function({
  Value<int> id,
  Value<String?> title,
  Value<int?> author,
  Value<int?> publisher,
});
typedef $$BookTableUpdateCompanionBuilder = BookCompanion Function({
  Value<int> id,
  Value<String?> title,
  Value<int?> author,
  Value<int?> publisher,
});

class $$BookTableTableManager extends RootTableManager<
    _$TodoDb,
    $BookTable,
    BookData,
    $$BookTableFilterComposer,
    $$BookTableOrderingComposer,
    $$BookTableProcessedTableManager,
    $$BookTableInsertCompanionBuilder,
    $$BookTableUpdateCompanionBuilder> {
  $$BookTableTableManager(_$TodoDb db, $BookTable table)
      : super(TableManagerState(
            db: db,
            table: table,
            filteringComposer: $$BookTableFilterComposer(db, table),
            orderingComposer: $$BookTableOrderingComposer(db, table),
            getChildManagerBuilder: (p0) =>
                $$BookTableProcessedTableManager(p0),
            getUpdateCompanionBuilder: ({
              Value<int> id = const Value.absent(),
              Value<String?> title = const Value.absent(),
              Value<int?> author = const Value.absent(),
              Value<int?> publisher = const Value.absent(),
            }) =>
                BookCompanion(
                  id: id,
                  title: title,
                  author: author,
                  publisher: publisher,
                ),
            getInsertCompanionBuilder: ({
              Value<int> id = const Value.absent(),
              Value<String?> title = const Value.absent(),
              Value<int?> author = const Value.absent(),
              Value<int?> publisher = const Value.absent(),
            }) =>
                BookCompanion.insert(
                  id: id,
                  title: title,
                  author: author,
                  publisher: publisher,
                )));
}

class _$TodoDbManager {
  final _$TodoDb _db;
  _$TodoDbManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$TodosTableTableTableManager get todosTable =>
      $$TodosTableTableTableManager(_db, _db.todosTable);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$SharedTodosTableTableManager get sharedTodos =>
      $$SharedTodosTableTableManager(_db, _db.sharedTodos);
  $$PureDefaultsTableTableManager get pureDefaults =>
      $$PureDefaultsTableTableManager(_db, _db.pureDefaults);
  $$WithCustomTypeTableTableManager get withCustomType =>
      $$WithCustomTypeTableTableManager(_db, _db.withCustomType);
  $$TableWithEveryColumnTypeTableTableManager get tableWithEveryColumnType =>
      $$TableWithEveryColumnTypeTableTableManager(
          _db, _db.tableWithEveryColumnType);
  $$BookClubTableTableManager get bookClub =>
      $$BookClubTableTableManager(_db, _db.bookClub);
  $$PersonTableTableManager get person =>
      $$PersonTableTableManager(_db, _db.person);
  $$BookTableTableManager get book => $$BookTableTableManager(_db, _db.book);
}

class AllTodosWithCategoryResult extends CustomResultSet {
  final RowId id;
  final String? title;
  final String content;
  final DateTime? targetDate;
  final int? category;
  final TodoStatus? status;
  final RowId catId;
  final String catDesc;
  AllTodosWithCategoryResult({
    required QueryRow row,
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

mixin _$SomeDaoMixin on DatabaseAccessor<TodoDb> {
  $UsersTable get users => attachedDatabase.users;
  $CategoriesTable get categories => attachedDatabase.categories;
  $TodosTableTable get todosTable => attachedDatabase.todosTable;
  $SharedTodosTable get sharedTodos => attachedDatabase.sharedTodos;
  $TodoWithCategoryViewView get todoWithCategoryView =>
      attachedDatabase.todoWithCategoryView;
  Selectable<TodoEntry> todosForUser({required RowId user}) {
    return customSelect(
        'SELECT t.* FROM todos AS t INNER JOIN shared_todos AS st ON st.todo = t.id INNER JOIN users AS u ON u.id = st.user WHERE u.id = ?1',
        variables: [
          Variable<int>($UsersTable.$converterid.toSql(user))
        ],
        readsFrom: {
          todosTable,
          sharedTodos,
          users,
        }).asyncMap(todosTable.mapFromRow);
  }
}
