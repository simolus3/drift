// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:drift_docs/snippets/_shared/todo_tables.drift.dart' as i1;
import 'package:drift_docs/snippets/_shared/todo_tables.dart' as i2;
import 'package:drift/internal/modular.dart' as i3;

class $TodoItemsTable extends i2.TodoItems
    with i0.TableInfo<$TodoItemsTable, i1.TodoItem> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TodoItemsTable(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _idMeta = const i0.VerificationMeta('id');
  @override
  late final i0.GeneratedColumn<int> id = i0.GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: i0.DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          i0.GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const i0.VerificationMeta _titleMeta =
      const i0.VerificationMeta('title');
  @override
  late final i0.GeneratedColumn<String> title = i0.GeneratedColumn<String>(
      'title', aliasedName, false,
      additionalChecks: i0.GeneratedColumn.checkTextLength(
          minTextLength: 6, maxTextLength: 32),
      type: i0.DriftSqlType.string,
      requiredDuringInsert: true);
  static const i0.VerificationMeta _contentMeta =
      const i0.VerificationMeta('content');
  @override
  late final i0.GeneratedColumn<String> content = i0.GeneratedColumn<String>(
      'body', aliasedName, false,
      type: i0.DriftSqlType.string, requiredDuringInsert: true);
  static const i0.VerificationMeta _categoryMeta =
      const i0.VerificationMeta('category');
  @override
  late final i0.GeneratedColumn<int> category = i0.GeneratedColumn<int>(
      'category', aliasedName, true,
      type: i0.DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          i0.GeneratedColumn.constraintIsAlways('REFERENCES categories (id)'));
  static const i0.VerificationMeta _dueDateMeta =
      const i0.VerificationMeta('dueDate');
  @override
  late final i0.GeneratedColumn<DateTime> dueDate =
      i0.GeneratedColumn<DateTime>('due_date', aliasedName, true,
          type: i0.DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<i0.GeneratedColumn> get $columns =>
      [id, title, content, category, dueDate];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'todo_items';
  @override
  i0.VerificationContext validateIntegrity(i0.Insertable<i1.TodoItem> instance,
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
    if (data.containsKey('body')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['body']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('due_date')) {
      context.handle(_dueDateMeta,
          dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta));
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {id};
  @override
  i1.TodoItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.TodoItem(
      id: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.string, data['${effectivePrefix}title'])!,
      content: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.string, data['${effectivePrefix}body'])!,
      category: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.int, data['${effectivePrefix}category']),
      dueDate: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.dateTime, data['${effectivePrefix}due_date']),
    );
  }

  @override
  $TodoItemsTable createAlias(String alias) {
    return $TodoItemsTable(attachedDatabase, alias);
  }
}

class TodoItem extends i0.DataClass implements i0.Insertable<i1.TodoItem> {
  final int id;
  final String title;
  final String content;
  final int? category;
  final DateTime? dueDate;
  const TodoItem(
      {required this.id,
      required this.title,
      required this.content,
      this.category,
      this.dueDate});
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['id'] = i0.Variable<int>(id);
    map['title'] = i0.Variable<String>(title);
    map['body'] = i0.Variable<String>(content);
    if (!nullToAbsent || category != null) {
      map['category'] = i0.Variable<int>(category);
    }
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = i0.Variable<DateTime>(dueDate);
    }
    return map;
  }

  i1.TodoItemsCompanion toCompanion(bool nullToAbsent) {
    return i1.TodoItemsCompanion(
      id: i0.Value(id),
      title: i0.Value(title),
      content: i0.Value(content),
      category: category == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(category),
      dueDate: dueDate == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(dueDate),
    );
  }

  factory TodoItem.fromJson(Map<String, dynamic> json,
      {i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return TodoItem(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      category: serializer.fromJson<int?>(json['category']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
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
      'dueDate': serializer.toJson<DateTime?>(dueDate),
    };
  }

  i1.TodoItem copyWith(
          {int? id,
          String? title,
          String? content,
          i0.Value<int?> category = const i0.Value.absent(),
          i0.Value<DateTime?> dueDate = const i0.Value.absent()}) =>
      i1.TodoItem(
        id: id ?? this.id,
        title: title ?? this.title,
        content: content ?? this.content,
        category: category.present ? category.value : this.category,
        dueDate: dueDate.present ? dueDate.value : this.dueDate,
      );
  TodoItem copyWithCompanion(i1.TodoItemsCompanion data) {
    return TodoItem(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      category: data.category.present ? data.category.value : this.category,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TodoItem(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('category: $category, ')
          ..write('dueDate: $dueDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, content, category, dueDate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.TodoItem &&
          other.id == this.id &&
          other.title == this.title &&
          other.content == this.content &&
          other.category == this.category &&
          other.dueDate == this.dueDate);
}

class TodoItemsCompanion extends i0.UpdateCompanion<i1.TodoItem> {
  final i0.Value<int> id;
  final i0.Value<String> title;
  final i0.Value<String> content;
  final i0.Value<int?> category;
  final i0.Value<DateTime?> dueDate;
  const TodoItemsCompanion({
    this.id = const i0.Value.absent(),
    this.title = const i0.Value.absent(),
    this.content = const i0.Value.absent(),
    this.category = const i0.Value.absent(),
    this.dueDate = const i0.Value.absent(),
  });
  TodoItemsCompanion.insert({
    this.id = const i0.Value.absent(),
    required String title,
    required String content,
    this.category = const i0.Value.absent(),
    this.dueDate = const i0.Value.absent(),
  })  : title = i0.Value(title),
        content = i0.Value(content);
  static i0.Insertable<i1.TodoItem> custom({
    i0.Expression<int>? id,
    i0.Expression<String>? title,
    i0.Expression<String>? content,
    i0.Expression<int>? category,
    i0.Expression<DateTime>? dueDate,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (content != null) 'body': content,
      if (category != null) 'category': category,
      if (dueDate != null) 'due_date': dueDate,
    });
  }

  i1.TodoItemsCompanion copyWith(
      {i0.Value<int>? id,
      i0.Value<String>? title,
      i0.Value<String>? content,
      i0.Value<int?>? category,
      i0.Value<DateTime?>? dueDate}) {
    return i1.TodoItemsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
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
      map['body'] = i0.Variable<String>(content.value);
    }
    if (category.present) {
      map['category'] = i0.Variable<int>(category.value);
    }
    if (dueDate.present) {
      map['due_date'] = i0.Variable<DateTime>(dueDate.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TodoItemsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('category: $category, ')
          ..write('dueDate: $dueDate')
          ..write(')'))
        .toString();
  }
}

typedef $$TodoItemsTableCreateCompanionBuilder = i1.TodoItemsCompanion
    Function({
  i0.Value<int> id,
  required String title,
  required String content,
  i0.Value<int?> category,
  i0.Value<DateTime?> dueDate,
});
typedef $$TodoItemsTableUpdateCompanionBuilder = i1.TodoItemsCompanion
    Function({
  i0.Value<int> id,
  i0.Value<String> title,
  i0.Value<String> content,
  i0.Value<int?> category,
  i0.Value<DateTime?> dueDate,
});

class $$TodoItemsTableFilterComposer
    extends i0.FilterComposer<i0.GeneratedDatabase, i1.$TodoItemsTable> {
  $$TodoItemsTableFilterComposer(super.$state);
  i0.ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          i0.ColumnFilters(column, joinBuilders: joinBuilders));

  i0.ColumnFilters<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          i0.ColumnFilters(column, joinBuilders: joinBuilders));

  i0.ColumnFilters<String> get content => $state.composableBuilder(
      column: $state.table.content,
      builder: (column, joinBuilders) =>
          i0.ColumnFilters(column, joinBuilders: joinBuilders));

  i0.ColumnFilters<DateTime> get dueDate => $state.composableBuilder(
      column: $state.table.dueDate,
      builder: (column, joinBuilders) =>
          i0.ColumnFilters(column, joinBuilders: joinBuilders));

  i1.$$CategoriesTableFilterComposer get category {
    final i1.$$CategoriesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.category,
        referencedTable: i3.ReadDatabaseContainer($state.db)
            .resultSet<i1.$CategoriesTable>('categories'),
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            i1.$$CategoriesTableFilterComposer(i0.ComposerState(
                $state.db,
                i3.ReadDatabaseContainer($state.db)
                    .resultSet<i1.$CategoriesTable>('categories'),
                joinBuilder,
                parentComposers)));
    return composer;
  }
}

class $$TodoItemsTableOrderingComposer
    extends i0.OrderingComposer<i0.GeneratedDatabase, i1.$TodoItemsTable> {
  $$TodoItemsTableOrderingComposer(super.$state);
  i0.ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          i0.ColumnOrderings(column, joinBuilders: joinBuilders));

  i0.ColumnOrderings<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          i0.ColumnOrderings(column, joinBuilders: joinBuilders));

  i0.ColumnOrderings<String> get content => $state.composableBuilder(
      column: $state.table.content,
      builder: (column, joinBuilders) =>
          i0.ColumnOrderings(column, joinBuilders: joinBuilders));

  i0.ColumnOrderings<DateTime> get dueDate => $state.composableBuilder(
      column: $state.table.dueDate,
      builder: (column, joinBuilders) =>
          i0.ColumnOrderings(column, joinBuilders: joinBuilders));

  i1.$$CategoriesTableOrderingComposer get category {
    final i1.$$CategoriesTableOrderingComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.category,
            referencedTable: i3.ReadDatabaseContainer($state.db)
                .resultSet<i1.$CategoriesTable>('categories'),
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder, parentComposers) =>
                i1.$$CategoriesTableOrderingComposer(i0.ComposerState(
                    $state.db,
                    i3.ReadDatabaseContainer($state.db)
                        .resultSet<i1.$CategoriesTable>('categories'),
                    joinBuilder,
                    parentComposers)));
    return composer;
  }
}

class $$TodoItemsTableTableManager extends i0.RootTableManager<
    i0.GeneratedDatabase,
    i1.$TodoItemsTable,
    i1.TodoItem,
    i1.$$TodoItemsTableFilterComposer,
    i1.$$TodoItemsTableOrderingComposer,
    $$TodoItemsTableCreateCompanionBuilder,
    $$TodoItemsTableUpdateCompanionBuilder,
    (
      i1.TodoItem,
      i0.BaseReferences<i0.GeneratedDatabase, i1.$TodoItemsTable, i1.TodoItem>
    ),
    i1.TodoItem,
    i0.PrefetchHooks Function({bool category})> {
  $$TodoItemsTableTableManager(
      i0.GeneratedDatabase db, i1.$TodoItemsTable table)
      : super(i0.TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              i1.$$TodoItemsTableFilterComposer(i0.ComposerState(db, table)),
          orderingComposer:
              i1.$$TodoItemsTableOrderingComposer(i0.ComposerState(db, table)),
          updateCompanionCallback: ({
            i0.Value<int> id = const i0.Value.absent(),
            i0.Value<String> title = const i0.Value.absent(),
            i0.Value<String> content = const i0.Value.absent(),
            i0.Value<int?> category = const i0.Value.absent(),
            i0.Value<DateTime?> dueDate = const i0.Value.absent(),
          }) =>
              i1.TodoItemsCompanion(
            id: id,
            title: title,
            content: content,
            category: category,
            dueDate: dueDate,
          ),
          createCompanionCallback: ({
            i0.Value<int> id = const i0.Value.absent(),
            required String title,
            required String content,
            i0.Value<int?> category = const i0.Value.absent(),
            i0.Value<DateTime?> dueDate = const i0.Value.absent(),
          }) =>
              i1.TodoItemsCompanion.insert(
            id: id,
            title: title,
            content: content,
            category: category,
            dueDate: dueDate,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), i0.BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TodoItemsTableProcessedTableManager = i0.ProcessedTableManager<
    i0.GeneratedDatabase,
    i1.$TodoItemsTable,
    i1.TodoItem,
    i1.$$TodoItemsTableFilterComposer,
    i1.$$TodoItemsTableOrderingComposer,
    $$TodoItemsTableCreateCompanionBuilder,
    $$TodoItemsTableUpdateCompanionBuilder,
    (
      i1.TodoItem,
      i0.BaseReferences<i0.GeneratedDatabase, i1.$TodoItemsTable, i1.TodoItem>
    ),
    i1.TodoItem,
    i0.PrefetchHooks Function({bool category})>;

class $CategoriesTable extends i2.Categories
    with i0.TableInfo<$CategoriesTable, i1.Category> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _idMeta = const i0.VerificationMeta('id');
  @override
  late final i0.GeneratedColumn<int> id = i0.GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: i0.DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          i0.GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const i0.VerificationMeta _nameMeta =
      const i0.VerificationMeta('name');
  @override
  late final i0.GeneratedColumn<String> name = i0.GeneratedColumn<String>(
      'name', aliasedName, false,
      type: i0.DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<i0.GeneratedColumn> get $columns => [id, name];
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
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
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
      name: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.string, data['${effectivePrefix}name'])!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends i0.DataClass implements i0.Insertable<i1.Category> {
  final int id;
  final String name;
  const Category({required this.id, required this.name});
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['id'] = i0.Variable<int>(id);
    map['name'] = i0.Variable<String>(name);
    return map;
  }

  i1.CategoriesCompanion toCompanion(bool nullToAbsent) {
    return i1.CategoriesCompanion(
      id: i0.Value(id),
      name: i0.Value(name),
    );
  }

  factory Category.fromJson(Map<String, dynamic> json,
      {i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  i1.Category copyWith({int? id, String? name}) => i1.Category(
        id: id ?? this.id,
        name: name ?? this.name,
      );
  Category copyWithCompanion(i1.CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
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
      (other is i1.Category && other.id == this.id && other.name == this.name);
}

class CategoriesCompanion extends i0.UpdateCompanion<i1.Category> {
  final i0.Value<int> id;
  final i0.Value<String> name;
  const CategoriesCompanion({
    this.id = const i0.Value.absent(),
    this.name = const i0.Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const i0.Value.absent(),
    required String name,
  }) : name = i0.Value(name);
  static i0.Insertable<i1.Category> custom({
    i0.Expression<int>? id,
    i0.Expression<String>? name,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  i1.CategoriesCompanion copyWith({i0.Value<int>? id, i0.Value<String>? name}) {
    return i1.CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (id.present) {
      map['id'] = i0.Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = i0.Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

typedef $$CategoriesTableCreateCompanionBuilder = i1.CategoriesCompanion
    Function({
  i0.Value<int> id,
  required String name,
});
typedef $$CategoriesTableUpdateCompanionBuilder = i1.CategoriesCompanion
    Function({
  i0.Value<int> id,
  i0.Value<String> name,
});

class $$CategoriesTableFilterComposer
    extends i0.FilterComposer<i0.GeneratedDatabase, i1.$CategoriesTable> {
  $$CategoriesTableFilterComposer(super.$state);
  i0.ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          i0.ColumnFilters(column, joinBuilders: joinBuilders));

  i0.ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          i0.ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$CategoriesTableOrderingComposer
    extends i0.OrderingComposer<i0.GeneratedDatabase, i1.$CategoriesTable> {
  $$CategoriesTableOrderingComposer(super.$state);
  i0.ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          i0.ColumnOrderings(column, joinBuilders: joinBuilders));

  i0.ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          i0.ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$CategoriesTableTableManager extends i0.RootTableManager<
    i0.GeneratedDatabase,
    i1.$CategoriesTable,
    i1.Category,
    i1.$$CategoriesTableFilterComposer,
    i1.$$CategoriesTableOrderingComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (
      i1.Category,
      i0.BaseReferences<i0.GeneratedDatabase, i1.$CategoriesTable, i1.Category>
    ),
    i1.Category,
    i0.PrefetchHooks Function()> {
  $$CategoriesTableTableManager(
      i0.GeneratedDatabase db, i1.$CategoriesTable table)
      : super(i0.TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              i1.$$CategoriesTableFilterComposer(i0.ComposerState(db, table)),
          orderingComposer:
              i1.$$CategoriesTableOrderingComposer(i0.ComposerState(db, table)),
          updateCompanionCallback: ({
            i0.Value<int> id = const i0.Value.absent(),
            i0.Value<String> name = const i0.Value.absent(),
          }) =>
              i1.CategoriesCompanion(
            id: id,
            name: name,
          ),
          createCompanionCallback: ({
            i0.Value<int> id = const i0.Value.absent(),
            required String name,
          }) =>
              i1.CategoriesCompanion.insert(
            id: id,
            name: name,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), i0.BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CategoriesTableProcessedTableManager = i0.ProcessedTableManager<
    i0.GeneratedDatabase,
    i1.$CategoriesTable,
    i1.Category,
    i1.$$CategoriesTableFilterComposer,
    i1.$$CategoriesTableOrderingComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (
      i1.Category,
      i0.BaseReferences<i0.GeneratedDatabase, i1.$CategoriesTable, i1.Category>
    ),
    i1.Category,
    i0.PrefetchHooks Function()>;

class $UsersTable extends i2.Users with i0.TableInfo<$UsersTable, i1.User> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _firstNameMeta =
      const i0.VerificationMeta('firstName');
  @override
  late final i0.GeneratedColumn<String> firstName = i0.GeneratedColumn<String>(
      'first_name', aliasedName, false,
      type: i0.DriftSqlType.string, requiredDuringInsert: true);
  static const i0.VerificationMeta _lastNameMeta =
      const i0.VerificationMeta('lastName');
  @override
  late final i0.GeneratedColumn<String> lastName = i0.GeneratedColumn<String>(
      'last_name', aliasedName, false,
      type: i0.DriftSqlType.string, requiredDuringInsert: true);
  static const i0.VerificationMeta _idMeta = const i0.VerificationMeta('id');
  @override
  late final i0.GeneratedColumn<int> id = i0.GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: i0.DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          i0.GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const i0.VerificationMeta _birthDateMeta =
      const i0.VerificationMeta('birthDate');
  @override
  late final i0.GeneratedColumn<DateTime> birthDate =
      i0.GeneratedColumn<DateTime>('birth_date', aliasedName, false,
          type: i0.DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<i0.GeneratedColumn> get $columns => [firstName, lastName, id, birthDate];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  i0.VerificationContext validateIntegrity(i0.Insertable<i1.User> instance,
      {bool isInserting = false}) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('first_name')) {
      context.handle(_firstNameMeta,
          firstName.isAcceptableOrUnknown(data['first_name']!, _firstNameMeta));
    } else if (isInserting) {
      context.missing(_firstNameMeta);
    }
    if (data.containsKey('last_name')) {
      context.handle(_lastNameMeta,
          lastName.isAcceptableOrUnknown(data['last_name']!, _lastNameMeta));
    } else if (isInserting) {
      context.missing(_lastNameMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('birth_date')) {
      context.handle(_birthDateMeta,
          birthDate.isAcceptableOrUnknown(data['birth_date']!, _birthDateMeta));
    } else if (isInserting) {
      context.missing(_birthDateMeta);
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {id};
  @override
  i1.User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.User(
      firstName: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.string, data['${effectivePrefix}first_name'])!,
      lastName: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.string, data['${effectivePrefix}last_name'])!,
      id: attachedDatabase.typeMapping
          .read(i0.DriftSqlType.int, data['${effectivePrefix}id'])!,
      birthDate: attachedDatabase.typeMapping.read(
          i0.DriftSqlType.dateTime, data['${effectivePrefix}birth_date'])!,
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends i0.DataClass implements i0.Insertable<i1.User> {
  final String firstName;
  final String lastName;
  final int id;
  final DateTime birthDate;
  const User(
      {required this.firstName,
      required this.lastName,
      required this.id,
      required this.birthDate});
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['first_name'] = i0.Variable<String>(firstName);
    map['last_name'] = i0.Variable<String>(lastName);
    map['id'] = i0.Variable<int>(id);
    map['birth_date'] = i0.Variable<DateTime>(birthDate);
    return map;
  }

  i1.UsersCompanion toCompanion(bool nullToAbsent) {
    return i1.UsersCompanion(
      firstName: i0.Value(firstName),
      lastName: i0.Value(lastName),
      id: i0.Value(id),
      birthDate: i0.Value(birthDate),
    );
  }

  factory User.fromJson(Map<String, dynamic> json,
      {i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return User(
      firstName: serializer.fromJson<String>(json['firstName']),
      lastName: serializer.fromJson<String>(json['lastName']),
      id: serializer.fromJson<int>(json['id']),
      birthDate: serializer.fromJson<DateTime>(json['birthDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'firstName': serializer.toJson<String>(firstName),
      'lastName': serializer.toJson<String>(lastName),
      'id': serializer.toJson<int>(id),
      'birthDate': serializer.toJson<DateTime>(birthDate),
    };
  }

  i1.User copyWith(
          {String? firstName,
          String? lastName,
          int? id,
          DateTime? birthDate}) =>
      i1.User(
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        id: id ?? this.id,
        birthDate: birthDate ?? this.birthDate,
      );
  User copyWithCompanion(i1.UsersCompanion data) {
    return User(
      firstName: data.firstName.present ? data.firstName.value : this.firstName,
      lastName: data.lastName.present ? data.lastName.value : this.lastName,
      id: data.id.present ? data.id.value : this.id,
      birthDate: data.birthDate.present ? data.birthDate.value : this.birthDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('id: $id, ')
          ..write('birthDate: $birthDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(firstName, lastName, id, birthDate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.User &&
          other.firstName == this.firstName &&
          other.lastName == this.lastName &&
          other.id == this.id &&
          other.birthDate == this.birthDate);
}

class UsersCompanion extends i0.UpdateCompanion<i1.User> {
  final i0.Value<String> firstName;
  final i0.Value<String> lastName;
  final i0.Value<int> id;
  final i0.Value<DateTime> birthDate;
  const UsersCompanion({
    this.firstName = const i0.Value.absent(),
    this.lastName = const i0.Value.absent(),
    this.id = const i0.Value.absent(),
    this.birthDate = const i0.Value.absent(),
  });
  UsersCompanion.insert({
    required String firstName,
    required String lastName,
    this.id = const i0.Value.absent(),
    required DateTime birthDate,
  })  : firstName = i0.Value(firstName),
        lastName = i0.Value(lastName),
        birthDate = i0.Value(birthDate);
  static i0.Insertable<i1.User> custom({
    i0.Expression<String>? firstName,
    i0.Expression<String>? lastName,
    i0.Expression<int>? id,
    i0.Expression<DateTime>? birthDate,
  }) {
    return i0.RawValuesInsertable({
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (id != null) 'id': id,
      if (birthDate != null) 'birth_date': birthDate,
    });
  }

  i1.UsersCompanion copyWith(
      {i0.Value<String>? firstName,
      i0.Value<String>? lastName,
      i0.Value<int>? id,
      i0.Value<DateTime>? birthDate}) {
    return i1.UsersCompanion(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      id: id ?? this.id,
      birthDate: birthDate ?? this.birthDate,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (firstName.present) {
      map['first_name'] = i0.Variable<String>(firstName.value);
    }
    if (lastName.present) {
      map['last_name'] = i0.Variable<String>(lastName.value);
    }
    if (id.present) {
      map['id'] = i0.Variable<int>(id.value);
    }
    if (birthDate.present) {
      map['birth_date'] = i0.Variable<DateTime>(birthDate.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('id: $id, ')
          ..write('birthDate: $birthDate')
          ..write(')'))
        .toString();
  }
}

typedef $$UsersTableCreateCompanionBuilder = i1.UsersCompanion Function({
  required String firstName,
  required String lastName,
  i0.Value<int> id,
  required DateTime birthDate,
});
typedef $$UsersTableUpdateCompanionBuilder = i1.UsersCompanion Function({
  i0.Value<String> firstName,
  i0.Value<String> lastName,
  i0.Value<int> id,
  i0.Value<DateTime> birthDate,
});

class $$UsersTableFilterComposer
    extends i0.FilterComposer<i0.GeneratedDatabase, i1.$UsersTable> {
  $$UsersTableFilterComposer(super.$state);
  i0.ColumnFilters<String> get firstName => $state.composableBuilder(
      column: $state.table.firstName,
      builder: (column, joinBuilders) =>
          i0.ColumnFilters(column, joinBuilders: joinBuilders));

  i0.ColumnFilters<String> get lastName => $state.composableBuilder(
      column: $state.table.lastName,
      builder: (column, joinBuilders) =>
          i0.ColumnFilters(column, joinBuilders: joinBuilders));

  i0.ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          i0.ColumnFilters(column, joinBuilders: joinBuilders));

  i0.ColumnFilters<DateTime> get birthDate => $state.composableBuilder(
      column: $state.table.birthDate,
      builder: (column, joinBuilders) =>
          i0.ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$UsersTableOrderingComposer
    extends i0.OrderingComposer<i0.GeneratedDatabase, i1.$UsersTable> {
  $$UsersTableOrderingComposer(super.$state);
  i0.ColumnOrderings<String> get firstName => $state.composableBuilder(
      column: $state.table.firstName,
      builder: (column, joinBuilders) =>
          i0.ColumnOrderings(column, joinBuilders: joinBuilders));

  i0.ColumnOrderings<String> get lastName => $state.composableBuilder(
      column: $state.table.lastName,
      builder: (column, joinBuilders) =>
          i0.ColumnOrderings(column, joinBuilders: joinBuilders));

  i0.ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          i0.ColumnOrderings(column, joinBuilders: joinBuilders));

  i0.ColumnOrderings<DateTime> get birthDate => $state.composableBuilder(
      column: $state.table.birthDate,
      builder: (column, joinBuilders) =>
          i0.ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$UsersTableTableManager extends i0.RootTableManager<
    i0.GeneratedDatabase,
    i1.$UsersTable,
    i1.User,
    i1.$$UsersTableFilterComposer,
    i1.$$UsersTableOrderingComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    (i1.User, i0.BaseReferences<i0.GeneratedDatabase, i1.$UsersTable, i1.User>),
    i1.User,
    i0.PrefetchHooks Function()> {
  $$UsersTableTableManager(i0.GeneratedDatabase db, i1.$UsersTable table)
      : super(i0.TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              i1.$$UsersTableFilterComposer(i0.ComposerState(db, table)),
          orderingComposer:
              i1.$$UsersTableOrderingComposer(i0.ComposerState(db, table)),
          updateCompanionCallback: ({
            i0.Value<String> firstName = const i0.Value.absent(),
            i0.Value<String> lastName = const i0.Value.absent(),
            i0.Value<int> id = const i0.Value.absent(),
            i0.Value<DateTime> birthDate = const i0.Value.absent(),
          }) =>
              i1.UsersCompanion(
            firstName: firstName,
            lastName: lastName,
            id: id,
            birthDate: birthDate,
          ),
          createCompanionCallback: ({
            required String firstName,
            required String lastName,
            i0.Value<int> id = const i0.Value.absent(),
            required DateTime birthDate,
          }) =>
              i1.UsersCompanion.insert(
            firstName: firstName,
            lastName: lastName,
            id: id,
            birthDate: birthDate,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), i0.BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UsersTableProcessedTableManager = i0.ProcessedTableManager<
    i0.GeneratedDatabase,
    i1.$UsersTable,
    i1.User,
    i1.$$UsersTableFilterComposer,
    i1.$$UsersTableOrderingComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    (i1.User, i0.BaseReferences<i0.GeneratedDatabase, i1.$UsersTable, i1.User>),
    i1.User,
    i0.PrefetchHooks Function()>;
