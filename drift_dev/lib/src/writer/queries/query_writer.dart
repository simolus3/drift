import 'package:drift_dev/moor_generator.dart';
import 'package:drift_dev/src/analyzer/options.dart';
import 'package:drift_dev/src/analyzer/sql_queries/explicit_alias_transformer.dart';
import 'package:drift_dev/src/analyzer/sql_queries/nested_queries.dart';
import 'package:drift_dev/src/utils/string_escaper.dart';
import 'package:drift_dev/writer.dart';
import 'package:sqlparser/sqlparser.dart' hide ResultColumn;

import 'sql_writer.dart';

const highestAssignedIndexVar = '\$arrayStartIndex';

/// Writes the handling code for a query. The code emitted will be a method that
/// should be included in a generated database or dao class.
class QueryWriter {
  final Scope scope;

  late final ExplicitAliasTransformer _transformer;
  final StringBuffer _buffer;

  DriftOptions get options => scope.writer.options;

  QueryWriter(this.scope) : _buffer = scope.leaf();

  void write(SqlQuery query) {
    // Note that writing queries can have a result set if they use a RETURNING
    // clause.
    final resultSet = query.resultSet;
    if (resultSet?.needsOwnClass == true) {
      final resultSetScope = scope.findScopeOfLevel(DartScope.library);
      ResultSetWriter(query, resultSetScope).write();
    }

    // We generate the Dart string literal for the SQL query by walking the
    // parsed AST. This eliminates unecessary whitespace and comments in the
    // generated code.
    // In some cases, the whitespace has an impact on the semantic of the
    // query. For instance, `SELECT 1 + 2` has a different column name than
    // `SELECT 1+2`. To work around this, we transform the query to add an
    // explicit alias to every column (since whitespace doesn't matter if the
    // query is written as `SELECT 1+2 AS c0`).
    // We do this transformation so late because it shouldn't have an impact on
    // analysis, Dart getter names stay the same.
    if (resultSet != null) {
      _transformer = ExplicitAliasTransformer();
      _transformer.rewrite(query.root!);

      final nested = query is SqlSelectQuery ? query.nestedContainer : null;
      if (nested != null) {
        addHelperNodes(nested);
      }
    }

    if (query is SqlSelectQuery) {
      _writeSelect(query);
    } else if (query is UpdatingQuery) {
      if (resultSet != null) {
        _writeUpdatingQueryWithReturning(query);
      } else {
        _writeUpdatingQuery(query);
      }
    }
  }

  void _writeSelect(SqlSelectQuery select) {
    _writeSelectStatementCreator(select);
  }

  String _nameOfCreationMethod(SqlSelectQuery select) => select.name;

  /// Writes the function literal that turns a "QueryRow" into the desired
  /// custom return type of a query.
  void _writeMappingLambda(SqlQuery query) {
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
      _buffer.write('(QueryRow row) ');
      if (query.needsAsyncMapping) {
        _buffer.write('async ');
      }
      _buffer.write('{ return ${query.resultClassName}(');

      if (options.rawResultSetData) {
        _buffer.write('row: row,\n');
      }

      for (final column in resultSet.columns) {
        final fieldName = resultSet.dartNameFor(column);
        _buffer.write('$fieldName: '
            '${readingCode(column, scope.generationOptions, options)},');
      }
      for (final nested in resultSet.nestedResults) {
        if (nested is NestedResultTable) {
          final prefix = resultSet.nestedPrefixFor(nested);
          if (prefix == null) continue;

          final fieldName = nested.dartFieldName;
          final tableGetter = nested.table.dbGetterName;

          final mappingMethod =
              nested.isNullable ? 'mapFromRowOrNull' : 'mapFromRow';

          _buffer.write('$fieldName: await $tableGetter.$mappingMethod(row, '
              'tablePrefix: ${asDartLiteral(prefix)}),');
        } else if (nested is NestedResultQuery) {
          final fieldName = nested.filedName();
          _buffer.write('$fieldName: await ');

          _writeCustomSelectStatement(nested.query);

          _buffer.write('.get(),');
        }
      }
      _buffer.write(');\n}');
    }
  }

  /// Returns Dart code that, given a variable of type `QueryRow` named `row`
  /// in the same scope, reads the [column] from that row and brings it into a
  /// suitable type.
  String readingCode(ResultColumn column, GenerationOptions generationOptions,
      DriftOptions moorOptions) {
    final specialName = _transformer.newNameFor(column.sqlParserColumn!);

    final dartLiteral = asDartLiteral(specialName ?? column.name);
    final method = column.nullable ? 'readNullable' : 'read';
    final rawDartType = dartTypeNames[column.type];
    var code = 'row.$method<$rawDartType>($dartLiteral)';

    final converter = column.typeConverter;
    if (converter != null) {
      if (converter.canBeSkippedForNulls && column.nullable) {
        // The type converter maps non-nullable types, but the column may be
        // nullable in SQL => just map null to null and only invoke the type
        // converter for non-null values.
        code = 'NullAwareTypeConverter.wrapFromSql'
            '(${_converter(converter)}, $code)';
      } else {
        // Just apply the type converter directly.
        code = '${_converter(converter)}.fromSql($code)';
      }
    }
    return code;
  }

  /// Writes a method returning a `Selectable<T>`, where `T` is the return type
  /// of the custom query.
  void _writeSelectStatementCreator(SqlSelectQuery select) {
    final returnType =
        'Selectable<${select.resultTypeCode(scope.generationOptions)}>';
    final methodName = _nameOfCreationMethod(select);

    _buffer.write('$returnType $methodName(');
    _writeParameters(select);
    _buffer.write(') {\n');

    _writeExpandedDeclarations(select);
    _buffer.write('return');
    _writeCustomSelectStatement(select);
    _buffer.write(';\n}\n');
  }

  void _writeCustomSelectStatement(SqlSelectQuery select) {
    _buffer.write(' customSelect(${_queryCode(select)}, ');
    _writeVariables(select);
    _buffer.write(', ');
    _writeReadsFrom(select);

    if (select.needsAsyncMapping) {
      _buffer.write(').asyncMap(');
    } else {
      _buffer.write(').map(');
    }
    _writeMappingLambda(select);
    _buffer.write(')');
  }

  void _writeUpdatingQueryWithReturning(UpdatingQuery update) {
    final type = update.resultTypeCode(scope.generationOptions);
    _buffer.write('Future<List<$type>> ${update.name}(');
    _writeParameters(update);
    _buffer.write(') {\n');

    _writeExpandedDeclarations(update);
    _buffer.write('return customWriteReturning(${_queryCode(update)},');
    _writeCommonUpdateParameters(update);

    _buffer.write(').then((rows) => ');
    if (update.needsAsyncMapping) {
      _buffer.write('Future.wait(rows.map(');
      _writeMappingLambda(update);
      _buffer.write('))');
    } else {
      _buffer.write('rows.map(');
      _writeMappingLambda(update);
      _buffer.write(')');
    }
    _buffer.write(');\n}');
  }

  void _writeUpdatingQuery(UpdatingQuery update) {
    /*
      Future<int> test() {
    return customUpdate('', variables: [], updates: {});
  }
     */
    final implName = update.isInsert ? 'customInsert' : 'customUpdate';

    _buffer.write('Future<int> ${update.name}(');
    _writeParameters(update);
    _buffer.write(') {\n');

    _writeExpandedDeclarations(update);
    _buffer.write('return $implName(${_queryCode(update)},');
    _writeCommonUpdateParameters(update);
    _buffer.write(',);\n}\n');
  }

  void _writeCommonUpdateParameters(UpdatingQuery update) {
    _writeVariables(update);
    _buffer.write(',');
    _writeUpdates(update);
    _writeUpdateKind(update);
  }

  void _writeParameters(SqlQuery query) {
    final namedElements = <FoundElement>[];

    String typeFor(FoundElement element) {
      var type = element.dartTypeCode();

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
    for (final element in query.elementsWithNestedQueries()) {
      if (element.hidden) continue;

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
          _buffer.write('required ');
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

  void _writeExpandedDeclarations(SqlQuery query) {
    _ExpandedDeclarationWriter(query, options, _buffer)
        .writeExpandedDeclarations();
  }

  void _writeVariables(SqlQuery query) {
    _ExpandedVariableWriter(query, scope, _buffer).writeVariables();
  }

  /// Returns a Dart string literal representing the query after variables have
  /// been expanded. For instance, 'SELECT * FROM t WHERE x IN ?' will be turned
  /// into 'SELECT * FROM t WHERE x IN ($expandedVar1)'.
  String _queryCode(SqlQuery query) {
    return SqlWriter(scope.options, query: query).write();
  }

  void _writeReadsFrom(SqlSelectQuery select) {
    _buffer.write('readsFrom: {');

    for (final table in select.readsFromTables) {
      _buffer.write('${table.dbGetterName},');
    }

    for (final element in select
        .elementsWithNestedQueries()
        .whereType<FoundDartPlaceholder>()) {
      _buffer.write('...${placeholderContextName(element)}.watchedTables,');
    }

    _buffer.write('}');
  }

  void _writeUpdates(UpdatingQuery update) {
    final from = update.updates.map((t) => t.table.dbGetterName).join(', ');
    _buffer
      ..write('updates: {')
      ..write(from)
      ..write('}');
  }

  void _writeUpdateKind(UpdatingQuery update) {
    if (update.isOnlyDelete) {
      _buffer.write(', updateKind: UpdateKind.delete');
    } else if (update.isOnlyUpdate) {
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
  final DriftOptions options;
  final StringBuffer _buffer;

  bool indexCounterWasDeclared = false;
  bool needsIndexCounter = false;
  int highestIndexBeforeArray = 0;

  _ExpandedDeclarationWriter(this.query, this.options, this._buffer);

  void writeExpandedDeclarations() {
    // When the SQL query is written to a Dart string, we give each variable an
    // eplixit index (e.g `?2`), regardless of how it was declared in the
    // source.
    // Array variables are converted into multiple variables at runtime, but
    // let's give variables before that an index, all other variables can be
    // turned into explicit indices though. We ensure that array variables have
    // higher indices than other variables.
    var index = 0;
    for (final variable in query.variables) {
      if (!variable.isArray) {
        // Re-assign continous indices to non-array variables
        highestIndexBeforeArray = variable.index = ++index;
      }
    }

    needsIndexCounter = true;
    for (final element in query.elementsWithNestedQueries()) {
      if (element is FoundVariable) {
        if (element.isArray) {
          _writeArrayVariable(element);
        }
      } else if (element is FoundDartPlaceholder) {
        _writeDartPlaceholder(element);
      }
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
        ..write(useExpression())
        ..write(', startIndex: $highestAssignedIndexVar');

      _buffer.write(');\n');
    } else {
      _buffer
        ..write(r'$write(')
        ..write(useExpression());
      if (query.hasMultipleTables) {
        _buffer.write(', hasMultipleTables: true');
      }
      _buffer
        ..write(', startIndex: $highestAssignedIndexVar')
        ..write(');\n');
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
    _writeNewVariables();
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
    // `Variable<int>(typeConverter.toSql(x))`.
    // Finally, if we're dealing with a list, we use a collection for to
    // write all the variables sequentially.
    String constructVar(String dartExpr) {
      // No longer an array here, we apply a for loop if necessary
      final type = element.innerColumnType(nullable: false);
      final buffer = StringBuffer('Variable<$type>(');
      final capture = element.forCaptured;

      final converter = element.typeConverter;
      if (converter != null) {
        // Apply the converter.
        if (element.nullable && converter.canBeSkippedForNulls) {
          buffer.write('NullAwareTypeConverter.wrapToSql('
              '${_converter(element.typeConverter!)}, $dartExpr)');
        } else {
          buffer
              .write('${_converter(element.typeConverter!)}.toSql($dartExpr)');
        }
      } else if (capture != null) {
        buffer.write('row.read(${asDartLiteral(capture.helperColumn)})');
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
      _buffer.write(constructVar(name));
    }
  }

  void _writeDartPlaceholder(FoundDartPlaceholder element) {
    _buffer.write('...${placeholderContextName(element)}.introducedVariables');
  }
}
