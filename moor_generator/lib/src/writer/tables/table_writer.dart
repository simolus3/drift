import 'package:moor_generator/src/model/specified_column.dart';
import 'package:moor_generator/src/model/specified_table.dart';
import 'package:moor_generator/src/utils/string_escaper.dart';
import 'package:moor_generator/src/writer/tables/data_class_writer.dart';
import 'package:moor_generator/src/writer/tables/update_companion_writer.dart';
import 'package:moor_generator/src/writer/utils/memoized_getter.dart';
import 'package:moor_generator/src/writer/writer.dart';
import 'package:sqlparser/sqlparser.dart';

class TableWriter {
  final SpecifiedTable table;
  final Scope scope;

  StringBuffer _buffer;

  TableWriter(this.table, this.scope);

  void writeInto() {
    writeDataClass();
    writeTableInfoClass();
  }

  void writeDataClass() {
    DataClassWriter(table, scope.child()).write();
    UpdateCompanionWriter(table, scope.child()).write();
  }

  void writeTableInfoClass() {
    _buffer = scope.leaf();

    final dataClass = table.dartTypeName;
    final tableDslName = table.fromClass?.name ?? 'Table';

    // class UsersTable extends Users implements TableInfo<Users, User> {
    final typeArgs = '<${table.tableInfoName}, $dataClass>';
    _buffer.write('class ${table.tableInfoName} extends $tableDslName with '
        'TableInfo$typeArgs ');
    if (table.isVirtualTable) {
      _buffer.write(', VirtualTableInfo$typeArgs ');
    }
    _buffer
      ..write('{\n')
      // write a GeneratedDatabase reference that is set in the constructor
      ..write('final GeneratedDatabase _db;\n')
      ..write('final String _alias;\n')
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
    _writeReverseMappingMethod();

    _writeAliasGenerator();

    _writeConvertersAsStaticFields();
    _overrideFieldsIfNeeded();

    // close class
    _buffer.write('}');
  }

  void _writeConvertersAsStaticFields() {
    for (final converter in table.converters) {
      final typeName = converter.typeOfConverter.displayName;
      final code = converter.expression.toSource();
      _buffer.write('static $typeName ${converter.fieldName} = $code;');
    }
  }

  void _writeMappingMethod() {
    final dataClassName = table.dartTypeName;

    _buffer
      ..write('@override\n$dataClassName map(Map<String, dynamic> data, '
          '{String tablePrefix}) {\n')
      ..write('final effectivePrefix = '
          "tablePrefix != null ? '\$tablePrefix.' : null;")
      ..write('return $dataClassName.fromData'
          '(data, _db, prefix: effectivePrefix);\n')
      ..write('}\n');
  }

  void _writeReverseMappingMethod() {
    // Map<String, Variable> entityToSql(covariant UpdateCompanion<D> instance)
    _buffer
      ..write('@override\nMap<String, Variable> entityToSql('
          '${table.getNameForCompanionClass(scope.options)} d) {\n')
      ..write('final map = <String, Variable> {};');

    for (final column in table.columns) {
      _buffer.write('if (d.${column.dartGetterName}.present) {');
      final mapSetter = 'map[${asDartLiteral(column.name.name)}] = '
          'Variable<${column.variableTypeName}, ${column.sqlTypeName}>';

      if (column.typeConverter != null) {
        // apply type converter before writing the variable
        final converter = column.typeConverter;
        final fieldName = '${table.tableInfoName}.${converter.fieldName}';
        _buffer
          ..write('final converter = $fieldName;\n')
          ..write(mapSetter)
          ..write('(converter.mapToSql(d.${column.dartGetterName}.value));');
      } else {
        // no type converter. Write variable directly
        _buffer
          ..write(mapSetter)
          ..write('(')
          ..write('d.${column.dartGetterName}.value')
          ..write(');');
      }

      _buffer.write('}');
    }

    _buffer.write('return map; \n}\n');
  }

  void _writeColumnGetter(SpecifiedColumn column) {
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

    expressionBuffer.write(');');

    writeMemoizedGetterWithBody(
      buffer: _buffer,
      getterName: column.dartGetterName,
      returnType: column.implColumnTypeName,
      code: expressionBuffer.toString(),
      // don't override on custom tables because we only override the column
      // when the base class is user defined
      hasOverride: !table.isFromSql,
    );
  }

  void _writeColumnVerificationMeta(SpecifiedColumn column) {
    if (!scope.writer.options.skipVerificationCode) {
      _buffer
        ..write('final VerificationMeta ${_fieldNameForColumnMeta(column)} = ')
        ..write("const VerificationMeta('${column.dartGetterName}');\n");
    }
  }

  void _writeValidityCheckMethod() {
    if (scope.writer.options.skipVerificationCode) return;

    _buffer
      ..write('@override\nVerificationContext validateIntegrity'
          '(${table.getNameForCompanionClass(scope.options)} d, '
          '{bool isInserting = false}) {\n')
      ..write('final context = VerificationContext();\n');

    for (final column in table.columns) {
      final getterName = column.dartGetterName;
      final metaName = _fieldNameForColumnMeta(column);

      if (column.typeConverter != null) {
        // dont't verify custom columns, we assume that the user knows what
        // they're doing
        _buffer.write(
            'context.handle($metaName, const VerificationResult.success());');
        continue;
      }

      _buffer
        ..write('if (d.$getterName.present) {\n')
        ..write('context.handle('
            '$metaName, '
            '$getterName.isAcceptableValue(d.$getterName.value, $metaName));')
        ..write('} else if ($getterName.isRequired && isInserting) {\n')
        ..write('context.missing($metaName);\n')
        ..write('}\n');
    }
    _buffer.write('return context;\n}\n');
  }

  String _fieldNameForColumnMeta(SpecifiedColumn column) {
    return '_${column.dartGetterName}Meta';
  }

  void _writePrimaryKeyOverride() {
    _buffer.write('@override\nSet<GeneratedColumn> get \$primaryKey => ');
    var primaryKey = table.primaryKey;

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
      final stmt =
          table.declaration.moorDeclaration as CreateVirtualTableStatement;
      final moduleAndArgs = asDartLiteral(
          '${stmt.moduleName}(${stmt.argumentContent.join(', ')})');
      _buffer
        ..write('@override\n')
        ..write('String get moduleAndArgs => $moduleAndArgs;\n');
    }
  }
}
