// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todos.dart';

// **************************************************************************
// MoorGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps, unnecessary_this
class Category extends DataClass implements Insertable<Category> {
  final int id;
  final String description;
  final CategoryPriority priority;
  final String descriptionInUpperCase;
  Category(
      {required this.id,
      required this.description,
      required this.priority,
      required this.descriptionInUpperCase});
  factory Category.fromData(Map<String, dynamic> data, {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return Category(
      id: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}id'])!,
      description: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}desc'])!,
      priority: $CategoriesTable.$converter0.mapToDart(const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}priority']))!,
      descriptionInUpperCase: const StringType().mapFromDatabaseResponse(
          data['${effectivePrefix}description_in_upper_case'])!,
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['desc'] = Variable<String>(description);
    {
      final converter = $CategoriesTable.$converter0;
      map['priority'] = Variable<int>(converter.mapToSql(priority)!);
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
      priority: serializer.fromJson<CategoryPriority>(json['priority']),
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
      'priority': serializer.toJson<CategoryPriority>(priority),
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
    Expression<CategoryPriority>? priority,
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
      final converter = $CategoriesTable.$converter0;
      map['priority'] = Variable<int>(converter.mapToSql(priority.value)!);
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

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  final GeneratedDatabase _db;
  final String? _alias;
  $CategoriesTable(this._db, [this._alias]);
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
      'desc', aliasedName, false,
      type: const StringType(),
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL UNIQUE');
  final VerificationMeta _priorityMeta = const VerificationMeta('priority');
  @override
  late final GeneratedColumnWithTypeConverter<CategoryPriority, int?> priority =
      GeneratedColumn<int?>('priority', aliasedName, false,
              type: const IntType(),
              requiredDuringInsert: false,
              defaultValue: const Constant(0))
          .withConverter<CategoryPriority>($CategoriesTable.$converter0);
  final VerificationMeta _descriptionInUpperCaseMeta =
      const VerificationMeta('descriptionInUpperCase');
  @override
  late final GeneratedColumn<String?> descriptionInUpperCase =
      GeneratedColumn<String?>('description_in_upper_case', aliasedName, false,
          type: const StringType(),
          requiredDuringInsert: false,
          generatedAs: GeneratedAs(description.upper(), false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, description, priority, descriptionInUpperCase];
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
    return Category.fromData(data,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(_db, alias);
  }

  static TypeConverter<CategoryPriority, int> $converter0 =
      const EnumIndexConverter<CategoryPriority>(CategoryPriority.values);
}

class TodoEntry extends DataClass implements Insertable<TodoEntry> {
  final int id;
  final String? title;
  final String content;
  final DateTime? targetDate;
  final int? category;
  TodoEntry(
      {required this.id,
      this.title,
      required this.content,
      this.targetDate,
      this.category});
  factory TodoEntry.fromData(Map<String, dynamic> data, {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return TodoEntry(
      id: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}id'])!,
      title: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}title']),
      content: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}content'])!,
      targetDate: const DateTimeType()
          .mapFromDatabaseResponse(data['${effectivePrefix}target_date']),
      category: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}category']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String?>(title);
    }
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || targetDate != null) {
      map['target_date'] = Variable<DateTime?>(targetDate);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<int?>(category);
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
    };
  }

  TodoEntry copyWith(
          {int? id,
          Value<String?> title = const Value.absent(),
          String? content,
          Value<DateTime?> targetDate = const Value.absent(),
          Value<int?> category = const Value.absent()}) =>
      TodoEntry(
        id: id ?? this.id,
        title: title.present ? title.value : this.title,
        content: content ?? this.content,
        targetDate: targetDate.present ? targetDate.value : this.targetDate,
        category: category.present ? category.value : this.category,
      );
  @override
  String toString() {
    return (StringBuffer('TodoEntry(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('targetDate: $targetDate, ')
          ..write('category: $category')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, content, targetDate, category);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TodoEntry &&
          other.id == this.id &&
          other.title == this.title &&
          other.content == this.content &&
          other.targetDate == this.targetDate &&
          other.category == this.category);
}

class TodosTableCompanion extends UpdateCompanion<TodoEntry> {
  final Value<int> id;
  final Value<String?> title;
  final Value<String> content;
  final Value<DateTime?> targetDate;
  final Value<int?> category;
  const TodosTableCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.category = const Value.absent(),
  });
  TodosTableCompanion.insert({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    required String content,
    this.targetDate = const Value.absent(),
    this.category = const Value.absent(),
  }) : content = Value(content);
  static Insertable<TodoEntry> custom({
    Expression<int>? id,
    Expression<String?>? title,
    Expression<String>? content,
    Expression<DateTime?>? targetDate,
    Expression<int?>? category,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (targetDate != null) 'target_date': targetDate,
      if (category != null) 'category': category,
    });
  }

  TodosTableCompanion copyWith(
      {Value<int>? id,
      Value<String?>? title,
      Value<String>? content,
      Value<DateTime?>? targetDate,
      Value<int?>? category}) {
    return TodosTableCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      targetDate: targetDate ?? this.targetDate,
      category: category ?? this.category,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String?>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (targetDate.present) {
      map['target_date'] = Variable<DateTime?>(targetDate.value);
    }
    if (category.present) {
      map['category'] = Variable<int?>(category.value);
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
          ..write('category: $category')
          ..write(')'))
        .toString();
  }
}

class $TodosTableTable extends TodosTable
    with TableInfo<$TodosTableTable, TodoEntry> {
  final GeneratedDatabase _db;
  final String? _alias;
  $TodosTableTable(this._db, [this._alias]);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int?> id = GeneratedColumn<int?>(
      'id', aliasedName, false,
      type: const IntType(),
      requiredDuringInsert: false,
      defaultConstraints: 'PRIMARY KEY AUTOINCREMENT');
  final VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String?> title = GeneratedColumn<String?>(
      'title', aliasedName, true,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 4, maxTextLength: 16),
      type: const StringType(),
      requiredDuringInsert: false);
  final VerificationMeta _contentMeta = const VerificationMeta('content');
  @override
  late final GeneratedColumn<String?> content = GeneratedColumn<String?>(
      'content', aliasedName, false,
      type: const StringType(), requiredDuringInsert: true);
  final VerificationMeta _targetDateMeta = const VerificationMeta('targetDate');
  @override
  late final GeneratedColumn<DateTime?> targetDate = GeneratedColumn<DateTime?>(
      'target_date', aliasedName, true,
      type: const IntType(), requiredDuringInsert: false);
  final VerificationMeta _categoryMeta = const VerificationMeta('category');
  @override
  late final GeneratedColumn<int?> category = GeneratedColumn<int?>(
      'category', aliasedName, true,
      type: const IntType(),
      requiredDuringInsert: false,
      defaultConstraints: 'REFERENCES categories (id)');
  @override
  List<GeneratedColumn> get $columns =>
      [id, title, content, targetDate, category];
  @override
  String get aliasedName => _alias ?? 'todos';
  @override
  String get actualTableName => 'todos';
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
  $TodosTableTable createAlias(String alias) {
    return $TodosTableTable(_db, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final int id;
  final String name;
  final bool isAwesome;
  final Uint8List profilePicture;
  final DateTime creationTime;
  User(
      {required this.id,
      required this.name,
      required this.isAwesome,
      required this.profilePicture,
      required this.creationTime});
  factory User.fromData(Map<String, dynamic> data, {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return User(
      id: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}id'])!,
      name: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}name'])!,
      isAwesome: const BoolType()
          .mapFromDatabaseResponse(data['${effectivePrefix}is_awesome'])!,
      profilePicture: const BlobType()
          .mapFromDatabaseResponse(data['${effectivePrefix}profile_picture'])!,
      creationTime: const DateTimeType()
          .mapFromDatabaseResponse(data['${effectivePrefix}creation_time'])!,
    );
  }
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
  int get hashCode =>
      Object.hash(id, name, isAwesome, profilePicture, creationTime);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.name == this.name &&
          other.isAwesome == this.isAwesome &&
          other.profilePicture == this.profilePicture &&
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

class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  final GeneratedDatabase _db;
  final String? _alias;
  $UsersTable(this._db, [this._alias]);
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
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 6, maxTextLength: 32),
      type: const StringType(),
      requiredDuringInsert: true);
  final VerificationMeta _isAwesomeMeta = const VerificationMeta('isAwesome');
  @override
  late final GeneratedColumn<bool?> isAwesome = GeneratedColumn<bool?>(
      'is_awesome', aliasedName, false,
      type: const BoolType(),
      requiredDuringInsert: false,
      defaultConstraints: 'CHECK (is_awesome IN (0, 1))',
      defaultValue: const Constant(true));
  final VerificationMeta _profilePictureMeta =
      const VerificationMeta('profilePicture');
  @override
  late final GeneratedColumn<Uint8List?> profilePicture =
      GeneratedColumn<Uint8List?>('profile_picture', aliasedName, false,
          type: const BlobType(), requiredDuringInsert: true);
  final VerificationMeta _creationTimeMeta =
      const VerificationMeta('creationTime');
  @override
  late final GeneratedColumn<DateTime?> creationTime =
      GeneratedColumn<DateTime?>('creation_time', aliasedName, false,
          type: const IntType(),
          requiredDuringInsert: false,
          defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, isAwesome, profilePicture, creationTime];
  @override
  String get aliasedName => _alias ?? 'users';
  @override
  String get actualTableName => 'users';
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
    return User.fromData(data,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(_db, alias);
  }
}

class SharedTodo extends DataClass implements Insertable<SharedTodo> {
  final int todo;
  final int user;
  SharedTodo({required this.todo, required this.user});
  factory SharedTodo.fromData(Map<String, dynamic> data, {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return SharedTodo(
      todo: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}todo'])!,
      user: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}user'])!,
    );
  }
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
  const SharedTodosCompanion({
    this.todo = const Value.absent(),
    this.user = const Value.absent(),
  });
  SharedTodosCompanion.insert({
    required int todo,
    required int user,
  })  : todo = Value(todo),
        user = Value(user);
  static Insertable<SharedTodo> custom({
    Expression<int>? todo,
    Expression<int>? user,
  }) {
    return RawValuesInsertable({
      if (todo != null) 'todo': todo,
      if (user != null) 'user': user,
    });
  }

  SharedTodosCompanion copyWith({Value<int>? todo, Value<int>? user}) {
    return SharedTodosCompanion(
      todo: todo ?? this.todo,
      user: user ?? this.user,
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SharedTodosCompanion(')
          ..write('todo: $todo, ')
          ..write('user: $user')
          ..write(')'))
        .toString();
  }
}

class $SharedTodosTable extends SharedTodos
    with TableInfo<$SharedTodosTable, SharedTodo> {
  final GeneratedDatabase _db;
  final String? _alias;
  $SharedTodosTable(this._db, [this._alias]);
  final VerificationMeta _todoMeta = const VerificationMeta('todo');
  @override
  late final GeneratedColumn<int?> todo = GeneratedColumn<int?>(
      'todo', aliasedName, false,
      type: const IntType(), requiredDuringInsert: true);
  final VerificationMeta _userMeta = const VerificationMeta('user');
  @override
  late final GeneratedColumn<int?> user = GeneratedColumn<int?>(
      'user', aliasedName, false,
      type: const IntType(), requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [todo, user];
  @override
  String get aliasedName => _alias ?? 'shared_todos';
  @override
  String get actualTableName => 'shared_todos';
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
    return SharedTodo.fromData(data,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  $SharedTodosTable createAlias(String alias) {
    return $SharedTodosTable(_db, alias);
  }
}

class TableWithoutPKCompanion extends UpdateCompanion<CustomRowClass> {
  final Value<int> notReallyAnId;
  final Value<double> someFloat;
  final Value<MyCustomObject> custom;
  const TableWithoutPKCompanion({
    this.notReallyAnId = const Value.absent(),
    this.someFloat = const Value.absent(),
    this.custom = const Value.absent(),
  });
  TableWithoutPKCompanion.insert({
    required int notReallyAnId,
    required double someFloat,
    this.custom = const Value.absent(),
  })  : notReallyAnId = Value(notReallyAnId),
        someFloat = Value(someFloat);
  static Insertable<CustomRowClass> createCustom({
    Expression<int>? notReallyAnId,
    Expression<double>? someFloat,
    Expression<MyCustomObject>? custom,
  }) {
    return RawValuesInsertable({
      if (notReallyAnId != null) 'not_really_an_id': notReallyAnId,
      if (someFloat != null) 'some_float': someFloat,
      if (custom != null) 'custom': custom,
    });
  }

  TableWithoutPKCompanion copyWith(
      {Value<int>? notReallyAnId,
      Value<double>? someFloat,
      Value<MyCustomObject>? custom}) {
    return TableWithoutPKCompanion(
      notReallyAnId: notReallyAnId ?? this.notReallyAnId,
      someFloat: someFloat ?? this.someFloat,
      custom: custom ?? this.custom,
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
    if (custom.present) {
      final converter = $TableWithoutPKTable.$converter0;
      map['custom'] = Variable<String>(converter.mapToSql(custom.value)!);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TableWithoutPKCompanion(')
          ..write('notReallyAnId: $notReallyAnId, ')
          ..write('someFloat: $someFloat, ')
          ..write('custom: $custom')
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
    ).toColumns(false);
  }
}

extension CustomRowClassToInsertable on CustomRowClass {
  _$CustomRowClassInsertable toInsertable() {
    return _$CustomRowClassInsertable(this);
  }
}

class $TableWithoutPKTable extends TableWithoutPK
    with TableInfo<$TableWithoutPKTable, CustomRowClass> {
  final GeneratedDatabase _db;
  final String? _alias;
  $TableWithoutPKTable(this._db, [this._alias]);
  final VerificationMeta _notReallyAnIdMeta =
      const VerificationMeta('notReallyAnId');
  @override
  late final GeneratedColumn<int?> notReallyAnId = GeneratedColumn<int?>(
      'not_really_an_id', aliasedName, false,
      type: const IntType(), requiredDuringInsert: true);
  final VerificationMeta _someFloatMeta = const VerificationMeta('someFloat');
  @override
  late final GeneratedColumn<double?> someFloat = GeneratedColumn<double?>(
      'some_float', aliasedName, false,
      type: const RealType(), requiredDuringInsert: true);
  final VerificationMeta _customMeta = const VerificationMeta('custom');
  @override
  late final GeneratedColumnWithTypeConverter<MyCustomObject, String?> custom =
      GeneratedColumn<String?>('custom', aliasedName, false,
              type: const StringType(),
              requiredDuringInsert: false,
              clientDefault: _uuid.v4)
          .withConverter<MyCustomObject>($TableWithoutPKTable.$converter0);
  @override
  List<GeneratedColumn> get $columns => [notReallyAnId, someFloat, custom];
  @override
  String get aliasedName => _alias ?? 'table_without_p_k';
  @override
  String get actualTableName => 'table_without_p_k';
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
    context.handle(_customMeta, const VerificationResult.success());
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => <GeneratedColumn>{};
  @override
  CustomRowClass map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomRowClass.map(
      const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}not_really_an_id'])!,
      const RealType()
          .mapFromDatabaseResponse(data['${effectivePrefix}some_float'])!,
      custom: $TableWithoutPKTable.$converter0.mapToDart(const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}custom']))!,
    );
  }

  @override
  $TableWithoutPKTable createAlias(String alias) {
    return $TableWithoutPKTable(_db, alias);
  }

  static TypeConverter<MyCustomObject, String> $converter0 =
      const CustomConverter();
}

class PureDefault extends DataClass implements Insertable<PureDefault> {
  final String? txt;
  PureDefault({this.txt});
  factory PureDefault.fromData(Map<String, dynamic> data, {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return PureDefault(
      txt: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}insert']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || txt != null) {
      map['insert'] = Variable<String?>(txt);
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
      txt: serializer.fromJson<String?>(json['txt']),
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
      'txt': serializer.toJson<String?>(txt),
    };
  }

  PureDefault copyWith({Value<String?> txt = const Value.absent()}) =>
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
  final Value<String?> txt;
  const PureDefaultsCompanion({
    this.txt = const Value.absent(),
  });
  PureDefaultsCompanion.insert({
    this.txt = const Value.absent(),
  });
  static Insertable<PureDefault> custom({
    Expression<String?>? txt,
  }) {
    return RawValuesInsertable({
      if (txt != null) 'insert': txt,
    });
  }

  PureDefaultsCompanion copyWith({Value<String?>? txt}) {
    return PureDefaultsCompanion(
      txt: txt ?? this.txt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (txt.present) {
      map['insert'] = Variable<String?>(txt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PureDefaultsCompanion(')
          ..write('txt: $txt')
          ..write(')'))
        .toString();
  }
}

class $PureDefaultsTable extends PureDefaults
    with TableInfo<$PureDefaultsTable, PureDefault> {
  final GeneratedDatabase _db;
  final String? _alias;
  $PureDefaultsTable(this._db, [this._alias]);
  final VerificationMeta _txtMeta = const VerificationMeta('txt');
  @override
  late final GeneratedColumn<String?> txt = GeneratedColumn<String?>(
      'insert', aliasedName, true,
      type: const StringType(), requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [txt];
  @override
  String get aliasedName => _alias ?? 'pure_defaults';
  @override
  String get actualTableName => 'pure_defaults';
  @override
  VerificationContext validateIntegrity(Insertable<PureDefault> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('insert')) {
      context.handle(
          _txtMeta, txt.isAcceptableOrUnknown(data['insert']!, _txtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {txt};
  @override
  PureDefault map(Map<String, dynamic> data, {String? tablePrefix}) {
    return PureDefault.fromData(data,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  $PureDefaultsTable createAlias(String alias) {
    return $PureDefaultsTable(_db, alias);
  }
}

class CategoryTodoCountViewData extends DataClass {
  final String description;
  final int itemCount;
  CategoryTodoCountViewData(
      {required this.description, required this.itemCount});
  factory CategoryTodoCountViewData.fromData(Map<String, dynamic> data,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return CategoryTodoCountViewData(
      description: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}categories.desc'])!,
      itemCount: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}item_count'])!,
    );
  }
  factory CategoryTodoCountViewData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryTodoCountViewData(
      description: serializer.fromJson<String>(json['description']),
      itemCount: serializer.fromJson<int>(json['itemCount']),
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
      'description': serializer.toJson<String>(description),
      'itemCount': serializer.toJson<int>(itemCount),
    };
  }

  CategoryTodoCountViewData copyWith({String? description, int? itemCount}) =>
      CategoryTodoCountViewData(
        description: description ?? this.description,
        itemCount: itemCount ?? this.itemCount,
      );
  @override
  String toString() {
    return (StringBuffer('CategoryTodoCountViewData(')
          ..write('description: $description, ')
          ..write('itemCount: $itemCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(description, itemCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryTodoCountViewData &&
          other.description == this.description &&
          other.itemCount == this.itemCount);
}

class $CategoryTodoCountViewView
    extends ViewInfo<$CategoryTodoCountViewView, CategoryTodoCountViewData>
    implements HasResultSet {
  final _$TodoDb _db;
  final String? _alias;
  $CategoryTodoCountViewView(this._db, [this._alias]);
  $TodosTableTable get todos => _db.todosTable;
  $CategoriesTable get categories => _db.categories;
  @override
  List<GeneratedColumn> get $columns => [categories.description, itemCount];
  @override
  String get aliasedName => _alias ?? entityName;
  @override
  String get entityName => 'category_todo_count_view';
  @override
  String? get createViewStmt => null;
  @override
  $CategoryTodoCountViewView get asDslTable => this;
  @override
  CategoryTodoCountViewData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    return CategoryTodoCountViewData.fromData(data,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  late final GeneratedColumn<String?> description = GeneratedColumn<String?>(
      'desc', aliasedName, false,
      type: const StringType(), $customConstraints: 'NOT NULL UNIQUE');
  late final GeneratedColumn<int?> itemCount = GeneratedColumn<int?>(
      'item_count', aliasedName, false,
      type: const IntType(), generatedAs: GeneratedAs(todos.id.count(), false));
  @override
  $CategoryTodoCountViewView createAlias(String alias) {
    return $CategoryTodoCountViewView(_db, alias);
  }

  @override
  Query? get query =>
      (_db.selectOnly(categories, includeJoinedTableColumns: false)
            ..addColumns($columns))
          .join([innerJoin(todos, todos.category.equalsExp(categories.id))]);
  @override
  Set<String> get readTables => const {'todos', 'categories'};
}

class TodoWithCategoryViewData extends DataClass {
  final String? title;
  final String description;
  TodoWithCategoryViewData({this.title, required this.description});
  factory TodoWithCategoryViewData.fromData(Map<String, dynamic> data,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return TodoWithCategoryViewData(
      title: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}todos.title']),
      description: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}categories.desc'])!,
    );
  }
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
  final _$TodoDb _db;
  final String? _alias;
  $TodoWithCategoryViewView(this._db, [this._alias]);
  $TodosTableTable get todos => _db.todosTable;
  $CategoriesTable get categories => _db.categories;
  @override
  List<GeneratedColumn> get $columns => [todos.title, categories.description];
  @override
  String get aliasedName => _alias ?? entityName;
  @override
  String get entityName => 'todo_with_category_view';
  @override
  String? get createViewStmt => null;
  @override
  $TodoWithCategoryViewView get asDslTable => this;
  @override
  TodoWithCategoryViewData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    return TodoWithCategoryViewData.fromData(data,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  late final GeneratedColumn<String?> title = GeneratedColumn<String?>(
      'title', aliasedName, true,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 4, maxTextLength: 16),
      type: const StringType());
  late final GeneratedColumn<String?> description = GeneratedColumn<String?>(
      'desc', aliasedName, false,
      type: const StringType(), $customConstraints: 'NOT NULL UNIQUE');
  @override
  $TodoWithCategoryViewView createAlias(String alias) {
    return $TodoWithCategoryViewView(_db, alias);
  }

  @override
  Query? get query => (_db.selectOnly(todos, includeJoinedTableColumns: false)
        ..addColumns($columns))
      .join([innerJoin(categories, categories.id.equalsExp(todos.category))]);
  @override
  Set<String> get readTables => const {'todos', 'categories'};
}

abstract class _$TodoDb extends GeneratedDatabase {
  _$TodoDb(QueryExecutor e) : super(SqlTypeSystem.defaultInstance, e);
  _$TodoDb.connect(DatabaseConnection c) : super.connect(c);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $TodosTableTable todosTable = $TodosTableTable(this);
  late final $UsersTable users = $UsersTable(this);
  late final $SharedTodosTable sharedTodos = $SharedTodosTable(this);
  late final $TableWithoutPKTable tableWithoutPK = $TableWithoutPKTable(this);
  late final $PureDefaultsTable pureDefaults = $PureDefaultsTable(this);
  late final $CategoryTodoCountViewView categoryTodoCountView =
      $CategoryTodoCountViewView(this);
  late final $TodoWithCategoryViewView todoWithCategoryView =
      $TodoWithCategoryViewView(this);
  late final SomeDao someDao = SomeDao(this as TodoDb);
  Selectable<AllTodosWithCategoryResult> allTodosWithCategory() {
    return customSelect(
        'SELECT  t.*, c.id AS catId, c."desc" AS catDesc FROM todos AS t INNER JOIN categories AS c ON c.id = t.category',
        variables: [],
        readsFrom: {
          categories,
          todosTable,
        }).map((QueryRow row) {
      return AllTodosWithCategoryResult(
        row: row,
        id: row.read<int>('id'),
        title: row.read<String?>('title'),
        content: row.read<String>('content'),
        targetDate: row.read<DateTime?>('target_date'),
        category: row.read<int?>('category'),
        catId: row.read<int>('catId'),
        catDesc: row.read<String>('catDesc'),
      );
    });
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
        'SELECT  * FROM todos WHERE title = ?2 OR id IN ($expandedvar3) OR title = ?1',
        variables: [
          Variable<String?>(var1),
          Variable<String?>(var2),
          for (var $ in var3) Variable<int>($)
        ],
        readsFrom: {
          todosTable,
        }).map(todosTable.mapFromRow);
  }

  Selectable<TodoEntry> search({required int id}) {
    return customSelect(
        'SELECT  * FROM todos WHERE CASE WHEN -1 = ?1 THEN 1 ELSE id = ?1 END',
        variables: [
          Variable<int>(id)
        ],
        readsFrom: {
          todosTable,
        }).map(todosTable.mapFromRow);
  }

  Selectable<MyCustomObject> findCustom() {
    return customSelect(
        'SELECT  custom FROM table_without_p_k WHERE some_float < 10',
        variables: [],
        readsFrom: {
          tableWithoutPK,
        }).map((QueryRow row) => $TableWithoutPKTable.$converter0
        .mapToDart(row.read<String>('custom'))!);
  }

  @override
  Iterable<TableInfo> get allTables => allSchemaEntities.whereType<TableInfo>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        categories,
        todosTable,
        users,
        sharedTodos,
        tableWithoutPK,
        pureDefaults,
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
  final int catId;
  final String catDesc;
  AllTodosWithCategoryResult({
    required QueryRow row,
    required this.id,
    this.title,
    required this.content,
    this.targetDate,
    this.category,
    required this.catId,
    required this.catDesc,
  }) : super(row);
  @override
  int get hashCode =>
      Object.hash(id, title, content, targetDate, category, catId, catDesc);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AllTodosWithCategoryResult &&
          other.id == this.id &&
          other.title == this.title &&
          other.content == this.content &&
          other.targetDate == this.targetDate &&
          other.category == this.category &&
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
          ..write('catId: $catId, ')
          ..write('catDesc: $catDesc')
          ..write(')'))
        .toString();
  }
}

// **************************************************************************
// DaoGenerator
// **************************************************************************

mixin _$SomeDaoMixin on DatabaseAccessor<TodoDb> {
  $UsersTable get users => attachedDatabase.users;
  $SharedTodosTable get sharedTodos => attachedDatabase.sharedTodos;
  $CategoriesTable get categories => attachedDatabase.categories;
  $TodosTableTable get todosTable => attachedDatabase.todosTable;
  Selectable<TodoEntry> todosForUser({required int user}) {
    return customSelect(
        'SELECT  t.* FROM todos AS t INNER JOIN shared_todos AS st ON st.todo = t.id INNER JOIN users AS u ON u.id = st.user WHERE u.id = ?1',
        variables: [
          Variable<int>(user)
        ],
        readsFrom: {
          todosTable,
          sharedTodos,
          users,
        }).map(todosTable.mapFromRow);
  }
}
