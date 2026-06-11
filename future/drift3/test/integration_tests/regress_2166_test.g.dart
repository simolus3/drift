// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'regress_2166_test.dart';

// ignore_for_file: type=lint
class $SomeTableTable extends SomeTable
    with ResultSet<SomeTableData, $SomeTableTable>
    implements GeneratedTable<SomeTableData, $SomeTableTable> {
  @override
  final String? alias;
  $SomeTableTable([this.alias]);
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
    requiredDuringInsert: false,
  )..owningResultSet = this;
  @override
  List<TableColumn> get columns => [id, name];
  @override
  String get entityName => $name;
  static const String $name = 'some_table';
  @override
  $SomeTableTable asSelfType() => this;

  @override
  Set<TableColumn> get primaryKey => {id};
  @override
  SomeTableData? Function(RawRow) createMapperFromPositions(
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
      return SomeTableData(
        id: type$0.dartValue(row[pos$id]!),
        name: type$1.nullableDartValue(row[pos$name]),
      );
    };
  }

  @override
  $SomeTableTable withAlias(String alias) {
    return $SomeTableTable(alias);
  }
}

class SomeTableData extends LegacyDataClass
    implements Insertable<SomeTableData> {
  final int id;
  final String? name;
  const SomeTableData({required this.id, this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id, BuiltinDriftType.int);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name, BuiltinDriftType.text);
    }
    return map;
  }

  SomeTableCompanion toCompanion(bool nullToAbsent) {
    return SomeTableCompanion(
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
    );
  }

  factory SomeTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SomeTableData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String?>(name),
    };
  }

  SomeTableData copyWith({
    int? id,
    Value<String?> name = const Value.absent(),
  }) => SomeTableData(
    id: id ?? this.id,
    name: name.present ? name.value : this.name,
  );
  SomeTableData copyWithCompanion(SomeTableCompanion data) {
    return SomeTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SomeTableData(')
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
      (other is SomeTableData &&
          other.id == this.id &&
          other.name == this.name);
}

class SomeTableCompanion extends UpdateCompanion<SomeTableData> {
  final Value<int> id;
  final Value<String?> name;
  const SomeTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  SomeTableCompanion.insert({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  static Insertable<SomeTableData> custom({
    Expression<int>? id,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  SomeTableCompanion copyWith({Value<int>? id, Value<String?>? name}) {
    return SomeTableCompanion(id: id ?? this.id, name: name ?? this.name);
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
    return (StringBuffer('SomeTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

abstract base class _$_SomeDb extends GeneratedDatabase {
  _$_SomeDb(super.implementation);
  $SomeTableTable get someTable => $SomeTableTable();
  @override
  DatabaseSchema get schema => _$schema;
  static final DatabaseSchema _$schema = DatabaseSchema([$SomeTableTable()]);
}
