import 'package:sqlparser/src/ast/ast.dart';

import 'utils.dart';

final statement = '''
CREATE TABLE IF NOT EXISTS users (
  id INT NOT NULL PRIMARY KEY DESC ON CONFLICT ROLLBACK AUTOINCREMENT,
  email VARCHAR NOT NULL UNIQUE ON CONFLICT ABORT,
  score INT CONSTRAINT "score set" NOT NULL DEFAULT 420 CHECK (score > 0),
  display_name VARCHAR COLLATE BINARY
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
            PrimaryKey(
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
            Unique(null, ConflictClause.abort),
          ],
        ),
        ColumnDefinition(
          columnName: 'score',
          typeName: 'INT',
          constraints: [
            NotNull('score set'),
            Default(null, NumericLiteral(420, token(TokenType.numberLiteral))),
            Check(
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
          ],
        )
      ],
    ),
  );
}
