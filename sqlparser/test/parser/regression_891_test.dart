import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  final caseExpr = CaseExpression(
    whens: [
      WhenComponent(
        when: BinaryExpression(
          NumericLiteral(1, token(TokenType.numberLiteral)),
          token(TokenType.equal),
          ColonNamedVariable(
            ColonVariableToken(null, ':isReviewFolderSelected'),
          ),
        ),
        then: IsExpression(
          true,
          Reference(tableName: 'n', columnName: 'nextReviewTime'),
          NullLiteral(token(TokenType.$null)),
        ),
      ),
    ],
    elseExpr: IsExpression(
      false,
      Reference(tableName: 'n', columnName: 'nextReviewTime'),
      NullLiteral(token(TokenType.$null)),
    ),
  );

  final folderExpr = BinaryExpression(
    Reference(tableName: 'n', columnName: 'folderId'),
    token(TokenType.equal),
    ColonNamedVariable(
      ColonVariableToken(null, ':selectedFolderId'),
    ),
  );

  test('repro 1', () {
    testStatement(
      '''
      SELECT * FROM notes n WHERE 
        CASE 
          WHEN 1 = :isReviewFolderSelected THEN n.nextReviewTime IS NOT NULL
          ELSE n.nextReviewTime IS NULL
         END
         and n.folderId = :selectedFolderId;
      ''',
      SelectStatement(
        from: TableReference('notes', 'n'),
        columns: [StarResultColumn()],
        where: BinaryExpression(
          caseExpr,
          token(TokenType.and),
          folderExpr,
        ),
      ),
    );
  });

  test('repro 2', () {
    testStatement(
      '''
      SELECT * FROM notes n WHERE 
      n.folderId = :selectedFolderId and
      CASE 
        WHEN 1 = :isReviewFolderSelected THEN n.nextReviewTime IS NOT NULL
        ELSE n.nextReviewTime IS NULL
      END;
      ''',
      SelectStatement(
        from: TableReference('notes', 'n'),
        columns: [StarResultColumn()],
        where: BinaryExpression(
          folderExpr,
          token(TokenType.and),
          caseExpr,
        ),
      ),
    );
  });
}
