import 'package:analyzer_plugin_fork/protocol/protocol_common.dart';
import 'package:moor_generator/src/analyzer/runner/file_graph.dart';
import 'package:sqlparser/sqlparser.dart';

import 'utils.dart';

/// Token types that have a semantic meaning more accurate than just "keyword"
const _semanticTokenTypes = {
  TokenType.$null, // reported as LITERAL_NULL
  TokenType.$true, // reported as LITERAL_BOOL
  TokenType.$false,
};

class MoorHighlightComputer {
  final FoundFile file;
  final List<HighlightRegion> _regions = [];

  MoorHighlightComputer(this.file);

  List<HighlightRegion> computeHighlights() {
    final moor = file.parsedMoorOrNull;
    if (moor == null) return _regions;

    final visitor = _HighlightingVisitor(this);
    moor.parsedFile.acceptWithoutArg(visitor);

    for (final token in moor.parseResult.tokens) {
      if (_semanticTokenTypes.contains(token.type)) continue;

      if (token is KeywordToken && !token.isIdentifier) {
        _contribute(token, HighlightRegionType.BUILT_IN);
      } else if (token is CommentToken) {
        final mode = const {
          CommentMode.cStyle: HighlightRegionType.COMMENT_BLOCK,
          CommentMode.line: HighlightRegionType.COMMENT_END_OF_LINE,
        }[token];
        _contribute(token, mode);
      } else if (token is InlineDartToken) {
        _contribute(token, HighlightRegionType.COMMENT_DOCUMENTATION);
      } else if (token is VariableToken) {
        _contribute(token, HighlightRegionType.PARAMETER_REFERENCE);
      } else if (token is StringLiteralToken) {
        _contribute(token, HighlightRegionType.LITERAL_STRING);
      }
    }

    return _regions;
  }

  void _contribute(SyntacticEntity node, HighlightRegionType type) {
    _regions.add(HighlightRegion(type, node.firstPosition, node.length));
  }

  void _contributeRange(int start, int endExclusive, HighlightRegionType type) {
    _regions.add(HighlightRegion(type, start, endExclusive - start));
  }
}

class _HighlightingVisitor extends RecursiveVisitor<void, void> {
  final MoorHighlightComputer collector;

  bool isDeclaringVariables = false;

  _HighlightingVisitor(this.collector);

  void _contribute(SyntacticEntity node, HighlightRegionType type) {
    collector._contribute(node, type);
  }

  @override
  void visitReference(Reference e, void arg) {
    _contribute(e, HighlightRegionType.INSTANCE_GETTER_REFERENCE);
  }

  @override
  void visitTableReference(TableReference e, void arg) {
    final tableToken = e.tableNameToken;
    if (tableToken != null) {
      _contribute(e, HighlightRegionType.TYPE_PARAMETER);
    }
    visitChildren(e, arg);
  }

  @override
  void visitTableInducingStatement(TableInducingStatement e, void arg) {
    if (e.tableNameToken != null) {
      _contribute(e.tableNameToken, HighlightRegionType.CLASS);
    }

    if (e is CreateVirtualTableStatement && e.moduleNameToken != null) {
      _contribute(
          e.moduleNameToken, HighlightRegionType.TOP_LEVEL_FUNCTION_REFERENCE);
    }

    visitChildren(e, arg);
  }

  @override
  void visitCreateIndexStatement(CreateIndexStatement e, void arg) {
    if (e.nameToken != null) {
      _contribute(e.nameToken, HighlightRegionType.CLASS);
    }

    visitChildren(e, arg);
  }

  @override
  void visitCreateTriggerStatement(CreateTriggerStatement e, void arg) {
    if (e.triggerNameToken != null) {
      _contribute(e.triggerNameToken, HighlightRegionType.CLASS);
    }

    visitChildren(e, arg);
  }

  @override
  void visitColumnDefinition(ColumnDefinition e, void arg) {
    final nameToken = e.nameToken;
    if (nameToken != null) {
      _contribute(nameToken, HighlightRegionType.INSTANCE_FIELD_DECLARATION);
    }

    final typeTokens = e.typeNames;
    if (typeTokens != null && typeTokens.isNotEmpty) {
      final first = typeTokens.first.firstPosition;
      final last = typeTokens.last.lastPosition;
      collector._contributeRange(first, last, HighlightRegionType.CLASS);
    }

    visitChildren(e, arg);
  }

  @override
  void visitTableConstraint(TableConstraint e, void arg) {
    if (e.nameToken != null) {
      collector._contribute(
          e.nameToken, HighlightRegionType.STATIC_GETTER_DECLARATION);
    }
    visitChildren(e, arg);
  }

  @override
  void visitSetComponent(SetComponent e, void arg) {
    _contribute(e.column, HighlightRegionType.INSTANCE_SETTER_REFERENCE);
    visitExcept(e, e.column, arg);
  }

  @override
  void visitMoorDeclaredStatement(DeclaredStatement e, void arg) {
    final identifier = e.identifier;
    if (identifier is SimpleName && identifier.identifier != null) {
      _contribute(identifier.identifier,
          HighlightRegionType.TOP_LEVEL_FUNCTION_DECLARATION);
    } else if (identifier is SpecialStatementIdentifier &&
        identifier.nameToken != null) {
      _contribute(identifier.nameToken, HighlightRegionType.ANNOTATION);
    }

    if (e.parameters != null) {
      isDeclaringVariables = true;
      visitList(e.parameters, arg);
      isDeclaringVariables = false;
    }

    visitChildren(e, arg);
  }

  @override
  void defaultLiteral(Literal e, void arg) {
    if (e is NullLiteral) {
      _contribute(e, HighlightRegionType.BUILT_IN);
    } else if (e is NumericLiteral) {
      _contribute(e, HighlightRegionType.LITERAL_INTEGER);
    } else if (e is BooleanLiteral) {
      _contribute(e, HighlightRegionType.LITERAL_BOOLEAN);
    }
    // string literals are reported for each string token
  }

  @override
  void visitVariable(Variable e, void arg) {
    final type = isDeclaringVariables
        ? HighlightRegionType.PARAMETER_DECLARATION
        : HighlightRegionType.PARAMETER_REFERENCE;
    _contribute(e, type);
    visitChildren(e, arg);
  }
}
