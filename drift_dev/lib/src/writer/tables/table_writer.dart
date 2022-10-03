import '../../analysis/results/results.dart';
import '../../utils/string_escaper.dart';
import '../utils/column_constraints.dart';
import '../utils/memoized_getter.dart';
import '../writer.dart';
import 'data_class_writer.dart';

/// Common writer for tables or views.
///
/// Both classes need to generate column getters and a mapping function.
abstract class TableOrViewWriter {
  DriftElementWithResultSet get tableOrView;
  TextEmitter get emitter;

  StringBuffer get buffer => emitter.buffer;

  void writeColumnGetter(DriftColumn column, bool isOverride) {
    final isNullable = column.nullable;
    final additionalParams = <String, String>{};
    final expressionBuffer = StringBuffer();
    final constraints = defaultConstraints(column);

    for (final constraint in column.constraints) {
      if (constraint is LimitingTextLength) {
        final buffer = StringBuffer('GeneratedColumn.checkTextLength(');

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
            'GeneratedAs($dartCode, ${constraint.stored})';
      }
    }

    additionalParams['type'] = column.sqlType.toString();

    if (tableOrView is DriftTable) {
      additionalParams['requiredDuringInsert'] = (tableOrView as DriftTable)
          .isColumnRequiredForInsert(column)
          .toString();
    }

    if (column.customConstraints != null) {
      additionalParams['\$customConstraints'] =
          asDartLiteral(column.customConstraints!);
    } else if (constraints.isNotEmpty) {
      // Use the default constraints supported by drift
      additionalParams['defaultConstraints'] = asDartLiteral(constraints);
    }

    if (column.defaultArgument != null) {
      additionalParams['defaultValue'] =
          emitter.dartCode(column.defaultArgument!);
    }

    if (column.clientDefaultCode != null) {
      additionalParams['clientDefault'] =
          emitter.dartCode(column.clientDefaultCode!);
    }

    final innerType = column.innerColumnType();
    var type = 'GeneratedColumn<$innerType>';
    expressionBuffer
      ..write(type)
      ..write(
          '(${asDartLiteral(column.nameInSql)}, aliasedName, $isNullable, ');

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
    if (converter != null) {
      // Generate a GeneratedColumnWithTypeConverter instance, as it has
      // additional methods to check for equality against a mapped value.
      final mappedType = emitter.dartCode(emitter.writer.dartType(column));

      final converterCode = emitter.dartCode(emitter.writer
          .readConverter(converter, forNullable: column.nullable));

      type = 'GeneratedColumnWithTypeConverter<$mappedType, $innerType>';
      expressionBuffer
        ..write('.withConverter<')
        ..write(mappedType)
        ..write('>(')
        ..write(converterCode)
        ..write(')');
    }

    writeMemoizedGetter(
      buffer: buffer,
      getterName: column.nameInDart,
      returnType: type,
      code: expressionBuffer.toString(),
      hasOverride: isOverride,
    );
  }

  void writeMappingMethod(Scope scope) {
    if (!scope.generationOptions.writeDataClasses) {
      buffer.writeln('''
        @override
        Never map(Map<String, dynamic> data, {$String? tablePrefix}) {
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
      ..write('@override $returnType map(Map<String, dynamic> data, '
          '{String? tablePrefix}) $asyncModifier {\n')
      ..write('final effectivePrefix = '
          "tablePrefix != null ? '\$tablePrefix.' : '';");

    if (tableOrView.hasExistingRowClass) {
      final info = tableOrView.existingRowClass!;

      final writer = RowMappingWriter(
        positional: [
          for (final positional in info.positionalColumns)
            tableOrView.columnBySqlName[positional]!
        ],
        named: info.namedColumns.map((dartParameter, columnName) {
          return MapEntry(
              tableOrView.columnBySqlName[columnName]!, dartParameter);
        }),
        table: tableOrView,
        writer: scope.writer,
        databaseGetter: 'attachedDatabase',
      );

      final ctor = info.constructor;
      emitter
        ..write('return ')
        ..write(isAsync ? 'await ' : '')
        ..writeDart(info.targetType);

      if (ctor.isNotEmpty) {
        buffer
          ..write('.')
          ..write(ctor);
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

  void writeGetColumnsOverride() {
    final columnsWithGetters =
        tableOrView.columns.map((c) => c.nameInDart).join(', ');
    buffer.write('@override\nList<GeneratedColumn> get \$columns => '
        '[$columnsWithGetters];\n');
  }

  void writeAsDslTable() {
    buffer.write(
        '@override\n${tableOrView.entityInfoName} get asDslTable => this;\n');
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
      scope.writer.options.skipVerificationCode ||
      scope.generationOptions.isGeneratingForSchema;

  void writeInto() {
    writeDataClass();
    writeTableInfoClass();
  }

  void writeDataClass() {
    if (!table.hasExistingRowClass &&
        scope.generationOptions.writeDataClasses) {
      DataClassWriter(table, scope.child()).write();
    }

    if (scope.generationOptions.writeCompanions) {
      //UpdateCompanionWriter(table, scope.child()).write();
    }
  }

  void writeTableInfoClass() {
    emitter = scope.leaf();

    if (!scope.generationOptions.writeDataClasses) {
      // Write a small table header without data class
      buffer.write('class ${table.entityInfoName} extends Table with '
          'TableInfo');
      if (table.isVirtual) {
        buffer.write(', VirtualTableInfo');
      }
    } else {
      // Regular generation, write full table class
      final dataClass = emitter.dartCode(emitter.writer.rowClass(table));
      final tableDslName = table.definingDartClass ?? 'Table';

      // class UsersTable extends Users implements TableInfo<Users, User> {
      final typeArgs = '<${table.entityInfoName}, $dataClass>';
      buffer.write('class ${table.entityInfoName} extends $tableDslName with '
          'TableInfo$typeArgs ');

      if (table.isVirtual) {
        buffer.write(', VirtualTableInfo$typeArgs ');
      }
    }

    buffer
      ..writeln('{')
      // write a GeneratedDatabase reference that is set in the constructor
      ..writeln('@override final GeneratedDatabase attachedDatabase;')
      ..writeln('final String? _alias;')
      ..writeln(
          '${table.entityInfoName}(this.attachedDatabase, [this._alias]);');

    // Generate the columns
    for (final column in table.columns) {
      _writeColumnVerificationMeta(column);
      // Only add an @override to a column getter if we're overriding the column
      // from a Dart DSL class.
      writeColumnGetter(column, table.id.isDefinedInDart);
    }

    // Generate $columns, $tableName, asDslTable getters
    writeGetColumnsOverride();
    buffer
      ..write('@override\nString get aliasedName => '
          '_alias ?? \'${table.id.name}\';\n')
      ..write(
          '@override\n String get actualTableName => \'${table.id.name}\';\n');

    _writeValidityCheckMethod();
    _writePrimaryKeyOverride();
    _writeUniqueKeyOverride();

    writeMappingMethod(scope);
    // _writeReverseMappingMethod();

    _writeAliasGenerator();

    _writeConvertersAsStaticFields();
    _overrideFieldsIfNeeded();

    // close class
    buffer.write('}');
  }

  void _writeConvertersAsStaticFields() {
    for (final converter in table.appliedConverters) {
      final typeName =
          emitter.dartCode(emitter.writer.converterType(converter));
      final code = converter.expression;

      buffer.write('static $typeName ${converter.fieldName} = $code;');

      // Generate wrappers for non-nullable type converters that are applied to
      // nullable converters.
      final column = converter.owningColumn;
      if (converter.canBeSkippedForNulls && column.nullable) {
        final nullableTypeName = emitter.dartCode(
            emitter.writer.converterType(converter, makeNullable: true));

        final wrap = converter.alsoAppliesToJsonConversion
            ? 'JsonTypeConverter.asNullable'
            : 'NullAwareTypeConverter.wrap';

        final code = '$wrap(${converter.fieldName})';

        buffer
            .write('static $nullableTypeName ${converter.nullableFieldName} = '
                '$code;');
      }
    }
  }

  void _writeColumnVerificationMeta(DriftColumn column) {
    if (!_skipVerification) {
      buffer
        ..write('final VerificationMeta ${_fieldNameForColumnMeta(column)} = ')
        ..write("const VerificationMeta('${column.nameInDart}');\n");
    }
  }

  void _writeValidityCheckMethod() {
    if (_skipVerification) return;

    final innerType = emitter.dartCode(emitter.writer.rowType(table));
    buffer
      ..write('@override\nVerificationContext validateIntegrity'
          '(Insertable<$innerType> instance, '
          '{bool isInserting = false}) {\n')
      ..write('final context = VerificationContext();\n')
      ..write('final data = instance.toColumns(true);\n');

    const locals = {'instance', 'isInserting', 'context', 'data'};

    for (final column in table.columns) {
      final getterName = thisIfNeeded(column.nameInDart, locals);
      final metaName = _fieldNameForColumnMeta(column);

      if (column.typeConverter != null) {
        // dont't verify custom columns, we assume that the user knows what
        // they're doing
        buffer.write(
            'context.handle($metaName, const VerificationResult.success());');
        continue;
      }

      final columnNameString = asDartLiteral(column.nameInSql);
      buffer
        ..write('if (data.containsKey($columnNameString)) {\n')
        ..write('context.handle('
            '$metaName, '
            '$getterName.isAcceptableOrUnknown('
            'data[$columnNameString]!, $metaName));')
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
    buffer.write('@override\nSet<GeneratedColumn> get \$primaryKey => ');
    final primaryKey = table.fullPrimaryKey;

    if (primaryKey.isEmpty) {
      buffer.write('const <GeneratedColumn>{};');
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
    final uniqueKeys =
        table.tableConstraints.whereType<UniqueColumns>().toList();

    if (uniqueKeys.isEmpty) {
      // We inherit from `TableInfo` which defaults this getter to an empty
      // list.
      return;
    }

    buffer.write('@override\nList<Set<GeneratedColumn>> get uniqueKeys => [');

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

    buffer
      ..write('@override\n')
      ..write('$typeName createAlias(String alias) {\n')
      ..write('return $typeName(attachedDatabase, alias);')
      ..write('}');
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

    if (table.overrideTableConstraints != null) {
      final value =
          table.overrideTableConstraints!.map(asDartLiteral).join(', ');

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
      final moduleAndArgs =
          asDartLiteral('${stmt.module}(${stmt.moduleArguments.join(', ')})');
      buffer
        ..write('@override\n')
        ..write('String get moduleAndArgs => $moduleAndArgs;\n');
    }
  }
}
