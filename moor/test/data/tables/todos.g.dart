// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todos.dart';

// **************************************************************************
// MoorGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps, unnecessary_this
class TodoEntry extends DataClass implements Insertable<TodoEntry> {
  final int id;
  final String title;
  final String content;
  final DateTime targetDate;
  final int category;
  TodoEntry(
      {@required this.id,
      this.title,
      @required this.content,
      this.targetDate,
      this.category});
  factory TodoEntry.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final intType = db.typeSystem.forDartType<int>();
    final stringType = db.typeSystem.forDartType<String>();
    final dateTimeType = db.typeSystem.forDartType<DateTime>();
    return TodoEntry(
      id: intType.mapFromDatabaseResponse(data['${effectivePrefix}id']),
      title:
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}title']),
      content:
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}content']),
      targetDate: dateTimeType
          .mapFromDatabaseResponse(data['${effectivePrefix}target_date']),
      category:
          intType.mapFromDatabaseResponse(data['${effectivePrefix}category']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<int>(id);
    }
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    if (!nullToAbsent || targetDate != null) {
      map['target_date'] = Variable<DateTime>(targetDate);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<int>(category);
    }
    return map;
  }

  TodosTableCompanion toCompanion(bool nullToAbsent) {
    return TodosTableCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      title:
          title == null && nullToAbsent ? const Value.absent() : Value(title),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      targetDate: targetDate == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDate),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
    );
  }

  factory TodoEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return TodoEntry(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      targetDate: serializer.fromJson<DateTime>(json['target_date']),
      category: serializer.fromJson<int>(json['category']),
    );
  }
  factory TodoEntry.fromJsonString(String encodedJson,
          {ValueSerializer serializer}) =>
      TodoEntry.fromJson(
          DataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'content': serializer.toJson<String>(content),
      'target_date': serializer.toJson<DateTime>(targetDate),
      'category': serializer.toJson<int>(category),
    };
  }

  TodoEntry copyWith(
          {int id,
          Value<String> title = const Value.absent(),
          String content,
          Value<DateTime> targetDate = const Value.absent(),
          Value<int> category = const Value.absent()}) =>
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
  int get hashCode => $mrjf($mrjc(
      id.hashCode,
      $mrjc(
          title.hashCode,
          $mrjc(content.hashCode,
              $mrjc(targetDate.hashCode, category.hashCode)))));
  @override
  bool operator ==(dynamic other) =>
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
  final Value<String> title;
  final Value<String> content;
  final Value<DateTime> targetDate;
  final Value<int> category;
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
    @required String content,
    this.targetDate = const Value.absent(),
    this.category = const Value.absent(),
  }) : content = Value(content);
  static Insertable<TodoEntry> custom({
    Expression<int> id,
    Expression<String> title,
    Expression<String> content,
    Expression<DateTime> targetDate,
    Expression<int> category,
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
      {Value<int> id,
      Value<String> title,
      Value<String> content,
      Value<DateTime> targetDate,
      Value<int> category}) {
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
  final String _alias;
  $TodosTableTable(this._db, [this._alias]);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  GeneratedIntColumn _id;
  @override
  GeneratedIntColumn get id => _id ??= _constructId();
  GeneratedIntColumn _constructId() {
    return GeneratedIntColumn('id', $tableName, false,
        hasAutoIncrement: true, declaredAsPrimaryKey: true);
  }

  final VerificationMeta _titleMeta = const VerificationMeta('title');
  GeneratedTextColumn _title;
  @override
  GeneratedTextColumn get title => _title ??= _constructTitle();
  GeneratedTextColumn _constructTitle() {
    return GeneratedTextColumn('title', $tableName, true,
        minTextLength: 4, maxTextLength: 16);
  }

  final VerificationMeta _contentMeta = const VerificationMeta('content');
  GeneratedTextColumn _content;
  @override
  GeneratedTextColumn get content => _content ??= _constructContent();
  GeneratedTextColumn _constructContent() {
    return GeneratedTextColumn(
      'content',
      $tableName,
      false,
    );
  }

  final VerificationMeta _targetDateMeta = const VerificationMeta('targetDate');
  GeneratedDateTimeColumn _targetDate;
  @override
  GeneratedDateTimeColumn get targetDate =>
      _targetDate ??= _constructTargetDate();
  GeneratedDateTimeColumn _constructTargetDate() {
    return GeneratedDateTimeColumn(
      'target_date',
      $tableName,
      true,
    );
  }

  final VerificationMeta _categoryMeta = const VerificationMeta('category');
  GeneratedIntColumn _category;
  @override
  GeneratedIntColumn get category => _category ??= _constructCategory();
  GeneratedIntColumn _constructCategory() {
    return GeneratedIntColumn(
      'category',
      $tableName,
      true,
    );
  }

  @override
  List<GeneratedColumn> get $columns =>
      [id, title, content, targetDate, category];
  @override
  $TodosTableTable get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'todos';
  @override
  final String actualTableName = 'todos';
  @override
  VerificationContext validateIntegrity(Insertable<TodoEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id'], _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title'], _titleMeta));
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content'], _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('target_date')) {
      context.handle(
          _targetDateMeta,
          targetDate.isAcceptableOrUnknown(
              data['target_date'], _targetDateMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category'], _categoryMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TodoEntry map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return TodoEntry.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  $TodosTableTable createAlias(String alias) {
    return $TodosTableTable(_db, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final int id;
  final String description;
  final CategoryPriority priority;
  Category(
      {@required this.id, @required this.description, @required this.priority});
  factory Category.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final intType = db.typeSystem.forDartType<int>();
    final stringType = db.typeSystem.forDartType<String>();
    return Category(
      id: intType.mapFromDatabaseResponse(data['${effectivePrefix}id']),
      description:
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}desc']),
      priority: $CategoriesTable.$converter0.mapToDart(
          intType.mapFromDatabaseResponse(data['${effectivePrefix}priority'])),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<int>(id);
    }
    if (!nullToAbsent || description != null) {
      map['desc'] = Variable<String>(description);
    }
    if (!nullToAbsent || priority != null) {
      final converter = $CategoriesTable.$converter0;
      map['priority'] = Variable<int>(converter.mapToSql(priority));
    }
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      priority: priority == null && nullToAbsent
          ? const Value.absent()
          : Value(priority),
    );
  }

  factory Category.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<int>(json['id']),
      description: serializer.fromJson<String>(json['description']),
      priority: serializer.fromJson<CategoryPriority>(json['priority']),
    );
  }
  factory Category.fromJsonString(String encodedJson,
          {ValueSerializer serializer}) =>
      Category.fromJson(
          DataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'description': serializer.toJson<String>(description),
      'priority': serializer.toJson<CategoryPriority>(priority),
    };
  }

  Category copyWith({int id, String description, CategoryPriority priority}) =>
      Category(
        id: id ?? this.id,
        description: description ?? this.description,
        priority: priority ?? this.priority,
      );
  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('description: $description, ')
          ..write('priority: $priority')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      $mrjf($mrjc(id.hashCode, $mrjc(description.hashCode, priority.hashCode)));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.description == this.description &&
          other.priority == this.priority);
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
    @required String description,
    this.priority = const Value.absent(),
  }) : description = Value(description);
  static Insertable<Category> custom({
    Expression<int> id,
    Expression<String> description,
    Expression<int> priority,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (description != null) 'desc': description,
      if (priority != null) 'priority': priority,
    });
  }

  CategoriesCompanion copyWith(
      {Value<int> id,
      Value<String> description,
      Value<CategoryPriority> priority}) {
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
      map['priority'] = Variable<int>(converter.mapToSql(priority.value));
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
  final String _alias;
  $CategoriesTable(this._db, [this._alias]);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  GeneratedIntColumn _id;
  @override
  GeneratedIntColumn get id => _id ??= _constructId();
  GeneratedIntColumn _constructId() {
    return GeneratedIntColumn('id', $tableName, false,
        hasAutoIncrement: true, declaredAsPrimaryKey: true);
  }

  final VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  GeneratedTextColumn _description;
  @override
  GeneratedTextColumn get description =>
      _description ??= _constructDescription();
  GeneratedTextColumn _constructDescription() {
    return GeneratedTextColumn('desc', $tableName, false,
        $customConstraints: 'NOT NULL UNIQUE');
  }

  final VerificationMeta _priorityMeta = const VerificationMeta('priority');
  GeneratedIntColumn _priority;
  @override
  GeneratedIntColumn get priority => _priority ??= _constructPriority();
  GeneratedIntColumn _constructPriority() {
    return GeneratedIntColumn('priority', $tableName, false,
        defaultValue: const Constant(0));
  }

  @override
  List<GeneratedColumn> get $columns => [id, description, priority];
  @override
  $CategoriesTable get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'categories';
  @override
  final String actualTableName = 'categories';
  @override
  VerificationContext validateIntegrity(Insertable<Category> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id'], _idMeta));
    }
    if (data.containsKey('desc')) {
      context.handle(_descriptionMeta,
          description.isAcceptableOrUnknown(data['desc'], _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    context.handle(_priorityMeta, const VerificationResult.success());
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return Category.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(_db, alias);
  }

  static TypeConverter<CategoryPriority, int> $converter0 =
      const EnumIndexConverter<CategoryPriority>(CategoryPriority.values);
}

class User extends DataClass implements Insertable<User> {
  final int id;
  final String name;
  final bool isAwesome;
  final Uint8List profilePicture;
  final DateTime creationTime;
  User(
      {@required this.id,
      @required this.name,
      @required this.isAwesome,
      @required this.profilePicture,
      @required this.creationTime});
  factory User.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final intType = db.typeSystem.forDartType<int>();
    final stringType = db.typeSystem.forDartType<String>();
    final boolType = db.typeSystem.forDartType<bool>();
    final uint8ListType = db.typeSystem.forDartType<Uint8List>();
    final dateTimeType = db.typeSystem.forDartType<DateTime>();
    return User(
      id: intType.mapFromDatabaseResponse(data['${effectivePrefix}id']),
      name: stringType.mapFromDatabaseResponse(data['${effectivePrefix}name']),
      isAwesome: boolType
          .mapFromDatabaseResponse(data['${effectivePrefix}is_awesome']),
      profilePicture: uint8ListType
          .mapFromDatabaseResponse(data['${effectivePrefix}profile_picture']),
      creationTime: dateTimeType
          .mapFromDatabaseResponse(data['${effectivePrefix}creation_time']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<int>(id);
    }
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || isAwesome != null) {
      map['is_awesome'] = Variable<bool>(isAwesome);
    }
    if (!nullToAbsent || profilePicture != null) {
      map['profile_picture'] = Variable<Uint8List>(profilePicture);
    }
    if (!nullToAbsent || creationTime != null) {
      map['creation_time'] = Variable<DateTime>(creationTime);
    }
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      isAwesome: isAwesome == null && nullToAbsent
          ? const Value.absent()
          : Value(isAwesome),
      profilePicture: profilePicture == null && nullToAbsent
          ? const Value.absent()
          : Value(profilePicture),
      creationTime: creationTime == null && nullToAbsent
          ? const Value.absent()
          : Value(creationTime),
    );
  }

  factory User.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      isAwesome: serializer.fromJson<bool>(json['isAwesome']),
      profilePicture: serializer.fromJson<Uint8List>(json['profilePicture']),
      creationTime: serializer.fromJson<DateTime>(json['creationTime']),
    );
  }
  factory User.fromJsonString(String encodedJson,
          {ValueSerializer serializer}) =>
      User.fromJson(DataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'isAwesome': serializer.toJson<bool>(isAwesome),
      'profilePicture': serializer.toJson<Uint8List>(profilePicture),
      'creationTime': serializer.toJson<DateTime>(creationTime),
    };
  }

  User copyWith(
          {int id,
          String name,
          bool isAwesome,
          Uint8List profilePicture,
          DateTime creationTime}) =>
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
  int get hashCode => $mrjf($mrjc(
      id.hashCode,
      $mrjc(
          name.hashCode,
          $mrjc(isAwesome.hashCode,
              $mrjc(profilePicture.hashCode, creationTime.hashCode)))));
  @override
  bool operator ==(dynamic other) =>
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
    @required String name,
    this.isAwesome = const Value.absent(),
    @required Uint8List profilePicture,
    this.creationTime = const Value.absent(),
  })  : name = Value(name),
        profilePicture = Value(profilePicture);
  static Insertable<User> custom({
    Expression<int> id,
    Expression<String> name,
    Expression<bool> isAwesome,
    Expression<Uint8List> profilePicture,
    Expression<DateTime> creationTime,
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
      {Value<int> id,
      Value<String> name,
      Value<bool> isAwesome,
      Value<Uint8List> profilePicture,
      Value<DateTime> creationTime}) {
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
  final String _alias;
  $UsersTable(this._db, [this._alias]);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  GeneratedIntColumn _id;
  @override
  GeneratedIntColumn get id => _id ??= _constructId();
  GeneratedIntColumn _constructId() {
    return GeneratedIntColumn('id', $tableName, false,
        hasAutoIncrement: true, declaredAsPrimaryKey: true);
  }

  final VerificationMeta _nameMeta = const VerificationMeta('name');
  GeneratedTextColumn _name;
  @override
  GeneratedTextColumn get name => _name ??= _constructName();
  GeneratedTextColumn _constructName() {
    return GeneratedTextColumn('name', $tableName, false,
        minTextLength: 6, maxTextLength: 32);
  }

  final VerificationMeta _isAwesomeMeta = const VerificationMeta('isAwesome');
  GeneratedBoolColumn _isAwesome;
  @override
  GeneratedBoolColumn get isAwesome => _isAwesome ??= _constructIsAwesome();
  GeneratedBoolColumn _constructIsAwesome() {
    return GeneratedBoolColumn('is_awesome', $tableName, false,
        defaultValue: const Constant(true));
  }

  final VerificationMeta _profilePictureMeta =
      const VerificationMeta('profilePicture');
  GeneratedBlobColumn _profilePicture;
  @override
  GeneratedBlobColumn get profilePicture =>
      _profilePicture ??= _constructProfilePicture();
  GeneratedBlobColumn _constructProfilePicture() {
    return GeneratedBlobColumn(
      'profile_picture',
      $tableName,
      false,
    );
  }

  final VerificationMeta _creationTimeMeta =
      const VerificationMeta('creationTime');
  GeneratedDateTimeColumn _creationTime;
  @override
  GeneratedDateTimeColumn get creationTime =>
      _creationTime ??= _constructCreationTime();
  GeneratedDateTimeColumn _constructCreationTime() {
    return GeneratedDateTimeColumn('creation_time', $tableName, false,
        defaultValue: currentDateAndTime);
  }

  @override
  List<GeneratedColumn> get $columns =>
      [id, name, isAwesome, profilePicture, creationTime];
  @override
  $UsersTable get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'users';
  @override
  final String actualTableName = 'users';
  @override
  VerificationContext validateIntegrity(Insertable<User> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id'], _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name'], _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_awesome')) {
      context.handle(_isAwesomeMeta,
          isAwesome.isAcceptableOrUnknown(data['is_awesome'], _isAwesomeMeta));
    }
    if (data.containsKey('profile_picture')) {
      context.handle(
          _profilePictureMeta,
          profilePicture.isAcceptableOrUnknown(
              data['profile_picture'], _profilePictureMeta));
    } else if (isInserting) {
      context.missing(_profilePictureMeta);
    }
    if (data.containsKey('creation_time')) {
      context.handle(
          _creationTimeMeta,
          creationTime.isAcceptableOrUnknown(
              data['creation_time'], _creationTimeMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return User.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(_db, alias);
  }
}

class SharedTodo extends DataClass implements Insertable<SharedTodo> {
  final int todo;
  final int user;
  SharedTodo({@required this.todo, @required this.user});
  factory SharedTodo.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final intType = db.typeSystem.forDartType<int>();
    return SharedTodo(
      todo: intType.mapFromDatabaseResponse(data['${effectivePrefix}todo']),
      user: intType.mapFromDatabaseResponse(data['${effectivePrefix}user']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || todo != null) {
      map['todo'] = Variable<int>(todo);
    }
    if (!nullToAbsent || user != null) {
      map['user'] = Variable<int>(user);
    }
    return map;
  }

  SharedTodosCompanion toCompanion(bool nullToAbsent) {
    return SharedTodosCompanion(
      todo: todo == null && nullToAbsent ? const Value.absent() : Value(todo),
      user: user == null && nullToAbsent ? const Value.absent() : Value(user),
    );
  }

  factory SharedTodo.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return SharedTodo(
      todo: serializer.fromJson<int>(json['todo']),
      user: serializer.fromJson<int>(json['user']),
    );
  }
  factory SharedTodo.fromJsonString(String encodedJson,
          {ValueSerializer serializer}) =>
      SharedTodo.fromJson(
          DataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'todo': serializer.toJson<int>(todo),
      'user': serializer.toJson<int>(user),
    };
  }

  SharedTodo copyWith({int todo, int user}) => SharedTodo(
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
  int get hashCode => $mrjf($mrjc(todo.hashCode, user.hashCode));
  @override
  bool operator ==(dynamic other) =>
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
    @required int todo,
    @required int user,
  })  : todo = Value(todo),
        user = Value(user);
  static Insertable<SharedTodo> custom({
    Expression<int> todo,
    Expression<int> user,
  }) {
    return RawValuesInsertable({
      if (todo != null) 'todo': todo,
      if (user != null) 'user': user,
    });
  }

  SharedTodosCompanion copyWith({Value<int> todo, Value<int> user}) {
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
  final String _alias;
  $SharedTodosTable(this._db, [this._alias]);
  final VerificationMeta _todoMeta = const VerificationMeta('todo');
  GeneratedIntColumn _todo;
  @override
  GeneratedIntColumn get todo => _todo ??= _constructTodo();
  GeneratedIntColumn _constructTodo() {
    return GeneratedIntColumn(
      'todo',
      $tableName,
      false,
    );
  }

  final VerificationMeta _userMeta = const VerificationMeta('user');
  GeneratedIntColumn _user;
  @override
  GeneratedIntColumn get user => _user ??= _constructUser();
  GeneratedIntColumn _constructUser() {
    return GeneratedIntColumn(
      'user',
      $tableName,
      false,
    );
  }

  @override
  List<GeneratedColumn> get $columns => [todo, user];
  @override
  $SharedTodosTable get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'shared_todos';
  @override
  final String actualTableName = 'shared_todos';
  @override
  VerificationContext validateIntegrity(Insertable<SharedTodo> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('todo')) {
      context.handle(
          _todoMeta, todo.isAcceptableOrUnknown(data['todo'], _todoMeta));
    } else if (isInserting) {
      context.missing(_todoMeta);
    }
    if (data.containsKey('user')) {
      context.handle(
          _userMeta, user.isAcceptableOrUnknown(data['user'], _userMeta));
    } else if (isInserting) {
      context.missing(_userMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {todo, user};
  @override
  SharedTodo map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return SharedTodo.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  $SharedTodosTable createAlias(String alias) {
    return $SharedTodosTable(_db, alias);
  }
}

class TableWithoutPKData extends DataClass
    implements Insertable<TableWithoutPKData> {
  final int notReallyAnId;
  final double someFloat;
  final MyCustomObject custom;
  TableWithoutPKData(
      {@required this.notReallyAnId,
      @required this.someFloat,
      @required this.custom});
  factory TableWithoutPKData.fromData(
      Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final intType = db.typeSystem.forDartType<int>();
    final doubleType = db.typeSystem.forDartType<double>();
    final stringType = db.typeSystem.forDartType<String>();
    return TableWithoutPKData(
      notReallyAnId: intType
          .mapFromDatabaseResponse(data['${effectivePrefix}not_really_an_id']),
      someFloat: doubleType
          .mapFromDatabaseResponse(data['${effectivePrefix}some_float']),
      custom: $TableWithoutPKTable.$converter0.mapToDart(
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}custom'])),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || notReallyAnId != null) {
      map['not_really_an_id'] = Variable<int>(notReallyAnId);
    }
    if (!nullToAbsent || someFloat != null) {
      map['some_float'] = Variable<double>(someFloat);
    }
    if (!nullToAbsent || custom != null) {
      final converter = $TableWithoutPKTable.$converter0;
      map['custom'] = Variable<String>(converter.mapToSql(custom));
    }
    return map;
  }

  TableWithoutPKCompanion toCompanion(bool nullToAbsent) {
    return TableWithoutPKCompanion(
      notReallyAnId: notReallyAnId == null && nullToAbsent
          ? const Value.absent()
          : Value(notReallyAnId),
      someFloat: someFloat == null && nullToAbsent
          ? const Value.absent()
          : Value(someFloat),
      custom:
          custom == null && nullToAbsent ? const Value.absent() : Value(custom),
    );
  }

  factory TableWithoutPKData.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return TableWithoutPKData(
      notReallyAnId: serializer.fromJson<int>(json['notReallyAnId']),
      someFloat: serializer.fromJson<double>(json['someFloat']),
      custom: serializer.fromJson<MyCustomObject>(json['custom']),
    );
  }
  factory TableWithoutPKData.fromJsonString(String encodedJson,
          {ValueSerializer serializer}) =>
      TableWithoutPKData.fromJson(
          DataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'notReallyAnId': serializer.toJson<int>(notReallyAnId),
      'someFloat': serializer.toJson<double>(someFloat),
      'custom': serializer.toJson<MyCustomObject>(custom),
    };
  }

  TableWithoutPKData copyWith(
          {int notReallyAnId, double someFloat, MyCustomObject custom}) =>
      TableWithoutPKData(
        notReallyAnId: notReallyAnId ?? this.notReallyAnId,
        someFloat: someFloat ?? this.someFloat,
        custom: custom ?? this.custom,
      );
  @override
  String toString() {
    return (StringBuffer('TableWithoutPKData(')
          ..write('notReallyAnId: $notReallyAnId, ')
          ..write('someFloat: $someFloat, ')
          ..write('custom: $custom')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(
      notReallyAnId.hashCode, $mrjc(someFloat.hashCode, custom.hashCode)));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is TableWithoutPKData &&
          other.notReallyAnId == this.notReallyAnId &&
          other.someFloat == this.someFloat &&
          other.custom == this.custom);
}

class TableWithoutPKCompanion extends UpdateCompanion<TableWithoutPKData> {
  final Value<int> notReallyAnId;
  final Value<double> someFloat;
  final Value<MyCustomObject> custom;
  const TableWithoutPKCompanion({
    this.notReallyAnId = const Value.absent(),
    this.someFloat = const Value.absent(),
    this.custom = const Value.absent(),
  });
  TableWithoutPKCompanion.insert({
    @required int notReallyAnId,
    @required double someFloat,
    this.custom = const Value.absent(),
  })  : notReallyAnId = Value(notReallyAnId),
        someFloat = Value(someFloat);
  static Insertable<TableWithoutPKData> createCustom({
    Expression<int> notReallyAnId,
    Expression<double> someFloat,
    Expression<String> custom,
  }) {
    return RawValuesInsertable({
      if (notReallyAnId != null) 'not_really_an_id': notReallyAnId,
      if (someFloat != null) 'some_float': someFloat,
      if (custom != null) 'custom': custom,
    });
  }

  TableWithoutPKCompanion copyWith(
      {Value<int> notReallyAnId,
      Value<double> someFloat,
      Value<MyCustomObject> custom}) {
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
      map['custom'] = Variable<String>(converter.mapToSql(custom.value));
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

class $TableWithoutPKTable extends TableWithoutPK
    with TableInfo<$TableWithoutPKTable, TableWithoutPKData> {
  final GeneratedDatabase _db;
  final String _alias;
  $TableWithoutPKTable(this._db, [this._alias]);
  final VerificationMeta _notReallyAnIdMeta =
      const VerificationMeta('notReallyAnId');
  GeneratedIntColumn _notReallyAnId;
  @override
  GeneratedIntColumn get notReallyAnId =>
      _notReallyAnId ??= _constructNotReallyAnId();
  GeneratedIntColumn _constructNotReallyAnId() {
    return GeneratedIntColumn(
      'not_really_an_id',
      $tableName,
      false,
    );
  }

  final VerificationMeta _someFloatMeta = const VerificationMeta('someFloat');
  GeneratedRealColumn _someFloat;
  @override
  GeneratedRealColumn get someFloat => _someFloat ??= _constructSomeFloat();
  GeneratedRealColumn _constructSomeFloat() {
    return GeneratedRealColumn(
      'some_float',
      $tableName,
      false,
    );
  }

  final VerificationMeta _customMeta = const VerificationMeta('custom');
  GeneratedTextColumn _custom;
  @override
  GeneratedTextColumn get custom => _custom ??= _constructCustom();
  GeneratedTextColumn _constructCustom() {
    return GeneratedTextColumn(
      'custom',
      $tableName,
      false,
    )..clientDefault = _uuid.v4;
  }

  @override
  List<GeneratedColumn> get $columns => [notReallyAnId, someFloat, custom];
  @override
  $TableWithoutPKTable get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'table_without_p_k';
  @override
  final String actualTableName = 'table_without_p_k';
  @override
  VerificationContext validateIntegrity(Insertable<TableWithoutPKData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('not_really_an_id')) {
      context.handle(
          _notReallyAnIdMeta,
          notReallyAnId.isAcceptableOrUnknown(
              data['not_really_an_id'], _notReallyAnIdMeta));
    } else if (isInserting) {
      context.missing(_notReallyAnIdMeta);
    }
    if (data.containsKey('some_float')) {
      context.handle(_someFloatMeta,
          someFloat.isAcceptableOrUnknown(data['some_float'], _someFloatMeta));
    } else if (isInserting) {
      context.missing(_someFloatMeta);
    }
    context.handle(_customMeta, const VerificationResult.success());
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => <GeneratedColumn>{};
  @override
  TableWithoutPKData map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return TableWithoutPKData.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  $TableWithoutPKTable createAlias(String alias) {
    return $TableWithoutPKTable(_db, alias);
  }

  static TypeConverter<MyCustomObject, String> $converter0 =
      const CustomConverter();
}

class PureDefault extends DataClass implements Insertable<PureDefault> {
  final String txt;
  PureDefault({this.txt});
  factory PureDefault.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final stringType = db.typeSystem.forDartType<String>();
    return PureDefault(
      txt: stringType.mapFromDatabaseResponse(data['${effectivePrefix}insert']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || txt != null) {
      map['insert'] = Variable<String>(txt);
    }
    return map;
  }

  PureDefaultsCompanion toCompanion(bool nullToAbsent) {
    return PureDefaultsCompanion(
      txt: txt == null && nullToAbsent ? const Value.absent() : Value(txt),
    );
  }

  factory PureDefault.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return PureDefault(
      txt: serializer.fromJson<String>(json['txt']),
    );
  }
  factory PureDefault.fromJsonString(String encodedJson,
          {ValueSerializer serializer}) =>
      PureDefault.fromJson(
          DataClass.parseJson(encodedJson) as Map<String, dynamic>,
          serializer: serializer);
  @override
  Map<String, dynamic> toJson({ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'txt': serializer.toJson<String>(txt),
    };
  }

  PureDefault copyWith({Value<String> txt = const Value.absent()}) =>
      PureDefault(
        txt: txt.present ? txt.value : this.txt,
      );
  @override
  String toString() {
    return (StringBuffer('PureDefault(')..write('txt: $txt')..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf(txt.hashCode);
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) || (other is PureDefault && other.txt == this.txt);
}

class PureDefaultsCompanion extends UpdateCompanion<PureDefault> {
  final Value<String> txt;
  const PureDefaultsCompanion({
    this.txt = const Value.absent(),
  });
  PureDefaultsCompanion.insert({
    this.txt = const Value.absent(),
  });
  static Insertable<PureDefault> custom({
    Expression<String> txt,
  }) {
    return RawValuesInsertable({
      if (txt != null) 'insert': txt,
    });
  }

  PureDefaultsCompanion copyWith({Value<String> txt}) {
    return PureDefaultsCompanion(
      txt: txt ?? this.txt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (txt.present) {
      map['insert'] = Variable<String>(txt.value);
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
  final String _alias;
  $PureDefaultsTable(this._db, [this._alias]);
  final VerificationMeta _txtMeta = const VerificationMeta('txt');
  GeneratedTextColumn _txt;
  @override
  GeneratedTextColumn get txt => _txt ??= _constructTxt();
  GeneratedTextColumn _constructTxt() {
    return GeneratedTextColumn(
      'insert',
      $tableName,
      true,
    );
  }

  @override
  List<GeneratedColumn> get $columns => [txt];
  @override
  $PureDefaultsTable get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'pure_defaults';
  @override
  final String actualTableName = 'pure_defaults';
  @override
  VerificationContext validateIntegrity(Insertable<PureDefault> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('insert')) {
      context.handle(
          _txtMeta, txt.isAcceptableOrUnknown(data['insert'], _txtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {txt};
  @override
  PureDefault map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return PureDefault.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  $PureDefaultsTable createAlias(String alias) {
    return $PureDefaultsTable(_db, alias);
  }
}

abstract class _$TodoDb extends GeneratedDatabase {
  _$TodoDb(QueryExecutor e) : super(SqlTypeSystem.defaultInstance, e);
  _$TodoDb.connect(DatabaseConnection c) : super.connect(c);
  $TodosTableTable _todosTable;
  $TodosTableTable get todosTable => _todosTable ??= $TodosTableTable(this);
  $CategoriesTable _categories;
  $CategoriesTable get categories => _categories ??= $CategoriesTable(this);
  $UsersTable _users;
  $UsersTable get users => _users ??= $UsersTable(this);
  $SharedTodosTable _sharedTodos;
  $SharedTodosTable get sharedTodos => _sharedTodos ??= $SharedTodosTable(this);
  $TableWithoutPKTable _tableWithoutPK;
  $TableWithoutPKTable get tableWithoutPK =>
      _tableWithoutPK ??= $TableWithoutPKTable(this);
  $PureDefaultsTable _pureDefaults;
  $PureDefaultsTable get pureDefaults =>
      _pureDefaults ??= $PureDefaultsTable(this);
  SomeDao _someDao;
  SomeDao get someDao => _someDao ??= SomeDao(this as TodoDb);
  Selectable<AllTodosWithCategoryResult> allTodosWithCategory() {
    return customSelect(
        'SELECT t.*, c.id as catId, c."desc" as catDesc FROM todos t INNER JOIN categories c ON c.id = t.category',
        variables: [],
        readsFrom: {categories, todosTable}).map((QueryRow row) {
      return AllTodosWithCategoryResult(
        row: row,
        id: row.readInt('id'),
        title: row.readString('title'),
        content: row.readString('content'),
        targetDate: row.readDateTime('target_date'),
        category: row.readInt('category'),
        catId: row.readInt('catId'),
        catDesc: row.readString('catDesc'),
      );
    });
  }

  Future<int> deleteTodoById(int var1) {
    return customUpdate(
      'DELETE FROM todos WHERE id = ?',
      variables: [Variable.withInt(var1)],
      updates: {todosTable},
      updateKind: UpdateKind.delete,
    );
  }

  Selectable<TodoEntry> withIn(String var1, String var2, List<int> var3) {
    var $arrayStartIndex = 3;
    final expandedvar3 = $expandVar($arrayStartIndex, var3.length);
    $arrayStartIndex += var3.length;
    return customSelect(
        'SELECT * FROM todos WHERE title = ?2 OR id IN ($expandedvar3) OR title = ?1',
        variables: [
          Variable.withString(var1),
          Variable.withString(var2),
          for (var $ in var3) Variable.withInt($)
        ],
        readsFrom: {
          todosTable
        }).map(todosTable.mapFromRow);
  }

  Selectable<TodoEntry> search(int id) {
    return customSelect(
        'SELECT * FROM todos WHERE CASE WHEN -1 = :id THEN 1 ELSE id = :id END',
        variables: [Variable.withInt(id)],
        readsFrom: {todosTable}).map(todosTable.mapFromRow);
  }

  Selectable<MyCustomObject> findCustom() {
    return customSelect(
            'SELECT custom FROM table_without_p_k WHERE some_float < 10',
            variables: [],
            readsFrom: {tableWithoutPK})
        .map((QueryRow row) => $TableWithoutPKTable.$converter0
            .mapToDart(row.readString('custom')));
  }

  @override
  Iterable<TableInfo> get allTables => allSchemaEntities.whereType<TableInfo>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        todosTable,
        categories,
        users,
        sharedTodos,
        tableWithoutPK,
        pureDefaults
      ];
}

class AllTodosWithCategoryResult extends CustomResultSet {
  final int id;
  final String title;
  final String content;
  final DateTime targetDate;
  final int category;
  final int catId;
  final String catDesc;
  AllTodosWithCategoryResult({
    @required QueryRow row,
    this.id,
    this.title,
    this.content,
    this.targetDate,
    this.category,
    this.catId,
    this.catDesc,
  }) : super(row);
  @override
  int get hashCode => $mrjf($mrjc(
      id.hashCode,
      $mrjc(
          title.hashCode,
          $mrjc(
              content.hashCode,
              $mrjc(
                  targetDate.hashCode,
                  $mrjc(category.hashCode,
                      $mrjc(catId.hashCode, catDesc.hashCode)))))));
  @override
  bool operator ==(dynamic other) =>
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
  $TodosTableTable get todosTable => attachedDatabase.todosTable;
  Selectable<TodoEntry> todosForUser(int user) {
    return customSelect(
        'SELECT t.* FROM todos t INNER JOIN shared_todos st ON st.todo = t.id INNER JOIN users u ON u.id = st.user WHERE u.id = :user',
        variables: [Variable.withInt(user)],
        readsFrom: {todosTable, sharedTodos, users}).map(todosTable.mapFromRow);
  }
}
