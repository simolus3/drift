import 'package:drift/drift.dart';
import 'package:recase/recase.dart';
import 'package:sqlparser/sqlparser.dart' hide ResultColumn;

import '../../analysis/resolver/queries/nested_queries.dart';
import '../../analysis/results/results.dart';
import '../../analysis/options.dart';
import '../../analysis/resolver/queries/explicit_alias_transformer.dart';
import '../../utils/string_escaper.dart';
import '../writer.dart';
import 'result_set_writer.dart';
import 'sql_writer.dart';
import 'utils.dart';

const highestAssignedIndexVar = '\$arrayStartIndex';

typedef _ArgumentContext = ({
  // Indicates that the argument is available under a prefix in SQL, probably
  // because it comes from a [NestedResultTable].
  String? sqlPrefix,
  // Indicates that, even if the argument appears to be non-nullable by itself,
  // it comes from a [NestedResultTable] part of an outer join that could make
  // the entire structure nullable.
  bool isNullable,
});

/// Writes the handling code for a query. The code emitted will be a method that
/// should be included in a generated database or dao class.
class QueryWriter {
  final Scope scope;

  late final ExplicitAliasTransformer _transformer;
  final TextEmitter _emitter;
  StringBuffer get _buffer => _emitter.buffer;

  DriftOptions get options => scope.writer.options;

  QueryWriter(this.scope) : _emitter = scope.leaf();

  void write(SqlQuery query) {
    // Note that writing queries can have a result set if they use a RETURNING
    // clause.
    final resultSet = query.resultSet;
    if (resultSet?.needsOwnClass == true) {
      final resultSetScope = scope.root.child();
      ResultSetWriter(query, resultSetScope).write();
    }

    // We generate the Dart string literal for the SQL query by walking the
    // parsed AST. This eliminates unnecessary whitespace and comments in the
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
  void _writeMappingLambda(InferredResultSet resultSet, QueryRowType rowClass) {
    final queryRow = _emitter.drift('QueryRow');
    final asyncModifier = rowClass.requiresAsynchronousContext ? 'async' : '';

    // We can write every available mapping as a Dart expression via
    // _writeArgumentExpression. This can be turned into a lambda by appending
    // it with `(QueryRow row) => $expression`. That's also what we're doing,
    // but if we'll just call mapFromRow in there, we can just tear that method
    // off instead. This is just an optimization.
    final singleValue = rowClass.singleValue;
    if (singleValue is MatchingDriftTable && singleValue.effectivelyNoAlias) {
      // Tear-off mapFromRow method on table
      _emitter.write('${singleValue.table.dbGetterName}.mapFromRow');
    } else {
      // In all other cases, we're off to write the expression.
      _emitter.write('($queryRow row) $asyncModifier => ');
      _writeArgumentExpression(
          rowClass, resultSet, (sqlPrefix: null, isNullable: false));
    }
  }

  /// Writes code that will read the [argument] for an existing row type from
  /// the raw `QueryRow`.
  void _writeArgumentExpression(
    ArgumentForQueryRowType argument,
    InferredResultSet resultSet,
    _ArgumentContext context,
  ) {
    switch (argument) {
      case RawQueryRow():
        _buffer.write('row');
      case ScalarResultColumn():
        _readScalar(argument, context);
      case MatchingDriftTable():
        _readMatchingTable(argument, context);
      case StructuredFromNestedColumn():
        final prefix = resultSet.nestedPrefixFor(argument.table);
        _writeArgumentExpression(
          argument.nestedType,
          resultSet,
          (sqlPrefix: prefix, isNullable: argument.nullable),
        );
      case MappedNestedListQuery():
        _buffer.write('await ');
        final query = argument.column.query;
        _writeCustomSelectStatement(query, argument.nestedType);
        _buffer.write('.get()');
      case QueryRowType():
        final singleValue = argument.singleValue;
        if (singleValue != null) {
          return _writeArgumentExpression(singleValue, resultSet, context);
        }

        if (context.isNullable) {
          // If this structed type is nullable, it's coming from an OUTER join
          // which means that, even if the individual components making up the
          // structure are non-nullable, they might all be null in SQL. We
          // detect this case by looking for a non-nullable column and, if it's
          // null, return null directly instead of creating the structured type.
          for (final arg in argument.positionalArguments
              .followedBy(argument.namedArguments.values)
              .whereType<ScalarResultColumn>()) {
            if (!arg.nullable) {
              final keyInMap = context.applyPrefix(arg.name);
              _buffer.write(
                  'row.data[${asDartLiteral(keyInMap)}] == null ? null : ');
            }
          }
        }

        final _ArgumentContext childContext = (
          sqlPrefix: context.sqlPrefix,
          // Individual fields making up this query row type aren't covered by
          // the outer nullability.
          isNullable: false,
        );

        if (!argument.isRecord) {
          // We're writing a constructor, so let's start with the class name.
          _emitter.writeDart(argument.rowType);

          final constructorName = argument.constructorName;
          if (constructorName.isNotEmpty) {
            _emitter
              ..write('.')
              ..write(constructorName);
          }
        }

        _buffer.write('(');
        for (final positional in argument.positionalArguments) {
          _writeArgumentExpression(positional, resultSet, childContext);
          _buffer.write(', ');
        }
        argument.namedArguments.forEach((name, parameter) {
          _buffer.write('$name: ');
          _writeArgumentExpression(parameter, resultSet, childContext);
          _buffer.write(', ');
        });

        _buffer.write(')');
    }
  }

  /// Writes Dart code that, given a variable of type `QueryRow` named `row`
  /// in the same scope, reads the [column] from that row and brings it into a
  /// suitable type.
  void _readScalar(ScalarResultColumn column, _ArgumentContext context) {
    final specialName = _transformer.newNameFor(column.sqlParserColumn!);
    final isNullable = context.isNullable || column.nullable;

    var name = specialName ?? column.name;
    if (context.sqlPrefix != null) {
      name = '${context.sqlPrefix}.$name';
    }

    final dartLiteral = asDartLiteral(name);

    final rawDartType =
        _emitter.dartCode(_emitter.innerColumnType(column.sqlType));
    String code;

    if (column.sqlType.isCustom) {
      final method = isNullable ? 'readNullableWithType' : 'readWithType';
      final typeImpl = _emitter.dartCode(column.sqlType.custom!.expression);
      code = 'row.$method<$rawDartType>($dartLiteral, $typeImpl)';
    } else {
      final method = isNullable ? 'readNullable' : 'read';
      code = 'row.$method<$rawDartType>($dartLiteral)';
    }

    final converter = column.typeConverter;
    if (converter != null) {
      if (converter.canBeSkippedForNulls && isNullable) {
        // The type converter maps non-nullable types, but the column may be
        // nullable in SQL => just map null to null and only invoke the type
        // converter for non-null values.
        final wrapFrom = _emitter.drift('NullAwareTypeConverter.wrapFromSql');
        code = '$wrapFrom(${readConverter(_emitter, converter)}, $code)';
      } else {
        // Just apply the type converter directly.
        code = '${readConverter(_emitter, converter)}.fromSql($code)';
      }
    }

    _emitter.write(code);
  }

  void _readMatchingTable(MatchingDriftTable match, _ArgumentContext context) {
    // note that, even if the result set has a matching table, we can't just
    // use the mapFromRow() function of that table - the column names might
    // be different!
    final table = match.table;

    if (match.effectivelyNoAlias) {
      final mappingMethod =
          context.isNullable ? 'mapFromRowOrNull' : 'mapFromRow';
      final sqlPrefix = context.sqlPrefix;

      _emitter.write('await ${table.dbGetterName}.$mappingMethod(row');
      if (sqlPrefix != null) {
        _emitter.write(', tablePrefix: ${asDartLiteral(sqlPrefix)}');
      }

      _emitter.write(')');
    } else {
      // If the entire table can be nullable, we can check whether a non-nullable
      // column from the table is null. If it is, the entire table is null. This
      // can happen when the table comes from an outer join.
      if (context.isNullable) {
        for (final MapEntry(:key, :value) in match.aliasToColumn.entries) {
          if (!value.nullable) {
            final mapKey = context.applyPrefix(key);

            _emitter
                .write('row.data[${asDartLiteral(mapKey)}] == null ? null : ');
          }
        }
      }

      _emitter.write('${table.dbGetterName}.mapFromRowWithAlias(row, const {');

      for (final alias in match.aliasToColumn.entries) {
        _emitter
          ..write(asDartLiteral(context.applyPrefix(alias.key)))
          ..write(': ')
          ..write(asDartLiteral(alias.value.nameInSql))
          ..write(', ');
      }

      _emitter.write('})');
    }
  }

  /// Writes a method returning a `Selectable<T>`, where `T` is the return type
  /// of the custom query.
  void _writeSelectStatementCreator(SqlSelectQuery select) {
    final returnType = AnnotatedDartCode.build((builder) {
      builder
        ..addSymbol('Selectable', AnnotatedDartCode.drift)
        ..addText('<')
        ..addQueryResultRowType(select)
        ..addText('>');
    });

    final methodName = _nameOfCreationMethod(select);

    _emitter
      ..writeDart(returnType)
      ..write(' $methodName(');
    _writeParameters(select);
    _buffer.write(') {\n');

    _writeExpandedDeclarations(select);
    _buffer.write('return');
    _writeCustomSelectStatement(select);
    _buffer.write(';\n}\n');
  }

  void _writeCustomSelectStatement(SqlSelectQuery select,
      [QueryRowType? resultType]) {
    _buffer.write(' customSelect(${_queryCode(select)}, ');
    _writeVariables(select);
    _buffer.write(', ');
    _writeReadsFrom(select);

    final resultSet = select.resultSet;
    resultType ??= select.queryRowType(options);

    if (resultType.requiresAsynchronousContext) {
      _buffer.write(').asyncMap(');
    } else {
      _buffer.write(').map(');
    }

    _writeMappingLambda(resultSet, resultType);
    _buffer.write(')');
  }

  void _writeUpdatingQueryWithReturning(UpdatingQuery update) {
    final type = AnnotatedDartCode.build((builder) {
      builder
        ..addSymbol('Future', AnnotatedDartCode.dartAsync)
        ..addText('<')
        ..addSymbol('List', AnnotatedDartCode.dartCore)
        ..addText('<')
        ..addQueryResultRowType(update)
        ..addText('>>');
    });

    _emitter
      ..writeDart(type)
      ..write(' ${update.name}(');
    _writeParameters(update);
    _buffer.write(') {\n');

    _writeExpandedDeclarations(update);
    _buffer.write('return customWriteReturning(${_queryCode(update)},');
    _writeCommonUpdateParameters(update);

    _buffer.write(').then((rows) => ');

    final resultSet = update.resultSet!;
    final rowType = update.queryRowType(options);

    if (rowType.requiresAsynchronousContext) {
      _buffer.write('Future.wait(rows.map(');
      _writeMappingLambda(resultSet, rowType);
      _buffer.write('))');
    } else {
      _buffer.write('rows.map(');
      _writeMappingLambda(resultSet, rowType);
      _buffer.write(').toList()');
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

    String scopedTypeName(FoundDartPlaceholder element) {
      return '${ReCase(query.name).pascalCase}\$${ReCase(element.name).camelCase}';
    }

    String typeFor(FoundElement element) {
      return _emitter.dartCode(element.dartType(scope));
    }

    String writeScopedTypeFor(FoundDartPlaceholder element) {
      final root = scope.root;
      final type = typeFor(element);
      final scopedType = scopedTypeName(element);

      final args = element.availableResultSets
          .map((e) =>
              '${_emitter.dartCode(scope.entityInfoType(e.entity))} ${e.name}')
          .join(', ');
      root.leaf().write('typedef $scopedType = $type Function($args);');

      return scopedType;
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

        var type = typeFor(element);
        if (element is FoundDartPlaceholder &&
            element.writeAsScopedFunction(options)) {
          type = writeScopedTypeFor(element);
        }
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
        var isNullable = false;
        var type = typeFor(optional);

        if (optional is FoundDartPlaceholder) {
          // If optional Dart placeholders are written as functions, they are
          // generated as nullable parameters. The default is handled with a
          // `??` in the method's body.
          if (optional.writeAsScopedFunction(options)) {
            isNullable = optional.hasDefaultOrImplicitFallback;
            type = writeScopedTypeFor(optional);

            if (isNullable) {
              type += '?';
            }
          } else {
            defaultCode = _defaultForDartPlaceholder(optional, scope);
          }
        }

        // No default value, this element is required if it's not nullable
        var isMarkedAsRequired = false;
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
    _ExpandedDeclarationWriter(query, options, scope, _buffer)
        .writeExpandedDeclarations();
  }

  void _writeVariables(SqlQuery query) {
    _ExpandedVariableWriter(query, _emitter).writeVariables();
  }

  /// Returns a Dart string literal representing the query after variables have
  /// been expanded. For instance, 'SELECT * FROM t WHERE x IN ?' will be turned
  /// into 'SELECT * FROM t WHERE x IN ($expandedVar1)'.
  String _queryCode(SqlQuery query) {
    final dialectForCode = <String, List<SqlDialect>>{};

    for (final dialect in scope.options.supportedDialects) {
      final code =
          SqlWriter(scope.options, dialect: dialect, query: query).write();

      dialectForCode.putIfAbsent(code, () => []).add(dialect);
    }

    if (dialectForCode.length == 1) {
      // All supported dialects use the same SQL syntax, so we can just use that
      return dialectForCode.keys.single;
    } else {
      // Create a switch expression matching over the dialect of the database
      // we're connected to.
      final buffer = StringBuffer('switch (executor.dialect) {');
      final dialectEnum = scope.drift('SqlDialect');

      var index = 0;
      for (final MapEntry(key: code, value: dialects)
          in dialectForCode.entries) {
        index++;

        buffer
            .write(dialects.map((e) => '$dialectEnum.${e.name}').join(' || '));
        if (index == dialectForCode.length) {
          // In the last branch, match all dialects as a fallback
          buffer.write(' || _ ');
        }

        buffer
          ..write(' => ')
          ..write(code)
          ..write(', ');
      }

      buffer.writeln('}');
      return buffer.toString();
    }
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
      _buffer.write(', updateKind: ${_emitter.drift('UpdateKind.delete')}');
    } else if (update.isOnlyUpdate) {
      _buffer.write(', updateKind: ${_emitter.drift('UpdateKind.update')}');
    }
  }
}

/// Returns code to load an instance of the [converter] at runtime.
String readConverter(TextEmitter emitter, AppliedTypeConverter converter) {
  return emitter.dartCode(emitter.readConverter(converter));
}

class _ExpandedDeclarationWriter {
  final SqlQuery query;
  final DriftOptions options;
  final Scope _scope;
  final StringBuffer _buffer;

  bool indexCounterWasDeclared = false;
  bool needsIndexCounter = false;
  int highestIndexBeforeArray = 0;

  _ExpandedDeclarationWriter(
      this.query, this.options, this._scope, this._buffer);

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
          final needsAlias = e.name != e.entity.schemaName;

          if (needsAlias) {
            return 'alias($table, ${asDartLiteral(e.name)})';
          } else {
            return table;
          }
        }).join(', ');

        final defaultValue = _defaultForDartPlaceholder(element, _scope);

        if (defaultValue != null) {
          // Optional elements written as a function are generated as nullable
          // parameters. We need to emit the default if the actual value is
          // null at runtime.
          return '${element.dartParameterName}?.call($args) ?? $defaultValue';
        } else {
          return '${element.dartParameterName}($args)';
        }
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

      if (element.availableResultSets.length > 1) {
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
  final TextEmitter _emitter;
  StringBuffer get _buffer => _emitter.buffer;

  _ExpandedVariableWriter(this.query, this._emitter);

  void writeVariables() {
    _buffer.write('variables: ');

    // Some dialects don't support variables with an explicit index. In that
    // case, we have to desugar them by duplicating variables, e.g. `:a AND :a`
    // would be transformed to `? AND ?` with us binding the value to both
    // variables.
    if (_emitter.writer.options.supportedDialects
            .any((e) => !e.supportsIndexedParameters) &&
        query.referencesAnyElementMoreThanOnce) {
      _buffer.write('executor.dialect.desugarDuplicateVariables([');
      _writeNewVariables();
      _buffer.write('],');

      // Every time a variable is used in the generated SQL text, we have to
      // track the variable's index in the second list
      _buffer.write('[');
      for (final source in query.elementSources) {
        switch (source.referencedElement) {
          case FoundVariable variable:
            _buffer.write('${variable.index}, ');
            break;
          case FoundDartPlaceholder placeholder:
            final context = placeholderContextName(placeholder);
            _buffer.write('...$context.variableIndices');
            break;
        }
      }

      _buffer.write('])');
    } else {
      _buffer.write('[');
      _writeNewVariables();
      _buffer.write(']');
    }
  }

  void _writeNewVariables() {
    // In the new generation mode, we first write all non-array variables in
    // a continuous block, then we proceed to add arrays and other expanded
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
      final type = _emitter
          .dartCode(_emitter.innerColumnType(element.sqlType, nullable: false));

      final varType = _emitter.drift('Variable');
      final buffer = StringBuffer('$varType<$type>(');
      final capture = element.forCaptured;

      final converter = element.typeConverter;
      if (converter != null) {
        // Apply the converter.
        if (element.nullable && converter.canBeSkippedForNulls) {
          final nullAware = _emitter.drift('NullAwareTypeConverter');

          buffer.write('$nullAware.wrapToSql('
              '${readConverter(_emitter, element.typeConverter!)}, $dartExpr)');
        } else {
          buffer.write(
              '${readConverter(_emitter, element.typeConverter!)}.toSql($dartExpr)');
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

String? _defaultForDartPlaceholder(
    FoundDartPlaceholder placeholder, Scope scope) {
  final kind = placeholder.type;
  if (kind is ExpressionDartPlaceholderType && kind.defaultValue != null) {
    // Wrap the default expression in parentheses to avoid issues with
    // the surrounding precedence in SQL.
    final (sql, dialectSpecific) =
        scope.sqlByDialect(Parentheses(kind.defaultValue!));

    if (dialectSpecific) {
      return 'const ${scope.drift('CustomExpression')}.dialectSpecific($sql)';
    } else {
      return 'const ${scope.drift('CustomExpression')}($sql)';
    }
  } else if (kind is SimpleDartPlaceholderType &&
      kind.kind == SimpleDartPlaceholderKind.orderBy) {
    return 'const ${scope.drift('OrderBy')}.nothing()';
  } else {
    assert(!placeholder.hasDefaultOrImplicitFallback);
    return null;
  }
}

extension on _ArgumentContext {
  String applyPrefix(String originalName) {
    return switch (sqlPrefix) {
      null => originalName,
      var s => '$s.$originalName',
    };
  }
}
