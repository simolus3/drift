// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CategoriesTable extends Categories
    with ResultSet<Category, $CategoriesTable>
    implements GeneratedTable<Category, $CategoriesTable> {
  @override
  final String? alias;
  $CategoriesTable([this.alias]);
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
  late final TableColumn<String> description = TableColumn<String>(
    name: 'desc',
    sqlType: BuiltinDriftType.text,
    requiredDuringInsert: true,
    constraints: () => [ColumnConstraint.customSql('NOT NULL UNIQUE')],
  )..owningResultSet = this;
  @override
  late final TableColumnWithTypeConverter<CategoryPriority, int> priority =
      TableColumn<int>(
          name: 'priority',
          sqlType: BuiltinDriftType.int,
          requiredDuringInsert: false,
          constraints: () => [
            const ColumnNotNullConstraint(),
            ColumnDefaultConstraint<int>(const Literal(0)),
          ],
        ).withConverter<CategoryPriority>($CategoriesTable.$converterpriority)
        ..owningResultSet = this;
  @override
  late final TableColumn<String> descriptionInUpperCase = TableColumn<String>(
    name: 'description_in_upper_case',
    sqlType: BuiltinDriftType.text,
    requiredDuringInsert: false,
    constraints: () => [
      const ColumnNotNullConstraint(),
      ColumnGeneratedAs(
        StringExpressionOperators(description).upper(),
        stored: false,
      ),
    ],
  )..owningResultSet = this;
  @override
  List<TableColumn> get columns => [
    id,
    description,
    priority,
    descriptionInUpperCase,
  ];
  @override
  String get entityName => $name;
  static const String $name = 'categories';
  @override
  $CategoriesTable asSelfType() => this;

  @override
  Set<TableColumn> get primaryKey => {id};
  @override
  Category? Function(RawRow) createMapperFromPositions(
    DriftDialect dialect,
    List<ColumnPosition> positions,
  ) {
    final pos$id = positions[0].index;
    final type$0 = BuiltinDriftType.int.resolveIn(dialect);
    final pos$description = positions[1].index;
    final type$1 = BuiltinDriftType.text.resolveIn(dialect);
    final pos$priority = positions[2].index;
    final pos$descriptionInUpperCase = positions[3].index;
    return (RawRow row) {
      // Not part of row if non-nullable column "id" is missing
      if (row[pos$id] == null) {
        return null;
      }
      return Category(
        id: type$0.dartValue(row[pos$id]!),
        description: type$1.dartValue(row[pos$description]!),
        priority: $CategoriesTable.$converterpriority.fromSql(
          type$0.dartValue(row[pos$priority]!),
        ),
        descriptionInUpperCase: type$1.dartValue(
          row[pos$descriptionInUpperCase]!,
        ),
      );
    };
  }

  @override
  $CategoriesTable withAlias(String alias) {
    return $CategoriesTable(alias);
  }

  static JsonTypeConverter2<CategoryPriority, int, int> $converterpriority =
      const EnumIndexConverter<CategoryPriority>(CategoryPriority.values);
}

class Category extends LegacyDataClass implements Insertable<Category> {
  final int id;
  final String description;
  final CategoryPriority priority;
  final String descriptionInUpperCase;
  const Category({
    required this.id,
    required this.description,
    required this.priority,
    required this.descriptionInUpperCase,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id, BuiltinDriftType.int);
    map['desc'] = Variable<String>(description, BuiltinDriftType.text);
    {
      map['priority'] = Variable<int>(
        $CategoriesTable.$converterpriority.toSql(priority),
        BuiltinDriftType.int,
      );
    }
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      description: Value(description),
      priority: Value(priority),
    );
  }

  factory Category.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<int>(json['id']),
      description: serializer.fromJson<String>(json['description']),
      priority: $CategoriesTable.$converterpriority.fromJson(
        serializer.fromJson<int>(json['priority']),
      ),
      descriptionInUpperCase: serializer.fromJson<String>(
        json['descriptionInUpperCase'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'description': serializer.toJson<String>(description),
      'priority': serializer.toJson<int>(
        $CategoriesTable.$converterpriority.toJson(priority),
      ),
      'descriptionInUpperCase': serializer.toJson<String>(
        descriptionInUpperCase,
      ),
    };
  }

  Category copyWith({
    int? id,
    String? description,
    CategoryPriority? priority,
    String? descriptionInUpperCase,
  }) => Category(
    id: id ?? this.id,
    description: description ?? this.description,
    priority: priority ?? this.priority,
    descriptionInUpperCase:
        descriptionInUpperCase ?? this.descriptionInUpperCase,
  );
  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('description: $description, ')
          ..write('priority: $priority, ')
          ..write('descriptionInUpperCase: $descriptionInUpperCase')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, description, priority, descriptionInUpperCase);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.description == this.description &&
          other.priority == this.priority &&
          other.descriptionInUpperCase == this.descriptionInUpperCase);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<int> id;
  final Value<String> description;
  final Value<CategoryPriority> priority;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.description = const Value.absent(),
    this.priority = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String description,
    this.priority = const Value.absent(),
  }) : description = Value(description);
  static Insertable<Category> custom({
    Expression<int>? id,
    Expression<String>? description,
    Expression<int>? priority,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (description != null) 'desc': description,
      if (priority != null) 'priority': priority,
    });
  }

  CategoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? description,
    Value<CategoryPriority>? priority,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      description: description ?? this.description,
      priority: priority ?? this.priority,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value, BuiltinDriftType.int);
    }
    if (description.present) {
      map['desc'] = Variable<String>(description.value, BuiltinDriftType.text);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(
        $CategoriesTable.$converterpriority.toSql(priority.value),
        BuiltinDriftType.int,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('description: $description, ')
          ..write('priority: $priority')
          ..write(')'))
        .toString();
  }
}

class $TableWithEveryColumnTypeTable extends TableWithEveryColumnType
    with ResultSet<TableWithEveryColumnTypeData, $TableWithEveryColumnTypeTable>
    implements
        GeneratedTable<
          TableWithEveryColumnTypeData,
          $TableWithEveryColumnTypeTable
        > {
  @override
  final String? alias;
  $TableWithEveryColumnTypeTable([this.alias]);
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
  late final TableColumn<bool> aBool = TableColumn<bool>(
    name: 'a_bool',
    sqlType: BuiltinDriftType.bool,
    requiredDuringInsert: false,
  )..owningResultSet = this;
  @override
  late final TableColumn<DateTime> aDateTime = TableColumn<DateTime>(
    name: 'a_date_time',
    sqlType: BuiltinDriftType.dateTime,
    requiredDuringInsert: false,
  )..owningResultSet = this;
  @override
  late final TableColumn<String> aText = TableColumn<String>(
    name: 'a_text',
    sqlType: BuiltinDriftType.text,
    requiredDuringInsert: false,
  )..owningResultSet = this;
  @override
  late final TableColumn<int> anInt = TableColumn<int>(
    name: 'an_int',
    sqlType: BuiltinDriftType.int,
    requiredDuringInsert: false,
  )..owningResultSet = this;
  @override
  late final TableColumn<BigInt> anInt64 = TableColumn<BigInt>(
    name: 'an_int64',
    sqlType: BuiltinDriftType.int64,
    requiredDuringInsert: false,
  )..owningResultSet = this;
  @override
  late final TableColumn<double> aReal = TableColumn<double>(
    name: 'a_real',
    sqlType: BuiltinDriftType.double,
    requiredDuringInsert: false,
  )..owningResultSet = this;
  @override
  late final TableColumn<Uint8List> aBlob = TableColumn<Uint8List>(
    name: 'a_blob',
    sqlType: BuiltinDriftType.byteArray,
    requiredDuringInsert: false,
  )..owningResultSet = this;
  @override
  late final TableColumnWithTypeConverter<TodoStatus?, int> anIntEnum =
      TableColumn<int>(
          name: 'an_int_enum',
          sqlType: BuiltinDriftType.int,
          requiredDuringInsert: false,
        ).withConverter<TodoStatus?>(
          $TableWithEveryColumnTypeTable.$converteranIntEnumn,
        )
        ..owningResultSet = this;
  @override
  late final TableColumnWithTypeConverter<MyCustomObject?, String>
  aTextWithConverter =
      TableColumn<String>(
          name: 'insert',
          sqlType: BuiltinDriftType.text,
          requiredDuringInsert: false,
        ).withConverter<MyCustomObject?>(
          $TableWithEveryColumnTypeTable.$converteraTextWithConvertern,
        )
        ..owningResultSet = this;
  @override
  List<TableColumn> get columns => [
    id,
    aBool,
    aDateTime,
    aText,
    anInt,
    anInt64,
    aReal,
    aBlob,
    anIntEnum,
    aTextWithConverter,
  ];
  @override
  String get entityName => $name;
  static const String $name = 'table_with_every_column_type';
  @override
  $TableWithEveryColumnTypeTable asSelfType() => this;

  @override
  Set<TableColumn> get primaryKey => {id};
  @override
  TableWithEveryColumnTypeData? Function(RawRow) createMapperFromPositions(
    DriftDialect dialect,
    List<ColumnPosition> positions,
  ) {
    final pos$id = positions[0].index;
    final type$0 = BuiltinDriftType.int.resolveIn(dialect);
    final pos$aBool = positions[1].index;
    final type$1 = BuiltinDriftType.bool.resolveIn(dialect);
    final pos$aDateTime = positions[2].index;
    final type$2 = BuiltinDriftType.dateTime.resolveIn(dialect);
    final pos$aText = positions[3].index;
    final type$3 = BuiltinDriftType.text.resolveIn(dialect);
    final pos$anInt = positions[4].index;
    final pos$anInt64 = positions[5].index;
    final type$4 = BuiltinDriftType.int64.resolveIn(dialect);
    final pos$aReal = positions[6].index;
    final type$5 = BuiltinDriftType.double.resolveIn(dialect);
    final pos$aBlob = positions[7].index;
    final type$6 = BuiltinDriftType.byteArray.resolveIn(dialect);
    final pos$anIntEnum = positions[8].index;
    final pos$aTextWithConverter = positions[9].index;
    return (RawRow row) {
      // Not part of row if non-nullable column "id" is missing
      if (row[pos$id] == null) {
        return null;
      }
      return TableWithEveryColumnTypeData(
        id: type$0.dartValue(row[pos$id]!),
        aBool: type$1.nullableDartValue(row[pos$aBool]),
        aDateTime: type$2.nullableDartValue(row[pos$aDateTime]),
        aText: type$3.nullableDartValue(row[pos$aText]),
        anInt: type$0.nullableDartValue(row[pos$anInt]),
        anInt64: type$4.nullableDartValue(row[pos$anInt64]),
        aReal: type$5.nullableDartValue(row[pos$aReal]),
        aBlob: type$6.nullableDartValue(row[pos$aBlob]),
        anIntEnum: $TableWithEveryColumnTypeTable.$converteranIntEnumn.fromSql(
          type$0.nullableDartValue(row[pos$anIntEnum]),
        ),
        aTextWithConverter: $TableWithEveryColumnTypeTable
            .$converteraTextWithConvertern
            .fromSql(type$3.nullableDartValue(row[pos$aTextWithConverter])),
      );
    };
  }

  @override
  $TableWithEveryColumnTypeTable withAlias(String alias) {
    return $TableWithEveryColumnTypeTable(alias);
  }

  static JsonTypeConverter2<TodoStatus, int, int> $converteranIntEnum =
      const EnumIndexConverter<TodoStatus>(TodoStatus.values);
  static JsonTypeConverter2<TodoStatus?, int?, int?> $converteranIntEnumn =
      JsonTypeConverter2.asNullable($converteranIntEnum);
  static JsonTypeConverter2<MyCustomObject, String, Map<String, Object?>>
  $converteraTextWithConverter = const CustomJsonConverter();
  static JsonTypeConverter2<MyCustomObject?, String?, Map<String, Object?>?>
  $converteraTextWithConvertern = JsonTypeConverter2.asNullable(
    $converteraTextWithConverter,
  );
}

class TableWithEveryColumnTypeData extends LegacyDataClass
    implements Insertable<TableWithEveryColumnTypeData> {
  final int id;
  final bool? aBool;
  final DateTime? aDateTime;
  final String? aText;
  final int? anInt;
  final BigInt? anInt64;
  final double? aReal;
  final Uint8List? aBlob;
  final TodoStatus? anIntEnum;
  final MyCustomObject? aTextWithConverter;
  const TableWithEveryColumnTypeData({
    required this.id,
    this.aBool,
    this.aDateTime,
    this.aText,
    this.anInt,
    this.anInt64,
    this.aReal,
    this.aBlob,
    this.anIntEnum,
    this.aTextWithConverter,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id, BuiltinDriftType.int);
    if (!nullToAbsent || aBool != null) {
      map['a_bool'] = Variable<bool>(aBool, BuiltinDriftType.bool);
    }
    if (!nullToAbsent || aDateTime != null) {
      map['a_date_time'] = Variable<DateTime>(
        aDateTime,
        BuiltinDriftType.dateTime,
      );
    }
    if (!nullToAbsent || aText != null) {
      map['a_text'] = Variable<String>(aText, BuiltinDriftType.text);
    }
    if (!nullToAbsent || anInt != null) {
      map['an_int'] = Variable<int>(anInt, BuiltinDriftType.int);
    }
    if (!nullToAbsent || anInt64 != null) {
      map['an_int64'] = Variable<BigInt>(anInt64, BuiltinDriftType.int64);
    }
    if (!nullToAbsent || aReal != null) {
      map['a_real'] = Variable<double>(aReal, BuiltinDriftType.double);
    }
    if (!nullToAbsent || aBlob != null) {
      map['a_blob'] = Variable<Uint8List>(aBlob, BuiltinDriftType.byteArray);
    }
    if (!nullToAbsent || anIntEnum != null) {
      map['an_int_enum'] = Variable<int>(
        $TableWithEveryColumnTypeTable.$converteranIntEnumn.toSql(anIntEnum),
        BuiltinDriftType.int,
      );
    }
    if (!nullToAbsent || aTextWithConverter != null) {
      map['insert'] = Variable<String>(
        $TableWithEveryColumnTypeTable.$converteraTextWithConvertern.toSql(
          aTextWithConverter,
        ),
        BuiltinDriftType.text,
      );
    }
    return map;
  }

  TableWithEveryColumnTypeCompanion toCompanion(bool nullToAbsent) {
    return TableWithEveryColumnTypeCompanion(
      id: Value(id),
      aBool: aBool == null && nullToAbsent
          ? const Value.absent()
          : Value(aBool),
      aDateTime: aDateTime == null && nullToAbsent
          ? const Value.absent()
          : Value(aDateTime),
      aText: aText == null && nullToAbsent
          ? const Value.absent()
          : Value(aText),
      anInt: anInt == null && nullToAbsent
          ? const Value.absent()
          : Value(anInt),
      anInt64: anInt64 == null && nullToAbsent
          ? const Value.absent()
          : Value(anInt64),
      aReal: aReal == null && nullToAbsent
          ? const Value.absent()
          : Value(aReal),
      aBlob: aBlob == null && nullToAbsent
          ? const Value.absent()
          : Value(aBlob),
      anIntEnum: anIntEnum == null && nullToAbsent
          ? const Value.absent()
          : Value(anIntEnum),
      aTextWithConverter: aTextWithConverter == null && nullToAbsent
          ? const Value.absent()
          : Value(aTextWithConverter),
    );
  }

  factory TableWithEveryColumnTypeData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TableWithEveryColumnTypeData(
      id: serializer.fromJson<int>(json['id']),
      aBool: serializer.fromJson<bool?>(json['aBool']),
      aDateTime: serializer.fromJson<DateTime?>(json['aDateTime']),
      aText: serializer.fromJson<String?>(json['aText']),
      anInt: serializer.fromJson<int?>(json['anInt']),
      anInt64: serializer.fromJson<BigInt?>(json['anInt64']),
      aReal: serializer.fromJson<double?>(json['aReal']),
      aBlob: serializer.fromJson<Uint8List?>(json['aBlob']),
      anIntEnum: $TableWithEveryColumnTypeTable.$converteranIntEnumn.fromJson(
        serializer.fromJson<int?>(json['anIntEnum']),
      ),
      aTextWithConverter: $TableWithEveryColumnTypeTable
          .$converteraTextWithConvertern
          .fromJson(
            serializer.fromJson<Map<String, Object?>?>(
              json['aTextWithConverter'],
            ),
          ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'aBool': serializer.toJson<bool?>(aBool),
      'aDateTime': serializer.toJson<DateTime?>(aDateTime),
      'aText': serializer.toJson<String?>(aText),
      'anInt': serializer.toJson<int?>(anInt),
      'anInt64': serializer.toJson<BigInt?>(anInt64),
      'aReal': serializer.toJson<double?>(aReal),
      'aBlob': serializer.toJson<Uint8List?>(aBlob),
      'anIntEnum': serializer.toJson<int?>(
        $TableWithEveryColumnTypeTable.$converteranIntEnumn.toJson(anIntEnum),
      ),
      'aTextWithConverter': serializer.toJson<Map<String, Object?>?>(
        $TableWithEveryColumnTypeTable.$converteraTextWithConvertern.toJson(
          aTextWithConverter,
        ),
      ),
    };
  }

  TableWithEveryColumnTypeData copyWith({
    int? id,
    Value<bool?> aBool = const Value.absent(),
    Value<DateTime?> aDateTime = const Value.absent(),
    Value<String?> aText = const Value.absent(),
    Value<int?> anInt = const Value.absent(),
    Value<BigInt?> anInt64 = const Value.absent(),
    Value<double?> aReal = const Value.absent(),
    Value<Uint8List?> aBlob = const Value.absent(),
    Value<TodoStatus?> anIntEnum = const Value.absent(),
    Value<MyCustomObject?> aTextWithConverter = const Value.absent(),
  }) => TableWithEveryColumnTypeData(
    id: id ?? this.id,
    aBool: aBool.present ? aBool.value : this.aBool,
    aDateTime: aDateTime.present ? aDateTime.value : this.aDateTime,
    aText: aText.present ? aText.value : this.aText,
    anInt: anInt.present ? anInt.value : this.anInt,
    anInt64: anInt64.present ? anInt64.value : this.anInt64,
    aReal: aReal.present ? aReal.value : this.aReal,
    aBlob: aBlob.present ? aBlob.value : this.aBlob,
    anIntEnum: anIntEnum.present ? anIntEnum.value : this.anIntEnum,
    aTextWithConverter: aTextWithConverter.present
        ? aTextWithConverter.value
        : this.aTextWithConverter,
  );
  TableWithEveryColumnTypeData copyWithCompanion(
    TableWithEveryColumnTypeCompanion data,
  ) {
    return TableWithEveryColumnTypeData(
      id: data.id.present ? data.id.value : this.id,
      aBool: data.aBool.present ? data.aBool.value : this.aBool,
      aDateTime: data.aDateTime.present ? data.aDateTime.value : this.aDateTime,
      aText: data.aText.present ? data.aText.value : this.aText,
      anInt: data.anInt.present ? data.anInt.value : this.anInt,
      anInt64: data.anInt64.present ? data.anInt64.value : this.anInt64,
      aReal: data.aReal.present ? data.aReal.value : this.aReal,
      aBlob: data.aBlob.present ? data.aBlob.value : this.aBlob,
      anIntEnum: data.anIntEnum.present ? data.anIntEnum.value : this.anIntEnum,
      aTextWithConverter: data.aTextWithConverter.present
          ? data.aTextWithConverter.value
          : this.aTextWithConverter,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TableWithEveryColumnTypeData(')
          ..write('id: $id, ')
          ..write('aBool: $aBool, ')
          ..write('aDateTime: $aDateTime, ')
          ..write('aText: $aText, ')
          ..write('anInt: $anInt, ')
          ..write('anInt64: $anInt64, ')
          ..write('aReal: $aReal, ')
          ..write('aBlob: $aBlob, ')
          ..write('anIntEnum: $anIntEnum, ')
          ..write('aTextWithConverter: $aTextWithConverter')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    aBool,
    aDateTime,
    aText,
    anInt,
    anInt64,
    aReal,
    $driftBlobEquality.hash(aBlob),
    anIntEnum,
    aTextWithConverter,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TableWithEveryColumnTypeData &&
          other.id == this.id &&
          other.aBool == this.aBool &&
          other.aDateTime == this.aDateTime &&
          other.aText == this.aText &&
          other.anInt == this.anInt &&
          other.anInt64 == this.anInt64 &&
          other.aReal == this.aReal &&
          $driftBlobEquality.equals(other.aBlob, this.aBlob) &&
          other.anIntEnum == this.anIntEnum &&
          other.aTextWithConverter == this.aTextWithConverter);
}

class TableWithEveryColumnTypeCompanion
    extends UpdateCompanion<TableWithEveryColumnTypeData> {
  final Value<int> id;
  final Value<bool?> aBool;
  final Value<DateTime?> aDateTime;
  final Value<String?> aText;
  final Value<int?> anInt;
  final Value<BigInt?> anInt64;
  final Value<double?> aReal;
  final Value<Uint8List?> aBlob;
  final Value<TodoStatus?> anIntEnum;
  final Value<MyCustomObject?> aTextWithConverter;
  const TableWithEveryColumnTypeCompanion({
    this.id = const Value.absent(),
    this.aBool = const Value.absent(),
    this.aDateTime = const Value.absent(),
    this.aText = const Value.absent(),
    this.anInt = const Value.absent(),
    this.anInt64 = const Value.absent(),
    this.aReal = const Value.absent(),
    this.aBlob = const Value.absent(),
    this.anIntEnum = const Value.absent(),
    this.aTextWithConverter = const Value.absent(),
  });
  TableWithEveryColumnTypeCompanion.insert({
    this.id = const Value.absent(),
    this.aBool = const Value.absent(),
    this.aDateTime = const Value.absent(),
    this.aText = const Value.absent(),
    this.anInt = const Value.absent(),
    this.anInt64 = const Value.absent(),
    this.aReal = const Value.absent(),
    this.aBlob = const Value.absent(),
    this.anIntEnum = const Value.absent(),
    this.aTextWithConverter = const Value.absent(),
  });
  static Insertable<TableWithEveryColumnTypeData> custom({
    Expression<int>? id,
    Expression<bool>? aBool,
    Expression<DateTime>? aDateTime,
    Expression<String>? aText,
    Expression<int>? anInt,
    Expression<BigInt>? anInt64,
    Expression<double>? aReal,
    Expression<Uint8List>? aBlob,
    Expression<int>? anIntEnum,
    Expression<String>? aTextWithConverter,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (aBool != null) 'a_bool': aBool,
      if (aDateTime != null) 'a_date_time': aDateTime,
      if (aText != null) 'a_text': aText,
      if (anInt != null) 'an_int': anInt,
      if (anInt64 != null) 'an_int64': anInt64,
      if (aReal != null) 'a_real': aReal,
      if (aBlob != null) 'a_blob': aBlob,
      if (anIntEnum != null) 'an_int_enum': anIntEnum,
      if (aTextWithConverter != null) 'insert': aTextWithConverter,
    });
  }

  TableWithEveryColumnTypeCompanion copyWith({
    Value<int>? id,
    Value<bool?>? aBool,
    Value<DateTime?>? aDateTime,
    Value<String?>? aText,
    Value<int?>? anInt,
    Value<BigInt?>? anInt64,
    Value<double?>? aReal,
    Value<Uint8List?>? aBlob,
    Value<TodoStatus?>? anIntEnum,
    Value<MyCustomObject?>? aTextWithConverter,
  }) {
    return TableWithEveryColumnTypeCompanion(
      id: id ?? this.id,
      aBool: aBool ?? this.aBool,
      aDateTime: aDateTime ?? this.aDateTime,
      aText: aText ?? this.aText,
      anInt: anInt ?? this.anInt,
      anInt64: anInt64 ?? this.anInt64,
      aReal: aReal ?? this.aReal,
      aBlob: aBlob ?? this.aBlob,
      anIntEnum: anIntEnum ?? this.anIntEnum,
      aTextWithConverter: aTextWithConverter ?? this.aTextWithConverter,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value, BuiltinDriftType.int);
    }
    if (aBool.present) {
      map['a_bool'] = Variable<bool>(aBool.value, BuiltinDriftType.bool);
    }
    if (aDateTime.present) {
      map['a_date_time'] = Variable<DateTime>(
        aDateTime.value,
        BuiltinDriftType.dateTime,
      );
    }
    if (aText.present) {
      map['a_text'] = Variable<String>(aText.value, BuiltinDriftType.text);
    }
    if (anInt.present) {
      map['an_int'] = Variable<int>(anInt.value, BuiltinDriftType.int);
    }
    if (anInt64.present) {
      map['an_int64'] = Variable<BigInt>(anInt64.value, BuiltinDriftType.int64);
    }
    if (aReal.present) {
      map['a_real'] = Variable<double>(aReal.value, BuiltinDriftType.double);
    }
    if (aBlob.present) {
      map['a_blob'] = Variable<Uint8List>(
        aBlob.value,
        BuiltinDriftType.byteArray,
      );
    }
    if (anIntEnum.present) {
      map['an_int_enum'] = Variable<int>(
        $TableWithEveryColumnTypeTable.$converteranIntEnumn.toSql(
          anIntEnum.value,
        ),
        BuiltinDriftType.int,
      );
    }
    if (aTextWithConverter.present) {
      map['insert'] = Variable<String>(
        $TableWithEveryColumnTypeTable.$converteraTextWithConvertern.toSql(
          aTextWithConverter.value,
        ),
        BuiltinDriftType.text,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TableWithEveryColumnTypeCompanion(')
          ..write('id: $id, ')
          ..write('aBool: $aBool, ')
          ..write('aDateTime: $aDateTime, ')
          ..write('aText: $aText, ')
          ..write('anInt: $anInt, ')
          ..write('anInt64: $anInt64, ')
          ..write('aReal: $aReal, ')
          ..write('aBlob: $aBlob, ')
          ..write('anIntEnum: $anIntEnum, ')
          ..write('aTextWithConverter: $aTextWithConverter')
          ..write(')'))
        .toString();
  }
}

class $TodosTableTable extends TodosTable
    with ResultSet<TodoEntry, $TodosTableTable>
    implements GeneratedTable<TodoEntry, $TodosTableTable> {
  @override
  final String? alias;
  $TodosTableTable([this.alias]);
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
  late final TableColumn<String> title = TableColumn<String>(
    name: 'title',
    sqlType: BuiltinDriftType.text,
    requiredDuringInsert: false,
  )..owningResultSet = this;
  @override
  late final TableColumn<String> content = TableColumn<String>(
    name: 'content',
    sqlType: BuiltinDriftType.text,
    requiredDuringInsert: true,
    constraints: () => [const ColumnNotNullConstraint()],
  )..owningResultSet = this;
  @override
  late final TableColumn<DateTime> targetDate = TableColumn<DateTime>(
    name: 'target_date',
    sqlType: BuiltinDriftType.dateTime,
    requiredDuringInsert: false,
    constraints: () => [const ColumnUniqueConstraint()],
  )..owningResultSet = this;
  @override
  late final TableColumn<int> category = TableColumn<int>(
    name: 'category',
    sqlType: BuiltinDriftType.int,
    requiredDuringInsert: false,
    constraints: () => [
      const ColumnForeignKeyConstraint(
        otherTableName: 'categories',
        otherColumnName: 'id',
        initiallyDeferred: true,
      ),
    ],
  )..owningResultSet = this;
  @override
  late final TableColumnWithTypeConverter<TodoStatus?, String> status =
      TableColumn<String>(
          name: 'status',
          sqlType: BuiltinDriftType.text,
          requiredDuringInsert: false,
        ).withConverter<TodoStatus?>($TodosTableTable.$converterstatusn)
        ..owningResultSet = this;
  @override
  List<TableColumn> get columns => [
    id,
    title,
    content,
    targetDate,
    category,
    status,
  ];
  @override
  String get entityName => $name;
  static const String $name = 'todos';
  @override
  $TodosTableTable asSelfType() => this;

  @override
  Set<TableColumn> get primaryKey => {id};
  @override
  List<Set<TableColumn>> get uniqueKeys => [
    {title, category},
    {title, targetDate},
  ];
  @override
  TodoEntry? Function(RawRow) createMapperFromPositions(
    DriftDialect dialect,
    List<ColumnPosition> positions,
  ) {
    final pos$id = positions[0].index;
    final type$0 = BuiltinDriftType.int.resolveIn(dialect);
    final pos$title = positions[1].index;
    final type$1 = BuiltinDriftType.text.resolveIn(dialect);
    final pos$content = positions[2].index;
    final pos$targetDate = positions[3].index;
    final type$2 = BuiltinDriftType.dateTime.resolveIn(dialect);
    final pos$category = positions[4].index;
    final pos$status = positions[5].index;
    return (RawRow row) {
      // Not part of row if non-nullable column "id" is missing
      if (row[pos$id] == null) {
        return null;
      }
      return TodoEntry(
        id: type$0.dartValue(row[pos$id]!),
        title: type$1.nullableDartValue(row[pos$title]),
        content: type$1.dartValue(row[pos$content]!),
        targetDate: type$2.nullableDartValue(row[pos$targetDate]),
        category: type$0.nullableDartValue(row[pos$category]),
        status: $TodosTableTable.$converterstatusn.fromSql(
          type$1.nullableDartValue(row[pos$status]),
        ),
      );
    };
  }

  @override
  $TodosTableTable withAlias(String alias) {
    return $TodosTableTable(alias);
  }

  static JsonTypeConverter2<TodoStatus, String, String> $converterstatus =
      const EnumNameConverter<TodoStatus>(TodoStatus.values);
  static JsonTypeConverter2<TodoStatus?, String?, String?> $converterstatusn =
      JsonTypeConverter2.asNullable($converterstatus);
}

class TodoEntry extends LegacyDataClass implements Insertable<TodoEntry> {
  final int id;
  final String? title;
  final String content;
  final DateTime? targetDate;
  final int? category;
  final TodoStatus? status;
  const TodoEntry({
    required this.id,
    this.title,
    required this.content,
    this.targetDate,
    this.category,
    this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id, BuiltinDriftType.int);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title, BuiltinDriftType.text);
    }
    map['content'] = Variable<String>(content, BuiltinDriftType.text);
    if (!nullToAbsent || targetDate != null) {
      map['target_date'] = Variable<DateTime>(
        targetDate,
        BuiltinDriftType.dateTime,
      );
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<int>(category, BuiltinDriftType.int);
    }
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<String>(
        $TodosTableTable.$converterstatusn.toSql(status),
        BuiltinDriftType.text,
      );
    }
    return map;
  }

  TodosTableCompanion toCompanion(bool nullToAbsent) {
    return TodosTableCompanion(
      id: Value(id),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      content: Value(content),
      targetDate: targetDate == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDate),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      status: status == null && nullToAbsent
          ? const Value.absent()
          : Value(status),
    );
  }

  factory TodoEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TodoEntry(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String?>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      targetDate: serializer.fromJson<DateTime?>(json['targetDate']),
      category: serializer.fromJson<int?>(json['category']),
      status: $TodosTableTable.$converterstatusn.fromJson(
        serializer.fromJson<String?>(json['status']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String?>(title),
      'content': serializer.toJson<String>(content),
      'targetDate': serializer.toJson<DateTime?>(targetDate),
      'category': serializer.toJson<int?>(category),
      'status': serializer.toJson<String?>(
        $TodosTableTable.$converterstatusn.toJson(status),
      ),
    };
  }

  TodoEntry copyWith({
    int? id,
    Value<String?> title = const Value.absent(),
    String? content,
    Value<DateTime?> targetDate = const Value.absent(),
    Value<int?> category = const Value.absent(),
    Value<TodoStatus?> status = const Value.absent(),
  }) => TodoEntry(
    id: id ?? this.id,
    title: title.present ? title.value : this.title,
    content: content ?? this.content,
    targetDate: targetDate.present ? targetDate.value : this.targetDate,
    category: category.present ? category.value : this.category,
    status: status.present ? status.value : this.status,
  );
  TodoEntry copyWithCompanion(TodosTableCompanion data) {
    return TodoEntry(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      targetDate: data.targetDate.present
          ? data.targetDate.value
          : this.targetDate,
      category: data.category.present ? data.category.value : this.category,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TodoEntry(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('targetDate: $targetDate, ')
          ..write('category: $category, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, content, targetDate, category, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TodoEntry &&
          other.id == this.id &&
          other.title == this.title &&
          other.content == this.content &&
          other.targetDate == this.targetDate &&
          other.category == this.category &&
          other.status == this.status);
}

class TodosTableCompanion extends UpdateCompanion<TodoEntry> {
  final Value<int> id;
  final Value<String?> title;
  final Value<String> content;
  final Value<DateTime?> targetDate;
  final Value<int?> category;
  final Value<TodoStatus?> status;
  const TodosTableCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.category = const Value.absent(),
    this.status = const Value.absent(),
  });
  TodosTableCompanion.insert({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    required String content,
    this.targetDate = const Value.absent(),
    this.category = const Value.absent(),
    this.status = const Value.absent(),
  }) : content = Value(content);
  static Insertable<TodoEntry> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? content,
    Expression<DateTime>? targetDate,
    Expression<int>? category,
    Expression<String>? status,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (targetDate != null) 'target_date': targetDate,
      if (category != null) 'category': category,
      if (status != null) 'status': status,
    });
  }

  TodosTableCompanion copyWith({
    Value<int>? id,
    Value<String?>? title,
    Value<String>? content,
    Value<DateTime?>? targetDate,
    Value<int?>? category,
    Value<TodoStatus?>? status,
  }) {
    return TodosTableCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      targetDate: targetDate ?? this.targetDate,
      category: category ?? this.category,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value, BuiltinDriftType.int);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value, BuiltinDriftType.text);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value, BuiltinDriftType.text);
    }
    if (targetDate.present) {
      map['target_date'] = Variable<DateTime>(
        targetDate.value,
        BuiltinDriftType.dateTime,
      );
    }
    if (category.present) {
      map['category'] = Variable<int>(category.value, BuiltinDriftType.int);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $TodosTableTable.$converterstatusn.toSql(status.value),
        BuiltinDriftType.text,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TodosTableCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('targetDate: $targetDate, ')
          ..write('category: $category, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }
}

class $UsersTable extends Users
    with ResultSet<User, $UsersTable>
    implements GeneratedTable<User, $UsersTable> {
  @override
  final String? alias;
  $UsersTable([this.alias]);
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
    constraints: () => [
      const ColumnNotNullConstraint(),
      const ColumnUniqueConstraint(),
    ],
  )..owningResultSet = this;
  @override
  late final TableColumn<bool> isAwesome = TableColumn<bool>(
    name: 'is_awesome',
    sqlType: BuiltinDriftType.bool,
    requiredDuringInsert: false,
    constraints: () => [
      const ColumnNotNullConstraint(),
      ColumnDefaultConstraint<bool>(const Literal(true)),
    ],
  )..owningResultSet = this;
  @override
  late final TableColumn<Uint8List> profilePicture = TableColumn<Uint8List>(
    name: 'profile_picture',
    sqlType: BuiltinDriftType.byteArray,
    requiredDuringInsert: true,
    constraints: () => [const ColumnNotNullConstraint()],
  )..owningResultSet = this;
  @override
  late final TableColumn<DateTime> creationTime = TableColumn<DateTime>(
    name: 'creation_time',
    sqlType: BuiltinDriftType.dateTime,
    requiredDuringInsert: false,
    constraints: () => [
      const ColumnNotNullConstraint(),
      ColumnDefaultConstraint<DateTime>(currentDateAndTime),
      ColumnCheckConstraint(
        ComparableExpr(creationTime).isGreaterThan(Literal(DateTime.utc(1950))),
      ),
    ],
  )..owningResultSet = this;
  @override
  List<TableColumn> get columns => [
    id,
    name,
    isAwesome,
    profilePicture,
    creationTime,
  ];
  @override
  String get entityName => $name;
  static const String $name = 'users';
  @override
  $UsersTable asSelfType() => this;

  @override
  Set<TableColumn> get primaryKey => {id};
  @override
  User? Function(RawRow) createMapperFromPositions(
    DriftDialect dialect,
    List<ColumnPosition> positions,
  ) {
    final pos$id = positions[0].index;
    final type$0 = BuiltinDriftType.int.resolveIn(dialect);
    final pos$name = positions[1].index;
    final type$1 = BuiltinDriftType.text.resolveIn(dialect);
    final pos$isAwesome = positions[2].index;
    final type$2 = BuiltinDriftType.bool.resolveIn(dialect);
    final pos$profilePicture = positions[3].index;
    final type$3 = BuiltinDriftType.byteArray.resolveIn(dialect);
    final pos$creationTime = positions[4].index;
    final type$4 = BuiltinDriftType.dateTime.resolveIn(dialect);
    return (RawRow row) {
      // Not part of row if non-nullable column "id" is missing
      if (row[pos$id] == null) {
        return null;
      }
      return User(
        id: type$0.dartValue(row[pos$id]!),
        name: type$1.dartValue(row[pos$name]!),
        isAwesome: type$2.dartValue(row[pos$isAwesome]!),
        profilePicture: type$3.dartValue(row[pos$profilePicture]!),
        creationTime: type$4.dartValue(row[pos$creationTime]!),
      );
    };
  }

  @override
  $UsersTable withAlias(String alias) {
    return $UsersTable(alias);
  }
}

class User extends LegacyDataClass implements Insertable<User> {
  final int id;
  final String name;
  final bool isAwesome;
  final Uint8List profilePicture;
  final DateTime creationTime;
  const User({
    required this.id,
    required this.name,
    required this.isAwesome,
    required this.profilePicture,
    required this.creationTime,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id, BuiltinDriftType.int);
    map['name'] = Variable<String>(name, BuiltinDriftType.text);
    map['is_awesome'] = Variable<bool>(isAwesome, BuiltinDriftType.bool);
    map['profile_picture'] = Variable<Uint8List>(
      profilePicture,
      BuiltinDriftType.byteArray,
    );
    map['creation_time'] = Variable<DateTime>(
      creationTime,
      BuiltinDriftType.dateTime,
    );
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      name: Value(name),
      isAwesome: Value(isAwesome),
      profilePicture: Value(profilePicture),
      creationTime: Value(creationTime),
    );
  }

  factory User.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      isAwesome: serializer.fromJson<bool>(json['isAwesome']),
      profilePicture: serializer.fromJson<Uint8List>(json['profilePicture']),
      creationTime: serializer.fromJson<DateTime>(json['creationTime']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'isAwesome': serializer.toJson<bool>(isAwesome),
      'profilePicture': serializer.toJson<Uint8List>(profilePicture),
      'creationTime': serializer.toJson<DateTime>(creationTime),
    };
  }

  User copyWith({
    int? id,
    String? name,
    bool? isAwesome,
    Uint8List? profilePicture,
    DateTime? creationTime,
  }) => User(
    id: id ?? this.id,
    name: name ?? this.name,
    isAwesome: isAwesome ?? this.isAwesome,
    profilePicture: profilePicture ?? this.profilePicture,
    creationTime: creationTime ?? this.creationTime,
  );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      isAwesome: data.isAwesome.present ? data.isAwesome.value : this.isAwesome,
      profilePicture: data.profilePicture.present
          ? data.profilePicture.value
          : this.profilePicture,
      creationTime: data.creationTime.present
          ? data.creationTime.value
          : this.creationTime,
    );
  }

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
  int get hashCode => Object.hash(
    id,
    name,
    isAwesome,
    $driftBlobEquality.hash(profilePicture),
    creationTime,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.name == this.name &&
          other.isAwesome == this.isAwesome &&
          $driftBlobEquality.equals(
            other.profilePicture,
            this.profilePicture,
          ) &&
          other.creationTime == this.creationTime);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<int> id;
  final Value<String> name;
  final Value<bool> isAwesome;
  final Value<Uint8List> profilePicture;
  final Value<DateTime> creationTime;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.isAwesome = const Value.absent(),
    this.profilePicture = const Value.absent(),
    this.creationTime = const Value.absent(),
  });
  UsersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.isAwesome = const Value.absent(),
    required Uint8List profilePicture,
    this.creationTime = const Value.absent(),
  }) : name = Value(name),
       profilePicture = Value(profilePicture);
  static Insertable<User> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<bool>? isAwesome,
    Expression<Uint8List>? profilePicture,
    Expression<DateTime>? creationTime,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (isAwesome != null) 'is_awesome': isAwesome,
      if (profilePicture != null) 'profile_picture': profilePicture,
      if (creationTime != null) 'creation_time': creationTime,
    });
  }

  UsersCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<bool>? isAwesome,
    Value<Uint8List>? profilePicture,
    Value<DateTime>? creationTime,
  }) {
    return UsersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      isAwesome: isAwesome ?? this.isAwesome,
      profilePicture: profilePicture ?? this.profilePicture,
      creationTime: creationTime ?? this.creationTime,
    );
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
    if (isAwesome.present) {
      map['is_awesome'] = Variable<bool>(
        isAwesome.value,
        BuiltinDriftType.bool,
      );
    }
    if (profilePicture.present) {
      map['profile_picture'] = Variable<Uint8List>(
        profilePicture.value,
        BuiltinDriftType.byteArray,
      );
    }
    if (creationTime.present) {
      map['creation_time'] = Variable<DateTime>(
        creationTime.value,
        BuiltinDriftType.dateTime,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isAwesome: $isAwesome, ')
          ..write('profilePicture: $profilePicture, ')
          ..write('creationTime: $creationTime')
          ..write(')'))
        .toString();
  }
}

class $DepartmentTable extends Department
    with ResultSet<DepartmentData, $DepartmentTable>
    implements GeneratedTable<DepartmentData, $DepartmentTable> {
  @override
  final String? alias;
  $DepartmentTable([this.alias]);
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
  static const String $name = 'department';
  @override
  $DepartmentTable asSelfType() => this;

  @override
  Set<TableColumn> get primaryKey => {id};
  @override
  DepartmentData? Function(RawRow) createMapperFromPositions(
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
      return DepartmentData(
        id: type$0.dartValue(row[pos$id]!),
        name: type$1.nullableDartValue(row[pos$name]),
      );
    };
  }

  @override
  $DepartmentTable withAlias(String alias) {
    return $DepartmentTable(alias);
  }
}

class DepartmentData extends LegacyDataClass
    implements Insertable<DepartmentData> {
  final int id;
  final String? name;
  const DepartmentData({required this.id, this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id, BuiltinDriftType.int);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name, BuiltinDriftType.text);
    }
    return map;
  }

  DepartmentCompanion toCompanion(bool nullToAbsent) {
    return DepartmentCompanion(
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
    );
  }

  factory DepartmentData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DepartmentData(
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

  DepartmentData copyWith({
    int? id,
    Value<String?> name = const Value.absent(),
  }) => DepartmentData(
    id: id ?? this.id,
    name: name.present ? name.value : this.name,
  );
  DepartmentData copyWithCompanion(DepartmentCompanion data) {
    return DepartmentData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DepartmentData(')
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
      (other is DepartmentData &&
          other.id == this.id &&
          other.name == this.name);
}

class DepartmentCompanion extends UpdateCompanion<DepartmentData> {
  final Value<int> id;
  final Value<String?> name;
  const DepartmentCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  DepartmentCompanion.insert({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  static Insertable<DepartmentData> custom({
    Expression<int>? id,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  DepartmentCompanion copyWith({Value<int>? id, Value<String?>? name}) {
    return DepartmentCompanion(id: id ?? this.id, name: name ?? this.name);
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
    return (StringBuffer('DepartmentCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $ProductTable extends Product
    with ResultSet<ProductData, $ProductTable>
    implements GeneratedTable<ProductData, $ProductTable> {
  @override
  final String? alias;
  $ProductTable([this.alias]);
  @override
  late final TableColumn<String> sku = TableColumn<String>(
    name: 'sku',
    sqlType: BuiltinDriftType.text,
    requiredDuringInsert: true,
    constraints: () => [const ColumnNotNullConstraint()],
  )..owningResultSet = this;
  @override
  late final TableColumn<String> name = TableColumn<String>(
    name: 'name',
    sqlType: BuiltinDriftType.text,
    requiredDuringInsert: false,
  )..owningResultSet = this;
  @override
  late final TableColumn<int> department = TableColumn<int>(
    name: 'department',
    sqlType: BuiltinDriftType.int,
    requiredDuringInsert: false,
    constraints: () => [
      const ColumnForeignKeyConstraint(
        otherTableName: 'department',
        otherColumnName: 'id',
      ),
    ],
  )..owningResultSet = this;
  @override
  List<TableColumn> get columns => [sku, name, department];
  @override
  String get entityName => $name;
  static const String $name = 'product';
  @override
  $ProductTable asSelfType() => this;

  @override
  Set<TableColumn> get primaryKey => const {};
  @override
  ProductData? Function(RawRow) createMapperFromPositions(
    DriftDialect dialect,
    List<ColumnPosition> positions,
  ) {
    final pos$sku = positions[0].index;
    final type$0 = BuiltinDriftType.text.resolveIn(dialect);
    final pos$name = positions[1].index;
    final pos$department = positions[2].index;
    final type$1 = BuiltinDriftType.int.resolveIn(dialect);
    return (RawRow row) {
      // Not part of row if non-nullable column "sku" is missing
      if (row[pos$sku] == null) {
        return null;
      }
      return ProductData(
        sku: type$0.dartValue(row[pos$sku]!),
        name: type$0.nullableDartValue(row[pos$name]),
        department: type$1.nullableDartValue(row[pos$department]),
      );
    };
  }

  @override
  $ProductTable withAlias(String alias) {
    return $ProductTable(alias);
  }
}

class ProductData extends LegacyDataClass implements Insertable<ProductData> {
  final String sku;
  final String? name;
  final int? department;
  const ProductData({required this.sku, this.name, this.department});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['sku'] = Variable<String>(sku, BuiltinDriftType.text);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name, BuiltinDriftType.text);
    }
    if (!nullToAbsent || department != null) {
      map['department'] = Variable<int>(department, BuiltinDriftType.int);
    }
    return map;
  }

  ProductCompanion toCompanion(bool nullToAbsent) {
    return ProductCompanion(
      sku: Value(sku),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      department: department == null && nullToAbsent
          ? const Value.absent()
          : Value(department),
    );
  }

  factory ProductData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductData(
      sku: serializer.fromJson<String>(json['sku']),
      name: serializer.fromJson<String?>(json['name']),
      department: serializer.fromJson<int?>(json['department']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sku': serializer.toJson<String>(sku),
      'name': serializer.toJson<String?>(name),
      'department': serializer.toJson<int?>(department),
    };
  }

  ProductData copyWith({
    String? sku,
    Value<String?> name = const Value.absent(),
    Value<int?> department = const Value.absent(),
  }) => ProductData(
    sku: sku ?? this.sku,
    name: name.present ? name.value : this.name,
    department: department.present ? department.value : this.department,
  );
  ProductData copyWithCompanion(ProductCompanion data) {
    return ProductData(
      sku: data.sku.present ? data.sku.value : this.sku,
      name: data.name.present ? data.name.value : this.name,
      department: data.department.present
          ? data.department.value
          : this.department,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductData(')
          ..write('sku: $sku, ')
          ..write('name: $name, ')
          ..write('department: $department')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sku, name, department);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductData &&
          other.sku == this.sku &&
          other.name == this.name &&
          other.department == this.department);
}

class ProductCompanion extends UpdateCompanion<ProductData> {
  final Value<String> sku;
  final Value<String?> name;
  final Value<int?> department;
  final Value<int> rowid;
  const ProductCompanion({
    this.sku = const Value.absent(),
    this.name = const Value.absent(),
    this.department = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductCompanion.insert({
    required String sku,
    this.name = const Value.absent(),
    this.department = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sku = Value(sku);
  static Insertable<ProductData> custom({
    Expression<String>? sku,
    Expression<String>? name,
    Expression<int>? department,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sku != null) 'sku': sku,
      if (name != null) 'name': name,
      if (department != null) 'department': department,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductCompanion copyWith({
    Value<String>? sku,
    Value<String?>? name,
    Value<int?>? department,
    Value<int>? rowid,
  }) {
    return ProductCompanion(
      sku: sku ?? this.sku,
      name: name ?? this.name,
      department: department ?? this.department,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value, BuiltinDriftType.text);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value, BuiltinDriftType.text);
    }
    if (department.present) {
      map['department'] = Variable<int>(department.value, BuiltinDriftType.int);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value, BuiltinDriftType.int);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductCompanion(')
          ..write('sku: $sku, ')
          ..write('name: $name, ')
          ..write('department: $department, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StoreTable extends Store
    with ResultSet<StoreData, $StoreTable>
    implements GeneratedTable<StoreData, $StoreTable> {
  @override
  final String? alias;
  $StoreTable([this.alias]);
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
  static const String $name = 'store';
  @override
  $StoreTable asSelfType() => this;

  @override
  Set<TableColumn> get primaryKey => {id};
  @override
  StoreData? Function(RawRow) createMapperFromPositions(
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
      return StoreData(
        id: type$0.dartValue(row[pos$id]!),
        name: type$1.nullableDartValue(row[pos$name]),
      );
    };
  }

  @override
  $StoreTable withAlias(String alias) {
    return $StoreTable(alias);
  }
}

class StoreData extends LegacyDataClass implements Insertable<StoreData> {
  final int id;
  final String? name;
  const StoreData({required this.id, this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id, BuiltinDriftType.int);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name, BuiltinDriftType.text);
    }
    return map;
  }

  StoreCompanion toCompanion(bool nullToAbsent) {
    return StoreCompanion(
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
    );
  }

  factory StoreData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoreData(
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

  StoreData copyWith({int? id, Value<String?> name = const Value.absent()}) =>
      StoreData(id: id ?? this.id, name: name.present ? name.value : this.name);
  StoreData copyWithCompanion(StoreCompanion data) {
    return StoreData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoreData(')
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
      (other is StoreData && other.id == this.id && other.name == this.name);
}

class StoreCompanion extends UpdateCompanion<StoreData> {
  final Value<int> id;
  final Value<String?> name;
  const StoreCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  StoreCompanion.insert({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  static Insertable<StoreData> custom({
    Expression<int>? id,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  StoreCompanion copyWith({Value<int>? id, Value<String?>? name}) {
    return StoreCompanion(id: id ?? this.id, name: name ?? this.name);
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
    return (StringBuffer('StoreCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $ListingTable extends Listing
    with ResultSet<ListingData, $ListingTable>
    implements GeneratedTable<ListingData, $ListingTable> {
  @override
  final String? alias;
  $ListingTable([this.alias]);
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
  late final TableColumn<String> product = TableColumn<String>(
    name: 'product',
    sqlType: BuiltinDriftType.text,
    requiredDuringInsert: true,
    constraints: () => [
      const ColumnNotNullConstraint(),
      const ColumnForeignKeyConstraint(
        otherTableName: 'product',
        otherColumnName: 'sku',
      ),
    ],
  )..owningResultSet = this;
  @override
  late final TableColumn<int> store = TableColumn<int>(
    name: 'store',
    sqlType: BuiltinDriftType.int,
    requiredDuringInsert: false,
    constraints: () => [
      const ColumnForeignKeyConstraint(
        otherTableName: 'store',
        otherColumnName: 'id',
      ),
    ],
  )..owningResultSet = this;
  @override
  late final TableColumn<double> price = TableColumn<double>(
    name: 'price',
    sqlType: BuiltinDriftType.double,
    requiredDuringInsert: false,
  )..owningResultSet = this;
  @override
  List<TableColumn> get columns => [id, product, store, price];
  @override
  String get entityName => $name;
  static const String $name = 'listing';
  @override
  $ListingTable asSelfType() => this;

  @override
  Set<TableColumn> get primaryKey => {id};
  @override
  ListingData? Function(RawRow) createMapperFromPositions(
    DriftDialect dialect,
    List<ColumnPosition> positions,
  ) {
    final pos$id = positions[0].index;
    final type$0 = BuiltinDriftType.int.resolveIn(dialect);
    final pos$product = positions[1].index;
    final type$1 = BuiltinDriftType.text.resolveIn(dialect);
    final pos$store = positions[2].index;
    final pos$price = positions[3].index;
    final type$2 = BuiltinDriftType.double.resolveIn(dialect);
    return (RawRow row) {
      // Not part of row if non-nullable column "id" is missing
      if (row[pos$id] == null) {
        return null;
      }
      return ListingData(
        id: type$0.dartValue(row[pos$id]!),
        product: type$1.dartValue(row[pos$product]!),
        store: type$0.nullableDartValue(row[pos$store]),
        price: type$2.nullableDartValue(row[pos$price]),
      );
    };
  }

  @override
  $ListingTable withAlias(String alias) {
    return $ListingTable(alias);
  }
}

class ListingData extends LegacyDataClass implements Insertable<ListingData> {
  final int id;
  final String product;
  final int? store;
  final double? price;
  const ListingData({
    required this.id,
    required this.product,
    this.store,
    this.price,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id, BuiltinDriftType.int);
    map['product'] = Variable<String>(product, BuiltinDriftType.text);
    if (!nullToAbsent || store != null) {
      map['store'] = Variable<int>(store, BuiltinDriftType.int);
    }
    if (!nullToAbsent || price != null) {
      map['price'] = Variable<double>(price, BuiltinDriftType.double);
    }
    return map;
  }

  ListingCompanion toCompanion(bool nullToAbsent) {
    return ListingCompanion(
      id: Value(id),
      product: Value(product),
      store: store == null && nullToAbsent
          ? const Value.absent()
          : Value(store),
      price: price == null && nullToAbsent
          ? const Value.absent()
          : Value(price),
    );
  }

  factory ListingData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ListingData(
      id: serializer.fromJson<int>(json['id']),
      product: serializer.fromJson<String>(json['product']),
      store: serializer.fromJson<int?>(json['store']),
      price: serializer.fromJson<double?>(json['price']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'product': serializer.toJson<String>(product),
      'store': serializer.toJson<int?>(store),
      'price': serializer.toJson<double?>(price),
    };
  }

  ListingData copyWith({
    int? id,
    String? product,
    Value<int?> store = const Value.absent(),
    Value<double?> price = const Value.absent(),
  }) => ListingData(
    id: id ?? this.id,
    product: product ?? this.product,
    store: store.present ? store.value : this.store,
    price: price.present ? price.value : this.price,
  );
  ListingData copyWithCompanion(ListingCompanion data) {
    return ListingData(
      id: data.id.present ? data.id.value : this.id,
      product: data.product.present ? data.product.value : this.product,
      store: data.store.present ? data.store.value : this.store,
      price: data.price.present ? data.price.value : this.price,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ListingData(')
          ..write('id: $id, ')
          ..write('product: $product, ')
          ..write('store: $store, ')
          ..write('price: $price')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, product, store, price);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ListingData &&
          other.id == this.id &&
          other.product == this.product &&
          other.store == this.store &&
          other.price == this.price);
}

class ListingCompanion extends UpdateCompanion<ListingData> {
  final Value<int> id;
  final Value<String> product;
  final Value<int?> store;
  final Value<double?> price;
  const ListingCompanion({
    this.id = const Value.absent(),
    this.product = const Value.absent(),
    this.store = const Value.absent(),
    this.price = const Value.absent(),
  });
  ListingCompanion.insert({
    this.id = const Value.absent(),
    required String product,
    this.store = const Value.absent(),
    this.price = const Value.absent(),
  }) : product = Value(product);
  static Insertable<ListingData> custom({
    Expression<int>? id,
    Expression<String>? product,
    Expression<int>? store,
    Expression<double>? price,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (product != null) 'product': product,
      if (store != null) 'store': store,
      if (price != null) 'price': price,
    });
  }

  ListingCompanion copyWith({
    Value<int>? id,
    Value<String>? product,
    Value<int?>? store,
    Value<double?>? price,
  }) {
    return ListingCompanion(
      id: id ?? this.id,
      product: product ?? this.product,
      store: store ?? this.store,
      price: price ?? this.price,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value, BuiltinDriftType.int);
    }
    if (product.present) {
      map['product'] = Variable<String>(product.value, BuiltinDriftType.text);
    }
    if (store.present) {
      map['store'] = Variable<int>(store.value, BuiltinDriftType.int);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value, BuiltinDriftType.double);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ListingCompanion(')
          ..write('id: $id, ')
          ..write('product: $product, ')
          ..write('store: $store, ')
          ..write('price: $price')
          ..write(')'))
        .toString();
  }
}

abstract base class _$TestDatabase extends GeneratedDatabase {
  _$TestDatabase(super.implementation);
  $TestDatabaseManager get managers => $TestDatabaseManager(this);
  $CategoriesTable get categories => $CategoriesTable();
  $TableWithEveryColumnTypeTable get tableWithEveryColumnType =>
      $TableWithEveryColumnTypeTable();
  $TodosTableTable get todosTable => $TodosTableTable();
  $UsersTable get users => $UsersTable();
  $DepartmentTable get department => $DepartmentTable();
  $ProductTable get product => $ProductTable();
  $StoreTable get store => $StoreTable();
  $ListingTable get listing => $ListingTable();
  @override
  DatabaseSchema get schema => _$schema;
  static final DatabaseSchema _$schema = DatabaseSchema([
    $CategoriesTable(),
    $TableWithEveryColumnTypeTable(),
    $TodosTableTable(),
    $UsersTable(),
    $DepartmentTable(),
    $ProductTable(),
    $StoreTable(),
    $ListingTable(),
  ]);
}

typedef $$CategoriesTableCreateCompanionBuilder =
    CategoriesCompanion Function({
      Value<int> id,
      required String description,
      Value<CategoryPriority> priority,
    });
typedef $$CategoriesTableUpdateCompanionBuilder =
    CategoriesCompanion Function({
      Value<int> id,
      Value<String> description,
      Value<CategoryPriority> priority,
    });

final class $$CategoriesTableReferences
    extends BaseReferences<_$TestDatabase, $CategoriesTable, Category> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<List<TodoEntry>> _todosTable(_$TestDatabase db) =>
      MultiTypedResultKey.fromTable(
        $TodosTableTable(),
        aliasName: 'categories__id__todos__category',
      );

  $$TodosTableTableProcessedTableManager get todos {
    final manager = $$TodosTableTableTableManager(
      $_db,
      $TodosTableTable(),
    ).filter((f) => f.category.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_todosTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$TestDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CategoryPriority, CategoryPriority, int>
  get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get descriptionInUpperCase => $composableBuilder(
    column: $table.descriptionInUpperCase,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> todos(
    Expression<bool> Function($$TodosTableTableFilterComposer f) f,
  ) {
    final $$TodosTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $TodosTableTable(),
      getReferencedColumn: (t) => t.category,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TodosTableTableFilterComposer(
            $db: $db,
            $table: $TodosTableTable(),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$TestDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descriptionInUpperCase => $composableBuilder(
    column: $table.descriptionInUpperCase,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$TestDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  TableColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  TableColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  TableColumnWithTypeConverter<CategoryPriority, int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  TableColumn<String> get descriptionInUpperCase => $composableBuilder(
    column: $table.descriptionInUpperCase,
    builder: (column) => column,
  );

  Expression<T> todos<T extends Object>(
    Expression<T> Function($$TodosTableTableAnnotationComposer a) f,
  ) {
    final $$TodosTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $TodosTableTable(),
      getReferencedColumn: (t) => t.category,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TodosTableTableAnnotationComposer(
            $db: $db,
            $table: $TodosTableTable(),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$TestDatabase,
          $CategoriesTable,
          Category,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (Category, $$CategoriesTableReferences),
          Category,
          PrefetchHooks Function({bool todos})
        > {
  $$CategoriesTableTableManager(_$TestDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<CategoryPriority> priority = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                description: description,
                priority: priority,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String description,
                Value<CategoryPriority> priority = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                description: description,
                priority: priority,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({todos = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (todos) $TodosTableTable()],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (todos)
                    await $_getPrefetchedData<
                      Category,
                      $CategoriesTable,
                      TodoEntry
                    >(
                      currentTable: table,
                      referencedTable: $$CategoriesTableReferences._todosTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$CategoriesTableReferences(db, table, p0).todos,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.category == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$TestDatabase,
      $CategoriesTable,
      Category,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (Category, $$CategoriesTableReferences),
      Category,
      PrefetchHooks Function({bool todos})
    >;
typedef $$TableWithEveryColumnTypeTableCreateCompanionBuilder =
    TableWithEveryColumnTypeCompanion Function({
      Value<int> id,
      Value<bool?> aBool,
      Value<DateTime?> aDateTime,
      Value<String?> aText,
      Value<int?> anInt,
      Value<BigInt?> anInt64,
      Value<double?> aReal,
      Value<Uint8List?> aBlob,
      Value<TodoStatus?> anIntEnum,
      Value<MyCustomObject?> aTextWithConverter,
    });
typedef $$TableWithEveryColumnTypeTableUpdateCompanionBuilder =
    TableWithEveryColumnTypeCompanion Function({
      Value<int> id,
      Value<bool?> aBool,
      Value<DateTime?> aDateTime,
      Value<String?> aText,
      Value<int?> anInt,
      Value<BigInt?> anInt64,
      Value<double?> aReal,
      Value<Uint8List?> aBlob,
      Value<TodoStatus?> anIntEnum,
      Value<MyCustomObject?> aTextWithConverter,
    });

class $$TableWithEveryColumnTypeTableFilterComposer
    extends Composer<_$TestDatabase, $TableWithEveryColumnTypeTable> {
  $$TableWithEveryColumnTypeTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get aBool => $composableBuilder(
    column: $table.aBool,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get aDateTime => $composableBuilder(
    column: $table.aDateTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aText => $composableBuilder(
    column: $table.aText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get anInt => $composableBuilder(
    column: $table.anInt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get anInt64 => $composableBuilder(
    column: $table.anInt64,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get aReal => $composableBuilder(
    column: $table.aReal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get aBlob => $composableBuilder(
    column: $table.aBlob,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TodoStatus?, TodoStatus, int> get anIntEnum =>
      $composableBuilder(
        column: $table.anIntEnum,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<MyCustomObject?, MyCustomObject, String>
  get aTextWithConverter => $composableBuilder(
    column: $table.aTextWithConverter,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$TableWithEveryColumnTypeTableOrderingComposer
    extends Composer<_$TestDatabase, $TableWithEveryColumnTypeTable> {
  $$TableWithEveryColumnTypeTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get aBool => $composableBuilder(
    column: $table.aBool,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get aDateTime => $composableBuilder(
    column: $table.aDateTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aText => $composableBuilder(
    column: $table.aText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get anInt => $composableBuilder(
    column: $table.anInt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get anInt64 => $composableBuilder(
    column: $table.anInt64,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get aReal => $composableBuilder(
    column: $table.aReal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get aBlob => $composableBuilder(
    column: $table.aBlob,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get anIntEnum => $composableBuilder(
    column: $table.anIntEnum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aTextWithConverter => $composableBuilder(
    column: $table.aTextWithConverter,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TableWithEveryColumnTypeTableAnnotationComposer
    extends Composer<_$TestDatabase, $TableWithEveryColumnTypeTable> {
  $$TableWithEveryColumnTypeTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  TableColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  TableColumn<bool> get aBool =>
      $composableBuilder(column: $table.aBool, builder: (column) => column);

  TableColumn<DateTime> get aDateTime =>
      $composableBuilder(column: $table.aDateTime, builder: (column) => column);

  TableColumn<String> get aText =>
      $composableBuilder(column: $table.aText, builder: (column) => column);

  TableColumn<int> get anInt =>
      $composableBuilder(column: $table.anInt, builder: (column) => column);

  TableColumn<BigInt> get anInt64 =>
      $composableBuilder(column: $table.anInt64, builder: (column) => column);

  TableColumn<double> get aReal =>
      $composableBuilder(column: $table.aReal, builder: (column) => column);

  TableColumn<Uint8List> get aBlob =>
      $composableBuilder(column: $table.aBlob, builder: (column) => column);

  TableColumnWithTypeConverter<TodoStatus?, int> get anIntEnum =>
      $composableBuilder(column: $table.anIntEnum, builder: (column) => column);

  TableColumnWithTypeConverter<MyCustomObject?, String>
  get aTextWithConverter => $composableBuilder(
    column: $table.aTextWithConverter,
    builder: (column) => column,
  );
}

class $$TableWithEveryColumnTypeTableTableManager
    extends
        RootTableManager<
          _$TestDatabase,
          $TableWithEveryColumnTypeTable,
          TableWithEveryColumnTypeData,
          $$TableWithEveryColumnTypeTableFilterComposer,
          $$TableWithEveryColumnTypeTableOrderingComposer,
          $$TableWithEveryColumnTypeTableAnnotationComposer,
          $$TableWithEveryColumnTypeTableCreateCompanionBuilder,
          $$TableWithEveryColumnTypeTableUpdateCompanionBuilder,
          (
            TableWithEveryColumnTypeData,
            BaseReferences<
              _$TestDatabase,
              $TableWithEveryColumnTypeTable,
              TableWithEveryColumnTypeData
            >,
          ),
          TableWithEveryColumnTypeData,
          PrefetchHooks Function()
        > {
  $$TableWithEveryColumnTypeTableTableManager(
    _$TestDatabase db,
    $TableWithEveryColumnTypeTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TableWithEveryColumnTypeTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$TableWithEveryColumnTypeTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TableWithEveryColumnTypeTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool?> aBool = const Value.absent(),
                Value<DateTime?> aDateTime = const Value.absent(),
                Value<String?> aText = const Value.absent(),
                Value<int?> anInt = const Value.absent(),
                Value<BigInt?> anInt64 = const Value.absent(),
                Value<double?> aReal = const Value.absent(),
                Value<Uint8List?> aBlob = const Value.absent(),
                Value<TodoStatus?> anIntEnum = const Value.absent(),
                Value<MyCustomObject?> aTextWithConverter =
                    const Value.absent(),
              }) => TableWithEveryColumnTypeCompanion(
                id: id,
                aBool: aBool,
                aDateTime: aDateTime,
                aText: aText,
                anInt: anInt,
                anInt64: anInt64,
                aReal: aReal,
                aBlob: aBlob,
                anIntEnum: anIntEnum,
                aTextWithConverter: aTextWithConverter,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool?> aBool = const Value.absent(),
                Value<DateTime?> aDateTime = const Value.absent(),
                Value<String?> aText = const Value.absent(),
                Value<int?> anInt = const Value.absent(),
                Value<BigInt?> anInt64 = const Value.absent(),
                Value<double?> aReal = const Value.absent(),
                Value<Uint8List?> aBlob = const Value.absent(),
                Value<TodoStatus?> anIntEnum = const Value.absent(),
                Value<MyCustomObject?> aTextWithConverter =
                    const Value.absent(),
              }) => TableWithEveryColumnTypeCompanion.insert(
                id: id,
                aBool: aBool,
                aDateTime: aDateTime,
                aText: aText,
                anInt: anInt,
                anInt64: anInt64,
                aReal: aReal,
                aBlob: aBlob,
                anIntEnum: anIntEnum,
                aTextWithConverter: aTextWithConverter,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TableWithEveryColumnTypeTableProcessedTableManager =
    ProcessedTableManager<
      _$TestDatabase,
      $TableWithEveryColumnTypeTable,
      TableWithEveryColumnTypeData,
      $$TableWithEveryColumnTypeTableFilterComposer,
      $$TableWithEveryColumnTypeTableOrderingComposer,
      $$TableWithEveryColumnTypeTableAnnotationComposer,
      $$TableWithEveryColumnTypeTableCreateCompanionBuilder,
      $$TableWithEveryColumnTypeTableUpdateCompanionBuilder,
      (
        TableWithEveryColumnTypeData,
        BaseReferences<
          _$TestDatabase,
          $TableWithEveryColumnTypeTable,
          TableWithEveryColumnTypeData
        >,
      ),
      TableWithEveryColumnTypeData,
      PrefetchHooks Function()
    >;
typedef $$TodosTableTableCreateCompanionBuilder =
    TodosTableCompanion Function({
      Value<int> id,
      Value<String?> title,
      required String content,
      Value<DateTime?> targetDate,
      Value<int?> category,
      Value<TodoStatus?> status,
    });
typedef $$TodosTableTableUpdateCompanionBuilder =
    TodosTableCompanion Function({
      Value<int> id,
      Value<String?> title,
      Value<String> content,
      Value<DateTime?> targetDate,
      Value<int?> category,
      Value<TodoStatus?> status,
    });

final class $$TodosTableTableReferences
    extends BaseReferences<_$TestDatabase, $TodosTableTable, TodoEntry> {
  $$TodosTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryTable(_$TestDatabase db) =>
      $CategoriesTable().withAlias('todos__category__categories__id');

  $$CategoriesTableProcessedTableManager? get category {
    final $_column = $_itemColumn<int>('category');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager(
      $_db,
      $CategoriesTable(),
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TodosTableTableFilterComposer
    extends Composer<_$TestDatabase, $TodosTableTable> {
  $$TodosTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TodoStatus?, TodoStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$CategoriesTableFilterComposer get category {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.category,
      referencedTable: $CategoriesTable(),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $CategoriesTable(),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TodosTableTableOrderingComposer
    extends Composer<_$TestDatabase, $TodosTableTable> {
  $$TodosTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get category {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.category,
      referencedTable: $CategoriesTable(),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $CategoriesTable(),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TodosTableTableAnnotationComposer
    extends Composer<_$TestDatabase, $TodosTableTable> {
  $$TodosTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  TableColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  TableColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  TableColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  TableColumn<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => column,
  );

  TableColumnWithTypeConverter<TodoStatus?, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get category {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.category,
      referencedTable: $CategoriesTable(),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $CategoriesTable(),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TodosTableTableTableManager
    extends
        RootTableManager<
          _$TestDatabase,
          $TodosTableTable,
          TodoEntry,
          $$TodosTableTableFilterComposer,
          $$TodosTableTableOrderingComposer,
          $$TodosTableTableAnnotationComposer,
          $$TodosTableTableCreateCompanionBuilder,
          $$TodosTableTableUpdateCompanionBuilder,
          (TodoEntry, $$TodosTableTableReferences),
          TodoEntry,
          PrefetchHooks Function({bool category})
        > {
  $$TodosTableTableTableManager(_$TestDatabase db, $TodosTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TodosTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TodosTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TodosTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<DateTime?> targetDate = const Value.absent(),
                Value<int?> category = const Value.absent(),
                Value<TodoStatus?> status = const Value.absent(),
              }) => TodosTableCompanion(
                id: id,
                title: title,
                content: content,
                targetDate: targetDate,
                category: category,
                status: status,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> title = const Value.absent(),
                required String content,
                Value<DateTime?> targetDate = const Value.absent(),
                Value<int?> category = const Value.absent(),
                Value<TodoStatus?> status = const Value.absent(),
              }) => TodosTableCompanion.insert(
                id: id,
                title: title,
                content: content,
                targetDate: targetDate,
                category: category,
                status: status,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TodosTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({category = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (category) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.category,
                                referencedTable: $$TodosTableTableReferences
                                    ._categoryTable(db),
                                referencedColumn: $$TodosTableTableReferences
                                    ._categoryTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TodosTableTableProcessedTableManager =
    ProcessedTableManager<
      _$TestDatabase,
      $TodosTableTable,
      TodoEntry,
      $$TodosTableTableFilterComposer,
      $$TodosTableTableOrderingComposer,
      $$TodosTableTableAnnotationComposer,
      $$TodosTableTableCreateCompanionBuilder,
      $$TodosTableTableUpdateCompanionBuilder,
      (TodoEntry, $$TodosTableTableReferences),
      TodoEntry,
      PrefetchHooks Function({bool category})
    >;
typedef $$UsersTableCreateCompanionBuilder =
    UsersCompanion Function({
      Value<int> id,
      required String name,
      Value<bool> isAwesome,
      required Uint8List profilePicture,
      Value<DateTime> creationTime,
    });
typedef $$UsersTableUpdateCompanionBuilder =
    UsersCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<bool> isAwesome,
      Value<Uint8List> profilePicture,
      Value<DateTime> creationTime,
    });

class $$UsersTableFilterComposer extends Composer<_$TestDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAwesome => $composableBuilder(
    column: $table.isAwesome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get profilePicture => $composableBuilder(
    column: $table.profilePicture,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creationTime => $composableBuilder(
    column: $table.creationTime,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UsersTableOrderingComposer
    extends Composer<_$TestDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAwesome => $composableBuilder(
    column: $table.isAwesome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get profilePicture => $composableBuilder(
    column: $table.profilePicture,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creationTime => $composableBuilder(
    column: $table.creationTime,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsersTableAnnotationComposer
    extends Composer<_$TestDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  TableColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  TableColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  TableColumn<bool> get isAwesome =>
      $composableBuilder(column: $table.isAwesome, builder: (column) => column);

  TableColumn<Uint8List> get profilePicture => $composableBuilder(
    column: $table.profilePicture,
    builder: (column) => column,
  );

  TableColumn<DateTime> get creationTime => $composableBuilder(
    column: $table.creationTime,
    builder: (column) => column,
  );
}

class $$UsersTableTableManager
    extends
        RootTableManager<
          _$TestDatabase,
          $UsersTable,
          User,
          $$UsersTableFilterComposer,
          $$UsersTableOrderingComposer,
          $$UsersTableAnnotationComposer,
          $$UsersTableCreateCompanionBuilder,
          $$UsersTableUpdateCompanionBuilder,
          (User, BaseReferences<_$TestDatabase, $UsersTable, User>),
          User,
          PrefetchHooks Function()
        > {
  $$UsersTableTableManager(_$TestDatabase db, $UsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> isAwesome = const Value.absent(),
                Value<Uint8List> profilePicture = const Value.absent(),
                Value<DateTime> creationTime = const Value.absent(),
              }) => UsersCompanion(
                id: id,
                name: name,
                isAwesome: isAwesome,
                profilePicture: profilePicture,
                creationTime: creationTime,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<bool> isAwesome = const Value.absent(),
                required Uint8List profilePicture,
                Value<DateTime> creationTime = const Value.absent(),
              }) => UsersCompanion.insert(
                id: id,
                name: name,
                isAwesome: isAwesome,
                profilePicture: profilePicture,
                creationTime: creationTime,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UsersTableProcessedTableManager =
    ProcessedTableManager<
      _$TestDatabase,
      $UsersTable,
      User,
      $$UsersTableFilterComposer,
      $$UsersTableOrderingComposer,
      $$UsersTableAnnotationComposer,
      $$UsersTableCreateCompanionBuilder,
      $$UsersTableUpdateCompanionBuilder,
      (User, BaseReferences<_$TestDatabase, $UsersTable, User>),
      User,
      PrefetchHooks Function()
    >;
typedef $$DepartmentTableCreateCompanionBuilder =
    DepartmentCompanion Function({Value<int> id, Value<String?> name});
typedef $$DepartmentTableUpdateCompanionBuilder =
    DepartmentCompanion Function({Value<int> id, Value<String?> name});

final class $$DepartmentTableReferences
    extends BaseReferences<_$TestDatabase, $DepartmentTable, DepartmentData> {
  $$DepartmentTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<List<ProductData>> _productRefsTable(
    _$TestDatabase db,
  ) => MultiTypedResultKey.fromTable(
    $ProductTable(),
    aliasName: 'department__id__product__department',
  );

  $$ProductTableProcessedTableManager get productRefs {
    final manager = $$ProductTableTableManager(
      $_db,
      $ProductTable(),
    ).filter((f) => f.department.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_productRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DepartmentTableFilterComposer
    extends Composer<_$TestDatabase, $DepartmentTable> {
  $$DepartmentTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> productRefs(
    Expression<bool> Function($$ProductTableFilterComposer f) f,
  ) {
    final $$ProductTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $ProductTable(),
      getReferencedColumn: (t) => t.department,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductTableFilterComposer(
            $db: $db,
            $table: $ProductTable(),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DepartmentTableOrderingComposer
    extends Composer<_$TestDatabase, $DepartmentTable> {
  $$DepartmentTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DepartmentTableAnnotationComposer
    extends Composer<_$TestDatabase, $DepartmentTable> {
  $$DepartmentTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  TableColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  TableColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  Expression<T> productRefs<T extends Object>(
    Expression<T> Function($$ProductTableAnnotationComposer a) f,
  ) {
    final $$ProductTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $ProductTable(),
      getReferencedColumn: (t) => t.department,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductTableAnnotationComposer(
            $db: $db,
            $table: $ProductTable(),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DepartmentTableTableManager
    extends
        RootTableManager<
          _$TestDatabase,
          $DepartmentTable,
          DepartmentData,
          $$DepartmentTableFilterComposer,
          $$DepartmentTableOrderingComposer,
          $$DepartmentTableAnnotationComposer,
          $$DepartmentTableCreateCompanionBuilder,
          $$DepartmentTableUpdateCompanionBuilder,
          (DepartmentData, $$DepartmentTableReferences),
          DepartmentData,
          PrefetchHooks Function({bool productRefs})
        > {
  $$DepartmentTableTableManager(_$TestDatabase db, $DepartmentTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DepartmentTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DepartmentTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DepartmentTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> name = const Value.absent(),
              }) => DepartmentCompanion(id: id, name: name),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> name = const Value.absent(),
              }) => DepartmentCompanion.insert(id: id, name: name),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DepartmentTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({productRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (productRefs) $ProductTable()],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (productRefs)
                    await $_getPrefetchedData<
                      DepartmentData,
                      $DepartmentTable,
                      ProductData
                    >(
                      currentTable: table,
                      referencedTable: $$DepartmentTableReferences
                          ._productRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$DepartmentTableReferences(
                            db,
                            table,
                            p0,
                          ).productRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.department == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$DepartmentTableProcessedTableManager =
    ProcessedTableManager<
      _$TestDatabase,
      $DepartmentTable,
      DepartmentData,
      $$DepartmentTableFilterComposer,
      $$DepartmentTableOrderingComposer,
      $$DepartmentTableAnnotationComposer,
      $$DepartmentTableCreateCompanionBuilder,
      $$DepartmentTableUpdateCompanionBuilder,
      (DepartmentData, $$DepartmentTableReferences),
      DepartmentData,
      PrefetchHooks Function({bool productRefs})
    >;
typedef $$ProductTableCreateCompanionBuilder =
    ProductCompanion Function({
      required String sku,
      Value<String?> name,
      Value<int?> department,
      Value<int> rowid,
    });
typedef $$ProductTableUpdateCompanionBuilder =
    ProductCompanion Function({
      Value<String> sku,
      Value<String?> name,
      Value<int?> department,
      Value<int> rowid,
    });

final class $$ProductTableReferences
    extends BaseReferences<_$TestDatabase, $ProductTable, ProductData> {
  $$ProductTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DepartmentTable _departmentTable(_$TestDatabase db) =>
      $DepartmentTable().withAlias('product__department__department__id');

  $$DepartmentTableProcessedTableManager? get department {
    final $_column = $_itemColumn<int>('department');
    if ($_column == null) return null;
    final manager = $$DepartmentTableTableManager(
      $_db,
      $DepartmentTable(),
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_departmentTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<List<ListingData>> _listingsTable(
    _$TestDatabase db,
  ) => MultiTypedResultKey.fromTable(
    $ListingTable(),
    aliasName: 'product__sku__listing__product',
  );

  $$ListingTableProcessedTableManager get listings {
    final manager = $$ListingTableTableManager(
      $_db,
      $ListingTable(),
    ).filter((f) => f.product.sku.sqlEquals($_itemColumn<String>('sku')!));

    final cache = $_typedResult.readTableOrNull(_listingsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProductTableFilterComposer
    extends Composer<_$TestDatabase, $ProductTable> {
  $$ProductTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  $$DepartmentTableFilterComposer get department {
    final $$DepartmentTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.department,
      referencedTable: $DepartmentTable(),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DepartmentTableFilterComposer(
            $db: $db,
            $table: $DepartmentTable(),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> listings(
    Expression<bool> Function($$ListingTableFilterComposer f) f,
  ) {
    final $$ListingTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sku,
      referencedTable: $ListingTable(),
      getReferencedColumn: (t) => t.product,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ListingTableFilterComposer(
            $db: $db,
            $table: $ListingTable(),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductTableOrderingComposer
    extends Composer<_$TestDatabase, $ProductTable> {
  $$ProductTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  $$DepartmentTableOrderingComposer get department {
    final $$DepartmentTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.department,
      referencedTable: $DepartmentTable(),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DepartmentTableOrderingComposer(
            $db: $db,
            $table: $DepartmentTable(),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProductTableAnnotationComposer
    extends Composer<_$TestDatabase, $ProductTable> {
  $$ProductTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  TableColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  TableColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  $$DepartmentTableAnnotationComposer get department {
    final $$DepartmentTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.department,
      referencedTable: $DepartmentTable(),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DepartmentTableAnnotationComposer(
            $db: $db,
            $table: $DepartmentTable(),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> listings<T extends Object>(
    Expression<T> Function($$ListingTableAnnotationComposer a) f,
  ) {
    final $$ListingTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sku,
      referencedTable: $ListingTable(),
      getReferencedColumn: (t) => t.product,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ListingTableAnnotationComposer(
            $db: $db,
            $table: $ListingTable(),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductTableTableManager
    extends
        RootTableManager<
          _$TestDatabase,
          $ProductTable,
          ProductData,
          $$ProductTableFilterComposer,
          $$ProductTableOrderingComposer,
          $$ProductTableAnnotationComposer,
          $$ProductTableCreateCompanionBuilder,
          $$ProductTableUpdateCompanionBuilder,
          (ProductData, $$ProductTableReferences),
          ProductData,
          PrefetchHooks Function({bool department, bool listings})
        > {
  $$ProductTableTableManager(_$TestDatabase db, $ProductTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> sku = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<int?> department = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductCompanion(
                sku: sku,
                name: name,
                department: department,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sku,
                Value<String?> name = const Value.absent(),
                Value<int?> department = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductCompanion.insert(
                sku: sku,
                name: name,
                department: department,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProductTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({department = false, listings = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (listings) $ListingTable()],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (department) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.department,
                                referencedTable: $$ProductTableReferences
                                    ._departmentTable(db),
                                referencedColumn: $$ProductTableReferences
                                    ._departmentTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (listings)
                    await $_getPrefetchedData<
                      ProductData,
                      $ProductTable,
                      ListingData
                    >(
                      currentTable: table,
                      referencedTable: $$ProductTableReferences._listingsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$ProductTableReferences(db, table, p0).listings,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.product == item.sku),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ProductTableProcessedTableManager =
    ProcessedTableManager<
      _$TestDatabase,
      $ProductTable,
      ProductData,
      $$ProductTableFilterComposer,
      $$ProductTableOrderingComposer,
      $$ProductTableAnnotationComposer,
      $$ProductTableCreateCompanionBuilder,
      $$ProductTableUpdateCompanionBuilder,
      (ProductData, $$ProductTableReferences),
      ProductData,
      PrefetchHooks Function({bool department, bool listings})
    >;
typedef $$StoreTableCreateCompanionBuilder =
    StoreCompanion Function({Value<int> id, Value<String?> name});
typedef $$StoreTableUpdateCompanionBuilder =
    StoreCompanion Function({Value<int> id, Value<String?> name});

final class $$StoreTableReferences
    extends BaseReferences<_$TestDatabase, $StoreTable, StoreData> {
  $$StoreTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<List<ListingData>> _listingsTable(
    _$TestDatabase db,
  ) => MultiTypedResultKey.fromTable(
    $ListingTable(),
    aliasName: 'store__id__listing__store',
  );

  $$ListingTableProcessedTableManager get listings {
    final manager = $$ListingTableTableManager(
      $_db,
      $ListingTable(),
    ).filter((f) => f.store.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_listingsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$StoreTableFilterComposer extends Composer<_$TestDatabase, $StoreTable> {
  $$StoreTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> listings(
    Expression<bool> Function($$ListingTableFilterComposer f) f,
  ) {
    final $$ListingTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $ListingTable(),
      getReferencedColumn: (t) => t.store,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ListingTableFilterComposer(
            $db: $db,
            $table: $ListingTable(),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StoreTableOrderingComposer
    extends Composer<_$TestDatabase, $StoreTable> {
  $$StoreTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StoreTableAnnotationComposer
    extends Composer<_$TestDatabase, $StoreTable> {
  $$StoreTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  TableColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  TableColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  Expression<T> listings<T extends Object>(
    Expression<T> Function($$ListingTableAnnotationComposer a) f,
  ) {
    final $$ListingTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $ListingTable(),
      getReferencedColumn: (t) => t.store,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ListingTableAnnotationComposer(
            $db: $db,
            $table: $ListingTable(),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StoreTableTableManager
    extends
        RootTableManager<
          _$TestDatabase,
          $StoreTable,
          StoreData,
          $$StoreTableFilterComposer,
          $$StoreTableOrderingComposer,
          $$StoreTableAnnotationComposer,
          $$StoreTableCreateCompanionBuilder,
          $$StoreTableUpdateCompanionBuilder,
          (StoreData, $$StoreTableReferences),
          StoreData,
          PrefetchHooks Function({bool listings})
        > {
  $$StoreTableTableManager(_$TestDatabase db, $StoreTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoreTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoreTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoreTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> name = const Value.absent(),
              }) => StoreCompanion(id: id, name: name),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> name = const Value.absent(),
              }) => StoreCompanion.insert(id: id, name: name),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$StoreTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({listings = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (listings) $ListingTable()],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (listings)
                    await $_getPrefetchedData<
                      StoreData,
                      $StoreTable,
                      ListingData
                    >(
                      currentTable: table,
                      referencedTable: $$StoreTableReferences._listingsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$StoreTableReferences(db, table, p0).listings,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.store == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$StoreTableProcessedTableManager =
    ProcessedTableManager<
      _$TestDatabase,
      $StoreTable,
      StoreData,
      $$StoreTableFilterComposer,
      $$StoreTableOrderingComposer,
      $$StoreTableAnnotationComposer,
      $$StoreTableCreateCompanionBuilder,
      $$StoreTableUpdateCompanionBuilder,
      (StoreData, $$StoreTableReferences),
      StoreData,
      PrefetchHooks Function({bool listings})
    >;
typedef $$ListingTableCreateCompanionBuilder =
    ListingCompanion Function({
      Value<int> id,
      required String product,
      Value<int?> store,
      Value<double?> price,
    });
typedef $$ListingTableUpdateCompanionBuilder =
    ListingCompanion Function({
      Value<int> id,
      Value<String> product,
      Value<int?> store,
      Value<double?> price,
    });

final class $$ListingTableReferences
    extends BaseReferences<_$TestDatabase, $ListingTable, ListingData> {
  $$ListingTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProductTable _productTable(_$TestDatabase db) =>
      $ProductTable().withAlias('listing__product__product__sku');

  $$ProductTableProcessedTableManager get product {
    final $_column = $_itemColumn<String>('product')!;

    final manager = $$ProductTableTableManager(
      $_db,
      $ProductTable(),
    ).filter((f) => f.sku.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $StoreTable _storeTable(_$TestDatabase db) =>
      $StoreTable().withAlias('listing__store__store__id');

  $$StoreTableProcessedTableManager? get store {
    final $_column = $_itemColumn<int>('store');
    if ($_column == null) return null;
    final manager = $$StoreTableTableManager(
      $_db,
      $StoreTable(),
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_storeTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ListingTableFilterComposer
    extends Composer<_$TestDatabase, $ListingTable> {
  $$ListingTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  $$ProductTableFilterComposer get product {
    final $$ProductTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.product,
      referencedTable: $ProductTable(),
      getReferencedColumn: (t) => t.sku,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductTableFilterComposer(
            $db: $db,
            $table: $ProductTable(),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StoreTableFilterComposer get store {
    final $$StoreTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.store,
      referencedTable: $StoreTable(),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoreTableFilterComposer(
            $db: $db,
            $table: $StoreTable(),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ListingTableOrderingComposer
    extends Composer<_$TestDatabase, $ListingTable> {
  $$ListingTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProductTableOrderingComposer get product {
    final $$ProductTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.product,
      referencedTable: $ProductTable(),
      getReferencedColumn: (t) => t.sku,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductTableOrderingComposer(
            $db: $db,
            $table: $ProductTable(),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StoreTableOrderingComposer get store {
    final $$StoreTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.store,
      referencedTable: $StoreTable(),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoreTableOrderingComposer(
            $db: $db,
            $table: $StoreTable(),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ListingTableAnnotationComposer
    extends Composer<_$TestDatabase, $ListingTable> {
  $$ListingTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  TableColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  TableColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  $$ProductTableAnnotationComposer get product {
    final $$ProductTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.product,
      referencedTable: $ProductTable(),
      getReferencedColumn: (t) => t.sku,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductTableAnnotationComposer(
            $db: $db,
            $table: $ProductTable(),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StoreTableAnnotationComposer get store {
    final $$StoreTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.store,
      referencedTable: $StoreTable(),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoreTableAnnotationComposer(
            $db: $db,
            $table: $StoreTable(),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ListingTableTableManager
    extends
        RootTableManager<
          _$TestDatabase,
          $ListingTable,
          ListingData,
          $$ListingTableFilterComposer,
          $$ListingTableOrderingComposer,
          $$ListingTableAnnotationComposer,
          $$ListingTableCreateCompanionBuilder,
          $$ListingTableUpdateCompanionBuilder,
          (ListingData, $$ListingTableReferences),
          ListingData,
          PrefetchHooks Function({bool product, bool store})
        > {
  $$ListingTableTableManager(_$TestDatabase db, $ListingTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ListingTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ListingTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ListingTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> product = const Value.absent(),
                Value<int?> store = const Value.absent(),
                Value<double?> price = const Value.absent(),
              }) => ListingCompanion(
                id: id,
                product: product,
                store: store,
                price: price,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String product,
                Value<int?> store = const Value.absent(),
                Value<double?> price = const Value.absent(),
              }) => ListingCompanion.insert(
                id: id,
                product: product,
                store: store,
                price: price,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ListingTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({product = false, store = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (product) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.product,
                                referencedTable: $$ListingTableReferences
                                    ._productTable(db),
                                referencedColumn: $$ListingTableReferences
                                    ._productTable(db)
                                    .sku,
                              )
                              as T;
                    }
                    if (store) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.store,
                                referencedTable: $$ListingTableReferences
                                    ._storeTable(db),
                                referencedColumn: $$ListingTableReferences
                                    ._storeTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ListingTableProcessedTableManager =
    ProcessedTableManager<
      _$TestDatabase,
      $ListingTable,
      ListingData,
      $$ListingTableFilterComposer,
      $$ListingTableOrderingComposer,
      $$ListingTableAnnotationComposer,
      $$ListingTableCreateCompanionBuilder,
      $$ListingTableUpdateCompanionBuilder,
      (ListingData, $$ListingTableReferences),
      ListingData,
      PrefetchHooks Function({bool product, bool store})
    >;

class $TestDatabaseManager {
  final _$TestDatabase _db;
  $TestDatabaseManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$TableWithEveryColumnTypeTableTableManager get tableWithEveryColumnType =>
      $$TableWithEveryColumnTypeTableTableManager(
        _db,
        _db.tableWithEveryColumnType,
      );
  $$TodosTableTableTableManager get todosTable =>
      $$TodosTableTableTableManager(_db, _db.todosTable);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$DepartmentTableTableManager get department =>
      $$DepartmentTableTableManager(_db, _db.department);
  $$ProductTableTableManager get product =>
      $$ProductTableTableManager(_db, _db.product);
  $$StoreTableTableManager get store =>
      $$StoreTableTableManager(_db, _db.store);
  $$ListingTableTableManager get listing =>
      $$ListingTableTableManager(_db, _db.listing);
}
