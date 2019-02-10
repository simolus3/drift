import 'package:recase/recase.dart';
import 'package:sally_generator/src/model/specified_table.dart';
import 'package:sally_generator/src/writer/data_class_writer.dart';

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
          'implements TableInfo<$tableDslName, $dataClass> {\n')
      // should have a GeneratedDatabase reference that is set in the constructor
      ..write('final GeneratedDatabase db;\n')
      ..write('${table.tableInfoName}(this.db);\n');

    // Generate the columns
    for (var column in table.columns) {
      final isNullable = false;

      // @override
      // GeneratedIntColumn get id => GeneratedIntColumn('sql_name', isNullable);
      buffer
        ..write('@override \n')
        ..write('${column.implColumnTypeName} get ${column.dartGetterName} => '
            '${column.implColumnTypeName}(\'${column.name.name}\', $isNullable);\n');
    }

    // Generate $columns, $tableName, asDslTable getters
    final columnsWithGetters =
        table.columns.map((c) => c.dartGetterName).join(', ');

    buffer
      ..write(
          '@override\nList<GeneratedColumn> get \$columns => [$columnsWithGetters];\n')
      ..write('@override\n$tableDslName get asDslTable => this;\n')
      ..write('@override\nString get \$tableName => \'${table.sqlName}\';\n');

    // todo replace set syntax with literal once dart supports it
    // write primary key getter: Set<Column> get $primaryKey => Set().add(id);
    final primaryKeyColumns = table.primaryKey.map((c) => c.dartGetterName);
    buffer.write('@override\nSet<GeneratedColumn> get \$primaryKey => Set()');
    for (var pkColumn in primaryKeyColumns) {
      buffer.write('..add($pkColumn)');
    }
    buffer.write('\n;');

    _writeMappingMethod(buffer);

    // close class
    buffer.write('}');
  }

  void _writeMappingMethod(StringBuffer buffer) {
    final dataClassName = table.dartTypeName;

    buffer
        .write('@override\n$dataClassName map(Map<String, dynamic> data) {\n');

    final dartTypeToResolver = <String, String>{};

    final types = table.columns.map((c) => c.dartTypeName).toSet();
    for (var usedType in types) {
      // final intType = db.typeSystem.forDartType<int>();
      final resolver = '${ReCase(usedType).camelCase}Type';
      dartTypeToResolver[usedType] = resolver;

      buffer
          .write('final $resolver = db.typeSystem.forDartType<$usedType>();\n');
    }

    // finally, the mighty constructor invocation:
    buffer.write('return $dataClassName(');

    for (var column in table.columns) {
      // id: intType.mapFromDatabaseResponse(data["id])
      final getter = column.dartGetterName;
      final resolver = dartTypeToResolver[column.dartTypeName];
      final typeParser =
          '$resolver.mapFromDatabaseResponse(data[\'${column.name.name}\'])';

      buffer.write('$getter: $typeParser,');
    }

    buffer.write(');}\n');
  }
}
