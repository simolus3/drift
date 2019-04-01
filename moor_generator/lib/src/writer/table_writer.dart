import 'package:moor_generator/src/model/specified_column.dart';
import 'package:moor_generator/src/model/specified_table.dart';
import 'package:moor_generator/src/writer/data_class_writer.dart';
import 'package:moor_generator/src/writer/utils.dart';

class TableWriter {
  final SpecifiedTable table;

  TableWriter(this.table);

  void writeInto(StringBuffer buffer) {
    writeDataClass(buffer);
    writeTableInfoClass(buffer);
  }

  void writeDataClass(StringBuffer buffer) {
    DataClassWriter(table).writeInto(buffer);
  }

  void writeTableInfoClass(StringBuffer buffer) {
    final dataClass = table.dartTypeName;
    final tableDslName = table.fromClass.name;

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

    // close class
    buffer.write('}');
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
    // Map<String, Variable> entityToSql(User d, {bool includeNulls = false) {
    buffer
      ..write('@override\nMap<String, Variable> entityToSql('
          '${table.dartTypeName} d, {bool includeNulls = false}) {\n')
      ..write('final map = <String, Variable> {};');

    for (var column in table.columns) {
      buffer.write('''
        if (d.${column.dartGetterName} != null || includeNulls) {
          map['${column.name.name}'] = Variable<${column.dartTypeName}, ${column.sqlTypeName}>(d.${column.dartGetterName});
        }
      ''');
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
      }
    }

    if (column.customConstraints != null) {
      // todo should we worry about escaping this string?
      additionalParams['\$customConstraints'] = "'${column.customConstraints}'";
    }

    if (column.defaultArgument != null) {
      additionalParams['defaultValue'] = column.defaultArgument.toSource();
    }

    // Handle aliasing
    expressionBuffer
      ..write("var cName = '${column.name.name}';\n")
      ..write("if (_alias != null) cName = '\$_alias.\$cName';\n")
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
      hasOverride: true,
    );
  }

  void _writeValidityCheckMethod(StringBuffer buffer) {
    final dataClass = table.dartTypeName;

    buffer.write(
        '@override\nbool validateIntegrity($dataClass instance, bool isInserting) => ');

    final validationCode = table.columns.map((column) {
      final getterName = column.dartGetterName;

      // generated columns have a isAcceptableValue(T value, bool duringInsert)
      // method

      return '$getterName.isAcceptableValue(instance.$getterName, isInserting)';
    }).join('&&');

    buffer..write(validationCode)..write(';\n');
  }

  void _writePrimaryKeyOverride(StringBuffer buffer) {
    buffer.write('@override\nSet<GeneratedColumn> get \$primaryKey => ');
    var primaryKey = table.primaryKey;

    // If there is an auto increment column, that forms the primary key. The
    // PK returned by table.primaryKey only contains column that have been
    // explicitly defined as PK, but with AI this happens implicitly.
    primaryKey ??= table.columns.where((c) => c.hasAI).toSet();

    if (primaryKey == null) {
      buffer.write('null;');
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
}
