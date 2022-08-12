import 'package:drift_dev/moor_generator.dart';
import 'package:drift_dev/src/utils/string_escaper.dart';
import 'package:drift_dev/writer.dart';
import 'package:sqlparser/sqlparser.dart';

import '../utils/column_constraints.dart';

/// Common writer for tables or views.
///
/// Both classes need to generate column getters and a mapping function.
abstract class TableOrViewWriter {
  DriftEntityWithResultSet get tableOrView;
  StringBuffer get buffer;

  void writeColumnGetter(
      DriftColumn column, GenerationOptions options, bool isOverride) {
    final isNullable = column.nullable;
    final additionalParams = <String, String>{};
    final expressionBuffer = StringBuffer();
    final constraints = defaultConstraints(column);

    for (final feature in column.features) {
      if (feature is LimitingTextLength) {
        final buffer = StringBuffer('GeneratedColumn.checkTextLength(');

        if (feature.minLength != null) {
          buffer.write('minTextLength: ${feature.minLength},');
        }
        if (feature.maxLength != null) {
          buffer.write('maxTextLength: ${feature.maxLength}');
        }
        buffer.write(')');

        additionalParams['additionalChecks'] = buffer.toString();
      }

      if (feature is DartCheckExpression) {
        additionalParams['check'] = '() => ${feature.dartExpression}';
      }
    }

    additionalParams['type'] = column.type.toString();

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
      additionalParams['defaultValue'] = column.defaultArgument!;
    }

    if (column.clientDefaultCode != null) {
      additionalParams['clientDefault'] = column.clientDefaultCode!;
    }

    if (column.generatedAs != null) {
      final generateAs = column.generatedAs!;
      final code = generateAs.dartExpression;

      if (code != null) {
        additionalParams['generatedAs'] =
            'GeneratedAs($code, ${generateAs.stored})';
      }
    }

    final innerType = column.innerColumnType();
    var type = 'GeneratedColumn<$innerType>';
    expressionBuffer
      ..write(type)
      ..write(
          '(${asDartLiteral(column.name.name)}, aliasedName, $isNullable, ');

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
      final mappedType = converter.dartTypeCode(column.nullable);

      final converterCode =
          converter.tableAndField(forNullableColumn: column.nullable);

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
      getterName: column.dartGetterName,
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

    final dataClassName = tableOrView.dartTypeCode();

    final isAsync = tableOrView.existingRowClass?.isAsyncFactory == true;
    final returnType = isAsync ? 'Future<$dataClassName>' : dataClassName;
    final asyncModifier = isAsync ? 'async' : '';

    buffer
      ..write('@override $returnType map(Map<String, dynamic> data, '
          '{String? tablePrefix}) $asyncModifier {\n')
      ..write('final effectivePrefix = '
          "tablePrefix != null ? '\$tablePrefix.' : '';");

    if (tableOrView.hasExistingRowClass) {
      final info = tableOrView.existingRowClass!;
      final positionalToIndex = <DriftColumn, int>{};
      final named = <DriftColumn, String>{};

      final parameters = info.constructor.parameters;
      info.mapping.forEach((column, parameter) {
        if (parameter.isNamed) {
          named[column] = parameter.name;
        } else {
          positionalToIndex[column] = parameters.indexOf(parameter);
        }
      });

      // Sort positional columns by the position of their respective parameter
      // in the constructor.
      final positional = positionalToIndex.keys.toList()
        ..sort(
            (a, b) => positionalToIndex[a]!.compareTo(positionalToIndex[b]!));

      final writer = RowMappingWriter(
        positional: positional,
        named: named,
        table: tableOrView,
        options: scope.generationOptions,
        databaseGetter: 'attachedDatabase',
      );

      final classElement = info.targetClass;
      final ctor = info.constructor;
      buffer
        ..write('return ')
        ..write(isAsync ? 'await ' : '')
        ..write(classElement.name);
      if (ctor.name.isNotEmpty) {
        buffer
          ..write('.')
          ..write(ctor.name);
      }

      writer.writeArguments(buffer);
      buffer.write(';\n');
    } else {
      List<DriftColumn> columns;

      final view = tableOrView;
      if (view is MoorView && view.viewQuery != null) {
        columns = view.viewQuery!.columns.map((e) => e.value).toList();
      } else {
        columns = tableOrView.columns;
      }

      final writer = RowMappingWriter(
        positional: const [],
        named: {for (final column in columns) column: column.dartGetterName},
        table: tableOrView,
        options: scope.generationOptions,
        databaseGetter: 'attachedDatabase',
      );

      buffer.write('return ${tableOrView.dartTypeName}');
      writer.writeArguments(buffer);
      buffer.writeln(';');
    }

    buffer.write('}\n');
  }

  void writeGetColumnsOverride() {
    final columnsWithGetters =
        tableOrView.columns.map((c) => c.dartGetterName).join(', ');
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
  late StringBuffer buffer;

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
      UpdateCompanionWriter(table, scope.child()).write();
    }
  }

  void writeTableInfoClass() {
    buffer = scope.leaf();

    if (!scope.generationOptions.writeDataClasses) {
      // Write a small table header without data class
      buffer.write('class ${table.entityInfoName} extends Table with '
          'TableInfo');
      if (table.isVirtualTable) {
        buffer.write(', VirtualTableInfo');
      }
    } else {
      // Regular generation, write full table class
      final dataClass = table.dartTypeCode(scope.generationOptions);
      final tableDslName = table.fromClass?.name ?? 'Table';

      // class UsersTable extends Users implements TableInfo<Users, User> {
      final typeArgs = '<${table.entityInfoName}, $dataClass>';
      buffer.write('class ${table.entityInfoName} extends $tableDslName with '
          'TableInfo$typeArgs ');

      if (table.isVirtualTable) {
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
      writeColumnGetter(column, scope.generationOptions, !table.isFromSql);
    }

    // Generate $columns, $tableName, asDslTable getters
    writeGetColumnsOverride();
    buffer
      ..write('@override\nString get aliasedName => '
          '_alias ?? \'${table.sqlName}\';\n')
      ..write(
          '@override\n String get actualTableName => \'${table.sqlName}\';\n');

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
    for (final converter in table.converters) {
      final typeName = converter.converterNameInCode();
      final code = converter.expression;

      buffer.write('static $typeName ${converter.fieldName} = $code;');
    }

    // Generate wrappers for non-nullable type converters that are applied to
    // nullable converters.
    for (final column in table.columns) {
      final converter = column.typeConverter;
      if (converter != null &&
          converter.canBeSkippedForNulls &&
          column.nullable) {
        final nullableTypeName =
            converter.converterNameInCode(makeNullable: true);

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
        ..write("const VerificationMeta('${column.dartGetterName}');\n");
    }
  }

  void _writeValidityCheckMethod() {
    if (_skipVerification) return;

    final innerType = table.dartTypeCode(scope.generationOptions);
    buffer
      ..write('@override\nVerificationContext validateIntegrity'
          '(Insertable<$innerType> instance, '
          '{bool isInserting = false}) {\n')
      ..write('final context = VerificationContext();\n')
      ..write('final data = instance.toColumns(true);\n');

    const locals = {'instance', 'isInserting', 'context', 'data'};

    for (final column in table.columns) {
      final getterName = column.thisIfNeeded(locals);
      final metaName = _fieldNameForColumnMeta(column);

      if (column.typeConverter != null) {
        // dont't verify custom columns, we assume that the user knows what
        // they're doing
        buffer.write(
            'context.handle($metaName, const VerificationResult.success());');
        continue;
      }

      final columnNameString = asDartLiteral(column.name.name);
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
    return '_${column.dartGetterName}Meta';
  }

  void _writePrimaryKeyOverride() {
    buffer.write('@override\nSet<GeneratedColumn> get \$primaryKey => ');
    final primaryKey = table.fullPrimaryKey;

    if (primaryKey.isEmpty) {
      buffer.write('<GeneratedColumn>{};');
      return;
    }

    buffer.write('{');
    final pkList = primaryKey.toList();
    for (var i = 0; i < pkList.length; i++) {
      final pk = pkList[i];

      buffer.write(pk.dartGetterName);
      if (i != pkList.length - 1) {
        buffer.write(', ');
      }
    }
    buffer.write('};\n');
  }

  void _writeUniqueKeyOverride() {
    final uniqueKeys = table.uniqueKeys ?? [];
    if (uniqueKeys.isEmpty) {
      // We inherit from `TableInfo` which defaults this getter to an empty
      // list.
      return;
    }

    buffer.write('@override\nList<Set<GeneratedColumn>> get uniqueKeys => [');

    for (final uniqueKey in uniqueKeys) {
      buffer.write('{');
      final uqList = uniqueKey.toList();
      for (var i = 0; i < uqList.length; i++) {
        final pk = uqList[i];

        buffer.write(pk.dartGetterName);
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
    if (table.overrideWithoutRowId != null) {
      final value = table.overrideWithoutRowId! ? 'true' : 'false';
      buffer
        ..write('@override\n')
        ..write('bool get withoutRowId => $value;\n');
    }

    if (table.isStrict) {
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

    if (table.overrideDontWriteConstraints != null) {
      final value = table.overrideDontWriteConstraints! ? 'true' : 'false';
      buffer
        ..write('@override\n')
        ..write('bool get dontWriteConstraints => $value;\n');
    }

    if (table.isVirtualTable) {
      final declaration = table.declaration as TableDeclarationWithSql;
      final stmt = declaration.creatingStatement as CreateVirtualTableStatement;
      final moduleAndArgs = asDartLiteral(
          '${stmt.moduleName}(${stmt.argumentContent.join(', ')})');
      buffer
        ..write('@override\n')
        ..write('String get moduleAndArgs => $moduleAndArgs;\n');
    }
  }
}
