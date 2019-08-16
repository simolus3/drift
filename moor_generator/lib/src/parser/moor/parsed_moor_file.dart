import 'package:moor_generator/src/model/specified_column.dart';
import 'package:moor_generator/src/model/specified_table.dart';
import 'package:moor_generator/src/parser/sql/type_mapping.dart';
import 'package:moor_generator/src/utils/names.dart';
import 'package:moor_generator/src/utils/string_escaper.dart';
import 'package:recase/recase.dart';
import 'package:sqlparser/sqlparser.dart';

/*
We're in the process of defining what a .moor file could actually look like.
At the moment, we only support "CREATE TABLE" statements:
``` // content of a .moor file
CREATE TABLE users (
  id INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL,
)
```

In the future, we'd also like to support
- import statements between moor files
- import statements from moor files referencing tables declared via the Dart DSL
- declaring statements in these files, similar to how compiled statements work
  with the annotation.
 */

class ParsedMoorFile {
  final List<CreateTable> declaredTables;

  ParsedMoorFile(this.declaredTables);
}

class CreateTable {
  /// The AST of this `CREATE TABLE` statement.
  final ParseResult ast;

  SpecifiedTable extractTable(TypeMapper mapper) {
    final table =
        SchemaFromCreateTable().read(ast.rootNode as CreateTableStatement);

    final foundColumns = <String, SpecifiedColumn>{};
    final primaryKey = <SpecifiedColumn>{};

    for (var column in table.resolvedColumns) {
      var isPrimaryKey = false;
      final features = <ColumnFeature>[];
      final sqlName = column.name;
      final dartName = ReCase(sqlName).camelCase;
      final constraintWriter = StringBuffer();
      final moorType = mapper.resolvedToMoor(column.type);
      String defaultValue;

      for (var constraint in column.constraints) {
        if (constraint is PrimaryKeyColumn) {
          isPrimaryKey = true;
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
      );

      foundColumns[column.name] = parsed;
      if (isPrimaryKey) {
        primaryKey.add(parsed);
      }
    }

    final tableName = table.name;
    final dartTableName = ReCase(tableName).pascalCase;

    final constraints = table.tableConstraints.map((c) => c.span.text).toList();

    for (var keyConstraint in table.tableConstraints.whereType<KeyClause>()) {
      if (keyConstraint.isPrimaryKey) {
        primaryKey.addAll(keyConstraint.indexedColumns
            .map((r) => foundColumns[r.columnName])
            .where((c) => c != null));
      }
    }

    return SpecifiedTable(
      fromClass: null,
      columns: foundColumns.values.toList(),
      sqlName: table.name,
      dartTypeName: dataClassNameForClassName(dartTableName),
      overriddenName: ReCase(tableName).pascalCase,
      primaryKey: primaryKey,
      overrideWithoutRowId: table.withoutRowId ? true : null,
      overrideTableConstraints: constraints.isNotEmpty ? constraints : null,
      // we take care of writing the primary key ourselves
      overrideDontWriteConstraints: true,
    );
  }

  CreateTable(this.ast);
}
