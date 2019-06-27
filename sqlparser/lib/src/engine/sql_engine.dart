import 'package:sqlparser/src/analysis/analysis.dart';
import 'package:sqlparser/src/ast/ast.dart';
import 'package:sqlparser/src/reader/parser/parser.dart';
import 'package:sqlparser/src/reader/tokenizer/scanner.dart';

class SqlEngine {
  final List<Table> knownTables = [];
  final List<SqlFunction> knownFunctions = [];

  SqlEngine({bool includeDefaults = true}) {
    if (includeDefaults) {
      knownFunctions.addAll(coreFunctions);
    }
  }

  void registerTable(Table table) {
    knownTables.add(table);
  }

  ReferenceScope _constructRootScope() {
    final scope = ReferenceScope(null);
    for (var table in knownTables) {
      scope.register(table.name, table);
    }
    for (var function in knownFunctions) {
      scope.register(function.name, function);
    }

    return scope;
  }

  /// Parses the [sql] statement. At the moment, only SELECT statements are
  /// supported.
  AstNode parse(String sql) {
    final scanner = Scanner(sql);
    final tokens = scanner.scanTokens();
    // todo error handling from scanner

    final parser = Parser(tokens);
    return parser.select();
  }

  AnalysisContext analyze(String sql) {
    final node = parse(sql);
    const SetParentVisitor().startAtRoot(node);

    final context = AnalysisContext(node, sql);
    final scope = _constructRootScope();

    ReferenceFinder(globalScope: scope).start(node);
    node..accept(ColumnResolver(context))..accept(ReferenceResolver(context));

    return context;
  }
}
