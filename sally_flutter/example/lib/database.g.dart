// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// **************************************************************************
// SallyGenerator
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

class _$TodosTable extends Todos implements TableInfo<Todos, TodoEntry> {
  final GeneratedDatabase _db;
  _$TodosTable(this._db);
  @override
  GeneratedIntColumn get id =>
      GeneratedIntColumn('id', false, hasAutoIncrement: true);
  @override
  GeneratedTextColumn get title => GeneratedTextColumn(
        'title',
        true,
      );
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
  Todos get asDslTable => this;
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
  Set<GeneratedColumn> get $primaryKey => Set();
  @override
  TodoEntry map(Map<String, dynamic> data) {
    return TodoEntry.fromData(data, _db);
  }

  @override
  Map<String, Variable> entityToSql(TodoEntry d) {
    final map = <String, Variable>{};
    if (d.id != null) {
      map['id'] = Variable<int, IntType>(d.id);
    }
    if (d.title != null) {
      map['title'] = Variable<String, StringType>(d.title);
    }
    if (d.content != null) {
      map['content'] = Variable<String, StringType>(d.content);
    }
    if (d.targetDate != null) {
      map['target_date'] = Variable<DateTime, DateTimeType>(d.targetDate);
    }
    if (d.category != null) {
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
  @override
  int get hashCode => (id.hashCode) * 31 + description.hashCode;
  @override
  bool operator ==(other) =>
      identical(this, other) ||
      (other is Category && other.id == id && other.description == description);
}

class _$CategoriesTable extends Categories
    implements TableInfo<Categories, Category> {
  final GeneratedDatabase _db;
  _$CategoriesTable(this._db);
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
  Set<GeneratedColumn> get $primaryKey => Set();
  @override
  Category map(Map<String, dynamic> data) {
    return Category.fromData(data, _db);
  }

  @override
  Map<String, Variable> entityToSql(Category d) {
    final map = <String, Variable>{};
    if (d.id != null) {
      map['id'] = Variable<int, IntType>(d.id);
    }
    if (d.description != null) {
      map['`desc`'] = Variable<String, StringType>(d.description);
    }
    return map;
  }
}

abstract class _$Database extends GeneratedDatabase {
  _$Database(QueryExecutor e) : super(const SqlTypeSystem.withDefaults(), e);
  _$TodosTable get todos => _$TodosTable(this);
  _$CategoriesTable get categories => _$CategoriesTable(this);
  @override
  List<TableInfo> get allTables => [todos, categories];
}
