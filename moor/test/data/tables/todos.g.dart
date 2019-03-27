// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todos.dart';

// **************************************************************************
// MoorGenerator
// **************************************************************************

class TodoEntry {
  final int id;
  final String title;
  final String content;
  final DateTime targetDate;
  final int category;
  TodoEntry(
      {this.id, this.title, this.content, this.targetDate, this.category});
  factory TodoEntry.fromData(Map<String, dynamic> data, GeneratedDatabase db) {
    final intType = db.typeSystem.forDartType<int>();
    final stringType = db.typeSystem.forDartType<String>();
    final dateTimeType = db.typeSystem.forDartType<DateTime>();
    return TodoEntry(
      id: intType.mapFromDatabaseResponse(data['id']),
      title: stringType.mapFromDatabaseResponse(data['title']),
      content: stringType.mapFromDatabaseResponse(data['content']),
      targetDate: dateTimeType.mapFromDatabaseResponse(data['target_date']),
      category: intType.mapFromDatabaseResponse(data['category']),
    );
  }
  factory TodoEntry.fromJson(Map<String, dynamic> json) {
    return TodoEntry(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      targetDate: json['targetDate'] as DateTime,
      category: json['category'] as int,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'targetDate': targetDate,
      'category': category,
    };
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
  int get hashCode =>
      ((((id.hashCode) * 31 + title.hashCode) * 31 + content.hashCode) * 31 +
              targetDate.hashCode) *
          31 +
      category.hashCode;
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

class $TodosTableTable extends TodosTable
    implements TableInfo<TodosTable, TodoEntry> {
  final GeneratedDatabase _db;
  $TodosTableTable(this._db);
  GeneratedIntColumn _id;
  @override
  GeneratedIntColumn get id =>
      _id ??= GeneratedIntColumn('id', false, hasAutoIncrement: true);
  GeneratedTextColumn _title;
  @override
  GeneratedTextColumn get title => _title ??=
      GeneratedTextColumn('title', true, minTextLength: 4, maxTextLength: 16);
  GeneratedTextColumn _content;
  @override
  GeneratedTextColumn get content => _content ??= GeneratedTextColumn(
        'content',
        false,
      );
  GeneratedDateTimeColumn _targetDate;
  @override
  GeneratedDateTimeColumn get targetDate =>
      _targetDate ??= GeneratedDateTimeColumn(
        'target_date',
        true,
      );
  GeneratedIntColumn _category;
  @override
  GeneratedIntColumn get category => _category ??= GeneratedIntColumn(
        'category',
        true,
      );
  @override
  List<GeneratedColumn> get $columns =>
      [id, title, content, targetDate, category];
  @override
  TodosTable get asDslTable => this;
  @override
  String get $tableName => 'todos';
  @override
  bool validateIntegrity(TodoEntry instance, bool isInserting) =>
      id.isAcceptableValue(instance.id, isInserting) &&
      title.isAcceptableValue(instance.title, isInserting) &&
      content.isAcceptableValue(instance.content, isInserting) &&
      targetDate.isAcceptableValue(instance.targetDate, isInserting) &&
      category.isAcceptableValue(instance.category, isInserting);
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TodoEntry map(Map<String, dynamic> data) {
    return TodoEntry.fromData(data, _db);
  }

  @override
  Map<String, Variable> entityToSql(TodoEntry d, {bool includeNulls = false}) {
    final map = <String, Variable>{};
    if (d.id != null || includeNulls) {
      map['id'] = Variable<int, IntType>(d.id);
    }
    if (d.title != null || includeNulls) {
      map['title'] = Variable<String, StringType>(d.title);
    }
    if (d.content != null || includeNulls) {
      map['content'] = Variable<String, StringType>(d.content);
    }
    if (d.targetDate != null || includeNulls) {
      map['target_date'] = Variable<DateTime, DateTimeType>(d.targetDate);
    }
    if (d.category != null || includeNulls) {
      map['category'] = Variable<int, IntType>(d.category);
    }
    return map;
  }
}

class Category {
  final int id;
  final String description;
  Category({this.id, this.description});
  factory Category.fromData(Map<String, dynamic> data, GeneratedDatabase db) {
    final intType = db.typeSystem.forDartType<int>();
    final stringType = db.typeSystem.forDartType<String>();
    return Category(
      id: intType.mapFromDatabaseResponse(data['id']),
      description: stringType.mapFromDatabaseResponse(data['`desc`']),
    );
  }
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      description: json['description'] as String,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
    };
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
  int get hashCode => (id.hashCode) * 31 + description.hashCode;
  @override
  bool operator ==(other) =>
      identical(this, other) ||
      (other is Category && other.id == id && other.description == description);
}

class $CategoriesTable extends Categories
    implements TableInfo<Categories, Category> {
  final GeneratedDatabase _db;
  $CategoriesTable(this._db);
  GeneratedIntColumn _id;
  @override
  GeneratedIntColumn get id =>
      _id ??= GeneratedIntColumn('id', false, hasAutoIncrement: true);
  GeneratedTextColumn _description;
  @override
  GeneratedTextColumn get description =>
      _description ??= GeneratedTextColumn('`desc`', false,
          $customConstraints: 'NOT NULL UNIQUE');
  @override
  List<GeneratedColumn> get $columns => [id, description];
  @override
  Categories get asDslTable => this;
  @override
  String get $tableName => 'categories';
  @override
  bool validateIntegrity(Category instance, bool isInserting) =>
      id.isAcceptableValue(instance.id, isInserting) &&
      description.isAcceptableValue(instance.description, isInserting);
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data) {
    return Category.fromData(data, _db);
  }

  @override
  Map<String, Variable> entityToSql(Category d, {bool includeNulls = false}) {
    final map = <String, Variable>{};
    if (d.id != null || includeNulls) {
      map['id'] = Variable<int, IntType>(d.id);
    }
    if (d.description != null || includeNulls) {
      map['`desc`'] = Variable<String, StringType>(d.description);
    }
    return map;
  }
}

class User {
  final int id;
  final String name;
  final bool isAwesome;
  final Uint8List profilePicture;
  User({this.id, this.name, this.isAwesome, this.profilePicture});
  factory User.fromData(Map<String, dynamic> data, GeneratedDatabase db) {
    final intType = db.typeSystem.forDartType<int>();
    final stringType = db.typeSystem.forDartType<String>();
    final boolType = db.typeSystem.forDartType<bool>();
    final uint8ListType = db.typeSystem.forDartType<Uint8List>();
    return User(
      id: intType.mapFromDatabaseResponse(data['id']),
      name: stringType.mapFromDatabaseResponse(data['name']),
      isAwesome: boolType.mapFromDatabaseResponse(data['is_awesome']),
      profilePicture:
          uint8ListType.mapFromDatabaseResponse(data['profile_picture']),
    );
  }
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      isAwesome: json['isAwesome'] as bool,
      profilePicture: json['profilePicture'] as Uint8List,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isAwesome': isAwesome,
      'profilePicture': profilePicture,
    };
  }

  User copyWith(
          {int id, String name, bool isAwesome, Uint8List profilePicture}) =>
      User(
        id: id ?? this.id,
        name: name ?? this.name,
        isAwesome: isAwesome ?? this.isAwesome,
        profilePicture: profilePicture ?? this.profilePicture,
      );
  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isAwesome: $isAwesome, ')
          ..write('profilePicture: $profilePicture')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      (((id.hashCode) * 31 + name.hashCode) * 31 + isAwesome.hashCode) * 31 +
      profilePicture.hashCode;
  @override
  bool operator ==(other) =>
      identical(this, other) ||
      (other is User &&
          other.id == id &&
          other.name == name &&
          other.isAwesome == isAwesome &&
          other.profilePicture == profilePicture);
}

class $UsersTable extends Users implements TableInfo<Users, User> {
  final GeneratedDatabase _db;
  $UsersTable(this._db);
  GeneratedIntColumn _id;
  @override
  GeneratedIntColumn get id =>
      _id ??= GeneratedIntColumn('id', false, hasAutoIncrement: true);
  GeneratedTextColumn _name;
  @override
  GeneratedTextColumn get name => _name ??=
      GeneratedTextColumn('name', false, minTextLength: 6, maxTextLength: 32);
  GeneratedBoolColumn _isAwesome;
  @override
  GeneratedBoolColumn get isAwesome => _isAwesome ??= GeneratedBoolColumn(
        'is_awesome',
        false,
      );
  GeneratedBlobColumn _profilePicture;
  @override
  GeneratedBlobColumn get profilePicture =>
      _profilePicture ??= GeneratedBlobColumn(
        'profile_picture',
        false,
      );
  @override
  List<GeneratedColumn> get $columns => [id, name, isAwesome, profilePicture];
  @override
  Users get asDslTable => this;
  @override
  String get $tableName => 'users';
  @override
  bool validateIntegrity(User instance, bool isInserting) =>
      id.isAcceptableValue(instance.id, isInserting) &&
      name.isAcceptableValue(instance.name, isInserting) &&
      isAwesome.isAcceptableValue(instance.isAwesome, isInserting) &&
      profilePicture.isAcceptableValue(instance.profilePicture, isInserting);
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data) {
    return User.fromData(data, _db);
  }

  @override
  Map<String, Variable> entityToSql(User d, {bool includeNulls = false}) {
    final map = <String, Variable>{};
    if (d.id != null || includeNulls) {
      map['id'] = Variable<int, IntType>(d.id);
    }
    if (d.name != null || includeNulls) {
      map['name'] = Variable<String, StringType>(d.name);
    }
    if (d.isAwesome != null || includeNulls) {
      map['is_awesome'] = Variable<bool, BoolType>(d.isAwesome);
    }
    if (d.profilePicture != null || includeNulls) {
      map['profile_picture'] = Variable<Uint8List, BlobType>(d.profilePicture);
    }
    return map;
  }
}

class SharedTodo {
  final int todo;
  final int user;
  SharedTodo({this.todo, this.user});
  factory SharedTodo.fromData(Map<String, dynamic> data, GeneratedDatabase db) {
    final intType = db.typeSystem.forDartType<int>();
    return SharedTodo(
      todo: intType.mapFromDatabaseResponse(data['todo']),
      user: intType.mapFromDatabaseResponse(data['user']),
    );
  }
  factory SharedTodo.fromJson(Map<String, dynamic> json) {
    return SharedTodo(
      todo: json['todo'] as int,
      user: json['user'] as int,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'todo': todo,
      'user': user,
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
  int get hashCode => (todo.hashCode) * 31 + user.hashCode;
  @override
  bool operator ==(other) =>
      identical(this, other) ||
      (other is SharedTodo && other.todo == todo && other.user == user);
}

class $SharedTodosTable extends SharedTodos
    implements TableInfo<SharedTodos, SharedTodo> {
  final GeneratedDatabase _db;
  $SharedTodosTable(this._db);
  GeneratedIntColumn _todo;
  @override
  GeneratedIntColumn get todo => _todo ??= GeneratedIntColumn(
        'todo',
        false,
      );
  GeneratedIntColumn _user;
  @override
  GeneratedIntColumn get user => _user ??= GeneratedIntColumn(
        'user',
        false,
      );
  @override
  List<GeneratedColumn> get $columns => [todo, user];
  @override
  SharedTodos get asDslTable => this;
  @override
  String get $tableName => 'shared_todos';
  @override
  bool validateIntegrity(SharedTodo instance, bool isInserting) =>
      todo.isAcceptableValue(instance.todo, isInserting) &&
      user.isAcceptableValue(instance.user, isInserting);
  @override
  Set<GeneratedColumn> get $primaryKey => {todo, user};
  @override
  SharedTodo map(Map<String, dynamic> data) {
    return SharedTodo.fromData(data, _db);
  }

  @override
  Map<String, Variable> entityToSql(SharedTodo d, {bool includeNulls = false}) {
    final map = <String, Variable>{};
    if (d.todo != null || includeNulls) {
      map['todo'] = Variable<int, IntType>(d.todo);
    }
    if (d.user != null || includeNulls) {
      map['user'] = Variable<int, IntType>(d.user);
    }
    return map;
  }
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
  @override
  List<TableInfo> get allTables => [todosTable, categories, users, sharedTodos];
}
