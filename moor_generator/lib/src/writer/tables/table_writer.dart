import 'package:moor_generator/moor_generator.dart';
import 'package:moor_generator/src/model/declarations/declaration.dart';
import 'package:moor_generator/src/utils/string_escaper.dart';
import 'package:moor_generator/writer.dart';
import 'package:sqlparser/sqlparser.dart';

class TableWriter {
  final MoorTable table;
  final Scope scope;

  StringBuffer _buffer;

  TableWriter(this.table, this.scope);

  bool get _skipVerification =>
      scope.writer.options.skipVerificationCode ||
      scope.generationOptions.isGeneratingForSchema;

  void writeInto() {
    if (!scope.generationOptions.isGeneratingForSchema) writeDataClass();
    writeTableInfoClass();
  }

  void writeDataClass() {
    DataClassWriter(table, scope.child()).write();
    UpdateCompanionWriter(table, scope.child()).write();
  }

  void writeTableInfoClass() {
    _buffer = scope.leaf();

    if (scope.generationOptions.isGeneratingForSchema) {
      // Write a small table header without data class
      _buffer.write('class ${table.tableInfoName} extends Table with '
          'TableInfo');
      if (table.isVirtualTable) {
        _buffer.write(', VirtualTableInfo');
      }
    } else {
      // Regular generation, write full table class
      final dataClass = table.dartTypeName;
      final tableDslName = table.fromClass?.name ?? 'Table';

      // class UsersTable extends Users implements TableInfo<Users, User> {
      final typeArgs = '<${table.tableInfoName}, $dataClass>';
      _buffer.write('class ${table.tableInfoName} extends $tableDslName with '
          'TableInfo$typeArgs ');

      if (table.isVirtualTable) {
        _buffer.write(', VirtualTableInfo$typeArgs ');
      }
    }

    _buffer
      ..write('{\n')
      // write a GeneratedDatabase reference that is set in the constructor
      ..write('final GeneratedDatabase _db;\n')
      ..write('final ${scope.nullableType('String')} _alias;\n')
      ..write('${table.tableInfoName}(this._db, [this._alias]);\n');

    // Generate the columns
    for (final column in table.columns) {
      _writeColumnVerificationMeta(column);
      _writeColumnGetter(column);
    }

    // Generate $columns, $tableName, asDslTable getters
    final columnsWithGetters =
        table.columns.map((c) => c.dartGetterName).join(', ');

    _buffer
      ..write('@override\nList<GeneratedColumn> get \$columns => '
          '[$columnsWithGetters];\n')
      ..write('@override\n${table.tableInfoName} get asDslTable => this;\n')
      ..write('@override\nString get \$tableName => '
          '_alias ?? \'${table.sqlName}\';\n')
      ..write(
          '@override\nfinal String actualTableName = \'${table.sqlName}\';\n');

    _writeValidityCheckMethod();
    _writePrimaryKeyOverride();

    _writeMappingMethod();
    // _writeReverseMappingMethod();

    _writeAliasGenerator();

    _writeConvertersAsStaticFields();
    _overrideFieldsIfNeeded();

    // close class
    _buffer.write('}');
  }

  void _writeConvertersAsStaticFields() {
    for (final converter in table.converters) {
      final typeName = converter.converterNameInCode(scope.generationOptions);
      final code = converter.expression;
      _buffer.write('static $typeName ${converter.fieldName} = $code;');
    }
  }

  void _writeMappingMethod() {
    if (scope.generationOptions.isGeneratingForSchema) {
      _buffer
        ..writeln('@override')
        ..writeln('Null map(Map<String, dynamic> data, '
            '{${scope.nullableType('String')} tablePrefix}) {')
        ..writeln('return null;')
        ..writeln('}');
      return;
    }

    final dataClassName = table.dartTypeName;

    _buffer
      ..write('@override\n$dataClassName map(Map<String, dynamic> data, '
          '{${scope.nullableType('String')} tablePrefix}) {\n')
      ..write('final effectivePrefix = '
          "tablePrefix != null ? '\$tablePrefix.' : null;")
      ..write('return $dataClassName.fromData'
          '(data, _db, prefix: effectivePrefix);\n')
      ..write('}\n');
  }

  void _writeColumnGetter(MoorColumn column) {
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
      ..write("('${column.name.name}', \$tableName, $isNullable, ");

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
      buffer: _buffer,
      getterName: column.dartGetterName,
      returnType: column.implColumnTypeName,
      code: expressionBuffer.toString(),
      // don't override on custom tables because we only override the column
      // when the base class is user defined
      hasOverride: !table.isFromSql,
      options: scope.generationOptions,
    );
  }

  void _writeColumnVerificationMeta(MoorColumn column) {
    if (!_skipVerification) {
      _buffer
        ..write('final VerificationMeta ${_fieldNameForColumnMeta(column)} = ')
        ..write("const VerificationMeta('${column.dartGetterName}');\n");
    }
  }

  void _writeValidityCheckMethod() {
    if (_skipVerification) return;

    _buffer
      ..write('@override\nVerificationContext validateIntegrity'
          '(Insertable<${table.dartTypeName}> instance, '
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
        _buffer.write(
            'context.handle($metaName, const VerificationResult.success());');
        continue;
      }

      final columnNameString = asDartLiteral(column.name.name);
      _buffer
        ..write('if (data.containsKey($columnNameString)) {\n')
        ..write('context.handle('
            '$metaName, '
            '$getterName.isAcceptableOrUnknown('
            'data[$columnNameString], $metaName));')
        ..write('}');

      if (table.isColumnRequiredForInsert(column)) {
        _buffer
          ..write(' else if (isInserting) {\n')
          ..write('context.missing($metaName);\n')
          ..write('}\n');
      }
    }
    _buffer.write('return context;\n}\n');
  }

  String _fieldNameForColumnMeta(MoorColumn column) {
    return '_${column.dartGetterName}Meta';
  }

  void _writePrimaryKeyOverride() {
    _buffer.write('@override\nSet<GeneratedColumn> get \$primaryKey => ');
    var primaryKey = table.fullPrimaryKey;

    // If there is an auto increment column, that forms the primary key. The
    // PK returned by table.primaryKey only contains column that have been
    // explicitly defined as PK, but with AI this happens implicitly.
    primaryKey ??= table.columns.where((c) => c.hasAI).toSet();

    if (primaryKey.isEmpty) {
      _buffer.write('<GeneratedColumn>{};');
      return;
    }

    _buffer.write('{');
    final pkList = primaryKey.toList();
    for (var i = 0; i < pkList.length; i++) {
      final pk = pkList[i];

      _buffer.write(pk.dartGetterName);
      if (i != pkList.length - 1) {
        _buffer.write(', ');
      }
    }
    _buffer.write('};\n');
  }

  void _writeAliasGenerator() {
    final typeName = table.tableInfoName;

    _buffer
      ..write('@override\n')
      ..write('$typeName createAlias(String alias) {\n')
      ..write('return $typeName(_db, alias);')
      ..write('}');
  }

  void _overrideFieldsIfNeeded() {
    if (table.overrideWithoutRowId != null) {
      final value = table.overrideWithoutRowId ? 'true' : 'false';
      _buffer
        ..write('@override\n')
        ..write('bool get withoutRowId => $value;\n');
    }

    if (table.overrideTableConstraints != null) {
      final value =
          table.overrideTableConstraints.map(asDartLiteral).join(', ');

      _buffer
        ..write('@override\n')
        ..write('List<String> get customConstraints => const [$value];\n');
    }

    if (table.overrideDontWriteConstraints != null) {
      final value = table.overrideDontWriteConstraints ? 'true' : 'false';
      _buffer
        ..write('@override\n')
        ..write('bool get dontWriteConstraints => $value;\n');
    }

    if (table.isVirtualTable) {
      final declaration = table.declaration as TableDeclarationWithSql;
      final stmt = declaration.creatingStatement as CreateVirtualTableStatement;
      final moduleAndArgs = asDartLiteral(
          '${stmt.moduleName}(${stmt.argumentContent.join(', ')})');
      _buffer
        ..write('@override\n')
        ..write('String get moduleAndArgs => $moduleAndArgs;\n');
    }
  }
}
