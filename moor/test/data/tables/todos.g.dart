// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todos.dart';

// **************************************************************************
// MoorGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps
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
  factory TodoEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer = const ValueSerializer.defaults()}) {
    return TodoEntry(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      targetDate: serializer.fromJson<DateTime>(json['target_date']),
      category: serializer.fromJson<int>(json['category']),
    );
  }
  @override
  Map<String, dynamic> toJson(
      {ValueSerializer serializer = const ValueSerializer.defaults()}) {
    return {
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'content': serializer.toJson<String>(content),
      'target_date': serializer.toJson<DateTime>(targetDate),
      'category': serializer.toJson<int>(category),
    };
  }

  @override
  T createCompanion<T extends UpdateCompanion<TodoEntry>>(bool nullToAbsent) {
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
    ) as T;
  }

  TodoEntry copyWith(
          {int id,
          String title,
          String content,
          DateTime targetDate,
          int category}) =>
      TodoEntry(
        id: id ?? this.id,
        title: title ?? this.title,
        content: content ?? this.content,
        targetDate: targetDate ?? this.targetDate,
        category: category ?? this.category,
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
      $mrjc(
          $mrjc($mrjc($mrjc(0, id.hashCode), title.hashCode), content.hashCode),
          targetDate.hashCode),
      category.hashCode));
  @override
  bool operator ==(other) =>
      identical(this, other) ||
      (other is TodoEntry &&
          other.id == id &&
          other.title == title &&
          other.content == content &&
          other.targetDate == targetDate &&
          other.category == category);
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
    return GeneratedIntColumn('id', $tableName, false, hasAutoIncrement: true);
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
  VerificationContext validateIntegrity(TodosTableCompanion d,
      {bool isInserting = false}) {
    final context = VerificationContext();
    if (d.id.present) {
      context.handle(_idMeta, id.isAcceptableValue(d.id.value, _idMeta));
    } else if (id.isRequired && isInserting) {
      context.missing(_idMeta);
    }
    if (d.title.present) {
      context.handle(
          _titleMeta, title.isAcceptableValue(d.title.value, _titleMeta));
    } else if (title.isRequired && isInserting) {
      context.missing(_titleMeta);
    }
    if (d.content.present) {
      context.handle(_contentMeta,
          content.isAcceptableValue(d.content.value, _contentMeta));
    } else if (content.isRequired && isInserting) {
      context.missing(_contentMeta);
    }
    if (d.targetDate.present) {
      context.handle(_targetDateMeta,
          targetDate.isAcceptableValue(d.targetDate.value, _targetDateMeta));
    } else if (targetDate.isRequired && isInserting) {
      context.missing(_targetDateMeta);
    }
    if (d.category.present) {
      context.handle(_categoryMeta,
          category.isAcceptableValue(d.category.value, _categoryMeta));
    } else if (category.isRequired && isInserting) {
      context.missing(_categoryMeta);
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
  Map<String, Variable> entityToSql(TodosTableCompanion d) {
    final map = <String, Variable>{};
    if (d.id.present) {
      map['id'] = Variable<int, IntType>(d.id.value);
    }
    if (d.title.present) {
      map['title'] = Variable<String, StringType>(d.title.value);
    }
    if (d.content.present) {
      map['content'] = Variable<String, StringType>(d.content.value);
    }
    if (d.targetDate.present) {
      map['target_date'] = Variable<DateTime, DateTimeType>(d.targetDate.value);
    }
    if (d.category.present) {
      map['category'] = Variable<int, IntType>(d.category.value);
    }
    return map;
  }

  @override
  $TodosTableTable createAlias(String alias) {
    return $TodosTableTable(_db, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final int id;
  final String description;
  Category({@required this.id, @required this.description});
  factory Category.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final intType = db.typeSystem.forDartType<int>();
    final stringType = db.typeSystem.forDartType<String>();
    return Category(
      id: intType.mapFromDatabaseResponse(data['${effectivePrefix}id']),
      description:
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}desc']),
    );
  }
  factory Category.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer = const ValueSerializer.defaults()}) {
    return Category(
      id: serializer.fromJson<int>(json['id']),
      description: serializer.fromJson<String>(json['description']),
    );
  }
  @override
  Map<String, dynamic> toJson(
      {ValueSerializer serializer = const ValueSerializer.defaults()}) {
    return {
      'id': serializer.toJson<int>(id),
      'description': serializer.toJson<String>(description),
    };
  }

  @override
  T createCompanion<T extends UpdateCompanion<Category>>(bool nullToAbsent) {
    return CategoriesCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
    ) as T;
  }

  Category copyWith({int id, String description}) => Category(
        id: id ?? this.id,
        description: description ?? this.description,
      );
  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc($mrjc(0, id.hashCode), description.hashCode));
  @override
  bool operator ==(other) =>
      identical(this, other) ||
      (other is Category && other.id == id && other.description == description);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<int> id;
  final Value<String> description;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.description = const Value.absent(),
  });
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
    return GeneratedIntColumn('id', $tableName, false, hasAutoIncrement: true);
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

  @override
  List<GeneratedColumn> get $columns => [id, description];
  @override
  $CategoriesTable get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'categories';
  @override
  final String actualTableName = 'categories';
  @override
  VerificationContext validateIntegrity(CategoriesCompanion d,
      {bool isInserting = false}) {
    final context = VerificationContext();
    if (d.id.present) {
      context.handle(_idMeta, id.isAcceptableValue(d.id.value, _idMeta));
    } else if (id.isRequired && isInserting) {
      context.missing(_idMeta);
    }
    if (d.description.present) {
      context.handle(_descriptionMeta,
          description.isAcceptableValue(d.description.value, _descriptionMeta));
    } else if (description.isRequired && isInserting) {
      context.missing(_descriptionMeta);
    }
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
  Map<String, Variable> entityToSql(CategoriesCompanion d) {
    final map = <String, Variable>{};
    if (d.id.present) {
      map['id'] = Variable<int, IntType>(d.id.value);
    }
    if (d.description.present) {
      map['desc'] = Variable<String, StringType>(d.description.value);
    }
    return map;
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(_db, alias);
  }
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
  factory User.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer = const ValueSerializer.defaults()}) {
    return User(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      isAwesome: serializer.fromJson<bool>(json['isAwesome']),
      profilePicture: serializer.fromJson<Uint8List>(json['profilePicture']),
      creationTime: serializer.fromJson<DateTime>(json['creationTime']),
    );
  }
  @override
  Map<String, dynamic> toJson(
      {ValueSerializer serializer = const ValueSerializer.defaults()}) {
    return {
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'isAwesome': serializer.toJson<bool>(isAwesome),
      'profilePicture': serializer.toJson<Uint8List>(profilePicture),
      'creationTime': serializer.toJson<DateTime>(creationTime),
    };
  }

  @override
  T createCompanion<T extends UpdateCompanion<User>>(bool nullToAbsent) {
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
    ) as T;
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
      $mrjc(
          $mrjc(
              $mrjc($mrjc(0, id.hashCode), name.hashCode), isAwesome.hashCode),
          profilePicture.hashCode),
      creationTime.hashCode));
  @override
  bool operator ==(other) =>
      identical(this, other) ||
      (other is User &&
          other.id == id &&
          other.name == name &&
          other.isAwesome == isAwesome &&
          other.profilePicture == profilePicture &&
          other.creationTime == creationTime);
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
    return GeneratedIntColumn('id', $tableName, false, hasAutoIncrement: true);
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
  VerificationContext validateIntegrity(UsersCompanion d,
      {bool isInserting = false}) {
    final context = VerificationContext();
    if (d.id.present) {
      context.handle(_idMeta, id.isAcceptableValue(d.id.value, _idMeta));
    } else if (id.isRequired && isInserting) {
      context.missing(_idMeta);
    }
    if (d.name.present) {
      context.handle(
          _nameMeta, name.isAcceptableValue(d.name.value, _nameMeta));
    } else if (name.isRequired && isInserting) {
      context.missing(_nameMeta);
    }
    if (d.isAwesome.present) {
      context.handle(_isAwesomeMeta,
          isAwesome.isAcceptableValue(d.isAwesome.value, _isAwesomeMeta));
    } else if (isAwesome.isRequired && isInserting) {
      context.missing(_isAwesomeMeta);
    }
    if (d.profilePicture.present) {
      context.handle(
          _profilePictureMeta,
          profilePicture.isAcceptableValue(
              d.profilePicture.value, _profilePictureMeta));
    } else if (profilePicture.isRequired && isInserting) {
      context.missing(_profilePictureMeta);
    }
    if (d.creationTime.present) {
      context.handle(
          _creationTimeMeta,
          creationTime.isAcceptableValue(
              d.creationTime.value, _creationTimeMeta));
    } else if (creationTime.isRequired && isInserting) {
      context.missing(_creationTimeMeta);
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
  Map<String, Variable> entityToSql(UsersCompanion d) {
    final map = <String, Variable>{};
    if (d.id.present) {
      map['id'] = Variable<int, IntType>(d.id.value);
    }
    if (d.name.present) {
      map['name'] = Variable<String, StringType>(d.name.value);
    }
    if (d.isAwesome.present) {
      map['is_awesome'] = Variable<bool, BoolType>(d.isAwesome.value);
    }
    if (d.profilePicture.present) {
      map['profile_picture'] =
          Variable<Uint8List, BlobType>(d.profilePicture.value);
    }
    if (d.creationTime.present) {
      map['creation_time'] =
          Variable<DateTime, DateTimeType>(d.creationTime.value);
    }
    return map;
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
  factory SharedTodo.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer = const ValueSerializer.defaults()}) {
    return SharedTodo(
      todo: serializer.fromJson<int>(json['todo']),
      user: serializer.fromJson<int>(json['user']),
    );
  }
  @override
  Map<String, dynamic> toJson(
      {ValueSerializer serializer = const ValueSerializer.defaults()}) {
    return {
      'todo': serializer.toJson<int>(todo),
      'user': serializer.toJson<int>(user),
    };
  }

  @override
  T createCompanion<T extends UpdateCompanion<SharedTodo>>(bool nullToAbsent) {
    return SharedTodosCompanion(
      todo: todo == null && nullToAbsent ? const Value.absent() : Value(todo),
      user: user == null && nullToAbsent ? const Value.absent() : Value(user),
    ) as T;
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
  int get hashCode => $mrjf($mrjc($mrjc(0, todo.hashCode), user.hashCode));
  @override
  bool operator ==(other) =>
      identical(this, other) ||
      (other is SharedTodo && other.todo == todo && other.user == user);
}

class SharedTodosCompanion extends UpdateCompanion<SharedTodo> {
  final Value<int> todo;
  final Value<int> user;
  const SharedTodosCompanion({
    this.todo = const Value.absent(),
    this.user = const Value.absent(),
  });
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
  VerificationContext validateIntegrity(SharedTodosCompanion d,
      {bool isInserting = false}) {
    final context = VerificationContext();
    if (d.todo.present) {
      context.handle(
          _todoMeta, todo.isAcceptableValue(d.todo.value, _todoMeta));
    } else if (todo.isRequired && isInserting) {
      context.missing(_todoMeta);
    }
    if (d.user.present) {
      context.handle(
          _userMeta, user.isAcceptableValue(d.user.value, _userMeta));
    } else if (user.isRequired && isInserting) {
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
  Map<String, Variable> entityToSql(SharedTodosCompanion d) {
    final map = <String, Variable>{};
    if (d.todo.present) {
      map['todo'] = Variable<int, IntType>(d.todo.value);
    }
    if (d.user.present) {
      map['user'] = Variable<int, IntType>(d.user.value);
    }
    return map;
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
  TableWithoutPKData({@required this.notReallyAnId, @required this.someFloat});
  factory TableWithoutPKData.fromData(
      Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final intType = db.typeSystem.forDartType<int>();
    final doubleType = db.typeSystem.forDartType<double>();
    return TableWithoutPKData(
      notReallyAnId: intType
          .mapFromDatabaseResponse(data['${effectivePrefix}not_really_an_id']),
      someFloat: doubleType
          .mapFromDatabaseResponse(data['${effectivePrefix}some_float']),
    );
  }
  factory TableWithoutPKData.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer = const ValueSerializer.defaults()}) {
    return TableWithoutPKData(
      notReallyAnId: serializer.fromJson<int>(json['notReallyAnId']),
      someFloat: serializer.fromJson<double>(json['someFloat']),
    );
  }
  @override
  Map<String, dynamic> toJson(
      {ValueSerializer serializer = const ValueSerializer.defaults()}) {
    return {
      'notReallyAnId': serializer.toJson<int>(notReallyAnId),
      'someFloat': serializer.toJson<double>(someFloat),
    };
  }

  @override
  T createCompanion<T extends UpdateCompanion<TableWithoutPKData>>(
      bool nullToAbsent) {
    return TableWithoutPKCompanion(
      notReallyAnId: notReallyAnId == null && nullToAbsent
          ? const Value.absent()
          : Value(notReallyAnId),
      someFloat: someFloat == null && nullToAbsent
          ? const Value.absent()
          : Value(someFloat),
    ) as T;
  }

  TableWithoutPKData copyWith({int notReallyAnId, double someFloat}) =>
      TableWithoutPKData(
        notReallyAnId: notReallyAnId ?? this.notReallyAnId,
        someFloat: someFloat ?? this.someFloat,
      );
  @override
  String toString() {
    return (StringBuffer('TableWithoutPKData(')
          ..write('notReallyAnId: $notReallyAnId, ')
          ..write('someFloat: $someFloat')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      $mrjf($mrjc($mrjc(0, notReallyAnId.hashCode), someFloat.hashCode));
  @override
  bool operator ==(other) =>
      identical(this, other) ||
      (other is TableWithoutPKData &&
          other.notReallyAnId == notReallyAnId &&
          other.someFloat == someFloat);
}

class TableWithoutPKCompanion extends UpdateCompanion<TableWithoutPKData> {
  final Value<int> notReallyAnId;
  final Value<double> someFloat;
  const TableWithoutPKCompanion({
    this.notReallyAnId = const Value.absent(),
    this.someFloat = const Value.absent(),
  });
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

  @override
  List<GeneratedColumn> get $columns => [notReallyAnId, someFloat];
  @override
  $TableWithoutPKTable get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'table_without_p_k';
  @override
  final String actualTableName = 'table_without_p_k';
  @override
  VerificationContext validateIntegrity(TableWithoutPKCompanion d,
      {bool isInserting = false}) {
    final context = VerificationContext();
    if (d.notReallyAnId.present) {
      context.handle(
          _notReallyAnIdMeta,
          notReallyAnId.isAcceptableValue(
              d.notReallyAnId.value, _notReallyAnIdMeta));
    } else if (notReallyAnId.isRequired && isInserting) {
      context.missing(_notReallyAnIdMeta);
    }
    if (d.someFloat.present) {
      context.handle(_someFloatMeta,
          someFloat.isAcceptableValue(d.someFloat.value, _someFloatMeta));
    } else if (someFloat.isRequired && isInserting) {
      context.missing(_someFloatMeta);
    }
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
  Map<String, Variable> entityToSql(TableWithoutPKCompanion d) {
    final map = <String, Variable>{};
    if (d.notReallyAnId.present) {
      map['not_really_an_id'] = Variable<int, IntType>(d.notReallyAnId.value);
    }
    if (d.someFloat.present) {
      map['some_float'] = Variable<double, RealType>(d.someFloat.value);
    }
    return map;
  }

  @override
  $TableWithoutPKTable createAlias(String alias) {
    return $TableWithoutPKTable(_db, alias);
  }
}

class AllTodosWithCategoryResult {
  final int id;
  final String title;
  final String content;
  final DateTime targetDate;
  final int category;
  final int catId;
  final String catDesc;
  AllTodosWithCategoryResult({
    this.id,
    this.title,
    this.content,
    this.targetDate,
    this.category,
    this.catId,
    this.catDesc,
  });
}

class TodosForUserResult {
  final int id;
  final String title;
  final String content;
  final DateTime targetDate;
  final int category;
  TodosForUserResult({
    this.id,
    this.title,
    this.content,
    this.targetDate,
    this.category,
  });
}

abstract class _$TodoDb extends GeneratedDatabase {
  _$TodoDb(QueryExecutor e) : super(const SqlTypeSystem.withDefaults(), e);
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
  AllTodosWithCategoryResult _rowToAllTodosWithCategoryResult(QueryRow row) {
    return AllTodosWithCategoryResult(
      id: row.readInt('id'),
      title: row.readString('title'),
      content: row.readString('content'),
      targetDate: row.readDateTime('target_date'),
      category: row.readInt('category'),
      catId: row.readInt('catId'),
      catDesc: row.readString('catDesc'),
    );
  }

  Future<List<AllTodosWithCategoryResult>> allTodosWithCategory() {
    return customSelect(
            'SELECT t.*, c.id as catId, c."desc" as catDesc FROM todos t INNER JOIN categories c ON c.id = t.category',
            variables: [])
        .then((rows) => rows.map(_rowToAllTodosWithCategoryResult).toList());
  }

  Stream<List<AllTodosWithCategoryResult>> watchAllTodosWithCategory() {
    return customSelectStream(
            'SELECT t.*, c.id as catId, c."desc" as catDesc FROM todos t INNER JOIN categories c ON c.id = t.category',
            variables: [])
        .map((rows) => rows.map(_rowToAllTodosWithCategoryResult).toList());
  }

  TodosForUserResult _rowToTodosForUserResult(QueryRow row) {
    return TodosForUserResult(
      id: row.readInt('id'),
      title: row.readString('title'),
      content: row.readString('content'),
      targetDate: row.readDateTime('target_date'),
      category: row.readInt('category'),
    );
  }

  Future<List<TodosForUserResult>> todosForUser(int user) {
    return customSelect(
        'SELECT t.* FROM todos t INNER JOIN shared_todos st ON st.todo = t.id INNER JOIN users u ON u.id = st.user WHERE u.id = :user',
        variables: [
          Variable.withInt(user),
        ]).then((rows) => rows.map(_rowToTodosForUserResult).toList());
  }

  Stream<List<TodosForUserResult>> watchTodosForUser(int user) {
    return customSelectStream(
        'SELECT t.* FROM todos t INNER JOIN shared_todos st ON st.todo = t.id INNER JOIN users u ON u.id = st.user WHERE u.id = :user',
        variables: [
          Variable.withInt(user),
        ]).map((rows) => rows.map(_rowToTodosForUserResult).toList());
  }

  @override
  List<TableInfo> get allTables =>
      [todosTable, categories, users, sharedTodos, tableWithoutPK];
}
