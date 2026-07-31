import 'package:collection/collection.dart';

import '../../analysis/results/results.dart';
import '../../utils/string_escaper.dart';
import '../utils/column_constraints.dart';
import '../utils/memoized_getter.dart';
import '../writer.dart';
import 'data_class_writer.dart';
import 'update_companion_writer.dart';

/// Common writer for tables or views.
///
/// Both classes need to generate column getters and a mapping function.
abstract class TableOrViewWriter {
  DriftElementWithResultSet get tableOrView;

  TextEmitter get emitter;

  StringBuffer get buffer => emitter.buffer;

  void writeColumnGetter(DriftColumn column, bool isOverride) {
    bool? isRequiredForInsert;

    if (tableOrView is DriftTable) {
      isRequiredForInsert = (tableOrView as DriftTable)
          .isColumnRequiredForInsert(column);
    }

    final (type, expression) = instantiateColumn(
      column,
      emitter,
      isRequiredForInsert: isRequiredForInsert,
      isForTable: tableOrView is DriftTable,
    );

    writeMemoizedGetter(
      buffer: buffer,
      getterName: column.nameInDart,
      returnType: type,
      code: expression,
      hasOverride: isOverride,
    );
  }

  void writeConvertersAsStaticFields() {
    if (emitter.writer.generationOptions.avoidUserCode) {
      return;
    }

    for (final converter in tableOrView.appliedConverters) {
      if (converter.owningColumn?.owner != tableOrView) continue;

      final typeName = emitter.dartCode(
        emitter.writer.converterType(converter),
      );
      final code = emitter.dartCode(converter.expression);
      buffer.write('static $typeName ${converter.fieldName} = $code;');

      // Generate wrappers for non-nullable type converters that are applied to
      // nullable columns.
      final column = converter.owningColumn!;
      if (converter.canBeSkippedForNulls && column.nullable) {
        final nullableTypeName = emitter.dartCode(
          emitter.writer.converterType(converter, makeNullable: true),
        );

        final wrap = converter.alsoAppliesToJsonConversion
            ? emitter.drift('JsonTypeConverter2.asNullable')
            : emitter.drift('NullAwareTypeConverter.wrap');

        final code = '$wrap(${converter.fieldName})';

        buffer.write(
          'static $nullableTypeName ${converter.nullableFieldName} = '
          '$code;',
        );
      }
    }
  }

  void writeMappingMethod(Scope scope) {
    if (scope.drift3) {
      return _writeDrift3MappingMethod(scope);
    }

    if (!scope.generationOptions.writeDataClasses) {
      buffer.writeln('''
        @override
        Never map(Map<String, dynamic> data, {String? tablePrefix}) {
          throw UnsupportedError('TableInfo.map in schema verification code');
        }
      ''');
      return;
    }

    final dataClassType = emitter.dartCode(emitter.writer.rowType(tableOrView));

    final isAsync = tableOrView.existingRowClass?.isAsyncFactory == true;
    final returnType = isAsync ? 'Future<$dataClassType>' : dataClassType;
    final asyncModifier = isAsync ? 'async' : '';

    buffer
      ..write(
        '@override $returnType map(Map<String, dynamic> data, '
        '{String? tablePrefix}) $asyncModifier {\n',
      )
      ..write(
        'final effectivePrefix = '
        "tablePrefix != null ? '\$tablePrefix.' : '';",
      );

    if (tableOrView.hasExistingRowClass) {
      final info = tableOrView.existingRowClass!;

      final writer = RowMappingWriter(
        positional: [
          for (final positional in info.positionalColumns)
            tableOrView.columnBySqlName[positional]!,
        ],
        named: info.namedColumns.map((dartParameter, columnName) {
          return MapEntry(
            tableOrView.columnBySqlName[columnName]!,
            dartParameter,
          );
        }),
        table: tableOrView,
        writer: scope.writer,
        databaseGetter: 'attachedDatabase',
      );

      final ctor = info.constructor;
      emitter
        ..write('return ')
        ..write(isAsync ? 'await ' : '');
      if (!info.isRecord) {
        // Write the constructor or async mapping method for this existing row
        // class. It will later be invoked by writing the arguments below.
        // For records, the argument syntax is already a valid record literal.
        emitter.writeDart(AnnotatedDartCode.type(info.targetType));

        if (ctor != 'new') {
          buffer
            ..write('.')
            ..write(ctor);
        }
      }

      writer.writeArguments(buffer);
      buffer.write(';\n');
    } else {
      final columns = tableOrView.columns;

      final writer = RowMappingWriter(
        positional: const [],
        named: {for (final column in columns) column: column.nameInDart},
        table: tableOrView,
        writer: scope.writer,
        databaseGetter: 'attachedDatabase',
      );

      emitter
        ..write('return ')
        ..writeDart(emitter.writer.rowClass(tableOrView));
      writer.writeArguments(buffer);
      buffer.writeln(';');
    }

    buffer.write('}\n');
  }

  void _writeDrift3MappingMethod(Scope scope) {
    final columnPosition = emitter.drift('ColumnPosition');
    final rawRow = emitter.drift('RawRow');

    if (!scope.generationOptions.writeDataClasses) {
      buffer.writeln('''
        @override
        Never createMapperFromPositions(${emitter.drift('DriftDialect')} dialect, List<$columnPosition> positions) {
          throw UnsupportedError('Mapping to Dart in schema verification code');
        }
      ''');
      return;
    }

    final dataClassType = emitter.dartCode(emitter.writer.rowType(tableOrView));

    buffer
      ..writeln('@override')
      ..write('$dataClassType? Function($rawRow) createMapperFromPositions(')
      ..writeln(
        '${emitter.drift('DriftDialect')} dialect, List<$columnPosition> positions) {',
      );

    final resolvedColumns = <DriftColumn, (String, String)>{};
    final types = <ColumnType, String>{};
    for (final (index, column) in tableOrView.columns.indexed) {
      final posVariable = 'pos\$${column.nameInDart}';
      buffer.writeln('final $posVariable = positions[$index].index;');

      final typeVariable = types.putIfAbsent(column.sqlType, () {
        final name = 'type\$${types.length}';
        emitter
          ..write('final $name = ')
          ..write(emitter.drift3SqlType(column.sqlType))
          ..writeln('.resolveIn(dialect);');
        return name;
      });
      resolvedColumns[column] = (posVariable, typeVariable);
    }
    buffer.writeln('return ($rawRow row) {');

    // We need to check whether this table is present in the row at all (it may
    // be absent for left outer joins).
    final firstNonNullableColumn = tableOrView.columns.firstWhereOrNull(
      (c) => !c.nullable,
    );
    if (firstNonNullableColumn case final column?) {
      buffer
        ..writeln(
          ' // Not part of row if non-nullable column "${column.nameInDart}" is missing',
        )
        ..writeln('if (row[${resolvedColumns[column]!.$1}] == null) {')
        ..writeln('return null;')
        ..writeln('}');
    }

    if (tableOrView.hasExistingRowClass) {
      final info = tableOrView.existingRowClass!;

      final writer = RowMappingWriter(
        positional: [
          for (final positional in info.positionalColumns)
            tableOrView.columnBySqlName[positional]!,
        ],
        named: info.namedColumns.map((dartParameter, columnName) {
          return MapEntry(
            tableOrView.columnBySqlName[columnName]!,
            dartParameter,
          );
        }),
        table: tableOrView,
        writer: scope.writer,
        databaseGetter: '_',
        columnToPositionAndType: resolvedColumns,
      );

      final ctor = info.constructor;
      emitter.write('return ');
      if (!info.isRecord) {
        // Write the constructor or async mapping method for this existing row
        // class. It will later be invoked by writing the arguments below.
        // For records, the argument syntax is already a valid record literal.
        emitter.writeDart(AnnotatedDartCode.type(info.targetType));

        if (ctor != 'new') {
          buffer
            ..write('.')
            ..write(ctor);
        }
      }

      writer.writeArguments(buffer);
      buffer.write(';\n');
    } else {
      final columns = tableOrView.columns;

      final writer = RowMappingWriter(
        positional: const [],
        named: {for (final column in columns) column: column.nameInDart},
        table: tableOrView,
        writer: scope.writer,
        databaseGetter: '_',
        columnToPositionAndType: resolvedColumns,
      );

      emitter
        ..write('return ')
        ..writeDart(emitter.writer.rowClass(tableOrView));
      writer.writeArguments(buffer);
      buffer.writeln(';');
    }

    buffer.write('};}\n');
  }

  void writeGetColumnsOverride() {
    final columnsWithGetters = tableOrView.columns
        .map((c) => c.nameInDart)
        .join(', ');

    if (emitter.parent!.drift3) {
      final type = tableOrView is DriftTable ? 'TableColumn' : 'SchemaColumn';
      buffer.write(
        '@override\nList<${emitter.drift(type)}> get columns => '
        '[$columnsWithGetters];\n',
      );
    } else {
      buffer.write(
        '@override\nList<${emitter.drift('GeneratedColumn')}> get \$columns => '
        '[$columnsWithGetters];\n',
      );
    }
  }

  void writeAsDslTable() {
    buffer.write(
      '@override\n${tableOrView.entityInfoName} get asDslTable => this;\n',
    );
  }

  void writeAsSelfType() {
    emitter.writeln(
      '@override\n${tableOrView.entityInfoName} asSelfType() => this;\n',
    );
  }

  /// Returns the Dart type and the Dart expression creating a `GeneratedColumn`
  /// instance in drift for the given [column].
  static (String, String) instantiateColumn(
    DriftColumn column,
    TextEmitter emitter, {
    bool isForTable = false,
    bool? isRequiredForInsert,
    bool isForVersionedSchema = false,
  }) {
    if (emitter.parent!.drift3) {
      return _instantiateColumnDrift3(
        column,
        emitter,
        isRequiredForInsert: isRequiredForInsert,
        isForTable: isForTable,
        isForVersionedSchema: isForVersionedSchema,
      );
    }

    final isNullable = column.nullable;
    final additionalParams = <String, String>{};
    final expressionBuffer = StringBuffer();
    final constraints = defaultConstraints(column);

    // Remove dialect-specific constraints for dialects we don't care about.
    constraints.removeWhere(
      (key, _) => !emitter.writer.options.supportedDialects.contains(key),
    );

    for (final constraint in column.constraints) {
      if (constraint is LimitingTextLength) {
        final buffer = StringBuffer(
          emitter.drift('GeneratedColumn.checkTextLength('),
        );

        if (constraint.minLength != null) {
          buffer.write('minTextLength: ${constraint.minLength},');
        }
        if (constraint.maxLength != null) {
          buffer.write('maxTextLength: ${constraint.maxLength}');
        }
        buffer.write(')');

        additionalParams['additionalChecks'] = buffer.toString();
      }

      if (constraint is DartCheckExpression) {
        final dartCheck = emitter.dartCode(constraint.dartExpression);
        additionalParams['check'] = '() => $dartCheck';
      }

      if (constraint is ColumnGeneratedAs) {
        final dartCode = emitter.dartCode(constraint.dartExpression);

        additionalParams['generatedAs'] =
            '${emitter.drift('GeneratedAs')}($dartCode, ${constraint.stored})';
      }

      if (constraint is PrimaryKeyColumn && constraint.isAutoIncrement) {
        additionalParams['hasAutoIncrement'] = 'true';
      }
    }

    switch (column.sqlType) {
      case ColumnDriftType():
        additionalParams['type'] = emitter.drift(
          column.sqlType.builtin.toString(),
        );
      case ColumnCustomType(:final custom):
        additionalParams['type'] = emitter.dartCode(custom.expression);
    }

    if (isRequiredForInsert != null) {
      additionalParams['requiredDuringInsert'] = isRequiredForInsert.toString();
    }

    if (column.customConstraints != null) {
      additionalParams['\$customConstraints'] = asDartLiteral(
        column.customConstraints!,
      );
    } else if (constraints.values.any((constraint) => constraint.isNotEmpty)) {
      // Use the default constraints supported by drift

      if (constraints.values.any(
        (value) => value != constraints.values.first,
      )) {
        // One or more constraints are different depending on dialect, generate
        // per-dialect constraints

        final literalEntries = [
          for (final entry in constraints.entries)
            '${emitter.drift('SqlDialect.${entry.key.name}')}: ${asDartLiteral(entry.value)},',
        ];

        additionalParams['defaultConstraints'] =
            '${emitter.drift('GeneratedColumn.constraintsDependsOnDialect')}({${literalEntries.join('\n')}})';
      } else {
        // Constraints are the same regardless of dialect, only generate one set
        // of them

        final constraint = asDartLiteral(constraints.values.first);

        additionalParams['defaultConstraints'] =
            '${emitter.drift('GeneratedColumn.constraintIsAlways')}($constraint)';
      }
    }

    if (column.defaultArgument != null) {
      additionalParams['defaultValue'] = emitter.dartCode(
        column.defaultArgument!,
      );
    }

    if (column.clientDefaultCode != null &&
        !emitter.writer.generationOptions.avoidUserCode) {
      additionalParams['clientDefault'] = emitter.dartCode(
        column.clientDefaultCode!,
      );
    }

    final innerType = emitter.innerColumnType(column.sqlType);
    var type =
        '${emitter.drift('GeneratedColumn')}<${emitter.dartCode(innerType)}>';
    expressionBuffer
      ..write(type)
      ..write(
        '(${asDartLiteral(column.nameInSql)}, aliasedName, $isNullable, ',
      );

    var first = true;
    additionalParams.forEach((name, value) {
      if (!first) {
        expressionBuffer.write(', ');
      } else {
        first = false;
      }

      expressionBuffer
        ..write(name)
        ..write(': ')
        ..write(value);
    });

    expressionBuffer.write(')');

    final converter = column.typeConverter;
    if (converter != null && !emitter.writer.generationOptions.avoidUserCode) {
      // Generate a GeneratedColumnWithTypeConverter instance, as it has
      // additional methods to check for equality against a mapped value.
      final mappedType = emitter.dartCode(emitter.writer.dartType(column));

      final converterCode = emitter.dartCode(
        emitter.writer.readConverter(converter, forNullable: column.nullable),
      );

      type =
          '${emitter.drift('GeneratedColumnWithTypeConverter')}'
          '<$mappedType, ${emitter.dartCode(innerType)}>';
      expressionBuffer
        ..write('.withConverter<')
        ..write(mappedType)
        ..write('>(')
        ..write(converterCode)
        ..write(')');
    }

    return (type, expressionBuffer.toString());
  }

  static (String, String) _instantiateColumnDrift3(
    DriftColumn column,
    TextEmitter emitter, {
    bool isForTable = false,
    bool? isRequiredForInsert,
    bool isForVersionedSchema = false,
  }) {
    AnnotatedDartCode? viewExpression;

    if (!isForTable) {
      for (final constraint in column.constraints) {
        // TODO: Store this on the view instead
        if (constraint is ColumnGeneratedAs) {
          viewExpression = constraint.dartExpression;
        }
      }
    }

    final namedParameters = <String, String>{
      'name': asDartLiteral(column.nameInSql),
      'sqlType': emitter.drift3SqlType(column.sqlType),
      if (viewExpression case final viewExpression?)
        'expression': emitter.dartCode(viewExpression),
    };
    final expressionBuffer = StringBuffer();

    if (isRequiredForInsert != null) {
      namedParameters['requiredDuringInsert'] = isRequiredForInsert.toString();
    }

    if (isForTable) {
      final constraints = columnConstraintsDrift3(emitter, column);

      if (column.customConstraints != null) {
        final list =
            '[${emitter.drift('ColumnConstraint.customSql')}'
            '(${asDartLiteral(column.customConstraints!)})]';

        namedParameters['constraints'] = '() => $list';
      } else if (constraints.isNotEmpty) {
        // Use the default constraints supported by drift
        namedParameters['constraints'] = '() => [${constraints.join(', ')}]';
      }

      if (column.clientDefaultCode != null &&
          !emitter.writer.generationOptions.avoidUserCode) {
        namedParameters['clientDefault'] = emitter.dartCode(
          column.clientDefaultCode!,
        );
      }
    }

    final innerType = emitter.innerColumnType(column.sqlType);
    var baseColumnImpl = isForTable ? 'TableColumn' : 'ViewColumn';
    var type =
        '${emitter.drift(baseColumnImpl)}<${emitter.dartCode(innerType)}>';

    expressionBuffer
      ..write(type)
      // Use ViewColumn.forDriftFile constructor if we don't have a Dart
      // expression backing the column (which is the case for SQL-defined
      // views).
      ..write(!isForTable && viewExpression == null ? '.forDriftFile' : '')
      ..write('(');

    var first = true;
    namedParameters.forEach((name, value) {
      if (!first) {
        expressionBuffer.write(', ');
      } else {
        first = false;
      }

      expressionBuffer
        ..write(name)
        ..write(': ')
        ..write(value);
    });

    expressionBuffer.write(')');

    final converter = column.typeConverter;
    if (converter != null && !emitter.writer.generationOptions.avoidUserCode) {
      // Generate a TableColumnWithTypeConverter instance, as it has
      // additional methods to check for equality against a mapped value.
      final mappedType = emitter.dartCode(emitter.writer.dartType(column));

      final converterCode = emitter.dartCode(
        emitter.writer.readConverter(converter, forNullable: column.nullable),
      );

      type =
          '${emitter.drift('${baseColumnImpl}WithTypeConverter')}'
          '<$mappedType, ${emitter.dartCode(innerType)}>';
      expressionBuffer
        ..write('.withConverter<')
        ..write(mappedType)
        ..write('>(')
        ..write(converterCode)
        ..write(')');
    }

    if (!isForVersionedSchema) {
      // This needs to be set on columns. For versioned table instances,
      // VersionedTable sets it.
      expressionBuffer.write('..owningResultSet = this');
    }
    return (type, expressionBuffer.toString());
  }
}

class TableWriter extends TableOrViewWriter {
  final DriftTable table;
  final Scope scope;

  @override
  late TextEmitter emitter;

  @override
  DriftTable get tableOrView => table;

  TableWriter(this.table, this.scope);

  bool get _skipVerification =>
      scope.drift3 ||
      scope.writer.options.skipVerificationCode ||
      scope.generationOptions.isGeneratingForSchema;

  void writeInto() {
    emitter = scope.leaf();

    writeDataClass();
    writeTableInfoClass();
  }

  void writeDataClass() {
    if (scope.generationOptions.writeDataClasses) {
      if (scope.options.writeToColumnsMixins) {
        writeToColumnsMixin();
      }

      final existing = table.existingRowClass;
      if (existing != null) {
        // We don't have to write a row class if we're using one provided by the
        // user. However, if the existing row type is a record, it is helpful
        // to generate a typedef for it.
        if (existing.isRecord) {
          emitter
            ..write('typedef ${table.nameOfRowClass} = ')
            ..writeDart(AnnotatedDartCode.type(existing.targetType))
            ..write(';');
        }
      } else {
        DataClassWriter(table, scope.child()).write();
      }
    }

    if (scope.generationOptions.writeCompanions) {
      UpdateCompanionWriter(table, scope.child()).write();
    }
  }

  void writeTableInfoClass() {
    if (!scope.generationOptions.writeDataClasses) {
      // Write a small table header without data class
      final infoName = table.entityInfoName;
      buffer
        ..write('class $infoName extends ')
        ..write(emitter.drift('Table'))
        ..write(' with ');
      if (scope.drift3) {
        buffer
          ..write(emitter.drift('ResultSet'))
          ..write('<Never, $infoName> implements ')
          ..write(emitter.drift('GeneratedTable'))
          ..write('<Never, $infoName>');
        if (table.isVirtual) {
          buffer
            ..write(', ${emitter.drift('VirtualTableInfo')}')
            ..write('<Never, $infoName>');
        }
      } else {
        buffer.write(emitter.drift('TableInfo'));

        if (table.isVirtual) {
          buffer.write(', ${emitter.drift('VirtualTableInfo')}');
        }
      }
    } else {
      // Regular generation, write full table class
      final dataClass = emitter.dartCode(emitter.writer.rowType(table));
      final tableDslName =
          table.definingDartClass ??
          AnnotatedDartCode.importedSymbol(AnnotatedDartCode.drift, 'Table');

      // class UsersTable extends Users implements TableInfo<Users, User> {
      final typeArgs = scope.drift3
          ? '<$dataClass, ${table.entityInfoName}>'
          : '<${table.entityInfoName}, $dataClass>';

      emitter
        ..write('class ${table.entityInfoName} extends ')
        ..writeDart(tableDslName)
        ..write(' with ');
      if (scope.drift3) {
        buffer
          ..write(emitter.drift('ResultSet'))
          ..write(typeArgs)
          ..write(' implements ')
          ..write(emitter.drift('GeneratedTable'));
      } else {
        buffer.write(emitter.drift('TableInfo'));
      }
      buffer.write(typeArgs);

      if (table.isVirtual) {
        buffer.write(', ${emitter.drift('VirtualTableInfo')}$typeArgs ');
      }
    }

    buffer.writeln('{');
    if (scope.drift3) {
      buffer
        ..writeln('@override')
        ..writeln('final String? alias;')
        ..writeln('${table.entityInfoName}([this.alias]);');
    } else {
      buffer
        // write a GeneratedDatabase reference that is set in the constructor
        ..writeln(
          '@override final ${emitter.drift('GeneratedDatabase')} attachedDatabase;',
        )
        ..writeln('final String? _alias;')
        ..writeln(
          '${table.entityInfoName}(this.attachedDatabase, [this._alias]);',
        );
    }

    // Generate the columns
    for (final column in table.columns) {
      _writeColumnVerificationMeta(column);
      // Only add an @override to a column getter if we're overriding the column
      // from a Dart DSL class.
      writeColumnGetter(column, table.id.isDefinedInDart);
    }

    // Generate $columns, $tableName, asDslTable getters
    writeGetColumnsOverride();
    if (scope.drift3) {
      buffer.write('@override\nString get entityName => \$name;');
    } else {
      buffer.writeln(
        '@override\nString get aliasedName => '
        '_alias ?? actualTableName;',
      );
      buffer.writeln('@override\nString get actualTableName => \$name;');
    }

    buffer.write(
      'static const String \$name = ${asDartLiteral(table.id.name)};\n',
    );

    if (scope.drift3) writeAsSelfType();
    _writeValidityCheckMethod();
    _writePrimaryKeyOverride();
    _writeUniqueKeyOverride();

    writeMappingMethod(scope);
    // _writeReverseMappingMethod();

    _writeAliasGenerator();

    writeConvertersAsStaticFields();
    _overrideFieldsIfNeeded();

    // close class
    buffer.write('}');
  }

  void writeToColumnsMixin() {
    buffer.write('mixin ${table.toColumnsMixin} ');

    final type = emitter.dartCode(emitter.writer.rowType(table));
    buffer.writeln('implements ${emitter.drift('Insertable')}<$type> {');

    for (final column in table.columns) {
      if (column.documentationComment != null) {
        buffer.write('${column.documentationComment}\n');
      }
      final typeName = emitter.dartCode(emitter.dartType(column));
      buffer.writeln('$typeName get ${column.nameInDart};');
    }

    emitter.writeToColumnsOverride(table.columns);
    buffer.write('}');
  }

  bool _generateVerificationFor(DriftColumn column) {
    // dont't verify custom columns, we assume that the user knows what
    // they're doing
    return column.typeConverter == null;
  }

  void _writeColumnVerificationMeta(DriftColumn column) {
    if (!_skipVerification && _generateVerificationFor(column)) {
      final meta = emitter.drift('VerificationMeta');
      final arg = asDartLiteral(column.nameInDart);

      buffer
        ..write('static const $meta ${_fieldNameForColumnMeta(column)} = ')
        ..writeln("const $meta($arg);");
    }
  }

  void _writeValidityCheckMethod() {
    if (_skipVerification) return;

    if (!table.columns.any(_generateVerificationFor)) {
      return;
    }

    final innerType = emitter.dartCode(emitter.writer.rowType(table));
    emitter
      ..writeln('@override')
      ..writeDriftRef('VerificationContext')
      ..write(' validateIntegrity(')
      ..writeDriftRef('Insertable')
      ..writeln('<$innerType> instance, {bool isInserting = false}) {')
      ..write('final context = ${emitter.drift('VerificationContext')}();\n')
      ..write('final data = instance.toColumns(true);\n');

    const locals = {'instance', 'isInserting', 'context', 'data'};

    for (final column in table.columns) {
      final getterName = thisIfNeeded(column.nameInDart, locals);
      final metaName = _fieldNameForColumnMeta(column);

      if (!_generateVerificationFor(column)) {
        continue;
      }

      final columnNameString = asDartLiteral(column.nameInSql);
      buffer
        ..write('if (data.containsKey($columnNameString)) {\n')
        ..write(
          'context.handle('
          '$metaName, '
          '$getterName.isAcceptableOrUnknown('
          'data[$columnNameString]!, $metaName));',
        )
        ..write('}');

      if (table.isColumnRequiredForInsert(column)) {
        buffer
          ..write(' else if (isInserting) {\n')
          ..write('context.missing($metaName);\n')
          ..write('}\n');
      }
    }
    buffer.write('return context;\n}\n');
  }

  String _fieldNameForColumnMeta(DriftColumn column) {
    return '_${column.nameInDart}Meta';
  }

  void _writePrimaryKeyOverride() {
    if (scope.drift3) {
      if (!table.tableConstraints.any((e) => e is PrimaryKeyColumns)) {
        // Don't write the implicit primary key from column constraints, in
        // drift3 overriding the primaryKey getter always adds a table
        // constraint.
        return;
      }

      buffer.write(
        '@override\nSet<${emitter.drift('TableColumn')}> get primaryKey => ',
      );
    } else {
      buffer.write(
        '@override\nSet<${emitter.drift('GeneratedColumn')}> get \$primaryKey => ',
      );
    }

    final primaryKey = table.fullPrimaryKey;

    if (primaryKey.isEmpty) {
      buffer.write('const {};');
      return;
    }

    buffer.write('{');
    final pkList = primaryKey.toList();
    for (var i = 0; i < pkList.length; i++) {
      final pk = pkList[i];

      buffer.write(pk.nameInDart);
      if (i != pkList.length - 1) {
        buffer.write(', ');
      }
    }
    buffer.write('};\n');
  }

  void _writeUniqueKeyOverride() {
    final uniqueKeys = table.tableConstraints
        .whereType<UniqueColumns>()
        .toList();

    if (uniqueKeys.isEmpty) {
      // We inherit from `TableInfo` which defaults this getter to an empty
      // list.
      return;
    }

    if (scope.drift3) {
      buffer.write(
        '@override\nList<Set<${emitter.drift('TableColumn')}>> '
        'get uniqueKeys => [',
      );
    } else {
      buffer.write(
        '@override\nList<Set<${emitter.drift('GeneratedColumn')}>> '
        'get uniqueKeys => [',
      );
    }

    for (final uniqueKey in uniqueKeys) {
      buffer.write('{');
      final uqList = uniqueKey.uniqueSet.toList();
      for (var i = 0; i < uqList.length; i++) {
        final pk = uqList[i];

        buffer.write(pk.nameInDart);
        if (i != uqList.length - 1) {
          buffer.write(', ');
        }
      }
      buffer.write('},\n');
    }
    buffer.write('];\n');
  }

  void _writeAliasGenerator() {
    final typeName = table.entityInfoName;

    buffer.writeln('@override');
    if (scope.drift3) {
      buffer
        ..write('$typeName withAlias(String alias) {\n')
        ..write('return $typeName(alias);');
    } else {
      buffer
        ..write('$typeName createAlias(String alias) {\n')
        ..write('return $typeName(attachedDatabase, alias);');
    }
    buffer.writeln('}');
  }

  void _overrideFieldsIfNeeded() {
    if (table.withoutRowId) {
      buffer
        ..writeln('@override')
        ..writeln('bool get withoutRowId => true;');
    }

    if (table.strict) {
      buffer
        ..write('@override\n')
        ..write('bool get isStrict => true;\n');
    }

    // For Dart tables, the user already overrides the `customConstraints`
    // getter in the source. So, since we extend that class by default, there's
    // no need to override them again.
    final writeTableConstraints =
        table.definingDartClass == null ||
        scope.generationOptions.forSchema != null;
    if (writeTableConstraints && table.overrideTableConstraints.isNotEmpty) {
      final value = table.overrideTableConstraints
          .map(asDartLiteral)
          .join(', ');

      buffer
        ..write('@override\n')
        ..write('List<String> get customConstraints => const [$value];\n');
    }

    if (!table.writeDefaultConstraints) {
      buffer
        ..write('@override\n')
        ..write('bool get dontWriteConstraints => true;\n');
    }

    if (table.isVirtual) {
      final stmt = table.virtualTableData!;
      final moduleAndArgs = asDartLiteral(stmt.moduleAndArgs);
      buffer
        ..write('@override\n')
        ..write('String get moduleAndArgs => $moduleAndArgs;\n');
    }
  }
}
