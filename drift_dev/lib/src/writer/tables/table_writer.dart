import 'package:drift/sqlite_keywords.dart';
import 'package:drift_dev/moor_generator.dart';
import 'package:drift_dev/src/utils/string_escaper.dart';
import 'package:drift_dev/writer.dart';
import 'package:sqlparser/sqlparser.dart';

/// Common writer for tables or views.
///
/// Both classes need to generate column getters and a mapping function.
abstract class TableOrViewWriter {
  MoorEntityWithResultSet get tableOrView;
  StringBuffer get buffer;

  void writeColumnGetter(
      MoorColumn column, GenerationOptions options, bool isOverride) {
    final isNullable = column.nullable;
    final additionalParams = <String, String>{};
    final expressionBuffer = StringBuffer();

    final defaultConstraints = <String>[];
    var wrotePkConstraint = false;

    for (final feature in column.features) {
      if (feature is PrimaryKey) {
        if (!wrotePkConstraint) {
          defaultConstraints.add(feature is AutoIncrement
              ? 'PRIMARY KEY AUTOINCREMENT'
              : 'PRIMARY KEY');

          wrotePkConstraint = true;
          break;
        }
      }
    }

    if (!wrotePkConstraint) {
      for (final feature in column.features) {
        if (feature is UniqueKey) {
          defaultConstraints.add('UNIQUE');
          break;
        }
      }
    }

    for (final feature in column.features) {
      if (feature is ResolvedDartForeignKeyReference) {
        final tableName = escapeIfNeeded(feature.otherTable.sqlName);
        final columnName = escapeIfNeeded(feature.otherColumn.name.name);

        var constraint = 'REFERENCES $tableName ($columnName)';

        final onUpdate = feature.onUpdate;
        final onDelete = feature.onDelete;

        if (onUpdate != null) {
          constraint = '$constraint ON UPDATE ${onUpdate.description}';
        }

        if (onDelete != null) {
          constraint = '$constraint ON DELETE ${onDelete.description}';
        }

        defaultConstraints.add(constraint);
      }

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
    }

    if (column.type == ColumnType.boolean) {
      final name = escapeIfNeeded(column.name.name);
      defaultConstraints.add('CHECK ($name IN (0, 1))');
    }
    additionalParams['type'] = 'const ${column.sqlType().runtimeType}()';

    if (tableOrView is MoorTable) {
      additionalParams['requiredDuringInsert'] = (tableOrView as MoorTable)
          .isColumnRequiredForInsert(column)
          .toString();
    }

    if (column.customConstraints != null) {
      additionalParams['\$customConstraints'] =
          asDartLiteral(column.customConstraints!);
    } else if (defaultConstraints.isNotEmpty) {
      // Use the default constraints supported by moor
      additionalParams['defaultConstraints'] =
          asDartLiteral(defaultConstraints.join(' '));
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

    final innerType = column.innerColumnType(options);
    var type = 'GeneratedColumn<$innerType>';
    expressionBuffer
      ..write(type)
      ..write("('${column.name.name}', aliasedName, $isNullable, ");

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
      final mappedType = converter.mappedType.codeString(options);
      type = 'GeneratedColumnWithTypeConverter<$mappedType, $innerType>';
      expressionBuffer
        ..write('.withConverter<')
        ..write(mappedType)
        ..write('>(')
        ..write(converter.tableAndField)
        ..write(')');
    }

    writeMemoizedGetter(
      buffer: buffer,
      getterName: column.dartGetterName,
      returnType: type,
      code: expressionBuffer.toString(),
      options: options,
      hasOverride: isOverride,
    );
  }

  void writeMappingMethod(Scope scope) {
    if (!scope.generationOptions.writeDataClasses) {
      final nullableString = scope.nullableType('String');
      buffer.writeln('''
        @override
        Never map(Map<String, dynamic> data, {$nullableString tablePrefix}) {
          throw UnsupportedError('TableInfo.map in schema verification code');
        }
      ''');
      return;
    }

    final dataClassName = tableOrView.dartTypeCode(scope.generationOptions);

    buffer.write('@override\n$dataClassName map(Map<String, dynamic> data, '
        '{${scope.nullableType('String')} tablePrefix}) {\n');

    if (tableOrView.hasExistingRowClass) {
      buffer.write('final effectivePrefix = '
          "tablePrefix != null ? '\$tablePrefix.' : '';");

      final info = tableOrView.existingRowClass!;
      final positionalToIndex = <MoorColumn, int>{};
      final named = <MoorColumn, String>{};

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
        positional,
        named,
        tableOrView,
        scope.generationOptions,
        scope.options,
      );

      final classElement = info.targetClass;
      final ctor = info.constructor;
      buffer
        ..write('return ')
        ..write(classElement.name);
      if (ctor.name.isNotEmpty) {
        buffer
          ..write('.')
          ..write(ctor.name);
      }

      writer.writeArguments(buffer);
      buffer.write(';\n');
    } else {
      // Use default .fromData constructor in the moor-generated data class
      final hasDbParameter = scope.generationOptions.writeForMoorPackage &&
          tableOrView is MoorTable;
      if (hasDbParameter) {
        buffer.write('return $dataClassName.fromData(data, attachedDatabase, '
            "prefix: tablePrefix != null ? '\$tablePrefix.' : null);\n");
      } else {
        buffer.write('return $dataClassName.fromData(data, '
            "prefix: tablePrefix != null ? '\$tablePrefix.' : null);\n");
      }
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
  final MoorTable table;
  final Scope scope;

  @override
  late StringBuffer buffer;

  @override
  MoorTable get tableOrView => table;

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
      ..writeln('final ${scope.nullableType('String')} _alias;')
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
      final typeName = converter.converterNameInCode(scope.generationOptions);
      final code = converter.expression;
      buffer.write('static $typeName ${converter.fieldName} = $code;');
    }
  }

  void _writeColumnVerificationMeta(MoorColumn column) {
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

    final nonNullAssert = scope.generationOptions.nnbd ? '!' : '';

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
            'data[$columnNameString]$nonNullAssert, $metaName));')
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

  String _fieldNameForColumnMeta(MoorColumn column) {
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
    buffer.write('@override\nSet<GeneratedColumn> get \$uniqueKey => ');
    final uniqueKey = table.uniqueKey ?? {};

    if (uniqueKey.isEmpty) {
      buffer.write('<GeneratedColumn>{};');
      return;
    }

    buffer.write('{');
    final uqList = uniqueKey.toList();
    for (var i = 0; i < uqList.length; i++) {
      final pk = uqList[i];

      buffer.write(pk.dartGetterName);
      if (i != uqList.length - 1) {
        buffer.write(', ');
      }
    }
    buffer.write('};\n');
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

extension on ReferenceAction {
  String get description {
    switch (this) {
      case ReferenceAction.setNull:
        return 'SET NULL';
      case ReferenceAction.setDefault:
        return 'SET DEFAULT';
      case ReferenceAction.cascade:
        return 'CASCADE';
      case ReferenceAction.restrict:
        return 'RESTRICT';
      case ReferenceAction.noAction:
        return 'NO ACTION';
    }
  }
}
