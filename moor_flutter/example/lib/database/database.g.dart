// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// **************************************************************************
// MoorGenerator
// **************************************************************************

class TodoEntry {
  final int id;
  final String content;
  final DateTime targetDate;
  final int category;
  TodoEntry({this.id, this.content, this.targetDate, this.category});
  factory TodoEntry.fromData(Map<String, dynamic> data, GeneratedDatabase db) {
    final intType = db.typeSystem.forDartType<int>();
    final stringType = db.typeSystem.forDartType<String>();
    final dateTimeType = db.typeSystem.forDartType<DateTime>();
    return TodoEntry(
      id: intType.mapFromDatabaseResponse(data['id']),
      content: stringType.mapFromDatabaseResponse(data['content']),
      targetDate: dateTimeType.mapFromDatabaseResponse(data['target_date']),
      category: intType.mapFromDatabaseResponse(data['category']),
    );
  }
  Map<String, Object> toJson() {
    return {
      'id': id,
      'content': content,
      'targetDate': targetDate,
      'category': category,
    };
  }

  TodoEntry copyWith(
          {int id, String content, DateTime targetDate, int category}) =>
      TodoEntry(
        id: id ?? this.id,
        content: content ?? this.content,
        targetDate: targetDate ?? this.targetDate,
        category: category ?? this.category,
      );
  @override
  String toString() {
    return (StringBuffer('TodoEntry(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('targetDate: $targetDate, ')
          ..write('category: $category')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      (((id.hashCode) * 31 + content.hashCode) * 31 + targetDate.hashCode) *
          31 +
      category.hashCode;
  @override
  bool operator ==(other) =>
      identical(this, other) ||
      (other is TodoEntry &&
          other.id == id &&
          other.content == content &&
          other.targetDate == targetDate &&
          other.category == category);
}

class $TodosTable extends Todos implements TableInfo<Todos, TodoEntry> {
  final GeneratedDatabase _db;
  $TodosTable(this._db);
  @override
  GeneratedIntColumn get id =>
      GeneratedIntColumn('id', false, hasAutoIncrement: true);
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
  List<GeneratedColumn> get $columns => [id, content, targetDate, category];
  @override
  Todos get asDslTable => this;
  @override
  String get $tableName => 'todos';
  @override
  bool validateIntegrity(TodoEntry instance, bool isInserting) =>
      id.isAcceptableValue(instance.id, isInserting) &&
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
  Map<String, Object> toJson() {
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

abstract class _$Database extends GeneratedDatabase {
  _$Database(QueryExecutor e) : super(const SqlTypeSystem.withDefaults(), e);
  $TodosTable get todos => $TodosTable(this);
  $CategoriesTable get categories => $CategoriesTable(this);
  TodosDao _todosDao;
  TodosDao get todosDao => _todosDao ??= TodosDao(this as Database);
  @override
  List<TableInfo> get allTables => [todos, categories];
}
