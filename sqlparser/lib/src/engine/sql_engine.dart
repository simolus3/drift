import 'package:sqlparser/src/analysis/analysis.dart';
import 'package:sqlparser/src/ast/ast.dart';
import 'package:sqlparser/src/reader/parser/parser.dart';
import 'package:sqlparser/src/reader/tokenizer/scanner.dart';

class SqlEngine {
  /// All tables registered with [registerTable].
  final List<Table> knownTables = [];

  /// All functions (like COUNT, SUM, etc.) which are available in sql.
  final List<SqlFunction> knownFunctions = [];

  SqlEngine({bool includeDefaults = true}) {
    if (includeDefaults) {
      knownFunctions.addAll(coreFunctions);
    }
  }

  /// Registers the [table], which means that it can later be used in sql
  /// statements.
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
    return parser.statement();
  }

  /// Parses and analyzes the [sql] statement, which at the moment has to be a
  /// select statement. The [AnalysisContext] returned contains all information
  /// about type hints, errors, and the parsed AST.
  ///
  /// The analyzer needs to know all the available tables to resolve references
  /// and result columns, so all known tables should be registered using
  /// [registerTable] before calling this method.
  AnalysisContext analyze(String sql) {
    final node = parse(sql);
    const SetParentVisitor().startAtRoot(node);

    final context = AnalysisContext(node, sql);
    final scope = _constructRootScope();

    ReferenceFinder(globalScope: scope).start(node);
    node
      ..accept(ColumnResolver(context))
      ..accept(ReferenceResolver(context))
      ..accept(TypeResolvingVisitor(context));

    return context;
  }
}
