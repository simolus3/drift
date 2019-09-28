import 'package:moor_generator/src/analyzer/runner/steps.dart';
import 'package:moor_generator/src/analyzer/sql_queries/meta/declarations.dart';
import 'package:moor_generator/src/analyzer/sql_queries/type_mapping.dart';
import 'package:moor_generator/src/model/specified_column.dart';
import 'package:moor_generator/src/model/specified_table.dart';
import 'package:moor_generator/src/model/used_type_converter.dart';
import 'package:moor_generator/src/utils/names.dart';
import 'package:moor_generator/src/utils/string_escaper.dart';
import 'package:recase/recase.dart';
import 'package:sqlparser/sqlparser.dart';

class CreateTableReader {
  /// The AST of this `CREATE TABLE` statement.
  final CreateTableStatement stmt;
  final Step step;

  CreateTableReader(this.stmt, this.step);

  SpecifiedTable extractTable(TypeMapper mapper) {
    final table = SchemaFromCreateTable().read(stmt);

    final foundColumns = <String, SpecifiedColumn>{};
    final primaryKey = <SpecifiedColumn>{};

    for (var column in table.resolvedColumns) {
      var isPrimaryKey = false;
      final features = <ColumnFeature>[];
      final sqlName = column.name;
      final dartName = ReCase(sqlName).camelCase;
      final constraintWriter = StringBuffer();
      final moorType = mapper.resolvedToMoor(column.type);
      UsedTypeConverter converter;
      String defaultValue;

      for (var constraint in column.constraints) {
        if (constraint is PrimaryKeyColumn) {
          isPrimaryKey = true;
          features.add(const PrimaryKey());
          if (constraint.autoIncrement) {
            features.add(AutoIncrement());
          }
        }
        if (constraint is Default) {
          final dartType = dartTypeNames[moorType];
          final sqlType = sqlTypes[moorType];
          final expressionName = 'const CustomExpression<$dartType, $sqlType>';
          final sqlDefault = constraint.expression.span.text;
          defaultValue = '$expressionName(${asDartLiteral(sqlDefault)})';
        }

        if (constraint is MappedBy) {
          converter = _readTypeConverter(constraint);
          // don't write MAPPED BY constraints when creating the table
          continue;
        }

        if (constraintWriter.isNotEmpty) {
          constraintWriter.write(' ');
        }
        constraintWriter.write(constraint.span.text);
      }

      final parsed = SpecifiedColumn(
        type: moorType,
        nullable: column.type.nullable,
        dartGetterName: dartName,
        name: ColumnName.implicitly(sqlName),
        features: features,
        customConstraints: constraintWriter.toString(),
        defaultArgument: defaultValue,
        typeConverter: converter,
      );

      final declaration =
          ColumnDeclaration(parsed, step.file, null, column.definition);
      parsed.declaration = declaration;

      foundColumns[column.name] = parsed;
      if (isPrimaryKey) {
        primaryKey.add(parsed);
      }
    }

    final tableName = table.name;
    final dartTableName = ReCase(tableName).pascalCase;
    final dataClassName = stmt.overriddenDataClassName ??
        dataClassNameForClassName(dartTableName);

    final constraints = table.tableConstraints.map((c) => c.span.text).toList();

    for (var keyConstraint in table.tableConstraints.whereType<KeyClause>()) {
      if (keyConstraint.isPrimaryKey) {
        primaryKey.addAll(keyConstraint.indexedColumns
            .map((r) => foundColumns[r.columnName])
            .where((c) => c != null));
      }
    }

    final specifiedTable = SpecifiedTable(
      fromClass: null,
      columns: foundColumns.values.toList(),
      sqlName: table.name,
      dartTypeName: dataClassName,
      overriddenName: dartTableName,
      primaryKey: primaryKey,
      overrideWithoutRowId: table.withoutRowId ? true : null,
      overrideTableConstraints: constraints.isNotEmpty ? constraints : null,
      // we take care of writing the primary key ourselves
      overrideDontWriteConstraints: true,
    );

    return specifiedTable
      ..declaration =
          TableDeclaration(specifiedTable, step.file, null, table.definition);
  }

  UsedTypeConverter _readTypeConverter(MappedBy mapper) {
    // todo we need to somehow parse the dart expression and check types
    return null;
  }
}
