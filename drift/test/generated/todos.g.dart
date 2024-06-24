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
  late final GeneratedColumnWithTypeConverter<RowId?, int> category =
      GeneratedColumn<int>('category', aliasedName, true,
              type: DriftSqlType.int,
              requiredDuringInsert: false,
              defaultConstraints: GeneratedColumn.constraintIsAlways(
                  'REFERENCES categories (id) DEFERRABLE INITIALLY DEFERRED'))
          .withConverter<RowId?>($TodosTableTable.$convertercategoryn);
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
    context.handle(_categoryMeta, const VerificationResult.success());
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
      category: $TodosTableTable.$convertercategoryn.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}category'])),
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
  static JsonTypeConverter2<RowId, int, int> $convertercategory =
      TypeConverter.extensionType<RowId, int>();
  static JsonTypeConverter2<RowId?, int?, int?> $convertercategoryn =
      JsonTypeConverter2.asNullable($convertercategory);
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
      targetDate: serializer.fromJson<DateTime?>(json['target_date']),
      category: $TodosTableTable.$convertercategoryn
          .fromJson(serializer.fromJson<int?>(json['category'])),
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
    with TableInfo<$DepartmentTable, DepartmentData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DepartmentTable(this.attachedDatabase, [this._alias]);
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
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'department';
  @override
  VerificationContext validateIntegrity(Insertable<DepartmentData> instance,
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
  DepartmentData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DepartmentData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name']),
    );
  }

  @override
  $DepartmentTable createAlias(String alias) {
    return $DepartmentTable(attachedDatabase, alias);
  }
}

class DepartmentData extends DataClass implements Insertable<DepartmentData> {
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

class $ProductTable extends Product with TableInfo<$ProductTable, ProductData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductTable(this.attachedDatabase, [this._alias]);
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
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _departmentMeta =
      const VerificationMeta('department');
  @override
  late final GeneratedColumn<int> department = GeneratedColumn<int>(
      'department', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES department (id)'));
  @override
  List<GeneratedColumn> get $columns => [id, name, department];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product';
  @override
  VerificationContext validateIntegrity(Insertable<ProductData> instance,
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
    if (data.containsKey('department')) {
      context.handle(
          _departmentMeta,
          department.isAcceptableOrUnknown(
              data['department']!, _departmentMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name']),
      department: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}department']),
    );
  }

  @override
  $ProductTable createAlias(String alias) {
    return $ProductTable(attachedDatabase, alias);
  }
}

class ProductData extends DataClass implements Insertable<ProductData> {
  final int id;
  final String? name;
  final int? department;
  const ProductData({required this.id, this.name, this.department});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
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
      id: Value(id),
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
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
      department: serializer.fromJson<int?>(json['department']),
    );
  }
  factory ProductData.fromJsonString(String encodedJson,
          {ValueSerializer? serializer}) =>
      ProductData.fromJson(
          DataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String?>(name),
      'department': serializer.toJson<int?>(department),
    };
  }

  ProductData copyWith(
          {int? id,
          Value<String?> name = const Value.absent(),
          Value<int?> department = const Value.absent()}) =>
      ProductData(
        id: id ?? this.id,
        name: name.present ? name.value : this.name,
        department: department.present ? department.value : this.department,
      );
  ProductData copyWithCompanion(ProductCompanion data) {
    return ProductData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      department:
          data.department.present ? data.department.value : this.department,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('department: $department')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, department);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductData &&
          other.id == this.id &&
          other.name == this.name &&
          other.department == this.department);
}

class ProductCompanion extends UpdateCompanion<ProductData> {
  final Value<int> id;
  final Value<String?> name;
  final Value<int?> department;
  const ProductCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.department = const Value.absent(),
  });
  ProductCompanion.insert({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.department = const Value.absent(),
  });
  static Insertable<ProductData> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? department,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (department != null) 'department': department,
    });
  }

  ProductCompanion copyWith(
      {Value<int>? id, Value<String?>? name, Value<int?>? department}) {
    return ProductCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      department: department ?? this.department,
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
    if (department.present) {
      map['department'] = Variable<int>(department.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('department: $department')
          ..write(')'))
        .toString();
  }
}

class $StoreTable extends Store with TableInfo<$StoreTable, StoreData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoreTable(this.attachedDatabase, [this._alias]);
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
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'store';
  @override
  VerificationContext validateIntegrity(Insertable<StoreData> instance,
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
  StoreData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoreData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name']),
    );
  }

  @override
  $StoreTable createAlias(String alias) {
    return $StoreTable(attachedDatabase, alias);
  }
}

class StoreData extends DataClass implements Insertable<StoreData> {
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

class $ListingTable extends Listing with TableInfo<$ListingTable, ListingData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ListingTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _productMeta =
      const VerificationMeta('product');
  @override
  late final GeneratedColumn<int> product = GeneratedColumn<int>(
      'product', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES product (id)'));
  static const VerificationMeta _storeMeta = const VerificationMeta('store');
  @override
  late final GeneratedColumn<int> store = GeneratedColumn<int>(
      'store', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES store (id)'));
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
      'price', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [id, product, store, price];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'listing';
  @override
  VerificationContext validateIntegrity(Insertable<ListingData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('product')) {
      context.handle(_productMeta,
          product.isAcceptableOrUnknown(data['product']!, _productMeta));
    }
    if (data.containsKey('store')) {
      context.handle(
          _storeMeta, store.isAcceptableOrUnknown(data['store']!, _storeMeta));
    }
    if (data.containsKey('price')) {
      context.handle(
          _priceMeta, price.isAcceptableOrUnknown(data['price']!, _priceMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ListingData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ListingData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      product: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}product']),
      store: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}store']),
      price: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}price']),
    );
  }

  @override
  $ListingTable createAlias(String alias) {
    return $ListingTable(attachedDatabase, alias);
  }
}

class ListingData extends DataClass implements Insertable<ListingData> {
  final int id;
  final int? product;
  final int? store;
  final double? price;
  const ListingData({required this.id, this.product, this.store, this.price});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || product != null) {
      map['product'] = Variable<int>(product);
    }
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
      product: product == null && nullToAbsent
          ? const Value.absent()
          : Value(product),
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
      product: serializer.fromJson<int?>(json['product']),
      store: serializer.fromJson<int?>(json['store']),
      price: serializer.fromJson<double?>(json['price']),
    );
  }
  factory ListingData.fromJsonString(String encodedJson,
          {ValueSerializer? serializer}) =>
      ListingData.fromJson(
          DataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'product': serializer.toJson<int?>(product),
      'store': serializer.toJson<int?>(store),
      'price': serializer.toJson<double?>(price),
    };
  }

  ListingData copyWith(
          {int? id,
          Value<int?> product = const Value.absent(),
          Value<int?> store = const Value.absent(),
          Value<double?> price = const Value.absent()}) =>
      ListingData(
        id: id ?? this.id,
        product: product.present ? product.value : this.product,
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
  final Value<int?> product;
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
    this.product = const Value.absent(),
    this.store = const Value.absent(),
    this.price = const Value.absent(),
  });
  static Insertable<ListingData> custom({
    Expression<int>? id,
    Expression<int>? product,
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
      Value<int?>? product,
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
      map['product'] = Variable<int>(product.value);
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
  $TodoDbManager get managers => $TodoDbManager(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $TodosTableTable todosTable = $TodosTableTable(this);
  late final $UsersTable users = $UsersTable(this);
  late final $SharedTodosTable sharedTodos = $SharedTodosTable(this);
  late final $TableWithoutPKTable tableWithoutPK = $TableWithoutPKTable(this);
  late final $PureDefaultsTable pureDefaults = $PureDefaultsTable(this);
  late final $WithCustomTypeTable withCustomType = $WithCustomTypeTable(this);
  late final $TableWithEveryColumnTypeTable tableWithEveryColumnType =
      $TableWithEveryColumnTypeTable(this);
  late final $DepartmentTable department = $DepartmentTable(this);
  late final $ProductTable product = $ProductTable(this);
  late final $StoreTable store = $StoreTable(this);
  late final $ListingTable listing = $ListingTable(this);
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
          category: NullAwareTypeConverter.wrapFromSql(
              $TodosTableTable.$convertercategory,
              row.readNullable<int>('category')),
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
        department,
        product,
        store,
        listing,
        categoryTodoCountView,
        todoWithCategoryView
      ];
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
    $$CategoriesTableInsertCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    $$CategoriesTableWithReferences,
    Category> {
  $$CategoriesTableTableManager(_$TodoDb db, $CategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$CategoriesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$CategoriesTableOrderingComposer(ComposerState(db, table)),
          createUpdateCompanionCallback: ({
            Value<RowId> id = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<CategoryPriority> priority = const Value.absent(),
          }) =>
              CategoriesCompanion(
            id: id,
            description: description,
            priority: priority,
          ),
          dataclassMapper: (p0) async =>
              p0.map((e) => $$CategoriesTableWithReferences(db, e)).toList(),
          createInsertCompanionCallback: ({
            Value<RowId> id = const Value.absent(),
            required String description,
            Value<CategoryPriority> priority = const Value.absent(),
          }) =>
              CategoriesCompanion.insert(
            id: id,
            description: description,
            priority: priority,
          ),
        ));
}

typedef $$CategoriesTableProcessedTableManager = ProcessedTableManager<
    _$TodoDb,
    $CategoriesTable,
    Category,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableInsertCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    $$CategoriesTableWithReferences,
    Category>;

class $$CategoriesTableFilterComposer
    extends FilterComposer<_$TodoDb, $CategoriesTable> {
  $$CategoriesTableFilterComposer(super.$state);
  ColumnWithTypeConverterFilters<RowId, RowId, int> get id =>
      $state.composableBuilder(
          column: $state.table.id,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnFilters<String> get description => $state.composableBuilder(
      column: $state.table.description,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<CategoryPriority, CategoryPriority, int>
      get priority => $state.composableBuilder(
          column: $state.table.priority,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnFilters<String> get descriptionInUpperCase => $state.composableBuilder(
      column: $state.table.descriptionInUpperCase,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ComposableFilter todos(
      ComposableFilter Function($$TodosTableTableFilterComposer f) f) {
    final $$TodosTableTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.todosTable,
        getReferencedColumn: (t) => t.category,
        builder: (joinBuilder, parentComposers) =>
            $$TodosTableTableFilterComposer(ComposerState($state.db,
                $state.db.todosTable, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends OrderingComposer<_$TodoDb, $CategoriesTable> {
  $$CategoriesTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get description => $state.composableBuilder(
      column: $state.table.description,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get priority => $state.composableBuilder(
      column: $state.table.priority,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get descriptionInUpperCase =>
      $state.composableBuilder(
          column: $state.table.descriptionInUpperCase,
          builder: (column, joinBuilders) =>
              ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$CategoriesTableWithReferences {
  // ignore: unused_field
  final _$TodoDb _db;
  final Category category;
  $$CategoriesTableWithReferences(this._db, this.category);

  $$TodosTableTableProcessedTableManager get todos {
    return $$TodosTableTableTableManager(_db, _db.todosTable)
        .filter((f) => f.category.id(category.id));
  }
}

typedef $$TodosTableTableInsertCompanionBuilder = TodosTableCompanion Function({
  Value<RowId> id,
  Value<String?> title,
  required String content,
  Value<DateTime?> targetDate,
  Value<RowId?> category,
  Value<TodoStatus?> status,
});
typedef $$TodosTableTableUpdateCompanionBuilder = TodosTableCompanion Function({
  Value<RowId> id,
  Value<String?> title,
  Value<String> content,
  Value<DateTime?> targetDate,
  Value<RowId?> category,
  Value<TodoStatus?> status,
});

class $$TodosTableTableTableManager extends RootTableManager<
    _$TodoDb,
    $TodosTableTable,
    TodoEntry,
    $$TodosTableTableFilterComposer,
    $$TodosTableTableOrderingComposer,
    $$TodosTableTableInsertCompanionBuilder,
    $$TodosTableTableUpdateCompanionBuilder,
    $$TodosTableTableWithReferences,
    TodoEntry> {
  $$TodosTableTableTableManager(_$TodoDb db, $TodosTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$TodosTableTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$TodosTableTableOrderingComposer(ComposerState(db, table)),
          createUpdateCompanionCallback: ({
            Value<RowId> id = const Value.absent(),
            Value<String?> title = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<DateTime?> targetDate = const Value.absent(),
            Value<RowId?> category = const Value.absent(),
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
          dataclassMapper: (p0) async =>
              p0.map((e) => $$TodosTableTableWithReferences(db, e)).toList(),
          createInsertCompanionCallback: ({
            Value<RowId> id = const Value.absent(),
            Value<String?> title = const Value.absent(),
            required String content,
            Value<DateTime?> targetDate = const Value.absent(),
            Value<RowId?> category = const Value.absent(),
            Value<TodoStatus?> status = const Value.absent(),
          }) =>
              TodosTableCompanion.insert(
            id: id,
            title: title,
            content: content,
            targetDate: targetDate,
            category: category,
            status: status,
          ),
        ));
}

typedef $$TodosTableTableProcessedTableManager = ProcessedTableManager<
    _$TodoDb,
    $TodosTableTable,
    TodoEntry,
    $$TodosTableTableFilterComposer,
    $$TodosTableTableOrderingComposer,
    $$TodosTableTableInsertCompanionBuilder,
    $$TodosTableTableUpdateCompanionBuilder,
    $$TodosTableTableWithReferences,
    TodoEntry>;

class $$TodosTableTableFilterComposer
    extends FilterComposer<_$TodoDb, $TodosTableTable> {
  $$TodosTableTableFilterComposer(super.$state);
  ColumnWithTypeConverterFilters<RowId, RowId, int> get id =>
      $state.composableBuilder(
          column: $state.table.id,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnFilters<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get content => $state.composableBuilder(
      column: $state.table.content,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get targetDate => $state.composableBuilder(
      column: $state.table.targetDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<TodoStatus?, TodoStatus, String> get status =>
      $state.composableBuilder(
          column: $state.table.status,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  $$CategoriesTableFilterComposer get category {
    final $$CategoriesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.category,
        referencedTable: $state.db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$CategoriesTableFilterComposer(ComposerState($state.db,
                $state.db.categories, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$TodosTableTableOrderingComposer
    extends OrderingComposer<_$TodoDb, $TodosTableTable> {
  $$TodosTableTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get content => $state.composableBuilder(
      column: $state.table.content,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get targetDate => $state.composableBuilder(
      column: $state.table.targetDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$CategoriesTableOrderingComposer get category {
    final $$CategoriesTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.category,
        referencedTable: $state.db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$CategoriesTableOrderingComposer(ComposerState($state.db,
                $state.db.categories, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$TodosTableTableWithReferences {
  // ignore: unused_field
  final _$TodoDb _db;
  final TodoEntry todoEntry;
  $$TodosTableTableWithReferences(this._db, this.todoEntry);

  $$CategoriesTableProcessedTableManager? get category {
    if (todoEntry.category == null) return null;
    return $$CategoriesTableTableManager(_db, _db.categories)
        .filter((f) => f.id(todoEntry.category!));
  }
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
    $$UsersTableInsertCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    $$UsersTableWithReferences,
    User> {
  $$UsersTableTableManager(_$TodoDb db, $UsersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$UsersTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$UsersTableOrderingComposer(ComposerState(db, table)),
          createUpdateCompanionCallback: ({
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
          dataclassMapper: (p0) async =>
              p0.map((e) => $$UsersTableWithReferences(db, e)).toList(),
          createInsertCompanionCallback: ({
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
          ),
        ));
}

typedef $$UsersTableProcessedTableManager = ProcessedTableManager<
    _$TodoDb,
    $UsersTable,
    User,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableInsertCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    $$UsersTableWithReferences,
    User>;

class $$UsersTableFilterComposer extends FilterComposer<_$TodoDb, $UsersTable> {
  $$UsersTableFilterComposer(super.$state);
  ColumnWithTypeConverterFilters<RowId, RowId, int> get id =>
      $state.composableBuilder(
          column: $state.table.id,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isAwesome => $state.composableBuilder(
      column: $state.table.isAwesome,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<Uint8List> get profilePicture => $state.composableBuilder(
      column: $state.table.profilePicture,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get creationTime => $state.composableBuilder(
      column: $state.table.creationTime,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$UsersTableOrderingComposer
    extends OrderingComposer<_$TodoDb, $UsersTable> {
  $$UsersTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isAwesome => $state.composableBuilder(
      column: $state.table.isAwesome,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<Uint8List> get profilePicture => $state.composableBuilder(
      column: $state.table.profilePicture,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get creationTime => $state.composableBuilder(
      column: $state.table.creationTime,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$UsersTableWithReferences {
  // ignore: unused_field
  final _$TodoDb _db;
  final User user;
  $$UsersTableWithReferences(this._db, this.user);
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
    $$SharedTodosTableInsertCompanionBuilder,
    $$SharedTodosTableUpdateCompanionBuilder,
    $$SharedTodosTableWithReferences,
    SharedTodo> {
  $$SharedTodosTableTableManager(_$TodoDb db, $SharedTodosTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$SharedTodosTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$SharedTodosTableOrderingComposer(ComposerState(db, table)),
          createUpdateCompanionCallback: ({
            Value<int> todo = const Value.absent(),
            Value<int> user = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SharedTodosCompanion(
            todo: todo,
            user: user,
            rowid: rowid,
          ),
          dataclassMapper: (p0) async =>
              p0.map((e) => $$SharedTodosTableWithReferences(db, e)).toList(),
          createInsertCompanionCallback: ({
            required int todo,
            required int user,
            Value<int> rowid = const Value.absent(),
          }) =>
              SharedTodosCompanion.insert(
            todo: todo,
            user: user,
            rowid: rowid,
          ),
        ));
}

typedef $$SharedTodosTableProcessedTableManager = ProcessedTableManager<
    _$TodoDb,
    $SharedTodosTable,
    SharedTodo,
    $$SharedTodosTableFilterComposer,
    $$SharedTodosTableOrderingComposer,
    $$SharedTodosTableInsertCompanionBuilder,
    $$SharedTodosTableUpdateCompanionBuilder,
    $$SharedTodosTableWithReferences,
    SharedTodo>;

class $$SharedTodosTableFilterComposer
    extends FilterComposer<_$TodoDb, $SharedTodosTable> {
  $$SharedTodosTableFilterComposer(super.$state);
  ColumnFilters<int> get todo => $state.composableBuilder(
      column: $state.table.todo,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get user => $state.composableBuilder(
      column: $state.table.user,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$SharedTodosTableOrderingComposer
    extends OrderingComposer<_$TodoDb, $SharedTodosTable> {
  $$SharedTodosTableOrderingComposer(super.$state);
  ColumnOrderings<int> get todo => $state.composableBuilder(
      column: $state.table.todo,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get user => $state.composableBuilder(
      column: $state.table.user,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$SharedTodosTableWithReferences {
  // ignore: unused_field
  final _$TodoDb _db;
  final SharedTodo sharedTodo;
  $$SharedTodosTableWithReferences(this._db, this.sharedTodo);
}

typedef $$TableWithoutPKTableInsertCompanionBuilder = TableWithoutPKCompanion
    Function({
  required int notReallyAnId,
  required double someFloat,
  Value<BigInt?> webSafeInt,
  Value<MyCustomObject> custom,
  Value<int> rowid,
});
typedef $$TableWithoutPKTableUpdateCompanionBuilder = TableWithoutPKCompanion
    Function({
  Value<int> notReallyAnId,
  Value<double> someFloat,
  Value<BigInt?> webSafeInt,
  Value<MyCustomObject> custom,
  Value<int> rowid,
});

class $$TableWithoutPKTableTableManager extends RootTableManager<
    _$TodoDb,
    $TableWithoutPKTable,
    CustomRowClass,
    $$TableWithoutPKTableFilterComposer,
    $$TableWithoutPKTableOrderingComposer,
    $$TableWithoutPKTableInsertCompanionBuilder,
    $$TableWithoutPKTableUpdateCompanionBuilder,
    $$TableWithoutPKTableWithReferences,
    CustomRowClass> {
  $$TableWithoutPKTableTableManager(_$TodoDb db, $TableWithoutPKTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$TableWithoutPKTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$TableWithoutPKTableOrderingComposer(ComposerState(db, table)),
          createUpdateCompanionCallback: ({
            Value<int> notReallyAnId = const Value.absent(),
            Value<double> someFloat = const Value.absent(),
            Value<BigInt?> webSafeInt = const Value.absent(),
            Value<MyCustomObject> custom = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TableWithoutPKCompanion(
            notReallyAnId: notReallyAnId,
            someFloat: someFloat,
            webSafeInt: webSafeInt,
            custom: custom,
            rowid: rowid,
          ),
          dataclassMapper: (p0) async => p0
              .map((e) => $$TableWithoutPKTableWithReferences(db, e))
              .toList(),
          createInsertCompanionCallback: ({
            required int notReallyAnId,
            required double someFloat,
            Value<BigInt?> webSafeInt = const Value.absent(),
            Value<MyCustomObject> custom = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TableWithoutPKCompanion.insert(
            notReallyAnId: notReallyAnId,
            someFloat: someFloat,
            webSafeInt: webSafeInt,
            custom: custom,
            rowid: rowid,
          ),
        ));
}

typedef $$TableWithoutPKTableProcessedTableManager = ProcessedTableManager<
    _$TodoDb,
    $TableWithoutPKTable,
    CustomRowClass,
    $$TableWithoutPKTableFilterComposer,
    $$TableWithoutPKTableOrderingComposer,
    $$TableWithoutPKTableInsertCompanionBuilder,
    $$TableWithoutPKTableUpdateCompanionBuilder,
    $$TableWithoutPKTableWithReferences,
    CustomRowClass>;

class $$TableWithoutPKTableFilterComposer
    extends FilterComposer<_$TodoDb, $TableWithoutPKTable> {
  $$TableWithoutPKTableFilterComposer(super.$state);
  ColumnFilters<int> get notReallyAnId => $state.composableBuilder(
      column: $state.table.notReallyAnId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get someFloat => $state.composableBuilder(
      column: $state.table.someFloat,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<BigInt> get webSafeInt => $state.composableBuilder(
      column: $state.table.webSafeInt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<MyCustomObject, MyCustomObject, String>
      get custom => $state.composableBuilder(
          column: $state.table.custom,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));
}

class $$TableWithoutPKTableOrderingComposer
    extends OrderingComposer<_$TodoDb, $TableWithoutPKTable> {
  $$TableWithoutPKTableOrderingComposer(super.$state);
  ColumnOrderings<int> get notReallyAnId => $state.composableBuilder(
      column: $state.table.notReallyAnId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get someFloat => $state.composableBuilder(
      column: $state.table.someFloat,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<BigInt> get webSafeInt => $state.composableBuilder(
      column: $state.table.webSafeInt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get custom => $state.composableBuilder(
      column: $state.table.custom,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$TableWithoutPKTableWithReferences {
  // ignore: unused_field
  final _$TodoDb _db;
  final CustomRowClass customRowClass;
  $$TableWithoutPKTableWithReferences(this._db, this.customRowClass);
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
    $$PureDefaultsTableInsertCompanionBuilder,
    $$PureDefaultsTableUpdateCompanionBuilder,
    $$PureDefaultsTableWithReferences,
    PureDefault> {
  $$PureDefaultsTableTableManager(_$TodoDb db, $PureDefaultsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$PureDefaultsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$PureDefaultsTableOrderingComposer(ComposerState(db, table)),
          createUpdateCompanionCallback: ({
            Value<MyCustomObject?> txt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PureDefaultsCompanion(
            txt: txt,
            rowid: rowid,
          ),
          dataclassMapper: (p0) async =>
              p0.map((e) => $$PureDefaultsTableWithReferences(db, e)).toList(),
          createInsertCompanionCallback: ({
            Value<MyCustomObject?> txt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PureDefaultsCompanion.insert(
            txt: txt,
            rowid: rowid,
          ),
        ));
}

typedef $$PureDefaultsTableProcessedTableManager = ProcessedTableManager<
    _$TodoDb,
    $PureDefaultsTable,
    PureDefault,
    $$PureDefaultsTableFilterComposer,
    $$PureDefaultsTableOrderingComposer,
    $$PureDefaultsTableInsertCompanionBuilder,
    $$PureDefaultsTableUpdateCompanionBuilder,
    $$PureDefaultsTableWithReferences,
    PureDefault>;

class $$PureDefaultsTableFilterComposer
    extends FilterComposer<_$TodoDb, $PureDefaultsTable> {
  $$PureDefaultsTableFilterComposer(super.$state);
  ColumnWithTypeConverterFilters<MyCustomObject?, MyCustomObject, String>
      get txt => $state.composableBuilder(
          column: $state.table.txt,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));
}

class $$PureDefaultsTableOrderingComposer
    extends OrderingComposer<_$TodoDb, $PureDefaultsTable> {
  $$PureDefaultsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get txt => $state.composableBuilder(
      column: $state.table.txt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$PureDefaultsTableWithReferences {
  // ignore: unused_field
  final _$TodoDb _db;
  final PureDefault pureDefault;
  $$PureDefaultsTableWithReferences(this._db, this.pureDefault);
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
    $$WithCustomTypeTableInsertCompanionBuilder,
    $$WithCustomTypeTableUpdateCompanionBuilder,
    $$WithCustomTypeTableWithReferences,
    WithCustomTypeData> {
  $$WithCustomTypeTableTableManager(_$TodoDb db, $WithCustomTypeTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$WithCustomTypeTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$WithCustomTypeTableOrderingComposer(ComposerState(db, table)),
          createUpdateCompanionCallback: ({
            Value<UuidValue> id = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WithCustomTypeCompanion(
            id: id,
            rowid: rowid,
          ),
          dataclassMapper: (p0) async => p0
              .map((e) => $$WithCustomTypeTableWithReferences(db, e))
              .toList(),
          createInsertCompanionCallback: ({
            required UuidValue id,
            Value<int> rowid = const Value.absent(),
          }) =>
              WithCustomTypeCompanion.insert(
            id: id,
            rowid: rowid,
          ),
        ));
}

typedef $$WithCustomTypeTableProcessedTableManager = ProcessedTableManager<
    _$TodoDb,
    $WithCustomTypeTable,
    WithCustomTypeData,
    $$WithCustomTypeTableFilterComposer,
    $$WithCustomTypeTableOrderingComposer,
    $$WithCustomTypeTableInsertCompanionBuilder,
    $$WithCustomTypeTableUpdateCompanionBuilder,
    $$WithCustomTypeTableWithReferences,
    WithCustomTypeData>;

class $$WithCustomTypeTableFilterComposer
    extends FilterComposer<_$TodoDb, $WithCustomTypeTable> {
  $$WithCustomTypeTableFilterComposer(super.$state);
  ColumnFilters<UuidValue> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$WithCustomTypeTableOrderingComposer
    extends OrderingComposer<_$TodoDb, $WithCustomTypeTable> {
  $$WithCustomTypeTableOrderingComposer(super.$state);
  ColumnOrderings<UuidValue> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$WithCustomTypeTableWithReferences {
  // ignore: unused_field
  final _$TodoDb _db;
  final WithCustomTypeData withCustomTypeData;
  $$WithCustomTypeTableWithReferences(this._db, this.withCustomTypeData);
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
    $$TableWithEveryColumnTypeTableInsertCompanionBuilder,
    $$TableWithEveryColumnTypeTableUpdateCompanionBuilder,
    $$TableWithEveryColumnTypeTableWithReferences,
    TableWithEveryColumnTypeData> {
  $$TableWithEveryColumnTypeTableTableManager(
      _$TodoDb db, $TableWithEveryColumnTypeTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer: $$TableWithEveryColumnTypeTableFilterComposer(
              ComposerState(db, table)),
          orderingComposer: $$TableWithEveryColumnTypeTableOrderingComposer(
              ComposerState(db, table)),
          createUpdateCompanionCallback: ({
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
          dataclassMapper: (p0) async => p0
              .map((e) => $$TableWithEveryColumnTypeTableWithReferences(db, e))
              .toList(),
          createInsertCompanionCallback: ({
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
          ),
        ));
}

typedef $$TableWithEveryColumnTypeTableProcessedTableManager
    = ProcessedTableManager<
        _$TodoDb,
        $TableWithEveryColumnTypeTable,
        TableWithEveryColumnTypeData,
        $$TableWithEveryColumnTypeTableFilterComposer,
        $$TableWithEveryColumnTypeTableOrderingComposer,
        $$TableWithEveryColumnTypeTableInsertCompanionBuilder,
        $$TableWithEveryColumnTypeTableUpdateCompanionBuilder,
        $$TableWithEveryColumnTypeTableWithReferences,
        TableWithEveryColumnTypeData>;

class $$TableWithEveryColumnTypeTableFilterComposer
    extends FilterComposer<_$TodoDb, $TableWithEveryColumnTypeTable> {
  $$TableWithEveryColumnTypeTableFilterComposer(super.$state);
  ColumnWithTypeConverterFilters<RowId, RowId, int> get id =>
      $state.composableBuilder(
          column: $state.table.id,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnFilters<bool> get aBool => $state.composableBuilder(
      column: $state.table.aBool,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get aDateTime => $state.composableBuilder(
      column: $state.table.aDateTime,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get aText => $state.composableBuilder(
      column: $state.table.aText,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get anInt => $state.composableBuilder(
      column: $state.table.anInt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<BigInt> get anInt64 => $state.composableBuilder(
      column: $state.table.anInt64,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get aReal => $state.composableBuilder(
      column: $state.table.aReal,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<Uint8List> get aBlob => $state.composableBuilder(
      column: $state.table.aBlob,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<TodoStatus?, TodoStatus, int> get anIntEnum =>
      $state.composableBuilder(
          column: $state.table.anIntEnum,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<MyCustomObject?, MyCustomObject, String>
      get aTextWithConverter => $state.composableBuilder(
          column: $state.table.aTextWithConverter,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));
}

class $$TableWithEveryColumnTypeTableOrderingComposer
    extends OrderingComposer<_$TodoDb, $TableWithEveryColumnTypeTable> {
  $$TableWithEveryColumnTypeTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get aBool => $state.composableBuilder(
      column: $state.table.aBool,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get aDateTime => $state.composableBuilder(
      column: $state.table.aDateTime,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get aText => $state.composableBuilder(
      column: $state.table.aText,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get anInt => $state.composableBuilder(
      column: $state.table.anInt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<BigInt> get anInt64 => $state.composableBuilder(
      column: $state.table.anInt64,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get aReal => $state.composableBuilder(
      column: $state.table.aReal,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<Uint8List> get aBlob => $state.composableBuilder(
      column: $state.table.aBlob,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get anIntEnum => $state.composableBuilder(
      column: $state.table.anIntEnum,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get aTextWithConverter => $state.composableBuilder(
      column: $state.table.aTextWithConverter,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$TableWithEveryColumnTypeTableWithReferences {
  // ignore: unused_field
  final _$TodoDb _db;
  final TableWithEveryColumnTypeData tableWithEveryColumnTypeData;
  $$TableWithEveryColumnTypeTableWithReferences(
      this._db, this.tableWithEveryColumnTypeData);
}

typedef $$DepartmentTableInsertCompanionBuilder = DepartmentCompanion Function({
  Value<int> id,
  Value<String?> name,
});
typedef $$DepartmentTableUpdateCompanionBuilder = DepartmentCompanion Function({
  Value<int> id,
  Value<String?> name,
});

class $$DepartmentTableTableManager extends RootTableManager<
    _$TodoDb,
    $DepartmentTable,
    DepartmentData,
    $$DepartmentTableFilterComposer,
    $$DepartmentTableOrderingComposer,
    $$DepartmentTableInsertCompanionBuilder,
    $$DepartmentTableUpdateCompanionBuilder,
    $$DepartmentTableWithReferences,
    DepartmentData> {
  $$DepartmentTableTableManager(_$TodoDb db, $DepartmentTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$DepartmentTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$DepartmentTableOrderingComposer(ComposerState(db, table)),
          createUpdateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> name = const Value.absent(),
          }) =>
              DepartmentCompanion(
            id: id,
            name: name,
          ),
          dataclassMapper: (p0) async =>
              p0.map((e) => $$DepartmentTableWithReferences(db, e)).toList(),
          createInsertCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> name = const Value.absent(),
          }) =>
              DepartmentCompanion.insert(
            id: id,
            name: name,
          ),
        ));
}

typedef $$DepartmentTableProcessedTableManager = ProcessedTableManager<
    _$TodoDb,
    $DepartmentTable,
    DepartmentData,
    $$DepartmentTableFilterComposer,
    $$DepartmentTableOrderingComposer,
    $$DepartmentTableInsertCompanionBuilder,
    $$DepartmentTableUpdateCompanionBuilder,
    $$DepartmentTableWithReferences,
    DepartmentData>;

class $$DepartmentTableFilterComposer
    extends FilterComposer<_$TodoDb, $DepartmentTable> {
  $$DepartmentTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ComposableFilter productRefs(
      ComposableFilter Function($$ProductTableFilterComposer f) f) {
    final $$ProductTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.product,
        getReferencedColumn: (t) => t.department,
        builder: (joinBuilder, parentComposers) => $$ProductTableFilterComposer(
            ComposerState(
                $state.db, $state.db.product, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$DepartmentTableOrderingComposer
    extends OrderingComposer<_$TodoDb, $DepartmentTable> {
  $$DepartmentTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$DepartmentTableWithReferences {
  // ignore: unused_field
  final _$TodoDb _db;
  final DepartmentData departmentData;
  $$DepartmentTableWithReferences(this._db, this.departmentData);

  $$ProductTableProcessedTableManager get productRefs {
    return $$ProductTableTableManager(_db, _db.product)
        .filter((f) => f.department.id(departmentData.id));
  }
}

typedef $$ProductTableInsertCompanionBuilder = ProductCompanion Function({
  Value<int> id,
  Value<String?> name,
  Value<int?> department,
});
typedef $$ProductTableUpdateCompanionBuilder = ProductCompanion Function({
  Value<int> id,
  Value<String?> name,
  Value<int?> department,
});

class $$ProductTableTableManager extends RootTableManager<
    _$TodoDb,
    $ProductTable,
    ProductData,
    $$ProductTableFilterComposer,
    $$ProductTableOrderingComposer,
    $$ProductTableInsertCompanionBuilder,
    $$ProductTableUpdateCompanionBuilder,
    $$ProductTableWithReferences,
    ProductData> {
  $$ProductTableTableManager(_$TodoDb db, $ProductTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$ProductTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$ProductTableOrderingComposer(ComposerState(db, table)),
          createUpdateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> name = const Value.absent(),
            Value<int?> department = const Value.absent(),
          }) =>
              ProductCompanion(
            id: id,
            name: name,
            department: department,
          ),
          dataclassMapper: (p0) async =>
              p0.map((e) => $$ProductTableWithReferences(db, e)).toList(),
          createInsertCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> name = const Value.absent(),
            Value<int?> department = const Value.absent(),
          }) =>
              ProductCompanion.insert(
            id: id,
            name: name,
            department: department,
          ),
        ));
}

typedef $$ProductTableProcessedTableManager = ProcessedTableManager<
    _$TodoDb,
    $ProductTable,
    ProductData,
    $$ProductTableFilterComposer,
    $$ProductTableOrderingComposer,
    $$ProductTableInsertCompanionBuilder,
    $$ProductTableUpdateCompanionBuilder,
    $$ProductTableWithReferences,
    ProductData>;

class $$ProductTableFilterComposer
    extends FilterComposer<_$TodoDb, $ProductTable> {
  $$ProductTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$DepartmentTableFilterComposer get department {
    final $$DepartmentTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.department,
        referencedTable: $state.db.department,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$DepartmentTableFilterComposer(ComposerState($state.db,
                $state.db.department, joinBuilder, parentComposers)));
    return composer;
  }

  ComposableFilter listings(
      ComposableFilter Function($$ListingTableFilterComposer f) f) {
    final $$ListingTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.listing,
        getReferencedColumn: (t) => t.product,
        builder: (joinBuilder, parentComposers) => $$ListingTableFilterComposer(
            ComposerState(
                $state.db, $state.db.listing, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$ProductTableOrderingComposer
    extends OrderingComposer<_$TodoDb, $ProductTable> {
  $$ProductTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$DepartmentTableOrderingComposer get department {
    final $$DepartmentTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.department,
        referencedTable: $state.db.department,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$DepartmentTableOrderingComposer(ComposerState($state.db,
                $state.db.department, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$ProductTableWithReferences {
  // ignore: unused_field
  final _$TodoDb _db;
  final ProductData productData;
  $$ProductTableWithReferences(this._db, this.productData);

  $$DepartmentTableProcessedTableManager? get department {
    if (productData.department == null) return null;
    return $$DepartmentTableTableManager(_db, _db.department)
        .filter((f) => f.id(productData.department!));
  }

  $$ListingTableProcessedTableManager get listings {
    return $$ListingTableTableManager(_db, _db.listing)
        .filter((f) => f.product.id(productData.id));
  }
}

typedef $$StoreTableInsertCompanionBuilder = StoreCompanion Function({
  Value<int> id,
  Value<String?> name,
});
typedef $$StoreTableUpdateCompanionBuilder = StoreCompanion Function({
  Value<int> id,
  Value<String?> name,
});

class $$StoreTableTableManager extends RootTableManager<
    _$TodoDb,
    $StoreTable,
    StoreData,
    $$StoreTableFilterComposer,
    $$StoreTableOrderingComposer,
    $$StoreTableInsertCompanionBuilder,
    $$StoreTableUpdateCompanionBuilder,
    $$StoreTableWithReferences,
    StoreData> {
  $$StoreTableTableManager(_$TodoDb db, $StoreTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$StoreTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$StoreTableOrderingComposer(ComposerState(db, table)),
          createUpdateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> name = const Value.absent(),
          }) =>
              StoreCompanion(
            id: id,
            name: name,
          ),
          dataclassMapper: (p0) async =>
              p0.map((e) => $$StoreTableWithReferences(db, e)).toList(),
          createInsertCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> name = const Value.absent(),
          }) =>
              StoreCompanion.insert(
            id: id,
            name: name,
          ),
        ));
}

typedef $$StoreTableProcessedTableManager = ProcessedTableManager<
    _$TodoDb,
    $StoreTable,
    StoreData,
    $$StoreTableFilterComposer,
    $$StoreTableOrderingComposer,
    $$StoreTableInsertCompanionBuilder,
    $$StoreTableUpdateCompanionBuilder,
    $$StoreTableWithReferences,
    StoreData>;

class $$StoreTableFilterComposer extends FilterComposer<_$TodoDb, $StoreTable> {
  $$StoreTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ComposableFilter listings(
      ComposableFilter Function($$ListingTableFilterComposer f) f) {
    final $$ListingTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.listing,
        getReferencedColumn: (t) => t.store,
        builder: (joinBuilder, parentComposers) => $$ListingTableFilterComposer(
            ComposerState(
                $state.db, $state.db.listing, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$StoreTableOrderingComposer
    extends OrderingComposer<_$TodoDb, $StoreTable> {
  $$StoreTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$StoreTableWithReferences {
  // ignore: unused_field
  final _$TodoDb _db;
  final StoreData storeData;
  $$StoreTableWithReferences(this._db, this.storeData);

  $$ListingTableProcessedTableManager get listings {
    return $$ListingTableTableManager(_db, _db.listing)
        .filter((f) => f.store.id(storeData.id));
  }
}

typedef $$ListingTableInsertCompanionBuilder = ListingCompanion Function({
  Value<int> id,
  Value<int?> product,
  Value<int?> store,
  Value<double?> price,
});
typedef $$ListingTableUpdateCompanionBuilder = ListingCompanion Function({
  Value<int> id,
  Value<int?> product,
  Value<int?> store,
  Value<double?> price,
});

class $$ListingTableTableManager extends RootTableManager<
    _$TodoDb,
    $ListingTable,
    ListingData,
    $$ListingTableFilterComposer,
    $$ListingTableOrderingComposer,
    $$ListingTableInsertCompanionBuilder,
    $$ListingTableUpdateCompanionBuilder,
    $$ListingTableWithReferences,
    ListingData> {
  $$ListingTableTableManager(_$TodoDb db, $ListingTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$ListingTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$ListingTableOrderingComposer(ComposerState(db, table)),
          createUpdateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> product = const Value.absent(),
            Value<int?> store = const Value.absent(),
            Value<double?> price = const Value.absent(),
          }) =>
              ListingCompanion(
            id: id,
            product: product,
            store: store,
            price: price,
          ),
          dataclassMapper: (p0) async =>
              p0.map((e) => $$ListingTableWithReferences(db, e)).toList(),
          createInsertCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> product = const Value.absent(),
            Value<int?> store = const Value.absent(),
            Value<double?> price = const Value.absent(),
          }) =>
              ListingCompanion.insert(
            id: id,
            product: product,
            store: store,
            price: price,
          ),
        ));
}

typedef $$ListingTableProcessedTableManager = ProcessedTableManager<
    _$TodoDb,
    $ListingTable,
    ListingData,
    $$ListingTableFilterComposer,
    $$ListingTableOrderingComposer,
    $$ListingTableInsertCompanionBuilder,
    $$ListingTableUpdateCompanionBuilder,
    $$ListingTableWithReferences,
    ListingData>;

class $$ListingTableFilterComposer
    extends FilterComposer<_$TodoDb, $ListingTable> {
  $$ListingTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get price => $state.composableBuilder(
      column: $state.table.price,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$ProductTableFilterComposer get product {
    final $$ProductTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.product,
        referencedTable: $state.db.product,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => $$ProductTableFilterComposer(
            ComposerState(
                $state.db, $state.db.product, joinBuilder, parentComposers)));
    return composer;
  }

  $$StoreTableFilterComposer get store {
    final $$StoreTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.store,
        referencedTable: $state.db.store,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => $$StoreTableFilterComposer(
            ComposerState(
                $state.db, $state.db.store, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$ListingTableOrderingComposer
    extends OrderingComposer<_$TodoDb, $ListingTable> {
  $$ListingTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get price => $state.composableBuilder(
      column: $state.table.price,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$ProductTableOrderingComposer get product {
    final $$ProductTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.product,
        referencedTable: $state.db.product,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$ProductTableOrderingComposer(ComposerState(
                $state.db, $state.db.product, joinBuilder, parentComposers)));
    return composer;
  }

  $$StoreTableOrderingComposer get store {
    final $$StoreTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.store,
        referencedTable: $state.db.store,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => $$StoreTableOrderingComposer(
            ComposerState(
                $state.db, $state.db.store, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$ListingTableWithReferences {
  // ignore: unused_field
  final _$TodoDb _db;
  final ListingData listingData;
  $$ListingTableWithReferences(this._db, this.listingData);

  $$ProductTableProcessedTableManager? get product {
    if (listingData.product == null) return null;
    return $$ProductTableTableManager(_db, _db.product)
        .filter((f) => f.id(listingData.product!));
  }

  $$StoreTableProcessedTableManager? get store {
    if (listingData.store == null) return null;
    return $$StoreTableTableManager(_db, _db.store)
        .filter((f) => f.id(listingData.store!));
  }
}

class $TodoDbManager {
  final _$TodoDb _db;
  $TodoDbManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$TodosTableTableTableManager get todosTable =>
      $$TodosTableTableTableManager(_db, _db.todosTable);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$SharedTodosTableTableManager get sharedTodos =>
      $$SharedTodosTableTableManager(_db, _db.sharedTodos);
  $$TableWithoutPKTableTableManager get tableWithoutPK =>
      $$TableWithoutPKTableTableManager(_db, _db.tableWithoutPK);
  $$PureDefaultsTableTableManager get pureDefaults =>
      $$PureDefaultsTableTableManager(_db, _db.pureDefaults);
  $$WithCustomTypeTableTableManager get withCustomType =>
      $$WithCustomTypeTableTableManager(_db, _db.withCustomType);
  $$TableWithEveryColumnTypeTableTableManager get tableWithEveryColumnType =>
      $$TableWithEveryColumnTypeTableTableManager(
          _db, _db.tableWithEveryColumnType);
  $$DepartmentTableTableManager get department =>
      $$DepartmentTableTableManager(_db, _db.department);
  $$ProductTableTableManager get product =>
      $$ProductTableTableManager(_db, _db.product);
  $$StoreTableTableManager get store =>
      $$StoreTableTableManager(_db, _db.store);
  $$ListingTableTableManager get listing =>
      $$ListingTableTableManager(_db, _db.listing);
}

class AllTodosWithCategoryResult extends CustomResultSet {
  final RowId id;
  final String? title;
  final String content;
  final DateTime? targetDate;
  final RowId? category;
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
