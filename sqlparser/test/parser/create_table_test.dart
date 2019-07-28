import 'package:sqlparser/src/ast/ast.dart';

import 'utils.dart';

final statement = '''
CREATE TABLE IF NOT EXISTS users (
  id INT NOT NULL PRIMARY KEY DESC ON CONFLICT ROLLBACK AUTOINCREMENT,
  email VARCHAR NOT NULL UNIQUE ON CONFLICT ABORT,
  score INT CONSTRAINT "score set" NOT NULL DEFAULT 420 CHECK (score > 0),
  display_name VARCHAR COLLATE BINARY 
     REFERENCES some(thing) ON UPDATE CASCADE ON DELETE SET NULL,
  
  UNIQUE (score, display_name) ON CONFLICT ABORT,
  FOREIGN KEY (id, email) REFERENCES another (a, b)
     ON DELETE NO ACTION ON UPDATE RESTRICT
)
''';

void main() {
  testStatement(
    statement,
    CreateTableStatement(
      tableName: 'users',
      ifNotExists: true,
      withoutRowId: false,
      columns: [
        ColumnDefinition(
          columnName: 'id',
          typeName: 'INT',
          constraints: [
            NotNull(null),
            PrimaryKeyColumn(
              null,
              autoIncrement: true,
              onConflict: ConflictClause.rollback,
              mode: OrderingMode.descending,
            ),
          ],
        ),
        ColumnDefinition(
          columnName: 'email',
          typeName: 'VARCHAR',
          constraints: [
            NotNull(null),
            UniqueColumn(null, ConflictClause.abort),
          ],
        ),
        ColumnDefinition(
          columnName: 'score',
          typeName: 'INT',
          constraints: [
            NotNull('score set'),
            Default(null, NumericLiteral(420, token(TokenType.numberLiteral))),
            CheckColumn(
              null,
              BinaryExpression(
                Reference(columnName: 'score'),
                token(TokenType.more),
                NumericLiteral(
                  0,
                  token(TokenType.numberLiteral),
                ),
              ),
            ),
          ],
        ),
        ColumnDefinition(
          columnName: 'display_name',
          typeName: 'VARCHAR',
          constraints: [
            CollateConstraint(
              null,
              'BINARY',
            ),
            ForeignKeyColumnConstraint(
              null,
              ForeignKeyClause(
                foreignTable: TableReference('some', null),
                columnNames: [Reference(columnName: 'thing')],
                onUpdate: ReferenceAction.cascade,
                onDelete: ReferenceAction.setNull,
              ),
            ),
          ],
        )
      ],
      tableConstraints: [
        KeyClause(
          null,
          isPrimaryKey: false,
          indexedColumns: [
            Reference(columnName: 'score'),
            Reference(columnName: 'display_name'),
          ],
          onConflict: ConflictClause.abort,
        ),
        ForeignKeyTableConstraint(
          null,
          columns: [
            Reference(columnName: 'id'),
            Reference(columnName: 'email'),
          ],
          clause: ForeignKeyClause(
            foreignTable: TableReference('another', null),
            columnNames: [
              Reference(columnName: 'a'),
              Reference(columnName: 'b'),
            ],
            onDelete: ReferenceAction.noAction,
            onUpdate: ReferenceAction.restrict,
          ),
        )
      ],
    ),
  );
}
