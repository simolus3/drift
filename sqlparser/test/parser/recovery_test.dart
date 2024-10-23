import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/src/utils/ast_equality.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  test('parses create table statements with a previous malformed inport', () {
    final file = parseDrift('''
import ;
CREATE TABLE foo (name TEXT);
    ''');

    expect(
        file.childNodes, contains(const TypeMatcher<CreateTableStatement>()));
  });

  test('recovers from parsing errors in column definition', () {
    final file = parseDrift('''
CREATE TABLE foo (
  id INTEGER PRIMARY,
  name TEXT NOT NULL
);
    ''');

    final stmt = file.childNodes.single as CreateTableStatement;
    enforceEqual(
      stmt,
      CreateTableStatement(
        tableName: 'foo',
        columns: [
          // id column can't be parsed because of the missing KEY
          ColumnDefinition(
            columnName: 'name',
            typeName: 'TEXT',
            constraints: [NotNull(null)],
          ),
        ],
      ),
    );
  });

  test('parses trailing comma with error', () {
    final engine =
        SqlEngine(EngineOptions(driftOptions: const DriftSqlOptions()));

    final result = engine.parseDriftFile('''
CREATE TABLE foo (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
);
    ''');

    expect(result.errors, hasLength(1));

    enforceEqual(
      result.rootNode.childNodes.single,
      CreateTableStatement(
        tableName: 'foo',
        columns: [
          ColumnDefinition(
            columnName: 'id',
            typeName: 'INTEGER',
            constraints: [PrimaryKeyColumn(null)],
          ),
          ColumnDefinition(
            columnName: 'name',
            typeName: 'TEXT',
            constraints: [NotNull(null)],
          ),
        ],
      ),
    );
  });

  test('recovers from multiple syntax errors in table definitions', () {
    // Regression test for https://github.com/simolus3/drift/issues/3273
    final engine = SqlEngine();
    final result = engine.parseMultiple('''
CREATE TABLE IF NOT EXISTS "employees" (
	"employee_id"	INTEGER,
	"department_id"	INTEGER NOT NULL,
	"employee_name"	TEXT(100) NOT NULL,
	PRIMARY KEY("employee_id" AUTOINCREMENT) -- invalid table constraint
);
CREATE TABLE IF NOT EXISTS "projects" (
	"project_id"	BIGINT AUTO_INCREMENT, -- invalid column constraint
	"employee_id"	INT NOT NULL,
	"project_title"	CHAR(255) NOT NULL,
	PRIMARY KEY("project_id", "employee_id")
);
''');

    expect(result.errors, [
      isParsingError(span: 'AUTOINCREMENT'),
      isParsingError(span: 'AUTO_INCREMENT'),
    ]);

    enforceEqual(
      result.rootNode,
      SemicolonSeparatedStatements([
        CreateTableStatement(
          tableName: 'employees',
          ifNotExists: true,
          columns: [
            ColumnDefinition(
              columnName: 'employee_id',
              typeName: 'INTEGER',
            ),
            ColumnDefinition(
              columnName: 'department_id',
              typeName: 'INTEGER',
              constraints: [NotNull(null)],
            ),
            ColumnDefinition(
              columnName: 'employee_name',
              typeName: 'TEXT(100)',
              constraints: [NotNull(null)],
            ),
          ],
          tableConstraints: [
            // The broken PRIMARY KEY is not included here, there's a syntax
            // error since we don't support AUTOINCREMENT here.
          ],
        ),
        CreateTableStatement(
          tableName: 'projects',
          ifNotExists: true,
          columns: [
            ColumnDefinition(
              columnName: 'project_id',
              typeName: 'BIGINT',
              constraints: [
                // The broken column constraint is not included
              ],
            ),
            ColumnDefinition(
              columnName: 'employee_id',
              typeName: 'INT',
              constraints: [NotNull(null)],
            ),
            ColumnDefinition(
              columnName: 'project_title',
              typeName: 'CHAR(255)',
              constraints: [NotNull(null)],
            ),
          ],
          tableConstraints: [
            KeyClause(null, isPrimaryKey: true, columns: [
              IndexedColumn(Reference(columnName: 'project_id')),
              IndexedColumn(Reference(columnName: 'employee_id')),
            ])
          ],
        ),
      ]),
    );
  });
}
