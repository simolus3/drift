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
  @override
  GeneratedIntColumn get id =>
      GeneratedIntColumn('id', false, hasAutoIncrement: true);
  @override
  GeneratedTextColumn get title =>
      GeneratedTextColumn('title', true, minTextLength: 4, maxTextLength: 16);
  @override
  GeneratedTextColumn get content => GeneratedTextColumn(
        'content',
        false,
      );
  @override
  GeneratedDateTimeColumn get targetDate => GeneratedDateTimeColumn(
        'target_date',
        true,
      );
  @override
  GeneratedIntColumn get category => GeneratedIntColumn(
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
  @override
  GeneratedIntColumn get id =>
      GeneratedIntColumn('id', false, hasAutoIncrement: true);
  @override
  GeneratedTextColumn get description => GeneratedTextColumn(
        '`desc`',
        false,
      );
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
  User({this.id, this.name, this.isAwesome});
  factory User.fromData(Map<String, dynamic> data, GeneratedDatabase db) {
    final intType = db.typeSystem.forDartType<int>();
    final stringType = db.typeSystem.forDartType<String>();
    final boolType = db.typeSystem.forDartType<bool>();
    return User(
      id: intType.mapFromDatabaseResponse(data['id']),
      name: stringType.mapFromDatabaseResponse(data['name']),
      isAwesome: boolType.mapFromDatabaseResponse(data['is_awesome']),
    );
  }
  User copyWith({int id, String name, bool isAwesome}) => User(
        id: id ?? this.id,
        name: name ?? this.name,
        isAwesome: isAwesome ?? this.isAwesome,
      );
  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isAwesome: $isAwesome')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      ((id.hashCode) * 31 + name.hashCode) * 31 + isAwesome.hashCode;
  @override
  bool operator ==(other) =>
      identical(this, other) ||
      (other is User &&
          other.id == id &&
          other.name == name &&
          other.isAwesome == isAwesome);
}

class $UsersTable extends Users implements TableInfo<Users, User> {
  final GeneratedDatabase _db;
  $UsersTable(this._db);
  @override
  GeneratedIntColumn get id =>
      GeneratedIntColumn('id', false, hasAutoIncrement: true);
  @override
  GeneratedTextColumn get name =>
      GeneratedTextColumn('name', false, minTextLength: 6, maxTextLength: 32);
  @override
  GeneratedBoolColumn get isAwesome => GeneratedBoolColumn(
        'is_awesome',
        false,
      );
  @override
  List<GeneratedColumn> get $columns => [id, name, isAwesome];
  @override
  Users get asDslTable => this;
  @override
  String get $tableName => 'users';
  @override
  bool validateIntegrity(User instance, bool isInserting) =>
      id.isAcceptableValue(instance.id, isInserting) &&
      name.isAcceptableValue(instance.name, isInserting) &&
      isAwesome.isAcceptableValue(instance.isAwesome, isInserting);
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
  @override
  GeneratedIntColumn get todo => GeneratedIntColumn(
        'todo',
        false,
      );
  @override
  GeneratedIntColumn get user => GeneratedIntColumn(
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
  $TodosTableTable get todosTable => $TodosTableTable(this);
  $CategoriesTable get categories => $CategoriesTable(this);
  $UsersTable get users => $UsersTable(this);
  $SharedTodosTable get sharedTodos => $SharedTodosTable(this);
  @override
  List<TableInfo> get allTables => [todosTable, categories, users, sharedTodos];
}
