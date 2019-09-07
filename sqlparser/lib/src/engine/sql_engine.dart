import 'package:sqlparser/src/analysis/analysis.dart';
import 'package:sqlparser/src/ast/ast.dart';
import 'package:sqlparser/src/engine/autocomplete/engine.dart';
import 'package:sqlparser/src/reader/parser/parser.dart';
import 'package:sqlparser/src/reader/tokenizer/scanner.dart';
import 'package:sqlparser/src/reader/tokenizer/token.dart';

class SqlEngine {
  /// All tables registered with [registerTable].
  final List<Table> knownTables = [];

  /// Moor extends the sql grammar a bit to support type converters and other
  /// features. Enabling this flag will make this engine parse sql with these
  /// extensions enabled.
  final bool useMoorExtensions;

  SqlEngine({this.useMoorExtensions = false});

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

    return scope;
  }

  /// Tokenizes the [source] into a list list [Token]s. Each [Token] contains
  /// information about where it appears in the [source] and a [TokenType].
  List<Token> tokenize(String source) {
    final scanner = Scanner(source, scanMoorTokens: useMoorExtensions);
    final tokens = scanner.scanTokens();

    if (scanner.errors.isNotEmpty) {
      throw CumulatedTokenizerException(scanner.errors);
    }

    return tokens;
  }

  /// Parses the [sql] statement into an AST-representation.
  ParseResult parse(String sql) {
    final tokens = tokenize(sql);
    final parser = Parser(tokens, useMoor: useMoorExtensions);

    final stmt = parser.statement();
    return ParseResult._(stmt, tokens, parser.errors, sql, null);
  }

  /// Parses a `.moor` file, which can consist of multiple statements and
  /// additional components like import statements.
  ParseResult parseMoorFile(String content) {
    assert(useMoorExtensions);

    final autoComplete = AutoCompleteEngine();
    final tokens = tokenize(content);
    final parser = Parser(tokens, useMoor: true, autoComplete: autoComplete);

    final moorFile = parser.moorFile();

    return ParseResult._(moorFile, tokens, parser.errors, content, autoComplete);
  }

  /// Parses and analyzes the [sql] statement. The [AnalysisContext] returned
  /// contains all information about type hints, errors, and the parsed AST.
  ///
  /// The analyzer needs to know all the available tables to resolve references
  /// and result columns, so all known tables should be registered using
  /// [registerTable] before calling this method.
  AnalysisContext analyze(String sql) {
    final result = parse(sql);
    return analyzeParsed(result);
  }

  /// Analyzes a parsed [result] statement. The [AnalysisContext] returned
  /// contains all information about type hints, errors, and the parsed AST.
  ///
  /// The analyzer needs to know all the available tables to resolve references
  /// and result columns, so all known tables should be registered using
  /// [registerTable] before calling this method.
  AnalysisContext analyzeParsed(ParseResult result) {
    final node = result.rootNode;
    const SetParentVisitor().startAtRoot(node);

    final context = AnalysisContext(node, result.sql);
    final scope = _constructRootScope();

    try {
      ReferenceFinder(globalScope: scope).start(node);

      if (node is CrudStatement) {
        node
          ..accept(ColumnResolver(context))
          ..accept(ReferenceResolver(context))
          ..accept(TypeResolvingVisitor(context));
      }
    } catch (e) {
      // todo should we do now? AFAIK, everything that causes an exception
      // is added as an error contained in the context.
    }

    return context;
  }
}

/// The result of parsing an sql query. Contains the root of the AST and all
/// errors that might have occurred during parsing.
class ParseResult {
  /// The topmost node in the sql AST that was parsed.
  final AstNode rootNode;

  /// The tokens that were scanned in the source file
  final List<Token> tokens;

  /// A list of all errors that occurred during parsing. [ParsingError.toString]
  /// returns a helpful description of what went wrong, along with the position
  /// where the error occurred.
  final List<ParsingError> errors;

  /// The sql source that created the AST at [rootNode].
  final String sql;

  /// The engine which can be used to handle auto-complete requests on this
  /// result.
  final AutoCompleteEngine autoCompleteEngine;

  ParseResult._(this.rootNode, this.tokens, this.errors, this.sql, this.autoCompleteEngine);
}
