import 'dart:collection';

import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/src/analysis/types/types.dart';
import 'package:sqlparser/src/reader/parser.dart';
import 'package:sqlparser/src/reader/tokenizer/scanner.dart';

import 'autocomplete/engine.dart';
import 'builtin_tables.dart';

class SqlEngine {
  /// All tables registered with [registerTable].
  final List<NamedResultSet> knownResultSets = [];
  final List<Module> _knownModules = [];

  /// Internal options for this sql engine.
  final EngineOptions options;

  SchemaFromCreateTable? _schemaReader;

  SqlEngine([EngineOptions? engineOptions])
      : options = engineOptions ?? EngineOptions() {
    for (final extension in options.enabledExtensions) {
      extension.register(this);
    }

    registerTable(sqliteMaster);
    // sqlite3_schema has been added in sqlite 3.33.0 as an alias to the master
    // table. Since 3.34.0 is the first version for which we have feature flags,
    // we just add it unconditionally.
    registerTable(sqliteSchema);

    registerTable(sqliteSequence);

    registerTable(dbstat);
  }

  /// Obtain a [SchemaFromCreateTable] instance compatible with the
  /// configuration of this engine.
  ///
  /// The returned reader can be used to read the table structure from a
  /// [TableInducingStatement] by using [SchemaFromCreateTable.read].
  SchemaFromCreateTable get schemaReader {
    return _schemaReader ??= _createSchemaReader(null);
  }

  SchemaFromCreateTable _createSchemaReader(
      AnalyzeStatementOptions? stmtOptions) {
    final driftOptions = options.driftOptions;

    if (stmtOptions != null) {
      return SchemaFromCreateTable(
        driftExtensions: driftOptions != null,
        driftUseTextForDateTime: driftOptions?.storeDateTimesAsText == true,
        statementOptions: stmtOptions,
      );
    } else {
      return _schemaReader ??= SchemaFromCreateTable(
        driftExtensions: driftOptions != null,
        driftUseTextForDateTime: driftOptions?.storeDateTimesAsText == true,
      );
    }
  }

  /// Registers the [table], which means that it can later be used in sql
  /// statements.
  void registerTable(Table table) {
    registerResultSet(table);
  }

  /// Registers the [view], which means that it can later be used in sql
  /// statements.
  void registerView(View view) {
    registerResultSet(view);
  }

  /// Registers an arbitrary [namedResultSet], which means that it can later
  /// be used in sql statements.
  void registerResultSet(NamedResultSet namedResultSet) {
    knownResultSets.add(namedResultSet);
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

  /// Registers the [handler], which can infer result sets for a table-valued
  /// function.
  void registerTableValuedFunctionHandler(TableValuedFunctionHandler handler) {
    options.addTableValuedFunctionHandler(handler);
  }

  RootScope _constructRootScope() {
    final scope = RootScope();

    for (final resultSet in knownResultSets) {
      scope.knownTables[resultSet.name] = resultSet;
    }

    for (final module in _knownModules) {
      scope.knownModules[module.name] = module;
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
    final scanner =
        Scanner(source, scanDriftTokens: options.useDriftExtensions);
    final tokens = scanner.scanTokens();

    return tokens;
  }

  Parser _createParser(
    List<Token> tokens, {
    AutoCompleteEngine? autoComplete,
    bool? driftExtensions,
  }) {
    final tokensForParser = tokens.where((t) => !t.invisibleToParser).toList();
    return Parser(
      tokensForParser,
      useDrift: driftExtensions ?? options.useDriftExtensions,
      autoComplete: autoComplete,
    );
  }

  /// Parses a single [sql] statement into an AST-representation.
  ParseResult parse(String sql) {
    final tokens = tokenize(sql);
    final parser = _createParser(tokens);

    final stmt = parser.safeStatement();
    return ParseResult._(stmt, tokens, parser.errors, sql, null);
  }

  /// Parses multiple [sql] statements, separated by a semicolon.
  ///
  /// You can use the [AstNode.childNodes] of the returned [ParseResult.rootNode]
  /// to inspect the returned statements.
  ParseResult parseMultiple(String sql) {
    final tokens = tokenize(sql);
    final parser = _createParser(tokens);

    final ast = parser.safeStatements();
    return ParseResult._(ast, tokens, parser.errors, sql, null);
  }

  /// Parses [sql] as a list of column constraints.
  ///
  /// The [ParseResult.rootNode] will be a [ColumnDefinition] with the parsed
  /// constraints.
  ParseResult parseColumnConstraints(String sql) {
    final tokens = tokenize(sql);
    final parser = _createParser(tokens, driftExtensions: false);

    return ParseResult._(
      ColumnDefinition(
        columnName: '',
        typeName: '',
        constraints: parser.columnConstraintsUntilEnd(),
      ),
      tokens,
      parser.errors,
      sql,
      null,
    );
  }

  /// Parses [sql] as a single table constraint.
  ///
  /// The [ParseResult.rootNode] will either be a [TableConstraint] or an
  /// [InvalidStatement] in case of parsing errors.
  ParseResult parseTableConstraint(String sql) {
    final tokens = tokenize(sql);
    final parser = _createParser(tokens, driftExtensions: false);

    AstNode? constraint;
    try {
      constraint = parser.tableConstraintOrNull(requireConstraint: true);
    } on ParsingError {
      // Ignore, will be added to parser.errors anyway
    }

    return ParseResult._(
      constraint ?? InvalidStatement(),
      tokens,
      parser.errors,
      sql,
      null,
    );
  }

  /// Parses a `.drift` file, which can consist of multiple statements and
  /// additional components like import statements.
  ParseResult parseDriftFile(String content) {
    assert(options.useDriftExtensions);

    final tokens = tokenize(content);
    final autoComplete = AutoCompleteEngine(tokens, this);
    final parser = _createParser(tokens, autoComplete: autoComplete);

    final driftFile = parser.driftFile();
    driftFile.scope = _constructRootScope();

    return ParseResult._(
        driftFile, tokens, parser.errors, content, autoComplete);
  }

  /// Parses and analyzes the [sql] statement. The [AnalysisContext] returned
  /// contains all information about type hints, errors, and the parsed AST.
  ///
  /// The analyzer needs to know all the available tables to resolve references
  /// and result columns, so all known tables should be registered using
  /// [registerTable] before calling this method.
  /// The [stmtOptions] can be used to pass additional options used to analyze
  /// this statement only.
  AnalysisContext analyze(String sql, {AnalyzeStatementOptions? stmtOptions}) {
    final result = parse(sql);
    final analyzed = analyzeParsed(result, stmtOptions: stmtOptions);

    // Add parsing errors that occurred at the beginning since they are the most
    // prominent problems.
    analyzed.errors.insertAll(0, result.errors.map(AnalysisError.fromParser));

    return analyzed;
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
      {AnalyzeStatementOptions? stmtOptions}) {
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
      {AnalyzeStatementOptions? stmtOptions}) {
    final context = _createContext(node, file, stmtOptions);
    _analyzeContext(context);
    return context;
  }

  AnalysisContext _createContext(
      AstNode node, String sql, AnalyzeStatementOptions? stmtOptions) {
    final schemaSupport = _createSchemaReader(stmtOptions);

    return AnalysisContext(node, sql, _constructRootScope(), options,
        stmtOptions: stmtOptions, schemaSupport: schemaSupport);
  }

  void _analyzeContext(AnalysisContext context) {
    final node = context.root;
    node.scope = context.rootScope;

    AstPreparingVisitor(context: context).start(node);

    node
      ..accept(ColumnResolver(context), const ColumnResolverContext())
      ..accept(ReferenceResolver(context), const ReferenceResolvingContext());

    final session = TypeInferenceSession(context, options);
    final resolver = TypeResolver(session);
    resolver.run(node);
    context.types2 = session.results!;

    node.acceptWithoutArg(LintingVisitor(options, context));
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
  final AutoCompleteEngine? autoCompleteEngine;

  ParseResult._(this.rootNode, this.tokens, this.errors, this.sql,
      this.autoCompleteEngine) {
    const SetParentVisitor().startAtRoot(rootNode);
  }

  /// Attempts to find the most relevant (bottom-most in the AST) nodes that
  /// intersects with the source range from [offset] to [offset] + [length].
  List<AstNode> findNodesAtPosition(int offset, {int length = 0}) {
    if (tokens.isEmpty) return const [];

    final candidates = <AstNode>{};
    final unchecked = Queue<AstNode>();
    unchecked.add(rootNode);

    while (unchecked.isNotEmpty) {
      final node = unchecked.removeFirst();

      final span = node.span!;
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
