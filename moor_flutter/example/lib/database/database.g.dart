// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// **************************************************************************
// MoorGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps
class TodoEntry extends DataClass {
  final int id;
  final String content;
  final DateTime targetDate;
  final int category;
  TodoEntry({this.id, this.content, this.targetDate, this.category});
  factory TodoEntry.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final intType = db.typeSystem.forDartType<int>();
    final stringType = db.typeSystem.forDartType<String>();
    final dateTimeType = db.typeSystem.forDartType<DateTime>();
    return TodoEntry(
      id: intType.mapFromDatabaseResponse(data['${effectivePrefix}id']),
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
      content: serializer.fromJson<String>(json['content']),
      targetDate: serializer.fromJson<DateTime>(json['targetDate']),
      category: serializer.fromJson<int>(json['category']),
    );
  }
  @override
  Map<String, dynamic> toJson(
      {ValueSerializer serializer = const ValueSerializer.defaults()}) {
    return {
      'id': serializer.toJson<int>(id),
      'content': serializer.toJson<String>(content),
      'targetDate': serializer.toJson<DateTime>(targetDate),
      'category': serializer.toJson<int>(category),
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
  int get hashCode => $mrjf($mrjc(
      $mrjc(
          $mrjc($mrjc(0, id.hashCode), content.hashCode), targetDate.hashCode),
      category.hashCode));
  @override
  bool operator ==(other) =>
      identical(this, other) ||
      (other is TodoEntry &&
          other.id == id &&
          other.content == content &&
          other.targetDate == targetDate &&
          other.category == category);
}

class $TodosTable extends Todos with TableInfo<$TodosTable, TodoEntry> {
  final GeneratedDatabase _db;
  final String _alias;
  $TodosTable(this._db, [this._alias]);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  GeneratedIntColumn _id;
  @override
  GeneratedIntColumn get id => _id ??= _constructId();
  GeneratedIntColumn _constructId() {
    return GeneratedIntColumn('id', $tableName, false, hasAutoIncrement: true);
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
    return GeneratedIntColumn('category', $tableName, true,
        $customConstraints: 'NULLABLE REFERENCES categories(id)');
  }

  @override
  List<GeneratedColumn> get $columns => [id, content, targetDate, category];
  @override
  $TodosTable get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'todos';
  @override
  final String actualTableName = 'todos';
  @override
  VerificationContext validateIntegrity(TodoEntry instance, bool isInserting) =>
      VerificationContext()
        ..handle(
            _idMeta, id.isAcceptableValue(instance.id, isInserting, _idMeta))
        ..handle(
            _contentMeta,
            content.isAcceptableValue(
                instance.content, isInserting, _contentMeta))
        ..handle(
            _targetDateMeta,
            targetDate.isAcceptableValue(
                instance.targetDate, isInserting, _targetDateMeta))
        ..handle(
            _categoryMeta,
            category.isAcceptableValue(
                instance.category, isInserting, _categoryMeta));
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
  $TodosTable createAlias(String alias) {
    return $TodosTable(_db, alias);
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
    return GeneratedTextColumn(
      'desc',
      $tableName,
      false,
    );
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
  VerificationContext validateIntegrity(Category instance, bool isInserting) =>
      VerificationContext()
        ..handle(
            _idMeta, id.isAcceptableValue(instance.id, isInserting, _idMeta))
        ..handle(
            _descriptionMeta,
            description.isAcceptableValue(
                instance.description, isInserting, _descriptionMeta));
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

abstract class _$Database extends GeneratedDatabase {
  _$Database(QueryExecutor e) : super(const SqlTypeSystem.withDefaults(), e);
  $TodosTable _todos;
  $TodosTable get todos => _todos ??= $TodosTable(this);
  $CategoriesTable _categories;
  $CategoriesTable get categories => _categories ??= $CategoriesTable(this);
  @override
  List<TableInfo> get allTables => [todos, categories];
}
