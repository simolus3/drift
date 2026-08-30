// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// ignore_for_file: type=lint
class $ExampleTableTable extends ExampleTable
    with ResultSet<ExampleTableData, $ExampleTableTable>
    implements GeneratedTable<ExampleTableData, $ExampleTableTable> {
  @override
  final String? alias;
  $ExampleTableTable([this.alias]);
  @override
  late final TableColumn<int> id = TableColumn<int>(
    name: 'id',
    sqlType: SqlType.int,
    requiredDuringInsert: false,
    constraints: () => [
      const ColumnPrimaryKeyConstraint(isAutoIncrementing: true),
      const ColumnNotNullConstraint(),
    ],
  )..owningResultSet = this;
  @override
  late final TableColumn<String> description = TableColumn<String>(
    name: 'description',
    sqlType: SqlType.text,
    requiredDuringInsert: true,
    constraints: () => [const ColumnNotNullConstraint()],
  )..owningResultSet = this;
  @override
  List<TableColumn> get columns => [id, description];
  @override
  String get entityName => $name;
  static const String $name = 'example_table';
  @override
  $ExampleTableTable asSelfType() => this;

  @override
  ExampleTableData? Function(RawRow) createMapperFromPositions(
    DriftDialect dialect,
    List<ColumnPosition> positions,
  ) {
    final pos$id = positions[0].index;
    final type$0 = SqlType.int.resolveIn(dialect);
    final pos$description = positions[1].index;
    final type$1 = SqlType.text.resolveIn(dialect);
    return (RawRow row) {
      // Not part of row if non-nullable column "id" is missing
      if (row[pos$id] == null) {
        return null;
      }
      return ExampleTableData(
        id: type$0.dartValue(row[pos$id]!),
        description: type$1.dartValue(row[pos$description]!),
      );
    };
  }

  @override
  $ExampleTableTable withAlias(String alias) {
    return $ExampleTableTable(alias);
  }
}

class ExampleTableData extends LegacyDataClass
    implements Insertable<ExampleTableData> {
  final int id;
  final String description;
  const ExampleTableData({required this.id, required this.description});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id, SqlType.int);
    map['description'] = Variable<String>(description, SqlType.text);
    return map;
  }

  ExampleTableCompanion toCompanion(bool nullToAbsent) {
    return ExampleTableCompanion(
      id: Value(id),
      description: Value(description),
    );
  }

  factory ExampleTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExampleTableData(
      id: serializer.fromJson<int>(json['id']),
      description: serializer.fromJson<String>(json['description']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'description': serializer.toJson<String>(description),
    };
  }

  ExampleTableData copyWith({int? id, String? description}) => ExampleTableData(
    id: id ?? this.id,
    description: description ?? this.description,
  );
  ExampleTableData copyWithCompanion(ExampleTableCompanion data) {
    return ExampleTableData(
      id: data.id.present ? data.id.value : this.id,
      description: data.description.present
          ? data.description.value
          : this.description,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExampleTableData(')
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
      (other is ExampleTableData &&
          other.id == this.id &&
          other.description == this.description);
}

class ExampleTableCompanion extends UpdateCompanion<ExampleTableData> {
  final Value<int> id;
  final Value<String> description;
  const ExampleTableCompanion({
    this.id = const Value.absent(),
    this.description = const Value.absent(),
  });
  ExampleTableCompanion.insert({
    this.id = const Value.absent(),
    required String description,
  }) : description = Value(description);
  static Insertable<ExampleTableData> custom({
    Expression<int>? id,
    Expression<String>? description,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (description != null) 'description': description,
    });
  }

  ExampleTableCompanion copyWith({Value<int>? id, Value<String>? description}) {
    return ExampleTableCompanion(
      id: id ?? this.id,
      description: description ?? this.description,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value, SqlType.int);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value, SqlType.text);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExampleTableCompanion(')
          ..write('id: $id, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }
}

abstract base class _$ExampleDatabase extends GeneratedDatabase {
  _$ExampleDatabase(super.implementation);
  $ExampleTableTable get exampleTable => $ExampleTableTable();
  TableOrViewStatements<ExampleTableData, $ExampleTableTable>
  get exampleTableQueries => this.exampleTable.statements(this);
  @override
  Map<KnownSqlDialect, Object> get dialectOptions => {
    KnownSqlDialect.sqlite: const SqliteOptions(
      strictTablesByDefault: true,
      storeDateTimesAsText: true,
      useBinaryJsonRepresentation: true,
    ),
  };
  @override
  DatabaseSchema get schema => _$schema;
  static final DatabaseSchema _$schema = DatabaseSchema([$ExampleTableTable()]);
}
