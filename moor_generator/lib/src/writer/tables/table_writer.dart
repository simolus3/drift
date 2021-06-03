//@dart=2.9
import 'package:moor_generator/moor_generator.dart';
import 'package:moor_generator/src/model/declarations/declaration.dart';
import 'package:moor_generator/src/utils/string_escaper.dart';
import 'package:moor_generator/writer.dart';
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

    for (final feature in column.features) {
      if (feature is AutoIncrement) {
        additionalParams['hasAutoIncrement'] = 'true';
      } else if (feature is LimitingTextLength) {
        if (feature.minLength != null) {
          additionalParams['minTextLength'] = feature.minLength.toString();
        }
        if (feature.maxLength != null) {
          additionalParams['maxTextLength'] = feature.maxLength.toString();
        }
      } else if (feature is PrimaryKey && column.type == ColumnType.integer) {
        // this field is only relevant for integer columns because an INTEGER
        // PRIMARY KEY is an alias for the rowid which should allow absent
        // values during insert, even without the `AUTOINCREMENT` clause.
        additionalParams['declaredAsPrimaryKey'] = 'true';
      }
    }

    if (column.customConstraints != null) {
      additionalParams['\$customConstraints'] =
          asDartLiteral(column.customConstraints);
    }

    if (column.defaultArgument != null) {
      additionalParams['defaultValue'] = column.defaultArgument;
    }

    expressionBuffer
      ..write('return ${column.implColumnTypeName}')
      ..write("('${column.name.name}', aliasedName, $isNullable, ");

    var first = true;
    additionalParams.forEach((name, value) {
      if (!first) {
        expressionBuffer.write(', ');
      } else {
        first = false;
      }

      expressionBuffer..write(name)..write(': ')..write(value);
    });

    expressionBuffer.write(')');

    if (column.clientDefaultCode != null) {
      expressionBuffer.write('..clientDefault = ${column.clientDefaultCode}');
    }

    expressionBuffer.write(';');

    writeMemoizedGetterWithBody(
      buffer: buffer,
      getterName: column.dartGetterName,
      returnType: column.implColumnTypeName,
      code: expressionBuffer.toString(),
      hasOverride: isOverride,
      options: options,
    );
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
  StringBuffer buffer;

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
      final dataClass = table.dartTypeName;
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
      ..write('{\n')
      // write a GeneratedDatabase reference that is set in the constructor
      ..write('final GeneratedDatabase _db;\n')
      ..write('final ${scope.nullableType('String')} _alias;\n')
      ..write('${table.entityInfoName}(this._db, [this._alias]);\n');

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

    _writeMappingMethod();
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

  void _writeMappingMethod() {
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

    final dataClassName = table.dartTypeName;

    buffer.write('@override\n$dataClassName map(Map<String, dynamic> data, '
        '{${scope.nullableType('String')} tablePrefix}) {\n');

    if (table.hasExistingRowClass) {
      buffer.write('final effectivePrefix = '
          "tablePrefix != null ? '\$tablePrefix.' : '';");

      final info = table.existingRowClass;
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
        ..sort((a, b) => positionalToIndex[a].compareTo(positionalToIndex[b]));

      final writer = RowMappingWriter(
        positional,
        named,
        table,
        scope.generationOptions,
        dbName: '_db',
      );

      final classElement = info.targetClass;
      final ctor = info.constructor;
      buffer..write('return ')..write(classElement.name);
      if (ctor.name != null && ctor.name.isNotEmpty) {
        buffer..write('.')..write(ctor.name);
      }

      writer.writeArguments(buffer);
      buffer.write(';\n');
    } else {
      // Use default .fromData constructor in the moor-generated data class
      buffer.write('return $dataClassName.fromData(data, _db, '
          "prefix: tablePrefix != null ? '\$tablePrefix.' : null);\n");
    }

    buffer.write('}\n');
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

    buffer
      ..write('@override\nVerificationContext validateIntegrity'
          '(Insertable<${table.dartTypeName}> instance, '
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
    var primaryKey = table.fullPrimaryKey;

    // If there is an auto increment column, that forms the primary key. The
    // PK returned by table.primaryKey only contains column that have been
    // explicitly defined as PK, but with AI this happens implicitly.
    primaryKey ??= table.columns.where((c) => c.hasAI).toSet();

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

  void _writeAliasGenerator() {
    final typeName = table.entityInfoName;

    buffer
      ..write('@override\n')
      ..write('$typeName createAlias(String alias) {\n')
      ..write('return $typeName(_db, alias);')
      ..write('}');
  }

  void _overrideFieldsIfNeeded() {
    if (table.overrideWithoutRowId != null) {
      final value = table.overrideWithoutRowId ? 'true' : 'false';
      buffer..write('@override\n')..write('bool get withoutRowId => $value;\n');
    }

    if (table.overrideTableConstraints != null) {
      final value =
          table.overrideTableConstraints.map(asDartLiteral).join(', ');

      buffer
        ..write('@override\n')
        ..write('List<String> get customConstraints => super.customConstraints'
            ' + const [$value];\n');
    }

    if (table.overrideDontWriteConstraints != null) {
      final value = table.overrideDontWriteConstraints ? 'true' : 'false';
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
