import 'dart:math' show max;

import 'package:moor_generator/src/analyzer/options.dart';
import 'package:moor_generator/src/model/specified_column.dart';
import 'package:moor_generator/src/model/sql_query.dart';
import 'package:moor_generator/src/utils/string_escaper.dart';
import 'package:moor_generator/src/writer/queries/result_set_writer.dart';
import 'package:moor_generator/src/writer/writer.dart';
import 'package:recase/recase.dart';
import 'package:sqlparser/sqlparser.dart' hide ResultColumn;

const highestAssignedIndexVar = '\$arrayStartIndex';

int _compareNodes(AstNode a, AstNode b) =>
    a.firstPosition.compareTo(b.firstPosition);

/// Writes the handling code for a query. The code emitted will be a method that
/// should be included in a generated database or dao class.
class QueryWriter {
  final SqlQuery query;
  final Scope scope;

  SqlSelectQuery get _select => query as SqlSelectQuery;
  UpdatingQuery get _update => query as UpdatingQuery;

  MoorOptions get options => scope.writer.options;
  StringBuffer _buffer;

  bool get _newSelectableMode =>
      query.declaredInMoorFile || options.compactQueryMethods;

  final Set<String> _writtenMappingMethods;

  QueryWriter(this.query, this.scope, this._writtenMappingMethods) {
    _buffer = scope.leaf();
  }

  /// The expanded sql that we insert into queries whenever an array variable
  /// appears. For the query "SELECT * FROM t WHERE x IN ?", we generate
  /// ```dart
  /// test(List<int> var1) {
  ///   final expandedvar1 = List.filled(var1.length, '?').join(',');
  ///   customSelect('SELECT * FROM t WHERE x IN ($expandedvar1)', ...);
  /// }
  /// ```
  String _expandedName(FoundVariable v) {
    return 'expanded${v.dartParameterName}';
  }

  String _placeholderContextName(FoundDartPlaceholder placeholder) {
    return 'generated${placeholder.name}';
  }

  void write() {
    if (query is SqlSelectQuery) {
      final select = query as SqlSelectQuery;
      if (select.resultSet.needsOwnClass) {
        final resultSetScope = scope.findScopeOfLevel(DartScope.library);
        ResultSetWriter(select, resultSetScope).write();
      }
      _writeSelect();
    } else if (query is UpdatingQuery) {
      _writeUpdatingQuery();
    }
  }

  void _writeSelect() {
    if (!_select.resultSet.singleColumn) {
      _writeMapping();
    }

    _writeSelectStatementCreator();

    if (!_newSelectableMode) {
      _writeOneTimeReader();
      _writeStreamReader();
    }
  }

  String _nameOfMappingMethod() {
    return '_rowTo${_select.resultClassName}';
  }

  String _nameOfCreationMethod() {
    if (_newSelectableMode) {
      return query.name;
    } else {
      return '${query.name}Query';
    }
  }

  /// Writes a mapping method that turns a "QueryRow" into the desired custom
  /// return type.
  void _writeMapping() {
    // avoid writing mapping methods twice if the same result class is written
    // more than once.
    if (!_writtenMappingMethods.contains(_nameOfMappingMethod())) {
      _buffer
        ..write('${_select.resultClassName} ${_nameOfMappingMethod()}')
        ..write('(QueryRow row) {\n')
        ..write('return ${_select.resultClassName}(');

      for (final column in _select.resultSet.columns) {
        final fieldName = _select.resultSet.dartNameFor(column);
        _buffer.write('$fieldName: ${_readingCode(column)},');
      }

      _buffer.write(');\n}\n');
      _writtenMappingMethods.add(_nameOfMappingMethod());
    }
  }

  /// Returns Dart code that, given a variable of type `QueryRow` named `row`
  /// in the same scope, reads the [column] from that row and brings it into a
  /// suitable type.
  String _readingCode(ResultColumn column) {
    final readMethod = readFromMethods[column.type];

    final dartLiteral = asDartLiteral(column.name);
    var code = 'row.$readMethod($dartLiteral)';

    if (column.converter != null) {
      final converter = column.converter;
      final infoName = converter.table.tableInfoName;
      final field = '$infoName.${converter.fieldName}';

      code = '$field.mapToDart($code)';
    }
    return code;
  }

  /// Writes a method returning a `Selectable<T>`, where `T` is the return type
  /// of the custom query.
  void _writeSelectStatementCreator() {
    final returnType = 'Selectable<${_select.resultClassName}>';
    final methodName = _nameOfCreationMethod();

    _buffer.write('$returnType $methodName(');
    _writeParameters();
    _buffer.write(') {\n');

    _writeExpandedDeclarations();
    _buffer.write('return customSelectQuery(${_queryCode()}, ');
    _writeVariables();
    _buffer.write(', ');
    _writeReadsFrom();

    _buffer.write(').map(');
    // for queries that only return one row, it makes more sense to inline the
    // mapping code with a lambda
    if (_select.resultSet.singleColumn) {
      final column = _select.resultSet.columns.single;
      _buffer.write('(QueryRow row) => ${_readingCode(column)}');
    } else {
      _buffer.write(_nameOfMappingMethod());
    }
    _buffer.write(');\n}\n');
  }

  void _writeOneTimeReader() {
    _buffer.write('Future<List<${_select.resultClassName}>> ${query.name}(');
    _writeParameters();
    _buffer..write(') {\n')..write('return ${_nameOfCreationMethod()}(');
    _writeUseParameters();
    _buffer.write(').get();\n}\n');
  }

  void _writeStreamReader() {
    final upperQueryName = ReCase(query.name).pascalCase;

    String methodName;
    // turning the query name into pascal case will remove underscores, add the
    // "private" modifier back in
    if (query.name.startsWith('_')) {
      methodName = '_watch$upperQueryName';
    } else {
      methodName = 'watch$upperQueryName';
    }

    _buffer.write('Stream<List<${_select.resultClassName}>> $methodName(');
    _writeParameters();
    _buffer..write(') {\n')..write('return ${_nameOfCreationMethod()}(');
    _writeUseParameters();
    _buffer.write(').watch();\n}\n');
  }

  void _writeUpdatingQuery() {
    /*
      Future<int> test() {
    return customUpdate('', variables: [], updates: {});
  }
     */
    final implName = _update.isInsert ? 'customInsert' : 'customUpdate';

    _buffer.write('Future<int> ${query.name}(');
    _writeParameters();
    _buffer.write(') {\n');

    _writeExpandedDeclarations();
    _buffer.write('return $implName(${_queryCode()},');

    _writeVariables();
    _buffer.write(',');
    _writeUpdates();

    _buffer.write(',);\n}\n');
  }

  void _writeParameters() {
    final paramList = query.elements.map((e) {
      return '${e.parameterType} ${e.dartParameterName}';
    }).join(', ');
    _buffer.write(paramList);
  }

  /// Writes code that uses the parameters as declared by [_writeParameters],
  /// assuming that for each parameter, a variable with the same name exists
  /// in the current scope.
  void _writeUseParameters() {
    final parameters = query.elements.map((e) => e.dartParameterName);
    _buffer.write(parameters.join(', '));
  }

  // Some notes on parameters and generating query code:
  // We expand array parameters to multiple variables at runtime (see the
  // documentation of FoundVariable and SqlQuery for further discussion).
  // To do this. we have to rewrite the sql. Consider this query:
  // SELECT * FROM t WHERE a = ?1 AND b IN :vars OR c IN :vars AND d = ?
  // When expanding an array variable, we write the expanded sql into a local
  // var called "expanded$Name", e.g. when we bind "vars" to [1, 2, 3] in the
  // query, then `expandedVars` would be "(?2, ?3, ?4)".
  // We use explicit indexes when expanding so that we don't have to expand the
  // "vars" variable twice. To do this, a local var called "$currentVarIndex"
  // keeps track of the highest variable number assigned.
  // We can use the same mechanism for runtime Dart placeholders, where we
  // generate a GenerationContext, write the placeholder and finally extract the
  // variables

  void _writeExpandedDeclarations() {
    var indexCounterWasDeclared = false;
    final needsIndexCounter = query.variables.any((v) => v.isArray);
    var highestIndexBeforeArray = 0;

    void _writeIndexCounterIfNeeded() {
      if (indexCounterWasDeclared || !needsIndexCounter) {
        return; // already written or not necessary at all
      }

      // we only need the index counter when the query contains an expanded
      // element.
      // add +1 because that's going to be the first index of this element.
      final firstVal = highestIndexBeforeArray + 1;
      _buffer.write('var $highestAssignedIndexVar = $firstVal;');
      indexCounterWasDeclared = true;
    }

    void _increaseIndexCounter(String by) {
      if (needsIndexCounter) {
        _buffer..write('$highestAssignedIndexVar += ')..write(by)..write(';\n');
      }
    }

    // query.elements are guaranteed to be sorted in the order in which they're
    // going to have an effect when expanded. See TypeMapper.extractElements for
    // the gory details.
    for (final element in query.elements) {
      if (element is FoundVariable) {
        if (element.isArray) {
          _writeIndexCounterIfNeeded();

          // final expandedvar1 = $expandVar(<startIndex>, <amount>);
          _buffer
            ..write('final ')
            ..write(_expandedName(element))
            ..write(' = ')
            ..write(r'$expandVar(')
            ..write(highestAssignedIndexVar)
            ..write(', ')
            ..write(element.dartParameterName)
            ..write('.length);\n');

          // increase highest index for the next expanded element
          _increaseIndexCounter('${element.dartParameterName}.length');
        }

        if (!indexCounterWasDeclared) {
          highestIndexBeforeArray = max(highestIndexBeforeArray, element.index);
        }
      } else if (element is FoundDartPlaceholder) {
        _writeIndexCounterIfNeeded();

        _buffer
          ..write('final ')
          ..write(_placeholderContextName(element))
          ..write(' = ')
          ..write(r'$write(')
          ..write(element.dartParameterName)
          ..write(');\n');

        // similar to the case for expanded array variables, we need to
        // increase the index
        _increaseIndexCounter(
            '${_placeholderContextName(element)}.amountOfVariables');
      }
    }
  }

  void _writeVariables() {
    _buffer.write('variables: [');

    var first = true;
    for (final element in query.elements) {
      if (!first) {
        _buffer.write(', ');
      }
      first = false;

      if (element is FoundVariable) {
        // for a regular variable: Variable.withInt(x),
        // for a list of vars: for (var $ in vars) Variable.withInt($),
        final constructor = createVariable[element.type];
        final name = element.dartParameterName;

        if (element.isArray) {
          _buffer.write('for (var \$ in $name) $constructor(\$)');
        } else {
          _buffer.write('$constructor($name)');
        }
      } else if (element is FoundDartPlaceholder) {
        _buffer.write(
            '...${_placeholderContextName(element)}.introducedVariables');
      }
    }

    _buffer.write(']');
  }

  /// Returns a Dart string literal representing the query after variables have
  /// been expanded. For instance, 'SELECT * FROM t WHERE x IN ?' will be turned
  /// into 'SELECT * FROM t WHERE x IN ($expandedVar1)'.
  String _queryCode() {
    // sort variables and placeholders by the order in which they appear
    final toReplace = query.fromContext.root.allDescendants
        .where((node) => node is Variable || node is DartPlaceholder)
        .toList()
          ..sort(_compareNodes);

    final buffer = StringBuffer("'");

    var lastIndex = query.fromContext.root.firstPosition;

    void replaceNode(AstNode node, String content) {
      // write everything that comes before this var into the buffer
      final currentIndex = node.firstPosition;
      final queryPart = query.sql.substring(lastIndex, currentIndex);
      buffer.write(escapeForDart(queryPart));
      lastIndex = node.lastPosition;

      // write the replaced content
      buffer.write(content);
    }

    for (final rewriteTarget in toReplace) {
      if (rewriteTarget is Variable) {
        final moorVar = query.variables.singleWhere(
            (f) => f.variable.resolvedIndex == rewriteTarget.resolvedIndex);

        if (moorVar.isArray) {
          replaceNode(rewriteTarget, '(\$${_expandedName(moorVar)})');
        }
      } else if (rewriteTarget is DartPlaceholder) {
        final moorPlaceholder =
            query.placeholders.singleWhere((p) => p.astNode == rewriteTarget);

        replaceNode(rewriteTarget,
            '\${${_placeholderContextName(moorPlaceholder)}.sql}');
      }
    }

    // write the final part after the last variable, plus the ending '
    final lastPosition = query.fromContext.root.lastPosition;
    buffer
      ..write(escapeForDart(query.sql.substring(lastIndex, lastPosition)))
      ..write("'");

    return buffer.toString();
  }

  void _writeReadsFrom() {
    final from = _select.readsFrom.map((t) => t.tableFieldName).join(', ');
    _buffer..write('readsFrom: {')..write(from)..write('}');
  }

  void _writeUpdates() {
    final from = _update.updates.map((t) => t.tableFieldName).join(', ');
    _buffer..write('updates: {')..write(from)..write('}');
  }
}
