import 'package:charcode/ascii.dart';
import 'package:moor_generator/moor_generator.dart';
import 'package:moor_generator/src/utils/string_escaper.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/utils/node_to_text.dart';

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

class SqlWriter extends NodeSqlBuilder {
  final StringBuffer _out;
  final SqlQuery query;
  final Map<NestedStarResultColumn, NestedResultTable> _starColumnToResolved;

  SqlWriter._(this.query, this._starColumnToResolved, StringBuffer out)
      : _out = out,
        super(_DartEscapingSink(out));

  factory SqlWriter(SqlQuery query) {
    // Index nested results by their syntactic origin for faster lookups later
    var doubleStarColumnToResolvedTable =
        const <NestedStarResultColumn, NestedResultTable>{};

    if (query is SqlSelectQuery) {
      doubleStarColumnToResolvedTable = {
        for (final nestedResult in query.resultSet.nestedResults)
          nestedResult.from: nestedResult
      };
    }
    return SqlWriter._(query, doubleStarColumnToResolvedTable, StringBuffer());
  }

  String write() {
    _out.write("'");
    visit(query.fromContext.root, null);
    _out.write("'");

    return _out.toString();
  }

  FoundVariable _findMoorVar(Variable target) {
    return query.variables.singleWhere(
      (f) => f.variable.resolvedIndex == target.resolvedIndex,
      orElse: () => null,
    );
  }

  void _writeArrayVariable(FoundVariable moorVar) {
    assert(moorVar.isArray);

    _writeRawInSpaces('(\$${expandedName(moorVar)})');
  }

  void _writeRawInSpaces(String str) {
    spaceIfNeeded();
    _out.write(str);
    needsSpace = true;
  }

  @override
  void visitDartPlaceholder(DartPlaceholder e, void arg) {
    final moorPlaceholder =
        query.placeholders.singleWhere((p) => p.astNode == e);

    _writeRawInSpaces('\${${placeholderContextName(moorPlaceholder)}.sql}');
  }

  @override
  void visitNamedVariable(ColonNamedVariable e, void arg) {
    final moor = _findMoorVar(e);
    if (moor != null && moor.isArray) {
      _writeArrayVariable(moor);
    } else {
      super.visitNamedVariable(e, arg);
    }
  }

  @override
  void visitNumberedVariable(NumberedVariable e, void arg) {
    final moor = _findMoorVar(e);
    if (moor != null && moor.isArray) {
      _writeArrayVariable(moor);
    } else {
      super.visitNumberedVariable(e, arg);
    }
  }

  @override
  void visitMoorNestedStarResultColumn(NestedStarResultColumn e, void arg) {
    final result = _starColumnToResolved[e];
    if (result == null) {
      return super.visitMoorNestedStarResultColumn(e, arg);
    }

    final select = query as SqlSelectQuery;
    final prefix = select.resultSet.nestedPrefixFor(result);
    final table = e.tableName;

    // Convert foo.** to "foo.a" AS "nested_0.a", ... for all columns in foo
    var isFirst = true;

    for (final column in result.table.columns) {
      if (isFirst) {
        isFirst = false;
      } else {
        _out.write(', ');
      }

      final columnName = column.name.name;
      _out.write('"$table"."$columnName" AS "$prefix.$columnName"');
    }
  }
}

class _DartEscapingSink implements StringSink {
  final StringSink _inner;

  _DartEscapingSink(this._inner);

  @override
  void write(Object obj) {
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
  void writeln([Object obj = '']) {
    write(obj);
    writeCharCode($lf);
  }
}
