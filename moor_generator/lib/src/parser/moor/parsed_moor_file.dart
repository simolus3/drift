import 'package:moor_generator/src/model/specified_column.dart';
import 'package:moor_generator/src/model/specified_table.dart';
import 'package:moor_generator/src/parser/sql/type_mapping.dart';
import 'package:moor_generator/src/utils/names.dart';
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

      for (var constraint in column.constraints) {
        if (constraint is PrimaryKeyColumn) {
          isPrimaryKey = true;
          if (constraint.autoIncrement) {
            features.add(AutoIncrement());
          }
        }

        if (constraintWriter.isNotEmpty) {
          constraintWriter.write(' ');
        }
        constraintWriter.write(constraint.span.text);
      }

      final parsed = SpecifiedColumn(
        type: mapper.resolvedToMoor(column.type),
        nullable: column.type.nullable,
        dartGetterName: dartName,
        name: ColumnName.implicitly(sqlName),
        declaredAsPrimaryKey: isPrimaryKey,
        features: features,
        customConstraints: constraintWriter.toString(),
      );

      foundColumns[column.name] = parsed;
      if (isPrimaryKey) {
        primaryKey.add(parsed);
      }
    }

    final tableName = table.name;
    final dartTableName = ReCase(tableName).pascalCase;

    // todo respect WITHOUT ROWID clause and table constraints
    return SpecifiedTable(
      fromClass: null,
      columns: foundColumns.values.toList(),
      sqlName: table.name,
      dartTypeName: dataClassNameForClassName(dartTableName),
      overriddenName: dartTableName,
      primaryKey: primaryKey,
    );
  }

  CreateTable(this.ast);
}
