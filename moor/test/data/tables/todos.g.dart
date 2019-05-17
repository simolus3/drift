// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todos.dart';

// **************************************************************************
// MoorGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps
class TodoEntry extends DataClass {
  final int id;
  final String title;
  final String content;
  final DateTime targetDate;
  final int category;
  TodoEntry(
      {this.id, this.title, this.content, this.targetDate, this.category});
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
  factory TodoEntry.fromJson(Map<String, dynamic> json) {
    return TodoEntry(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      targetDate: json['targetDate'] as DateTime,
      category: json['category'] as int,
    );
  }
  @override
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

class $TodosTableTable extends TodosTable
    with TableInfo<$TodosTableTable, TodoEntry> {
  final GeneratedDatabase _db;
  final String _alias;
  $TodosTableTable(this._db, [this._alias]);
  GeneratedIntColumn _id;
  @override
  GeneratedIntColumn get id => _id ??= _constructId();
  GeneratedIntColumn _constructId() {
    return GeneratedIntColumn('id', $tableName, false, hasAutoIncrement: true);
  }

  GeneratedTextColumn _title;
  @override
  GeneratedTextColumn get title => _title ??= _constructTitle();
  GeneratedTextColumn _constructTitle() {
    return GeneratedTextColumn('title', $tableName, true,
        minTextLength: 4, maxTextLength: 16);
  }

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
  bool validateIntegrity(TodoEntry instance, bool isInserting) =>
      id.isAcceptableValue(instance.id, isInserting) &&
      title.isAcceptableValue(instance.title, isInserting) &&
      content.isAcceptableValue(instance.content, isInserting) &&
      targetDate.isAcceptableValue(instance.targetDate, isInserting) &&
      category.isAcceptableValue(instance.category, isInserting);
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TodoEntry map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return TodoEntry.fromData(data, _db, prefix: effectivePrefix);
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

  @override
  $TodosTableTable createAlias(String alias) {
    return $TodosTableTable(_db, alias);
  }
}

class Category extends DataClass {
  final int id;
  final String description;
  Category({this.id, this.description});
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
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      description: json['description'] as String,
    );
  }
  @override
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
  int get hashCode => $mrjf($mrjc($mrjc(0, id.hashCode), description.hashCode));
  @override
  bool operator ==(other) =>
      identical(this, other) ||
      (other is Category && other.id == id && other.description == description);
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  final GeneratedDatabase _db;
  final String _alias;
  $CategoriesTable(this._db, [this._alias]);
  GeneratedIntColumn _id;
  @override
  GeneratedIntColumn get id => _id ??= _constructId();
  GeneratedIntColumn _constructId() {
    return GeneratedIntColumn('id', $tableName, false, hasAutoIncrement: true);
  }

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
  bool validateIntegrity(Category instance, bool isInserting) =>
      id.isAcceptableValue(instance.id, isInserting) &&
      description.isAcceptableValue(instance.description, isInserting);
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return Category.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Map<String, Variable> entityToSql(Category d, {bool includeNulls = false}) {
    final map = <String, Variable>{};
    if (d.id != null || includeNulls) {
      map['id'] = Variable<int, IntType>(d.id);
    }
    if (d.description != null || includeNulls) {
      map['desc'] = Variable<String, StringType>(d.description);
    }
    return map;
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(_db, alias);
  }
}

class User extends DataClass {
  final int id;
  final String name;
  final bool isAwesome;
  final Uint8List profilePicture;
  final DateTime creationTime;
  User(
      {this.id,
      this.name,
      this.isAwesome,
      this.profilePicture,
      this.creationTime});
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
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      isAwesome: json['isAwesome'] as bool,
      profilePicture: json['profilePicture'] as Uint8List,
      creationTime: json['creationTime'] as DateTime,
    );
  }
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isAwesome': isAwesome,
      'profilePicture': profilePicture,
      'creationTime': creationTime,
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

class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  final GeneratedDatabase _db;
  final String _alias;
  $UsersTable(this._db, [this._alias]);
  GeneratedIntColumn _id;
  @override
  GeneratedIntColumn get id => _id ??= _constructId();
  GeneratedIntColumn _constructId() {
    return GeneratedIntColumn('id', $tableName, false, hasAutoIncrement: true);
  }

  GeneratedTextColumn _name;
  @override
  GeneratedTextColumn get name => _name ??= _constructName();
  GeneratedTextColumn _constructName() {
    return GeneratedTextColumn('name', $tableName, false,
        minTextLength: 6, maxTextLength: 32);
  }

  GeneratedBoolColumn _isAwesome;
  @override
  GeneratedBoolColumn get isAwesome => _isAwesome ??= _constructIsAwesome();
  GeneratedBoolColumn _constructIsAwesome() {
    return GeneratedBoolColumn('is_awesome', $tableName, false,
        defaultValue: const Constant(true));
  }

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
  bool validateIntegrity(User instance, bool isInserting) =>
      id.isAcceptableValue(instance.id, isInserting) &&
      name.isAcceptableValue(instance.name, isInserting) &&
      isAwesome.isAcceptableValue(instance.isAwesome, isInserting) &&
      profilePicture.isAcceptableValue(instance.profilePicture, isInserting) &&
      creationTime.isAcceptableValue(instance.creationTime, isInserting);
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return User.fromData(data, _db, prefix: effectivePrefix);
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
    if (d.creationTime != null || includeNulls) {
      map['creation_time'] = Variable<DateTime, DateTimeType>(d.creationTime);
    }
    return map;
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(_db, alias);
  }
}

class SharedTodo extends DataClass {
  final int todo;
  final int user;
  SharedTodo({this.todo, this.user});
  factory SharedTodo.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final intType = db.typeSystem.forDartType<int>();
    return SharedTodo(
      todo: intType.mapFromDatabaseResponse(data['${effectivePrefix}todo']),
      user: intType.mapFromDatabaseResponse(data['${effectivePrefix}user']),
    );
  }
  factory SharedTodo.fromJson(Map<String, dynamic> json) {
    return SharedTodo(
      todo: json['todo'] as int,
      user: json['user'] as int,
    );
  }
  @override
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
  int get hashCode => $mrjf($mrjc($mrjc(0, todo.hashCode), user.hashCode));
  @override
  bool operator ==(other) =>
      identical(this, other) ||
      (other is SharedTodo && other.todo == todo && other.user == user);
}

class $SharedTodosTable extends SharedTodos
    with TableInfo<$SharedTodosTable, SharedTodo> {
  final GeneratedDatabase _db;
  final String _alias;
  $SharedTodosTable(this._db, [this._alias]);
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
  bool validateIntegrity(SharedTodo instance, bool isInserting) =>
      todo.isAcceptableValue(instance.todo, isInserting) &&
      user.isAcceptableValue(instance.user, isInserting);
  @override
  Set<GeneratedColumn> get $primaryKey => {todo, user};
  @override
  SharedTodo map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return SharedTodo.fromData(data, _db, prefix: effectivePrefix);
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

  @override
  $SharedTodosTable createAlias(String alias) {
    return $SharedTodosTable(_db, alias);
  }
}

class TableWithoutPKData extends DataClass {
  final int notReallyAnId;
  final num someFloat;
  TableWithoutPKData({this.notReallyAnId, this.someFloat});
  factory TableWithoutPKData.fromData(
      Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final intType = db.typeSystem.forDartType<int>();
    final numType = db.typeSystem.forDartType<num>();
    return TableWithoutPKData(
      notReallyAnId: intType
          .mapFromDatabaseResponse(data['${effectivePrefix}not_really_an_id']),
      someFloat:
          numType.mapFromDatabaseResponse(data['${effectivePrefix}some_float']),
    );
  }
  factory TableWithoutPKData.fromJson(Map<String, dynamic> json) {
    return TableWithoutPKData(
      notReallyAnId: json['notReallyAnId'] as int,
      someFloat: json['someFloat'] as num,
    );
  }
  @override
  Map<String, dynamic> toJson() {
    return {
      'notReallyAnId': notReallyAnId,
      'someFloat': someFloat,
    };
  }

  TableWithoutPKData copyWith({int notReallyAnId, num someFloat}) =>
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

class $TableWithoutPKTable extends TableWithoutPK
    with TableInfo<$TableWithoutPKTable, TableWithoutPKData> {
  final GeneratedDatabase _db;
  final String _alias;
  $TableWithoutPKTable(this._db, [this._alias]);
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
  bool validateIntegrity(TableWithoutPKData instance, bool isInserting) =>
      notReallyAnId.isAcceptableValue(instance.notReallyAnId, isInserting) &&
      someFloat.isAcceptableValue(instance.someFloat, isInserting);
  @override
  Set<GeneratedColumn> get $primaryKey => <GeneratedColumn>{};
  @override
  TableWithoutPKData map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return TableWithoutPKData.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Map<String, Variable> entityToSql(TableWithoutPKData d,
      {bool includeNulls = false}) {
    final map = <String, Variable>{};
    if (d.notReallyAnId != null || includeNulls) {
      map['not_really_an_id'] = Variable<int, IntType>(d.notReallyAnId);
    }
    if (d.someFloat != null || includeNulls) {
      map['some_float'] = Variable<num, RealType>(d.someFloat);
    }
    return map;
  }

  @override
  $TableWithoutPKTable createAlias(String alias) {
    return $TableWithoutPKTable(_db, alias);
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
  $TableWithoutPKTable _tableWithoutPK;
  $TableWithoutPKTable get tableWithoutPK =>
      _tableWithoutPK ??= $TableWithoutPKTable(this);
  @override
  List<TableInfo> get allTables =>
      [todosTable, categories, users, sharedTodos, tableWithoutPK];
}
