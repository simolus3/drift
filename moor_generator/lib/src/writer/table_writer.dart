import 'package:moor_generator/src/model/specified_column.dart';
import 'package:moor_generator/src/model/specified_table.dart';
import 'package:moor_generator/src/state/session.dart';
import 'package:moor_generator/src/utils/string_escaper.dart';
import 'package:moor_generator/src/writer/data_class_writer.dart';
import 'package:moor_generator/src/writer/update_companion_writer.dart';
import 'package:moor_generator/src/writer/utils.dart';

class TableWriter {
  final SpecifiedTable table;
  final GeneratorSession session;

  TableWriter(this.table, this.session);

  void writeInto(StringBuffer buffer) {
    writeDataClass(buffer);
    writeTableInfoClass(buffer);
  }

  void writeDataClass(StringBuffer buffer) {
    DataClassWriter(table, session).writeInto(buffer);
    UpdateCompanionWriter(table, session).writeInto(buffer);
  }

  void writeTableInfoClass(StringBuffer buffer) {
    final dataClass = table.dartTypeName;
    final tableDslName = table.fromClass?.name ?? 'Table';

    // class UsersTable extends Users implements TableInfo<Users, User> {
    buffer
      ..write('class ${table.tableInfoName} extends $tableDslName '
          'with TableInfo<${table.tableInfoName}, $dataClass> {\n')
      // should have a GeneratedDatabase reference that is set in the constructor
      ..write('final GeneratedDatabase _db;\n')
      ..write('final String _alias;\n')
      ..write('${table.tableInfoName}(this._db, [this._alias]);\n');

    // Generate the columns
    for (var column in table.columns) {
      _writeColumnVerificationMeta(buffer, column);
      _writeColumnGetter(buffer, column);
    }

    // Generate $columns, $tableName, asDslTable getters
    final columnsWithGetters =
        table.columns.map((c) => c.dartGetterName).join(', ');

    buffer
      ..write(
          '@override\nList<GeneratedColumn> get \$columns => [$columnsWithGetters];\n')
      ..write('@override\n${table.tableInfoName} get asDslTable => this;\n')
      ..write(
          '@override\nString get \$tableName => _alias ?? \'${table.sqlName}\';\n')
      ..write(
          '@override\nfinal String actualTableName = \'${table.sqlName}\';\n');

    _writeValidityCheckMethod(buffer);
    _writePrimaryKeyOverride(buffer);

    _writeMappingMethod(buffer);
    _writeReverseMappingMethod(buffer);

    _writeAliasGenerator(buffer);

    _writeConvertersAsStaticFields(buffer);
    _overrideFieldsIfNeeded(buffer);

    // close class
    buffer.write('}');
  }

  void _writeConvertersAsStaticFields(StringBuffer buffer) {
    for (var converter in table.converters) {
      final typeName = converter.typeOfConverter.displayName;
      final code = converter.expression.toSource();
      buffer..write('static $typeName ${converter.fieldName} = $code;');
    }
  }

  void _writeMappingMethod(StringBuffer buffer) {
    final dataClassName = table.dartTypeName;

    buffer
      ..write(
          '@override\n$dataClassName map(Map<String, dynamic> data, {String tablePrefix}) {\n')
      ..write(
          "final effectivePrefix = tablePrefix != null ? '\$tablePrefix.' : null;")
      ..write(
          'return $dataClassName.fromData(data, _db, prefix: effectivePrefix);\n')
      ..write('}\n');
  }

  void _writeReverseMappingMethod(StringBuffer buffer) {
    // Map<String, Variable> entityToSql(covariant UpdateCompanion<D> instance)
    buffer
      ..write('@override\nMap<String, Variable> entityToSql('
          '${table.updateCompanionName} d) {\n')
      ..write('final map = <String, Variable> {};');

    for (var column in table.columns) {
      buffer.write('if (d.${column.dartGetterName}.present) {');
      final mapSetter = 'map[${asDartLiteral(column.name.name)}] = '
          'Variable<${column.variableTypeName}, ${column.sqlTypeName}>';

      if (column.typeConverter != null) {
        // apply type converter before writing the variable
        final converter = column.typeConverter;
        final fieldName = '${table.tableInfoName}.${converter.fieldName}';
        buffer
          ..write('final converter = $fieldName;\n')
          ..write(mapSetter)
          ..write('(converter.mapToSql(d.${column.dartGetterName}.value));');
      } else {
        // no type converter. Write variable directly
        buffer
          ..write(mapSetter)
          ..write('(')
          ..write('d.${column.dartGetterName}.value')
          ..write(');');
      }

      buffer.write('}');
    }

    buffer.write('return map; \n}\n');
  }

  void _writeColumnGetter(StringBuffer buffer, SpecifiedColumn column) {
    final isNullable = column.nullable;
    final additionalParams = <String, String>{};
    final expressionBuffer = StringBuffer();

    for (var feature in column.features) {
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
      // GeneratedIntColumn('sql_name', tableName, isNullable, additionalField: true)
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
      buffer: buffer,
      getterName: column.dartGetterName,
      returnType: column.implColumnTypeName,
      code: expressionBuffer.toString(),
      // don't override on custom tables because we only override the column
      // when the base class is user defined
      hasOverride: !table.isFromSql,
    );
  }

  void _writeColumnVerificationMeta(
      StringBuffer buffer, SpecifiedColumn column) {
    // final VerificationMeta _targetDateMeta = const VerificationMeta('targetDate');
    buffer
      ..write('final VerificationMeta ${_fieldNameForColumnMeta(column)} = ')
      ..write("const VerificationMeta('${column.dartGetterName}');\n");
  }

  void _writeValidityCheckMethod(StringBuffer buffer) {
    buffer
      ..write('@override\nVerificationContext validateIntegrity'
          '(${table.updateCompanionName} d, {bool isInserting = false}) {\n')
      ..write('final context = VerificationContext();\n');

    for (var column in table.columns) {
      final getterName = column.dartGetterName;
      final metaName = _fieldNameForColumnMeta(column);

      if (column.typeConverter != null) {
        // dont't verify custom columns, we assume that the user knows what
        // they're doing
        buffer
          ..write(
              'context.handle($metaName, const VerificationResult.success());');
        continue;
      }

      buffer
        ..write('if (d.$getterName.present) {\n')
        ..write('context.handle('
            '$metaName, '
            '$getterName.isAcceptableValue(d.$getterName.value, $metaName));')
        ..write('} else if ($getterName.isRequired && isInserting) {\n')
        ..write('context.missing($metaName);\n')
        ..write('}\n');
    }
    buffer.write('return context;\n}\n');
  }

  String _fieldNameForColumnMeta(SpecifiedColumn column) {
    return '_${column.dartGetterName}Meta';
  }

  void _writePrimaryKeyOverride(StringBuffer buffer) {
    buffer.write('@override\nSet<GeneratedColumn> get \$primaryKey => ');
    var primaryKey = table.primaryKey;

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

  void _writeAliasGenerator(StringBuffer buffer) {
    final typeName = table.tableInfoName;

    buffer
      ..write('@override\n')
      ..write('$typeName createAlias(String alias) {\n')
      ..write('return $typeName(_db, alias);')
      ..write('}');
  }

  void _overrideFieldsIfNeeded(StringBuffer buffer) {
    if (table.overrideWithoutRowId != null) {
      final value = table.overrideWithoutRowId ? 'true' : 'false';
      buffer
        ..write('@override\n')
        ..write('final bool withoutRowId = $value;\n');
    }

    if (table.overrideTableConstraints != null) {
      final value =
          table.overrideTableConstraints.map(asDartLiteral).join(', ');

      buffer
        ..write('@override\n')
        ..write('final List<String> customConstraints = const [$value];\n');
    }

    if (table.overrideDontWriteConstraints != null) {
      final value = table.overrideDontWriteConstraints ? 'true' : 'false';
      buffer
        ..write('@override\n')
        ..write('final bool dontWriteConstraints = $value;\n');
    }
  }
}
