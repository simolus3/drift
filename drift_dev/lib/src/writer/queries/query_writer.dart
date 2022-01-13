import 'dart:math' show max;

import 'package:drift_dev/moor_generator.dart';
import 'package:drift_dev/src/analyzer/options.dart';
import 'package:drift_dev/src/analyzer/sql_queries/explicit_alias_transformer.dart';
import 'package:drift_dev/src/utils/string_escaper.dart';
import 'package:drift_dev/writer.dart';
import 'package:recase/recase.dart';
import 'package:sqlparser/sqlparser.dart' hide ResultColumn;

import 'sql_writer.dart';

const highestAssignedIndexVar = '\$arrayStartIndex';

int _compareNodes(AstNode a, AstNode b) =>
    a.firstPosition.compareTo(b.firstPosition);

/// Writes the handling code for a query. The code emitted will be a method that
/// should be included in a generated database or dao class.
class QueryWriter {
  final SqlQuery query;
  final Scope scope;

  late ExplicitAliasTransformer _transformer;

  SqlSelectQuery get _select => query as SqlSelectQuery;
  UpdatingQuery get _update => query as UpdatingQuery;

  MoorOptions get options => scope.writer.options;
  late StringBuffer _buffer;

  bool get _newSelectableMode =>
      query.declaredInMoorFile || options.compactQueryMethods;

  QueryWriter(this.query, this.scope) {
    _buffer = scope.leaf();
  }

  void write() {
    // Note that writing queries can have a result set if they use a RETURNING
    // clause.
    final resultSet = query.resultSet;
    if (resultSet?.needsOwnClass == true) {
      final resultSetScope = scope.findScopeOfLevel(DartScope.library);
      ResultSetWriter(query, resultSetScope).write();
    }

    // The new sql code generation generates query code from the parsed AST,
    // which eliminates unnecessary whitespace and comments. These can sometimes
    // have a semantic meaning though, for instance when they're used in
    // columns. So, we transform the query to add an explicit alias to every
    // column!
    // We do this transformation so late because it shouldn't have an impact on
    // analysis, Dart getter names stay the same.
    if (resultSet != null && options.newSqlCodeGeneration) {
      _transformer = ExplicitAliasTransformer();
      _transformer.rewrite(query.fromContext!.root);
    }

    if (query is SqlSelectQuery) {
      _writeSelect();
    } else if (query is UpdatingQuery) {
      if (resultSet != null) {
        _writeUpdatingQueryWithReturning();
      } else {
        _writeUpdatingQuery();
      }
    }
  }

  void _writeSelect() {
    _writeSelectStatementCreator();

    if (!_newSelectableMode) {
      _writeOneTimeReader();
      _writeStreamReader();
    }
  }

  String _nameOfCreationMethod() {
    if (_newSelectableMode) {
      return query.name;
    } else {
      return '${query.name}Query';
    }
  }

  /// Writes the function literal that turns a "QueryRow" into the desired
  /// custom return type of a query.
  void _writeMappingLambda() {
    final resultSet = query.resultSet!;

    if (resultSet.singleColumn) {
      final column = resultSet.columns.single;
      _buffer.write('(QueryRow row) => '
          '${readingCode(column, scope.generationOptions, options)}');
    } else if (resultSet.matchingTable != null) {
      // note that, even if the result set has a matching table, we can't just
      // use the mapFromRow() function of that table - the column names might
      // be different!
      final match = resultSet.matchingTable!;
      final table = match.table;

      if (match.effectivelyNoAlias) {
        _buffer.write('${table.dbGetterName}.mapFromRow');
      } else {
        _buffer
          ..write('(QueryRow row) => ')
          ..write('${table.dbGetterName}.mapFromRowWithAlias(row, const {');

        for (final alias in match.aliasToColumn.entries) {
          _buffer
            ..write(asDartLiteral(alias.key))
            ..write(': ')
            ..write(asDartLiteral(alias.value.name.name))
            ..write(', ');
        }

        _buffer.write('})');
      }
    } else {
      _buffer.write('(QueryRow row) { return ${query.resultClassName}(');

      if (options.rawResultSetData) {
        _buffer.write('row: row,\n');
      }

      for (final column in resultSet.columns) {
        final fieldName = resultSet.dartNameFor(column);
        _buffer.write('$fieldName: '
            '${readingCode(column, scope.generationOptions, options)},');
      }
      for (final nested in resultSet.nestedResults) {
        final prefix = resultSet.nestedPrefixFor(nested);
        if (prefix == null) continue;

        final fieldName = nested.dartFieldName;
        final tableGetter = nested.table.dbGetterName;

        final mappingMethod =
            nested.isNullable ? 'mapFromRowOrNull' : 'mapFromRow';

        _buffer.write('$fieldName: $tableGetter.$mappingMethod(row, '
            'tablePrefix: ${asDartLiteral(prefix)}),');
      }
      _buffer.write(');\n}');
    }
  }

  /// Returns Dart code that, given a variable of type `QueryRow` named `row`
  /// in the same scope, reads the [column] from that row and brings it into a
  /// suitable type.
  String readingCode(ResultColumn column, GenerationOptions generationOptions,
      MoorOptions moorOptions) {
    var rawDartType = dartTypeNames[column.type];
    if (column.nullable && generationOptions.nnbd) {
      rawDartType = '$rawDartType?';
    }

    String? specialName;
    if (options.newSqlCodeGeneration) {
      specialName = _transformer.newNameFor(column.sqlParserColumn!);
    }

    final dartLiteral = asDartLiteral(specialName ?? column.name);
    var code = 'row.read<$rawDartType>($dartLiteral)';

    if (column.typeConverter != null) {
      final nullableDartType = moorOptions.nullAwareTypeConverters
          ? column.typeConverter!.hasNullableDartType
          : column.nullable;
      final needsAssert = !nullableDartType && generationOptions.nnbd;

      final converter = column.typeConverter;
      code = '${_converter(converter!)}.mapToDart($code)';
      if (needsAssert) code += '!';
    }
    return code;
  }

  /// Writes a method returning a `Selectable<T>`, where `T` is the return type
  /// of the custom query.
  void _writeSelectStatementCreator() {
    final returnType =
        'Selectable<${_select.resultTypeCode(scope.generationOptions)}>';
    final methodName = _nameOfCreationMethod();

    _buffer.write('$returnType $methodName(');
    _writeParameters();
    _buffer.write(') {\n');

    _writeExpandedDeclarations();
    _buffer.write('return customSelect(${_queryCode()}, ');
    _writeVariables();
    _buffer.write(', ');
    _writeReadsFrom();

    _buffer.write(').map(');
    _writeMappingLambda();
    _buffer.write(');\n}\n');
  }

  void _writeOneTimeReader() {
    final returnType =
        'Future<List<${_select.resultTypeCode(scope.generationOptions)}>>';
    _buffer.write('$returnType ${query.name}(');
    _writeParameters();
    _buffer
      ..write(') {\n')
      ..write('return ${_nameOfCreationMethod()}(');
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

    final returnType =
        'Stream<List<${_select.resultTypeCode(scope.generationOptions)}>>';
    _buffer.write('$returnType $methodName(');
    _writeParameters();
    _buffer
      ..write(') {\n')
      ..write('return ${_nameOfCreationMethod()}(');
    _writeUseParameters();
    _buffer.write(').watch();\n}\n');
  }

  void _writeUpdatingQueryWithReturning() {
    final type = query.resultTypeCode(scope.generationOptions);
    _buffer.write('Future<List<$type>> ${query.name}(');
    _writeParameters();
    _buffer.write(') {\n');

    _writeExpandedDeclarations();
    _buffer.write('return customWriteReturning(${_queryCode()},');
    _writeCommonUpdateParameters();
    _buffer.write(').then((rows) => rows.map(');
    _writeMappingLambda();
    _buffer.write(').toList());\n}');
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
    _writeCommonUpdateParameters();
    _buffer.write(',);\n}\n');
  }

  void _writeCommonUpdateParameters() {
    _writeVariables();
    _buffer.write(',');
    _writeUpdates();
    if(!_update.isInsert) _writeUpdateKind();
  }

  void _writeParameters() {
    final namedElements = <FoundElement>[];

    String typeFor(FoundElement element) {
      var type = element.dartTypeCode(scope.generationOptions);

      if (element is FoundDartPlaceholder &&
          element.writeAsScopedFunction(options)) {
        // Generate a function providing result sets that are in scope as args

        final args = element.availableResultSets
            .map((e) => '${e.argumentType} ${e.name}')
            .join(', ');
        type = '$type Function($args)';
      }

      return type;
    }

    var needsComma = false;
    for (final element in query.elements) {
      // Placeholders with a default value generate optional (and thus, named)
      // parameters. Since moor 4, we have an option to also generate named
      // parameters for named variables.
      final isNamed = (element is FoundDartPlaceholder && element.hasDefault) ||
          (element.hasSqlName && options.generateNamedParameters);

      if (isNamed) {
        namedElements.add(element);
      } else {
        if (needsComma) _buffer.write(', ');

        final type = typeFor(element);
        _buffer.write('$type ${element.dartParameterName}');
        needsComma = true;
      }
    }

    // Write optional placeholder as named arguments
    if (namedElements.isNotEmpty) {
      if (needsComma) _buffer.write(', ');
      _buffer.write('{');
      needsComma = false;

      for (final optional in namedElements) {
        if (needsComma) _buffer.write(', ');
        needsComma = true;

        String? defaultCode;

        if (optional is FoundDartPlaceholder) {
          final kind = optional.type;
          if (kind is ExpressionDartPlaceholderType &&
              kind.defaultValue != null) {
            // Wrap the default expression in parentheses to avoid issues with
            // the surrounding precedence in SQL.
            final sql = SqlWriter(scope.options)
                .writeNodeIntoStringLiteral(Parentheses(kind.defaultValue!));
            defaultCode = 'const CustomExpression($sql)';
          } else if (kind is SimpleDartPlaceholderType &&
              kind.kind == SimpleDartPlaceholderKind.orderBy) {
            defaultCode = 'const OrderBy.nothing()';
          }

          // If the parameter is converted to a scoped function, we also need to
          // generate a scoped function as a default value. Since defaults have
          // to be constants, we generate a top-level function which is then
          // used as a tear-off.
          if (optional.writeAsScopedFunction(options) && defaultCode != null) {
            final root = scope.root;
            final counter = root.counter++;
            // ignore: prefer_interpolation_to_compose_strings
            final functionName = r'_$moor$default$' + counter.toString();

            final buffer = root.leaf()
              ..write(optional.dartTypeCode(scope.generationOptions))
              ..write(' ')
              ..write(functionName)
              ..write('(');
            var i = 0;
            for (final arg in optional.availableResultSets) {
              if (i != 0) buffer.write(', ');

              buffer
                ..write(arg.argumentType)
                ..write(' ')
                ..write('_' * (i + 1));
              i++;
            }
            buffer
              ..write(') => ')
              ..write(defaultCode)
              ..write(';');

            // With the function being written, the default code is just a tear-
            // off of that function
            defaultCode = functionName;
          }
        }

        final type = typeFor(optional);

        // No default value, this element is required if it's not nullable
        var isMarkedAsRequired = false;
        var isNullable = false;
        if (optional is FoundVariable) {
          isMarkedAsRequired = optional.isRequired;
          isNullable = optional.nullableInDart;
        }
        final isRequired =
            (!isNullable || isMarkedAsRequired) && defaultCode == null ||
                options.namedParametersAlwaysRequired;
        if (isRequired) {
          _buffer
            ..write(scope.required)
            ..write(' ');
        }

        _buffer.write('$type ${optional.dartParameterName}');
        if (defaultCode != null && !isRequired) {
          _buffer
            ..write(' =  ')
            ..write(defaultCode);
        }
      }

      _buffer.write('}');
    }
  }

  /// Writes code that uses the parameters as declared by [_writeParameters],
  /// assuming that for each parameter, a variable with the same name exists
  /// in the current scope.
  void _writeUseParameters() {
    final parameters = query.elements.map((e) => e.dartParameterName);
    _buffer.write(parameters.join(', '));
  }

  void _writeExpandedDeclarations() {
    _ExpandedDeclarationWriter(query, options, _buffer)
        .writeExpandedDeclarations();
  }

  void _writeVariables() {
    _ExpandedVariableWriter(query, scope, _buffer).writeVariables();
  }

  /// Returns a Dart string literal representing the query after variables have
  /// been expanded. For instance, 'SELECT * FROM t WHERE x IN ?' will be turned
  /// into 'SELECT * FROM t WHERE x IN ($expandedVar1)'.
  String _queryCode() {
    if (scope.options.newSqlCodeGeneration) {
      return SqlWriter(scope.options, query: query).write();
    } else {
      return _legacyQueryCode();
    }
  }

  String _legacyQueryCode() {
    final context = query.fromContext!;
    // sort variables and placeholders by the order in which they appear
    final toReplace = context.root.allDescendants
        .where((node) =>
            node is Variable ||
            node is DartPlaceholder ||
            node is NestedStarResultColumn)
        .toList()
      ..sort(_compareNodes);

    final buffer = StringBuffer("'");

    // Index nested results by their syntactic origin for faster lookups later
    var doubleStarColumnToResolvedTable =
        const <NestedStarResultColumn, NestedResultTable>{};
    if (query is SqlSelectQuery) {
      doubleStarColumnToResolvedTable = {
        for (final nestedResult in _select.resultSet.nestedResults)
          nestedResult.from: nestedResult
      };
    }

    var lastIndex = context.root.firstPosition;

    void replaceNode(AstNode node, String content) {
      // write everything that comes before this var into the buffer
      final currentIndex = node.firstPosition;
      final queryPart = context.sql.substring(lastIndex, currentIndex);
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
          replaceNode(rewriteTarget, '(\$${expandedName(moorVar)})');
        }
      } else if (rewriteTarget is DartPlaceholder) {
        final moorPlaceholder =
            query.placeholders.singleWhere((p) => p.astNode == rewriteTarget);

        replaceNode(rewriteTarget,
            '\${${placeholderContextName(moorPlaceholder)}.sql}');
      } else if (rewriteTarget is NestedStarResultColumn) {
        final result = doubleStarColumnToResolvedTable[rewriteTarget];
        if (result == null) continue;

        final prefix = _select.resultSet.nestedPrefixFor(result);
        final table = rewriteTarget.tableName;

        // Convert foo.** to "foo.a" AS "nested_0.a", ... for all columns in foo
        final expanded = StringBuffer();
        var isFirst = true;

        for (final column in result.table.columns) {
          if (isFirst) {
            isFirst = false;
          } else {
            expanded.write(', ');
          }

          final columnName = column.name.name;
          expanded.write('"$table"."$columnName" AS "$prefix.$columnName"');
        }

        replaceNode(rewriteTarget, expanded.toString());
      }
    }

    // write the final part after the last variable, plus the ending '
    final lastPosition = context.root.lastPosition;
    buffer
      ..write(escapeForDart(context.sql.substring(lastIndex, lastPosition)))
      ..write("'");

    return buffer.toString();
  }

  void _writeReadsFrom() {
    _buffer.write('readsFrom: {');

    for (final table in _select.readsFromTables) {
      _buffer.write('${table.dbGetterName},');
    }

    for (final element in query.elements.whereType<FoundDartPlaceholder>()) {
      _buffer.write('...${placeholderContextName(element)}.watchedTables,');
    }

    _buffer.write('}');
  }

  void _writeUpdates() {
    final from = _update.updates.map((t) => t.table.dbGetterName).join(', ');
    _buffer
      ..write('updates: {')
      ..write(from)
      ..write('}');
  }

  void _writeUpdateKind() {
    if (_update.isOnlyDelete) {
      _buffer.write(', updateKind: UpdateKind.delete');
    } else if (_update.isOnlyUpdate) {
      _buffer.write(', updateKind: UpdateKind.update');
    }
  }
}

/// Returns code to load an instance of the [converter] at runtime.
String _converter(UsedTypeConverter converter) {
  final infoName = converter.table!.entityInfoName;
  final field = '$infoName.${converter.fieldName}';

  return field;
}

class _ExpandedDeclarationWriter {
  final SqlQuery query;
  final MoorOptions options;
  final StringBuffer _buffer;

  bool indexCounterWasDeclared = false;
  bool needsIndexCounter = false;
  int highestIndexBeforeArray = 0;

  _ExpandedDeclarationWriter(this.query, this.options, this._buffer);

  void writeExpandedDeclarations() {
    if (options.newSqlCodeGeneration) {
      _writeExpandedDeclarationsForNewQueryCode();
    } else {
      _writeLegacyExpandedDeclarations();
    }
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
  //
  // For the new query generation mode, we instead give every regular variable
  // an explicit index and then append arrays and other constructs after these
  // indices have been written.

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
      _buffer
        ..write('$highestAssignedIndexVar += ')
        ..write(by)
        ..write(';\n');
    }
  }

  void _writeLegacyExpandedDeclarations() {
    for (final variable in query.variables) {
      // Variables use an explicit index, we need to know the start index at
      // runtime (can be dynamic when placeholders or other arrays appear before
      // this one)
      if (variable.isArray) {
        needsIndexCounter = true;
        break;
      }

      highestIndexBeforeArray = max(highestIndexBeforeArray, variable.index);
    }

    // query.elements are guaranteed to be sorted in the order in which they're
    // going to have an effect when expanded. See TypeMapper.extractElements for
    // the gory details.
    for (final element in query.elements) {
      if (element is FoundVariable) {
        if (element.isArray) {
          _writeArrayVariable(element);
        }
      } else if (element is FoundDartPlaceholder) {
        _writeDartPlaceholder(element);
      }
    }
  }

  void _writeExpandedDeclarationsForNewQueryCode() {
    // In the new code generation, each variable is given an explicit index,
    // regardless of how it was declared. in the source. We then start writing
    // expanded declarations with higher indices, but otherwise in order.
    var index = 0;
    for (final variable in query.variables) {
      if (!variable.isArray) {
        // Re-assign continous indices to non-array variables
        highestIndexBeforeArray = variable.index = ++index;
      }
    }

    needsIndexCounter = true;
    for (final element in query.elements) {
      if (element is FoundVariable) {
        if (element.isArray) {
          _writeArrayVariable(element);
        }
      } else if (element is FoundDartPlaceholder) {
        _writeDartPlaceholder(element);
      }
    }
  }

  void _writeDartPlaceholder(FoundDartPlaceholder element) {
    String useExpression() {
      if (element.writeAsScopedFunction(options)) {
        // The parameter is a function type that needs to be evaluated first
        final args = element.availableResultSets.map((e) {
          final table = 'this.${e.entity.dbGetterName}';
          final needsAlias = e.name != e.entity.displayName;

          if (needsAlias) {
            return 'alias($table, ${asDartLiteral(e.name)})';
          } else {
            return table;
          }
        }).join(', ');
        return '${element.dartParameterName}($args)';
      } else {
        // We can just use the parameter directly
        return element.dartParameterName;
      }
    }

    _writeIndexCounterIfNeeded();
    _buffer
      ..write('final ')
      ..write(placeholderContextName(element))
      ..write(' = ');

    final type = element.type;
    if (type is InsertableDartPlaceholderType) {
      final table = type.table;

      _buffer
        ..write(r'$writeInsertable(this.')
        ..write(table?.dbGetterName)
        ..write(', ')
        ..write(useExpression());

      if (options.newSqlCodeGeneration) {
        _buffer.write(', startIndex: $highestAssignedIndexVar');
      }
      _buffer.write(');\n');
    } else {
      _buffer
        ..write(r'$write(')
        ..write(useExpression());
      if (query.hasMultipleTables) {
        _buffer.write(', hasMultipleTables: true');
      }
      if (options.newSqlCodeGeneration) {
        _buffer.write(', startIndex: $highestAssignedIndexVar');
      }

      _buffer.write(');\n');
    }

    // similar to the case for expanded array variables, we need to
    // increase the index
    _increaseIndexCounter(
        '${placeholderContextName(element)}.amountOfVariables');
  }

  void _writeArrayVariable(FoundVariable element) {
    assert(element.isArray);

    _writeIndexCounterIfNeeded();

    // final expandedvar1 = $expandVar(<startIndex>, <amount>);
    _buffer
      ..write('final ')
      ..write(expandedName(element))
      ..write(' = ')
      ..write(r'$expandVar(')
      ..write(highestAssignedIndexVar)
      ..write(', ')
      ..write(element.dartParameterName)
      ..write('.length);\n');

    // increase highest index for the next expanded element
    _increaseIndexCounter('${element.dartParameterName}.length');
  }
}

class _ExpandedVariableWriter {
  final SqlQuery query;
  final Scope scope;
  final StringBuffer _buffer;

  _ExpandedVariableWriter(this.query, this.scope, this._buffer);

  void writeVariables() {
    _buffer.write('variables: [');

    if (scope.options.newSqlCodeGeneration) {
      _writeNewVariables();
    } else {
      _writeLegacyVariables();
    }

    _buffer.write(']');
  }

  void _writeNewVariables() {
    // In the new generation mode, we first write all non-array variables in
    // a continous block, then we proceed to add arrays and other expanded
    // declarations.
    var first = true;

    for (final variable in query.variables) {
      if (!variable.isArray) {
        if (!first) {
          _buffer.write(', ');
        }

        _writeElement(variable);
        first = false;
      }
    }

    for (final element in query.elements) {
      final shouldBeWritten = element is! FoundVariable || element.isArray;

      if (shouldBeWritten) {
        if (!first) {
          _buffer.write(', ');
        }

        _writeElement(element);
        first = false;
      }
    }
  }

  void _writeLegacyVariables() {
    var first = true;
    for (final element in query.elements) {
      if (!first) {
        _buffer.write(', ');
      }
      first = false;

      _writeElement(element);
    }
  }

  void _writeElement(FoundElement element) {
    if (element is FoundVariable) {
      _writeVariable(element);
    } else if (element is FoundDartPlaceholder) {
      _writeDartPlaceholder(element);
    }
  }

  void _writeVariable(FoundVariable element) {
    // Variables without type converters are written as:
    // `Variable<int>(x)`. When there's a type converter, we instead use
    // `Variable<int>(typeConverter.mapToSql(x))`.
    // Finally, if we're dealing with a list, we use a collection for to
    // write all the variables sequentially.
    String constructVar(String dartExpr) {
      // No longer an array here, we apply a for loop if necessary
      final type =
          element.variableTypeCodeWithoutArray(scope.generationOptions);
      final buffer = StringBuffer('Variable<$type>(');

      if (element.typeConverter != null) {
        // Apply the converter
        buffer
            .write('${_converter(element.typeConverter!)}.mapToSql($dartExpr)');

        final needsNullAssertion =
            !element.nullable && scope.generationOptions.nnbd;
        if (needsNullAssertion) {
          buffer.write('!');
        }
      } else {
        buffer.write(dartExpr);
      }

      buffer.write(')');
      return buffer.toString();
    }

    final name = element.dartParameterName;

    if (element.isArray) {
      final constructor = constructVar(r'$');
      _buffer.write('for (var \$ in $name) $constructor');
    } else {
      _buffer.write('${constructVar(name)}');
    }
  }

  void _writeDartPlaceholder(FoundDartPlaceholder element) {
    _buffer.write('...${placeholderContextName(element)}.introducedVariables');
  }
}
