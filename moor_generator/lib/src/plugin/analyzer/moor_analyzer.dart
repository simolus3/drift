import 'package:analyzer/file_system/file_system.dart';
import 'package:moor_generator/src/plugin/analyzer/results.dart';
import 'package:sqlparser/sqlparser.dart';

class MoorAnalyzer {
  Future<MoorAnalysisResults> analyze(File file) async {
    final content = file.readAsStringSync();
    final sqlEngine = SqlEngine();

    final tokens = sqlEngine.tokenize(content);
    final stmts = sqlEngine.parseMultiple(tokens, content);

    return MoorAnalysisResults(stmts.map((r) => r.rootNode).toList(), tokens);
  }
}
