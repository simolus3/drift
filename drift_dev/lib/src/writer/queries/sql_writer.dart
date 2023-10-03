import 'package:charcode/ascii.dart';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart' show SqlDialect;
// ignore: deprecated_member_use
import 'package:drift/sqlite_keywords.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/utils/node_to_text.dart';

import '../../analysis/resolver/drift/element_resolver.dart';
import '../../analysis/results/results.dart';
import '../../analysis/options.dart';
import '../../utils/string_escaper.dart';

/// The expanded sql that we insert into queries whenever an array variable
/// appears. For the query "SELECT * FROM t WHERE x IN ?", we generate
/// ```dart
/// test(List<int> var1) {
///   final expandedvar1 = List.filled(var1.length, '?').join(',');
///   customSelect('SELECT * FROM t WHERE x IN ($expandedvar1)', ...);
/// }
/// ```
String expandedName(FoundVariable v) {
  return 'expanded${v.dartParameterName}';
}

String placeholderContextName(FoundDartPlaceholder placeholder) {
  return 'generated${placeholder.name}';
}

extension ToSqlText on AstNode {
  String toSqlWithoutDriftSpecificSyntax(
      DriftOptions options, SqlDialect dialect) {
    final writer = SqlWriter(options, dialect: dialect, escapeForDart: false);
    return writer.writeSql(this);
  }
}

class SqlWriter extends NodeSqlBuilder {
  final StringBuffer _out;
  final SqlQuery? query;
  final DriftOptions options;
  final SqlDialect dialect;
  final Map<NestedStarResultColumn, NestedResultTable> _starColumnToResolved;

  bool get _isPostgres => dialect == SqlDialect.postgres;

  SqlWriter._(this.query, this.options, this.dialect,
      this._starColumnToResolved, StringBuffer out, bool escapeForDart)
      : _out = out,
        super(escapeForDart ? _DartEscapingSink(out) : out);

  factory SqlWriter(
    DriftOptions options, {
    required SqlDialect dialect,
    SqlQuery? query,
    bool escapeForDart = true,
    StringBuffer? buffer,
  }) {
    // Index nested results by their syntactic origin for faster lookups later
    var doubleStarColumnToResolvedTable =
        const <NestedStarResultColumn, NestedResultTable>{};

    if (query is SqlSelectQuery) {
      doubleStarColumnToResolvedTable = {
        for (final nestedResult in query.resultSet.nestedResults)
          if (nestedResult is NestedResultTable) nestedResult.from: nestedResult
      };
    }
    return SqlWriter._(query, options, dialect, doubleStarColumnToResolvedTable,
        buffer ?? StringBuffer(), escapeForDart);
  }

  String write() {
    return writeNodeIntoStringLiteral(query!.root!);
  }

  String writeNodeIntoStringLiteral(AstNode node) {
    _out.write("'");
    visit(node, null);
    _out.write("'");

    return _out.toString();
  }

  String writeSql(AstNode node) {
    visit(node, null);
    return _out.toString();
  }

  @override
  bool isKeyword(String lexeme) {
    return isKeywordLexeme(lexeme) ||
        switch (dialect) {
          SqlDialect.postgres => isPostgresKeywordLexeme(lexeme),
          SqlDialect.mariadb =>
            additionalMariaDBKeywords.contains(lexeme.toUpperCase()),
          _ => false,
        };
  }

  @override
  String escapeIdentifier(String identifier) {
    return dialect.escape(identifier);
  }

  FoundVariable? _findVariable(Variable target) {
    return query!.variables
        .firstWhereOrNull((f) => f.originalIndex == target.resolvedIndex);
  }

  void _writeAnalyzedVariable(FoundVariable variable) {
    if (variable.isArray) {
      _writeRawInSpaces('(\$${expandedName(variable)})');
    } else {
      final mark = _isPostgres ? '\\\$' : '?';
      final syntax =
          dialect.supportsIndexedParameters ? '$mark${variable.index}' : mark;

      _writeRawInSpaces(syntax);
    }
  }

  void _writeRawInSpaces(String str) {
    spaceIfNeeded();
    _out.write(str);
    needsSpace = true;
  }

  @override
  void visitCastExpression(CastExpression e, void arg) {
    final schema = SchemaFromCreateTable(
      driftExtensions: true,
      driftUseTextForDateTime: options.storeDateTimeValuesAsText,
    );

    final type = schema.resolveColumnType(e.typeName);

    String? overriddenTypeName;

    if (type.hint<IsDateTime>() != null) {
      overriddenTypeName = options.storeDateTimeValuesAsText ? 'TEXT' : 'INT';
    } else if (type.hint<IsBoolean>() != null) {
      overriddenTypeName = 'INT';
    } else {
      final enumMatch = FoundReferencesInSql.enumRegex.firstMatch(e.typeName);

      if (enumMatch != null) {
        final isStoredAsText = enumMatch.group(1) != null;
        overriddenTypeName = isStoredAsText ? 'TEXT' : 'INT';
      }
    }

    if (overriddenTypeName != null) {
      keyword(TokenType.cast);
      symbol('(');
      visit(e.operand, arg);
      keyword(TokenType.as);
      symbol(overriddenTypeName, spaceBefore: true);
      symbol(')', spaceAfter: true);
    } else {
      super.visitCastExpression(e, arg);
    }
  }

  @override
  void visitColumnConstraint(ColumnConstraint e, void arg) {
    if (e is MappedBy) {
      // Just drop this constraint, it just serves as a type marker to drift
      return;
    }

    super.visitColumnConstraint(e, arg);
  }

  @override
  void visitNamedVariable(ColonNamedVariable e, void arg) {
    final found = _findVariable(e);
    if (found != null) {
      _writeAnalyzedVariable(found);
    } else {
      super.visitNamedVariable(e, arg);
    }
  }

  @override
  void visitNumberedVariable(NumberedVariable e, void arg) {
    final found = _findVariable(e);
    if (found != null) {
      _writeAnalyzedVariable(found);
    } else {
      super.visitNumberedVariable(e, arg);
    }
  }

  @override
  void visitDriftSpecificNode(DriftSpecificNode e, void arg) {
    if (e is NestedStarResultColumn) {
      final result = _starColumnToResolved[e];
      if (result == null) {
        return super.visitDriftSpecificNode(e, arg);
      }

      final select = query as SqlSelectQuery;
      final prefix = select.resultSet.nestedPrefixFor(result);
      final table = e.tableName;

      // Convert foo.** to "foo.a" AS "nested_0.a", ... for all columns in foo
      var isFirst = true;

      for (final column in result.innerResultSet.scalarColumns) {
        if (isFirst) {
          isFirst = false;
        } else {
          _out.write(', ');
        }

        final columnName = column.name;

        final escapedTable = escapeIdentifier(table);
        final escapedColumn = escapeIdentifier(columnName);
        final escapedAlias = escapeIdentifier('$prefix.$columnName');

        _out.write('$escapedTable.$escapedColumn AS $escapedAlias');
      }
    } else if (e is DartPlaceholder) {
      final moorPlaceholder =
          query!.placeholders.singleWhere((p) => p.astNode == e);

      _writeRawInSpaces('\${${placeholderContextName(moorPlaceholder)}.sql}');
    } else if (e is NestedQueryColumn) {
      assert(
        false,
        'This should be unreachable, because all NestedQueryColumns are '
        'replaced in the NestedQueryTransformer with there required input '
        'variables (or just removed if no variables are required)',
      );
    } else {
      return super.visitDriftSpecificNode(e, arg);
    }
  }
}

class _DartEscapingSink implements StringSink {
  final StringSink _inner;

  _DartEscapingSink(this._inner);

  @override
  void write(Object? obj) {
    _inner.write(escapeForDart(obj.toString()));
  }

  @override
  void writeAll(Iterable objects, [String separator = '']) {
    var first = true;
    for (final obj in objects) {
      if (!first) write(separator);

      write(obj);
      first = false;
    }
  }

  @override
  void writeCharCode(int charCode) {
    const needsEscape = {$$, $single_quote};
    if (needsEscape.contains(charCode)) {
      _inner.writeCharCode($backslash);
    }

    _inner.writeCharCode(charCode);
  }

  @override
  void writeln([Object? obj = '']) {
    write(obj);
    writeCharCode($lf);
  }
}
