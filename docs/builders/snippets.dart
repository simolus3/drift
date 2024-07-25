import 'package:build/build.dart';
import 'package:code_snippets/builder.dart';
import 'package:code_snippets/highlight.dart';
import 'package:source_span/source_span.dart';
import 'package:sqlparser/sqlparser.dart';

class SnippetsBuilder extends CodeExcerptBuilder {
  // ignore: avoid_unused_constructor_parameters
  SnippetsBuilder([BuilderOptions? options])
      : super(
          dropIndendation: true,
          overriddenDartDocUrls: {
            // For CI builds, the dartdoc output for the drift package is added
            // under the `api/` url.
            if (options?.config['release'] == true) 'drift': Uri.parse('/api/'),
          },
        );

  @override
  bool shouldEmitFor(AssetId input, Excerpter excerpts) {
    return true;
  }

  @override
  Future<Highlighter?> highlighterFor(
      AssetId assetId, String content, BuildStep buildStep) async {
    switch (assetId.extension) {
      case '.drift':
        return _DriftHighlighter(
            SourceFile.fromString(content, url: assetId.uri));
      default:
        return super.highlighterFor(assetId, content, buildStep);
    }
  }
}

class _DriftHighlighter extends Highlighter {
  _DriftHighlighter(super.file);

  @override
  void highlight() {
    final engine = SqlEngine(
      EngineOptions(
        driftOptions: const DriftSqlOptions(),
        version: SqliteVersion.current,
      ),
    );

    final result = engine.parseDriftFile(file.span(0).text);
    _HighlightingVisitor().visit(result.rootNode, this);

    for (final token in result.tokens) {
      const ignoredKeyword = [
        TokenType.$null,
        TokenType.$true,
        TokenType.$false
      ];

      if (token is KeywordToken &&
          !ignoredKeyword.contains(token.type) &&
          !token.isIdentifier) {
        reportSql(token, RegionType.keyword);
      } else if (token is CommentToken) {
        reportSql(token, RegionType.comment);
      } else if (token is StringLiteralToken) {
        reportSql(token, RegionType.string);
      }
    }
  }

  void reportSql(SyntacticEntity? entity, RegionType type) {
    if (entity != null) {
      report(HighlightRegion(
          type, file.span(entity.firstPosition, entity.lastPosition)));
    }
  }
}

class _HighlightingVisitor extends RecursiveVisitor<_DriftHighlighter, void> {
  @override
  void visitCreateTriggerStatement(
      CreateTriggerStatement e, _DriftHighlighter arg) {
    arg.reportSql(e.triggerNameToken, RegionType.classTitle);
    visitChildren(e, arg);
  }

  @override
  void visitCreateViewStatement(CreateViewStatement e, _DriftHighlighter arg) {
    arg.reportSql(e.viewNameToken, RegionType.classTitle);
    visitChildren(e, arg);
  }

  @override
  void visitColumnDefinition(ColumnDefinition e, _DriftHighlighter arg) {
    arg
      ..reportSql(e.nameToken, RegionType.variable)
      ..reportSql(e.typeNames?.toSingleEntity, RegionType.type);

    visitChildren(e, arg);
  }

  @override
  void visitColumnConstraint(ColumnConstraint e, _DriftHighlighter arg) {
    if (e is NotNull) {
      arg.reportSql(e.$null, RegionType.keyword);
    } else if (e is NullColumnConstraint) {
      arg.reportSql(e.$null, RegionType.keyword);
    }
    super.visitColumnConstraint(e, arg);
  }

  @override
  void visitNullLiteral(NullLiteral e, _DriftHighlighter arg) {
    arg.reportSql(e, RegionType.builtIn);
  }

  @override
  void visitNumericLiteral(NumericLiteral e, _DriftHighlighter arg) {
    arg.reportSql(e, RegionType.number);
  }

  @override
  void visitDriftSpecificNode(DriftSpecificNode e, _DriftHighlighter arg) {
    if (e is DeclaredStatement) {
      final name = e.identifier;
      if (name is SimpleName) {
        arg.reportSql(name.identifier, RegionType.functionTitle);
      }
    }

    super.visitDriftSpecificNode(e, arg);
  }

  @override
  void visitBooleanLiteral(BooleanLiteral e, _DriftHighlighter arg) {
    arg.reportSql(e, RegionType.literal);
  }

  @override
  void visitReference(Reference e, _DriftHighlighter arg) {
    arg.reportSql(e, RegionType.variable);
  }

  @override
  void visitTableReference(TableReference e, _DriftHighlighter arg) {
    arg.reportSql(e.tableNameToken, RegionType.type);
  }

  @override
  void visitTableInducingStatement(
      TableInducingStatement e, _DriftHighlighter arg) {
    arg.reportSql(e.tableNameToken, RegionType.classTitle);

    if (e is CreateVirtualTableStatement) {
      arg.reportSql(e.moduleNameToken, RegionType.invokedFunctionTitle);
    }

    visitChildren(e, arg);
  }

  @override
  void visitVariable(Variable e, _DriftHighlighter arg) {
    arg.reportSql(e, RegionType.variable);
  }
}
