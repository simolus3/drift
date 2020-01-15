import 'dart:collection';

import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/src/analysis/types2/types.dart' as t2;
import 'package:sqlparser/src/engine/module/fts5.dart';
import 'package:sqlparser/src/engine/options.dart';
import 'package:sqlparser/src/reader/parser/parser.dart';
import 'package:sqlparser/src/reader/tokenizer/scanner.dart';
import 'package:sqlparser/src/reader/tokenizer/token.dart';

import 'autocomplete/engine.dart';
import 'builtin_tables.dart';

class SqlEngine {
  /// All tables registered with [registerTable].
  final List<Table> knownTables = [];
  final List<Module> _knownModules = [];

  /// Internal options for this sql engine.
  final EngineOptions options;

  SchemaFromCreateTable _schemaReader;

  SqlEngine(
      {@Deprecated('Use SqlEngine.withOptions instead')
          bool useMoorExtensions = false,
      @Deprecated('Use SqlEngine.withOptions instead')
          bool enableJson1Module = false,
      @Deprecated('Use SqlEngine.withOptions instead')
          bool enableFts5 = false})
      : this.withOptions(_constructOptions(
          // ignore: deprecated_member_use_from_same_package
          moor: useMoorExtensions,
          // ignore: deprecated_member_use_from_same_package
          json1: enableJson1Module,
          // ignore: deprecated_member_use_from_same_package
          fts5: enableFts5,
        ));

  SqlEngine.withOptions(this.options) {
    for (final extension in options.enabledExtensions) {
      extension.register(this);
    }

    registerTable(sqliteMaster);
    registerTable(sqliteSequence);
  }

  /// Obtain a [SchemaFromCreateTable] instance compatible with the
  /// configuration of this engine.
  ///
  /// The returned reader can be used to read the table structure from a
  /// [TableInducingStatement] by using [SchemaFromCreateTable.read].
  SchemaFromCreateTable get schemaReader {
    return _schemaReader ??=
        SchemaFromCreateTable(moorExtensions: options.useMoorExtensions);
  }

  /// Registers the [table], which means that it can later be used in sql
  /// statements.
  void registerTable(Table table) {
    knownTables.add(table);
  }

  /// Registers the [module], which means that it can be used as a function in
  /// `CREATE VIRTUAL TABLE` statements.
  void registerModule(Module module) {
    _knownModules.add(module);
  }

  /// Registers the [handler], which can provide implementations for additional
  /// sql functions that can then be used in statements analyzed through this
  /// engine.
  void registerFunctionHandler(FunctionHandler handler) {
    options.addFunctionHandler(handler);
  }

  ReferenceScope _constructRootScope({ReferenceScope parent}) {
    final scope = parent == null ? ReferenceScope(null) : parent.createChild();
    for (final table in knownTables) {
      scope.register(table.name, table);
    }

    for (final module in _knownModules) {
      scope.register(module.name, module);
    }

    return scope;
  }

  /// Tokenizes the [source] into a list list [Token]s. Each [Token] contains
  /// information about where it appears in the [source] and a [TokenType].
  ///
  /// Note that the list might be tokens that should be
  /// [Token.invisibleToParser], if you're passing them to a [Parser] directly,
  /// you need to filter them. When using the methods in this class, this will
  /// be taken care of automatically.
  List<Token> tokenize(String source) {
    final scanner = Scanner(source, scanMoorTokens: options.useMoorExtensions);
    final tokens = scanner.scanTokens();

    if (scanner.errors.isNotEmpty) {
      throw CumulatedTokenizerException(scanner.errors);
    }

    return tokens;
  }

  /// Parses a single [sql] statement into an AST-representation.
  ParseResult parse(String sql) {
    final tokens = tokenize(sql);
    final tokensForParser = tokens.where((t) => !t.invisibleToParser).toList();
    final parser = Parser(tokensForParser, useMoor: options.useMoorExtensions);

    final stmt = parser.statement();
    return ParseResult._(stmt, tokens, parser.errors, sql, null);
  }

  /// Parses a `.moor` file, which can consist of multiple statements and
  /// additional components like import statements.
  ParseResult parseMoorFile(String content) {
    assert(options.useMoorExtensions);

    final tokens = tokenize(content);
    final autoComplete = AutoCompleteEngine(tokens);

    final tokensForParser = tokens.where((t) => !t.invisibleToParser).toList();
    final parser =
        Parser(tokensForParser, useMoor: true, autoComplete: autoComplete);

    final moorFile = parser.moorFile();
    _attachRootScope(moorFile);

    return ParseResult._(
        moorFile, tokens, parser.errors, content, autoComplete);
  }

  /// Parses and analyzes the [sql] statement. The [AnalysisContext] returned
  /// contains all information about type hints, errors, and the parsed AST.
  ///
  /// The analyzer needs to know all the available tables to resolve references
  /// and result columns, so all known tables should be registered using
  /// [registerTable] before calling this method.
  /// The [stmtOptions] can be used to pass additional options used to analyze
  /// this statement only.
  AnalysisContext analyze(String sql, {AnalyzeStatementOptions stmtOptions}) {
    final result = parse(sql);
    return analyzeParsed(result, stmtOptions: stmtOptions);
  }

  /// Analyzes a parsed [result] statement. The [AnalysisContext] returned
  /// contains all information about type hints, errors, and the parsed AST.
  ///
  /// The analyzer needs to know all the available tables to resolve references
  /// and result columns, so all known tables should be registered using
  /// [registerTable] before calling this method.
  /// The [stmtOptions] can be used to pass additional options used to analyze
  /// this statement only.
  AnalysisContext analyzeParsed(ParseResult result,
      {AnalyzeStatementOptions stmtOptions}) {
    final node = result.rootNode;

    final context = _createContext(node, result.sql, stmtOptions);
    _analyzeContext(context);

    return context;
  }

  /// Analyzes the given [node], which should be a [CrudStatement].
  /// The [AnalysisContext] enhances the AST by reporting type hints and errors.
  /// The [file] should contain the full SQL source code that was used to parse
  /// the [node].
  ///
  /// The analyzer needs to know all the available tables to resolve references
  /// and result columns, so all known tables should be registered using
  /// [registerTable] before calling this method.
  /// The [stmtOptions] can be used to pass additional options used to analyze
  /// this statement only.
  AnalysisContext analyzeNode(AstNode node, String file,
      {AnalyzeStatementOptions stmtOptions}) {
    final context = _createContext(node, file, stmtOptions);
    _analyzeContext(context);
    return context;
  }

  AnalysisContext _createContext(
      AstNode node, String sql, AnalyzeStatementOptions stmtOptions) {
    return AnalysisContext(node, sql, options,
        stmtOptions: stmtOptions, schemaSupport: schemaReader);
  }

  void _analyzeContext(AnalysisContext context) {
    final node = context.root;
    _attachRootScope(node);

    try {
      AstPreparingVisitor(context: context).start(node);

      node
        ..acceptWithoutArg(ColumnResolver(context))
        ..acceptWithoutArg(ReferenceResolver(context));

      if (options.enableExperimentalTypeInference) {
        final session = t2.TypeInferenceSession(context, options);
        final resolver = t2.TypeResolver(session);
        resolver.run(node);
        context.types2 = session.results;
      } else {
        node.acceptWithoutArg(TypeResolvingVisitor(context));
      }

      node.acceptWithoutArg(LintingVisitor(options, context));
    } catch (_) {
      rethrow;
    }
  }

  void _attachRootScope(AstNode root) {
    // calling node.referenceScope throws when no scope is set, we use the
    // nullable variant here
    final safeScope = root.selfAndParents
        .map((node) => node.meta<ReferenceScope>())
        .firstWhere((e) => e != null, orElse: () => null);

    root.scope = _constructRootScope(parent: safeScope);
  }

  static EngineOptions _constructOptions({bool moor, bool fts5, bool json1}) {
    final extensions = [
      if (fts5) const Fts5Extension(),
    ];
    return EngineOptions(
      useMoorExtensions: moor,
      enableJson1: json1,
      enabledExtensions: extensions,
    );
  }
}

/// The result of parsing an sql query. Contains the root of the AST and all
/// errors that might have occurred during parsing.
class ParseResult {
  /// The topmost node in the sql AST that was parsed.
  final AstNode rootNode;

  /// The tokens that were scanned in the source file, including those that are
  /// [Token.invisibleToParser].
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

  ParseResult._(this.rootNode, this.tokens, this.errors, this.sql,
      this.autoCompleteEngine) {
    const SetParentVisitor().startAtRoot(rootNode);
  }

  /// Attempts to find the most relevant (bottom-most in the AST) nodes that
  /// intersects with the source range from [offset] to [offset] + [length].
  List<AstNode> findNodesAtPosition(int offset, {int length = 0}) {
    if (tokens.isEmpty || rootNode == null) return const [];

    final candidates = <AstNode>{};
    final unchecked = Queue<AstNode>();
    unchecked.add(rootNode);

    while (unchecked.isNotEmpty) {
      final node = unchecked.removeFirst();

      final span = node.span;
      final start = span.start.offset;
      final end = span.end.offset;

      final hasIntersection = !(end < offset || start > offset + length);
      if (hasIntersection) {
        // this node matches. As we want to find the bottom-most node in the AST
        // that matches, this means that the parent is no longer a candidate.
        candidates.add(node);
        candidates.remove(node.parent);

        // assume that the span of a node is a superset of the span of any
        // child, so each child could potentially be interesting.
        unchecked.addAll(node.childNodes);
      }
    }

    return candidates.toList();
  }

  /// Returns the lexeme that created an AST [node] (which should be a child of
  /// [rootNode], e.g appear in this result).
  String lexemeOfNode(AstNode node) {
    return sql.substring(node.firstPosition, node.lastPosition);
  }
}
