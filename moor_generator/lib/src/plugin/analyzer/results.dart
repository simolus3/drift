import 'package:sqlparser/sqlparser.dart';

class MoorAnalysisResults {
  final List<AstNode> statements;
  final List<Token> sqlTokens;

  MoorAnalysisResults(this.statements, this.sqlTokens);
}
