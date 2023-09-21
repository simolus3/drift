// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:drift_docs/snippets/modular/drift/example.drift.dart' as i1;
import 'package:drift/internal/modular.dart' as i2;

class Todos extends i0.Table with i0.TableInfo<Todos, i1.Todo> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  Todos(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _idMeta = const i0.VerificationMeta('id');
  late final i0.GeneratedColumn<int> id = i0.GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: i0.DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT');
  static const i0.VerificationMeta _titleMeta =
      const i0.VerificationMeta('title');
  late final i0.GeneratedColumn<String> title = i0.GeneratedColumn<String>(
      'title', aliasedName, false,
      type: i0.DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const i0.VerificationMeta _contentMeta =
      const i0.VerificationMeta('content');
  late final i0.GeneratedColumn<String> content = i0.GeneratedColumn<String>(
      'content', aliasedName, false,
      type: i0.DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const i0.VerificationMeta _categoryMeta =
      const i0.VerificationMeta('category');
  late final i0.GeneratedColumn<int> category = i0.GeneratedColumn<int>(
      'category', aliasedName, true,
      type: i0.DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'REFERENCES categories(id)');
  @override
  List<i0.GeneratedColumn> get $columns => [id, title, content, category];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'todos';
  @override
  i0.VerificationContext validateIntegrity(i0.Insertable<i1.Todo> instance,
      {bool isInserting = false}) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {id};
  @override
  i1.Todo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.Todo(
      id: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.string, data['${effectivePrefix}title'])!,
      content: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.string, data['${effectivePrefix}content'])!,
      category: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.int, data['${effectivePrefix}category']),
    );
  }

  @override
  Todos createAlias(String alias) {
    return Todos(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Todo extends i0.DataClass implements i0.Insertable<i1.Todo> {
  final int id;
  final String title;
  final String content;
  final int? category;
  const Todo(
      {required this.id,
      required this.title,
      required this.content,
      this.category});
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['id'] = i0.Variable<int>(id);
    map['title'] = i0.Variable<String>(title);
    map['content'] = i0.Variable<String>(content);
    if (!nullToAbsent || category != null) {
      map['category'] = i0.Variable<int>(category);
    }
    return map;
  }

  i1.TodosCompanion toCompanion(bool nullToAbsent) {
    return i1.TodosCompanion(
      id: i0.Value(id),
      title: i0.Value(title),
      content: i0.Value(content),
      category: category == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(category),
    );
  }

  factory Todo.fromJson(Map<String, dynamic> json,
      {i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return Todo(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      category: serializer.fromJson<int?>(json['category']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'content': serializer.toJson<String>(content),
      'category': serializer.toJson<int?>(category),
    };
  }

  i1.Todo copyWith(
          {int? id,
          String? title,
          String? content,
          i0.Value<int?> category = const i0.Value.absent()}) =>
      i1.Todo(
        id: id ?? this.id,
        title: title ?? this.title,
        content: content ?? this.content,
        category: category.present ? category.value : this.category,
      );
  @override
  String toString() {
    return (StringBuffer('Todo(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('category: $category')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, content, category);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.Todo &&
          other.id == this.id &&
          other.title == this.title &&
          other.content == this.content &&
          other.category == this.category);
}

class TodosCompanion extends i0.UpdateCompanion<i1.Todo> {
  final i0.Value<int> id;
  final i0.Value<String> title;
  final i0.Value<String> content;
  final i0.Value<int?> category;
  const TodosCompanion({
    this.id = const i0.Value.absent(),
    this.title = const i0.Value.absent(),
    this.content = const i0.Value.absent(),
    this.category = const i0.Value.absent(),
  });
  TodosCompanion.insert({
    this.id = const i0.Value.absent(),
    required String title,
    required String content,
    this.category = const i0.Value.absent(),
  })  : title = i0.Value(title),
        content = i0.Value(content);
  static i0.Insertable<i1.Todo> custom({
    i0.Expression<int>? id,
    i0.Expression<String>? title,
    i0.Expression<String>? content,
    i0.Expression<int>? category,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (category != null) 'category': category,
    });
  }

  i1.TodosCompanion copyWith(
      {i0.Value<int>? id,
      i0.Value<String>? title,
      i0.Value<String>? content,
      i0.Value<int?>? category}) {
    return i1.TodosCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (id.present) {
      map['id'] = i0.Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = i0.Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = i0.Variable<String>(content.value);
    }
    if (category.present) {
      map['category'] = i0.Variable<int>(category.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TodosCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('category: $category')
          ..write(')'))
        .toString();
  }
}

class Categories extends i0.Table with i0.TableInfo<Categories, i1.Category> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  Categories(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _idMeta = const i0.VerificationMeta('id');
  late final i0.GeneratedColumn<int> id = i0.GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: i0.DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT');
  static const i0.VerificationMeta _descriptionMeta =
      const i0.VerificationMeta('description');
  late final i0.GeneratedColumn<String> description =
      i0.GeneratedColumn<String>('description', aliasedName, false,
          type: i0.DriftSqlType.string,
          requiredDuringInsert: true,
          $customConstraints: 'NOT NULL');
  @override
  List<i0.GeneratedColumn> get $columns => [id, description];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  i0.VerificationContext validateIntegrity(i0.Insertable<i1.Category> instance,
      {bool isInserting = false}) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {id};
  @override
  i1.Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.Category(
      id: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.int, data['${effectivePrefix}id'])!,
      description: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.string, data['${effectivePrefix}description'])!,
    );
  }

  @override
  Categories createAlias(String alias) {
    return Categories(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Category extends i0.DataClass implements i0.Insertable<i1.Category> {
  final int id;
  final String description;
  const Category({required this.id, required this.description});
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['id'] = i0.Variable<int>(id);
    map['description'] = i0.Variable<String>(description);
    return map;
  }

  i1.CategoriesCompanion toCompanion(bool nullToAbsent) {
    return i1.CategoriesCompanion(
      id: i0.Value(id),
      description: i0.Value(description),
    );
  }

  factory Category.fromJson(Map<String, dynamic> json,
      {i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<int>(json['id']),
      description: serializer.fromJson<String>(json['description']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'description': serializer.toJson<String>(description),
    };
  }

  i1.Category copyWith({int? id, String? description}) => i1.Category(
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
  int get hashCode => Object.hash(id, description);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.Category &&
          other.id == this.id &&
          other.description == this.description);
}

class CategoriesCompanion extends i0.UpdateCompanion<i1.Category> {
  final i0.Value<int> id;
  final i0.Value<String> description;
  const CategoriesCompanion({
    this.id = const i0.Value.absent(),
    this.description = const i0.Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const i0.Value.absent(),
    required String description,
  }) : description = i0.Value(description);
  static i0.Insertable<i1.Category> custom({
    i0.Expression<int>? id,
    i0.Expression<String>? description,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (description != null) 'description': description,
    });
  }

  i1.CategoriesCompanion copyWith(
      {i0.Value<int>? id, i0.Value<String>? description}) {
    return i1.CategoriesCompanion(
      id: id ?? this.id,
      description: description ?? this.description,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (id.present) {
      map['id'] = i0.Variable<int>(id.value);
    }
    if (description.present) {
      map['description'] = i0.Variable<String>(description.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }
}

class ExampleDrift extends i2.ModularAccessor {
  ExampleDrift(i0.GeneratedDatabase db) : super(db);
  i0.Selectable<i1.Todo> filterTodos(FilterTodos$predicate predicate) {
    var $arrayStartIndex = 1;
    final generatedpredicate =
        $write(predicate(this.todos), startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedpredicate.amountOfVariables;
    return customSelect('SELECT * FROM todos WHERE ${generatedpredicate.sql}',
        variables: [
          ...generatedpredicate.introducedVariables
        ],
        readsFrom: {
          todos,
          ...generatedpredicate.watchedTables,
        }).asyncMap(todos.mapFromRow);
  }

  i0.Selectable<i1.Todo> getTodos({GetTodos$predicate? predicate}) {
    var $arrayStartIndex = 1;
    final generatedpredicate = $write(
        predicate?.call(this.todos) ?? const i0.CustomExpression('(TRUE)'),
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedpredicate.amountOfVariables;
    return customSelect('SELECT * FROM todos WHERE ${generatedpredicate.sql}',
        variables: [
          ...generatedpredicate.introducedVariables
        ],
        readsFrom: {
          todos,
          ...generatedpredicate.watchedTables,
        }).asyncMap(todos.mapFromRow);
  }

  i1.Todos get todos => this.resultSet<i1.Todos>('todos');
}

typedef FilterTodos$predicate = i0.Expression<bool> Function(i1.Todos todos);
typedef GetTodos$predicate = i0.Expression<bool> Function(i1.Todos todos);
