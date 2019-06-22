import 'package:sqlparser/src/ast/ast.dart';
import 'package:sqlparser/src/reader/parser/parser.dart';
import 'package:sqlparser/src/reader/tokenizer/scanner.dart';

class SqlEngine {
  /// Parses the [sql] statement. At the moment, only SELECT statements are
  /// supported.
  AstNode parse(String sql) {
    final scanner = Scanner(sql);
    final tokens = scanner.scanTokens();
    // todo error handling from scanner

    final parser = Parser(tokens);
    return parser.select();
  }
}
