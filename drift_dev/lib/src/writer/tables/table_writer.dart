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
      isRequiredForInsert =
          (tableOrView as DriftTable).isColumnRequiredForInsert(column);
    }

    final (type, expression) = instantiateColumn(
      column,
      emitter,
      isRequiredForInsert: isRequiredForInsert,
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
    for (final converter in tableOrView.appliedConverters) {
      if (converter.owningColumn?.owner != tableOrView) continue;

      final typeName =
          emitter.dartCode(emitter.writer.converterType(converter));
      final code = emitter.dartCode(converter.expression);

      buffer.write('static $typeName ${converter.fieldName} = $code;');

      // Generate wrappers for non-nullable type converters that are applied to
      // nullable converters.
      final column = converter.owningColumn!;
      if (converter.canBeSkippedForNulls && column.nullable) {
        final nullableTypeName = emitter.dartCode(
            emitter.writer.converterType(converter, makeNullable: true));

        final wrap = converter.alsoAppliesToJsonConversion
            ? emitter.drift('JsonTypeConverter2.asNullable')
            : emitter.drift('NullAwareTypeConverter.wrap');

        final code = '$wrap(${converter.fieldName})';

        buffer
            .write('static $nullableTypeName ${converter.nullableFieldName} = '
                '$code;');
      }
    }
  }

  void writeMappingMethod(Scope scope) {
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
        ..write(isAsync ? 'await ' : '');
      if (!info.isRecord) {
        // Write the constructor or async mapping method for this existing row
        // class. It will later be invoked by writing the arguments below.
        // For records, the argument syntax is already a valid record literal.
        emitter.writeDart(AnnotatedDartCode.type(info.targetType));

        if (ctor.isNotEmpty) {
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

  void writeGetColumnsOverride() {
    final columnsWithGetters =
        tableOrView.columns.map((c) => c.nameInDart).join(', ');
    buffer.write(
        '@override\nList<${emitter.drift('GeneratedColumn')}> get \$columns => '
        '[$columnsWithGetters];\n');
  }

  void writeAsDslTable() {
    buffer.write(
        '@override\n${tableOrView.entityInfoName} get asDslTable => this;\n');
  }

  /// Returns the Dart type and the Dart expression creating a `GeneratedColumn`
  /// instance in drift for the given [column].
  static (String, String) instantiateColumn(
    DriftColumn column,
    TextEmitter emitter, {
    bool? isRequiredForInsert,
  }) {
    final isNullable = column.nullable;
    final additionalParams = <String, String>{};
    final expressionBuffer = StringBuffer();
    final constraints = defaultConstraints(column);

    // Remove dialect-specific constraints for dialects we don't care about.
    constraints.removeWhere(
        (key, _) => !emitter.writer.options.supportedDialects.contains(key));

    for (final constraint in column.constraints) {
      if (constraint is LimitingTextLength) {
        final buffer =
            StringBuffer(emitter.drift('GeneratedColumn.checkTextLength('));

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

    if (column.sqlType.isCustom) {
      additionalParams['type'] =
          emitter.dartCode(column.sqlType.custom!.expression);
    } else {
      additionalParams['type'] =
          emitter.drift(column.sqlType.builtin.toString());
    }

    if (isRequiredForInsert != null) {
      additionalParams['requiredDuringInsert'] = isRequiredForInsert.toString();
    }

    if (column.customConstraints != null) {
      additionalParams['\$customConstraints'] =
          asDartLiteral(column.customConstraints!);
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
      additionalParams['defaultValue'] =
          emitter.dartCode(column.defaultArgument!);
    }

    if (column.clientDefaultCode != null) {
      additionalParams['clientDefault'] =
          emitter.dartCode(column.clientDefaultCode!);
    }

    final innerType = emitter.innerColumnType(column.sqlType);
    var type =
        '${emitter.drift('GeneratedColumn')}<${emitter.dartCode(innerType)}>';
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

      type = '${emitter.drift('GeneratedColumnWithTypeConverter')}'
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
      buffer
        ..write('class ${table.entityInfoName} extends ')
        ..write(emitter.drift('Table'))
        ..write(' with ')
        ..write(emitter.drift('TableInfo'));
      if (table.isVirtual) {
        buffer.write(', ${emitter.drift('VirtualTableInfo')}');
      }
    } else {
      // Regular generation, write full table class
      final dataClass = emitter.dartCode(emitter.writer.rowType(table));
      final tableDslName = table.definingDartClass ??
          AnnotatedDartCode.importedSymbol(AnnotatedDartCode.drift, 'Table');

      // class UsersTable extends Users implements TableInfo<Users, User> {
      final typeArgs = '<${table.entityInfoName}, $dataClass>';

      emitter
        ..write('class ${table.entityInfoName} extends ')
        ..writeDart(tableDslName)
        ..write(' with ')
        ..writeDart(AnnotatedDartCode.importedSymbol(
            AnnotatedDartCode.drift, 'TableInfo'))
        ..write(typeArgs);

      if (table.isVirtual) {
        buffer.write(', ${emitter.drift('VirtualTableInfo')}$typeArgs ');
      }
    }

    buffer
      ..writeln('{')
      // write a GeneratedDatabase reference that is set in the constructor
      ..writeln(
          '@override final ${emitter.drift('GeneratedDatabase')} attachedDatabase;')
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
          '_alias ?? actualTableName;\n')
      ..write('@override\n String get actualTableName => \$name;\n')
      ..write('static const String \$name = \'${table.id.name}\';\n');

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
    buffer.write('mixin ${table.baseDartName}ToColumns ');

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

  void _writeColumnVerificationMeta(DriftColumn column) {
    if (!_skipVerification) {
      final meta = emitter.drift('VerificationMeta');

      buffer
        ..write('static const $meta ${_fieldNameForColumnMeta(column)} = ')
        ..writeln("const $meta('${column.nameInDart}');");
    }
  }

  void _writeValidityCheckMethod() {
    if (_skipVerification) return;

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

      if (column.typeConverter != null) {
        // dont't verify custom columns, we assume that the user knows what
        // they're doing
        buffer.write('context.handle($metaName, '
            'const ${emitter.drift('VerificationResult')}.success());');
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
    buffer.write(
        '@override\nSet<${emitter.drift('GeneratedColumn')}> get \$primaryKey => ');
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
    final uniqueKeys =
        table.tableConstraints.whereType<UniqueColumns>().toList();

    if (uniqueKeys.isEmpty) {
      // We inherit from `TableInfo` which defaults this getter to an empty
      // list.
      return;
    }

    buffer.write('@override\nList<Set<${emitter.drift('GeneratedColumn')}>> '
        'get uniqueKeys => [');

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

    // For Dart tables, the user already overrides the `customConstraints`
    // getter in the source. So, since we extend that class by default, there's
    // no need to override them again.
    final writeTableConstraints = table.definingDartClass == null ||
        scope.generationOptions.forSchema != null;
    if (writeTableConstraints && table.overrideTableConstraints.isNotEmpty) {
      final value =
          table.overrideTableConstraints.map(asDartLiteral).join(', ');

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
