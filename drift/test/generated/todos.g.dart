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
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
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
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
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
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
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

  static JsonTypeConverter2<CategoryPriority, int, int> $converterpriority =
      const EnumIndexConverter<CategoryPriority>(CategoryPriority.values);
}

class Category extends DataClass implements Insertable<Category> {
  final int id;
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
    map['id'] = Variable<int>(id);
    map['desc'] = Variable<String>(description);
    {
      final converter = $CategoriesTable.$converterpriority;
      map['priority'] = Variable<int>(converter.toSql(priority));
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
      id: serializer.fromJson<int>(json['id']),
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
      'id': serializer.toJson<int>(id),
      'description': serializer.toJson<String>(description),
      'priority': serializer
          .toJson<int>($CategoriesTable.$converterpriority.toJson(priority)),
      'descriptionInUpperCase':
          serializer.toJson<String>(descriptionInUpperCase),
    };
  }

  Category copyWith(
          {int? id,
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
  final Value<int> id;
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
      {Value<int>? id,
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
      map['id'] = Variable<int>(id.value);
    }
    if (description.present) {
      map['desc'] = Variable<String>(description.value);
    }
    if (priority.present) {
      final converter = $CategoriesTable.$converterpriority;

      map['priority'] = Variable<int>(converter.toSql(priority.value));
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
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
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
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
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

  static JsonTypeConverter2<TodoStatus, String, String> $converterstatus =
      const EnumNameConverter<TodoStatus>(TodoStatus.values);
  static JsonTypeConverter2<TodoStatus?, String?, String?> $converterstatusn =
      JsonTypeConverter2.asNullable($converterstatus);
}

class TodoEntry extends DataClass implements Insertable<TodoEntry> {
  final int id;
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
    map['id'] = Variable<int>(id);
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
      final converter = $TodosTableTable.$converterstatusn;
      map['status'] = Variable<String>(converter.toSql(status));
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
      id: serializer.fromJson<int>(json['id']),
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
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String?>(title),
      'content': serializer.toJson<String>(content),
      'target_date': serializer.toJson<DateTime?>(targetDate),
      'category': serializer.toJson<int?>(category),
      'status': serializer
          .toJson<String?>($TodosTableTable.$converterstatusn.toJson(status)),
    };
  }

  TodoEntry copyWith(
          {int? id,
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
  final Value<int> id;
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
      {Value<int>? id,
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
      map['id'] = Variable<int>(id.value);
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
      final converter = $TodosTableTable.$converterstatusn;

      map['status'] = Variable<String>(converter.toSql(status.value));
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
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
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
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
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
}

class User extends DataClass implements Insertable<User> {
  final int id;
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
    map['id'] = Variable<int>(id);
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
      id: serializer.fromJson<int>(json['id']),
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
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'isAwesome': serializer.toJson<bool>(isAwesome),
      'profilePicture': serializer.toJson<Uint8List>(profilePicture),
      'creationTime': serializer.toJson<DateTime>(creationTime),
    };
  }

  User copyWith(
          {int? id,
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
  final Value<int> id;
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
      {Value<int>? id,
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
      map['id'] = Variable<int>(id.value);
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
      final converter = $TableWithoutPKTable.$convertercustom;

      map['custom'] = Variable<String>(converter.toSql(custom.value));
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
      final converter = $PureDefaultsTable.$convertertxtn;
      map['insert'] = Variable<String>(converter.toSql(txt));
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
      final converter = $PureDefaultsTable.$convertertxtn;

      map['insert'] = Variable<String>(converter.toSql(txt.value));
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
      type: const UuidType(), requiredDuringInsert: true);
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
          .read(const UuidType(), data['${effectivePrefix}id'])!,
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
    map['id'] = Variable<UuidValue>(id);
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
      map['id'] = Variable<UuidValue>(id.value, const UuidType());
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
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $TodosTableTable todosTable = $TodosTableTable(this);
  late final $UsersTable users = $UsersTable(this);
  late final $SharedTodosTable sharedTodos = $SharedTodosTable(this);
  late final $TableWithoutPKTable tableWithoutPK = $TableWithoutPKTable(this);
  late final $PureDefaultsTable pureDefaults = $PureDefaultsTable(this);
  late final $WithCustomTypeTable withCustomType = $WithCustomTypeTable(this);
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
          id: row.read<int>('id'),
          title: row.readNullable<String>('title'),
          content: row.read<String>('content'),
          targetDate: row.readNullable<DateTime>('target_date'),
          category: row.readNullable<int>('category'),
          status: NullAwareTypeConverter.wrapFromSql(
              $TodosTableTable.$converterstatus,
              row.readNullable<String>('status')),
          catId: row.read<int>('catId'),
          catDesc: row.read<String>('catDesc'),
        ));
  }

  Future<int> deleteTodoById(int var1) {
    return customUpdate(
      'DELETE FROM todos WHERE id = ?1',
      variables: [Variable<int>(var1)],
      updates: {todosTable},
      updateKind: UpdateKind.delete,
    );
  }

  Selectable<TodoEntry> withIn(String? var1, String? var2, List<int> var3) {
    var $arrayStartIndex = 3;
    final expandedvar3 = $expandVar($arrayStartIndex, var3.length);
    $arrayStartIndex += var3.length;
    return customSelect(
        'SELECT * FROM todos WHERE title = ?2 OR id IN ($expandedvar3) OR title = ?1',
        variables: [
          Variable<String>(var1),
          Variable<String>(var2),
          for (var $ in var3) Variable<int>($)
        ],
        readsFrom: {
          todosTable,
        }).asyncMap(todosTable.mapFromRow);
  }

  Selectable<TodoEntry> search({required int id}) {
    return customSelect(
        'SELECT * FROM todos WHERE CASE WHEN -1 = ?1 THEN 1 ELSE id = ?1 END',
        variables: [
          Variable<int>(id)
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
        categoryTodoCountView,
        todoWithCategoryView
      ];
}

class AllTodosWithCategoryResult extends CustomResultSet {
  final int id;
  final String? title;
  final String content;
  final DateTime? targetDate;
  final int? category;
  final TodoStatus? status;
  final int catId;
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
  Selectable<TodoEntry> todosForUser({required int user}) {
    return customSelect(
        'SELECT t.* FROM todos AS t INNER JOIN shared_todos AS st ON st.todo = t.id INNER JOIN users AS u ON u.id = st.user WHERE u.id = ?1',
        variables: [
          Variable<int>(user)
        ],
        readsFrom: {
          todosTable,
          sharedTodos,
          users,
        }).asyncMap(todosTable.mapFromRow);
  }
}
