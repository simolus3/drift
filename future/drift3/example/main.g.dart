// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// ignore_for_file: type=lint
class $TodoCategoriesTable extends TodoCategories
    with ResultSet<TodoCategory, $TodoCategoriesTable>
    implements GeneratedTable<TodoCategory, $TodoCategoriesTable> {
  @override
  final String? alias;
  $TodoCategoriesTable([this.alias]);
  @override
  late final TableColumn<int> id = TableColumn<int>(
    name: 'id',
    sqlType: BuiltinDriftType.int,
    requiredDuringInsert: false,
    constraints: () => [
      const ColumnPrimaryKeyConstraint(isAutoIncrementing: true),
      const ColumnNotNullConstraint(),
    ],
  )..owningResultSet = this;
  @override
  late final TableColumn<String> name = TableColumn<String>(
    name: 'name',
    sqlType: BuiltinDriftType.text,
    requiredDuringInsert: true,
    constraints: () => [const ColumnNotNullConstraint()],
  )..owningResultSet = this;
  @override
  List<TableColumn> get columns => [id, name];
  @override
  String get entityName => $name;
  static const String $name = 'todo_categories';
  @override
  $TodoCategoriesTable asSelfType() => this;

  @override
  Set<TableColumn> get primaryKey => {id};
  @override
  TodoCategory? Function(RawRow) createMapperFromPositions(
    DriftDialect dialect,
    List<ColumnPosition> positions,
  ) {
    final pos$id = positions[0].index;
    final type$0 = BuiltinDriftType.int.resolveIn(dialect);
    final pos$name = positions[1].index;
    final type$1 = BuiltinDriftType.text.resolveIn(dialect);
    return (RawRow row) {
      // Not part of row if non-nullable column "id" is missing
      if (row[pos$id] == null) {
        return null;
      }
      return TodoCategory(
        id: type$0.dartValue(row[pos$id]!),
        name: type$1.dartValue(row[pos$name]!),
      );
    };
  }

  @override
  $TodoCategoriesTable withAlias(String alias) {
    return $TodoCategoriesTable(alias);
  }
}

class TodoCategory extends LegacyDataClass implements Insertable<TodoCategory> {
  final int id;
  final String name;
  const TodoCategory({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id, BuiltinDriftType.int);
    map['name'] = Variable<String>(name, BuiltinDriftType.text);
    return map;
  }

  TodoCategoriesCompanion toCompanion(bool nullToAbsent) {
    return TodoCategoriesCompanion(id: Value(id), name: Value(name));
  }

  factory TodoCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TodoCategory(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  TodoCategory copyWith({int? id, String? name}) =>
      TodoCategory(id: id ?? this.id, name: name ?? this.name);
  TodoCategory copyWithCompanion(TodoCategoriesCompanion data) {
    return TodoCategory(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TodoCategory(')
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
      (other is TodoCategory && other.id == this.id && other.name == this.name);
}

class TodoCategoriesCompanion extends UpdateCompanion<TodoCategory> {
  final Value<int> id;
  final Value<String> name;
  const TodoCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  TodoCategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
  }) : name = Value(name);
  static Insertable<TodoCategory> custom({
    Expression<int>? id,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  TodoCategoriesCompanion copyWith({Value<int>? id, Value<String>? name}) {
    return TodoCategoriesCompanion(id: id ?? this.id, name: name ?? this.name);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value, BuiltinDriftType.int);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value, BuiltinDriftType.text);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TodoCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

abstract base class _$Database extends GeneratedDatabase {
  _$Database(super.implementation);
  $TodoCategoriesTable get todoCategories => $TodoCategoriesTable();
  @override
  DatabaseSchema get schema => _$schema;
  static final DatabaseSchema _$schema = DatabaseSchema([
    $TodoCategoriesTable(),
  ]);
}
