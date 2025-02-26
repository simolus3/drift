// ignore_for_file: implementation_imports

import 'dart:convert';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';

import 'package:drift_dev/src/backends/build/backend.dart';
import 'package:drift_dev/src/analysis/driver/driver.dart';
import 'package:drift_dev/src/analysis/options.dart';
import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:drift_dev/src/analysis/driver/error.dart';
import 'package:drift_dev/src/analysis/resolver/queries/query_analyzer.dart';
import 'package:drift_dev/src/writer/writer.dart';
import 'package:drift_dev/src/writer/queries/query_writer.dart';
import 'package:drift_riverpod/drift_riverpod.dart';
import 'package:source_gen/source_gen.dart';

import 'utils.dart';

final annotationChecker = TypeChecker.fromUrl(
    'package:drift_riverpod/src/annotation.dart#QueryProvider');

final class QueryProviderDefinition {
  final QueryProvider annotation;
  final TopLevelVariableElement element;
  final String methodName;
  final Expression databaseProvider;
  final DriftElementId database;
  final List<QueryParameterDefinition> parameters;
  final FormalParameterList? parameterDeclarations;
  final List<StatementPart> statement;
  final DartType? fixedResultType;

  bool get isSingleRow => annotation.singleRow;

  QueryProviderDefinition({
    required this.annotation,
    required this.element,
    required this.methodName,
    required this.databaseProvider,
    required this.database,
    required this.parameters,
    required this.statement,
    required this.parameterDeclarations,
    required this.fixedResultType,
  });

  String get name => element.name;

  static Future<(QueryProviderDefinition?, List<DriftAnalysisError>)> parse(
      Element element, AstNode declaration,
      [DartObject? annotation]) async {
    annotation ??= annotationChecker.firstAnnotationOf(element)!;

    final parser = _QueryProviderParser(
        await KnownElements.read(element), element, declaration, annotation);
    return (parser.parseInner(), parser.errors);
  }

  String buildSql() {
    final buffer = StringBuffer();
    for (final part in statement) {
      switch (part) {
        case StringPart():
          buffer.write(part.lexeme);
        case DartExpression(:final variableIndex):
          buffer.write('?$variableIndex');
      }
    }

    return buffer.toString();
  }
}

final class _QueryProviderParser {
  final KnownElements knownElements;
  final Element element;
  final AstNode declaration;
  final DartObject annotation;

  late final typeSystem = element.library!.typeSystem;
  final errors = <DriftAnalysisError>[];
  final parts = <StatementPart>[];
  int _variableIndex = 1;

  final Map<ParameterElement, QueryParameterDefinition> _parametersToQuery = {};
  final List<QueryParameterDefinition> _parameters = [];

  _QueryProviderParser(
      this.knownElements, this.element, this.declaration, this.annotation);

  void error(String message, [SyntacticEntity? on]) {
    if (on != null) {
      errors.add(DriftAnalysisError.inDartAst(element, on, message));
    } else {
      errors.add(DriftAnalysisError.forDartElement(element, message));
    }
  }

  DriftElementId? readDatabaseType(DartType type, Expression context) {
    // We expect that type is a riverpod provider providing a drift database.
    final asProviderListenable =
        type.asInstanceOf(knownElements.providerListenable);
    if (asProviderListenable == null) {
      error('This must be a riverpod provider', context);
      return null;
    }

    final [databaseType] = asProviderListenable.typeArguments;
    if (databaseType is! InterfaceType) {
      error('The provider must provide a drift database or accessor', context);
      return null;
    }

    return DriftElementId(
        databaseType.element.library.source.uri, databaseType.element.name);
  }

  QueryProviderDefinition? parseInner() {
    final parsed = annotation.readQueryProvider();
    final rowTypeArg = (annotation.type as InterfaceType).typeArguments[0];

    if (element is! TopLevelVariableElement) {
      error('Query providers must be top-level variables.');
      return null;
    }

    final field = declaration as VariableDeclaration;
    final initializer = field.initializer;
    if (initializer == null) {
      error('Query provider must have an initializer');
      return null;
    }
    if (initializer is! MethodInvocation) {
      error(
          'Must be a method invocation, e.g. '
          "`database.${element.name}('SELECT * FROM users;')`",
          initializer);
      return null;
    }

    final providerExpr = initializer.target;
    if (providerExpr == null || providerExpr.staticType == null) {
      error('Could not resolve provider');
      return null;
    }
    final databaseType =
        readDatabaseType(providerExpr.staticType!, providerExpr);
    if (databaseType == null) {
      return null;
    }

    final arguments = initializer.argumentList.arguments;
    if (arguments.length != 1) {
      error('Expected a single argument, the SQL query',
          initializer.argumentList);
      return null;
    }

    final argument = arguments[0];
    FormalParameterList? rawParameters;
    Expression? sqlStatement;
    if (argument is FunctionExpression) {
      if (argument.parameters case final params?) {
        rawParameters = params;
        _parseArguments(params);
      }

      if (argument.body case ExpressionFunctionBody(:final expression)) {
        sqlStatement = expression;
      } else {
        error('This must be an expression function body', argument.body);
      }
    } else {
      sqlStatement = argument;
    }

    if (sqlStatement == null) {
      return null;
    }
    addStatement(sqlStatement);

    return QueryProviderDefinition(
      annotation: parsed,
      element: element as TopLevelVariableElement,
      methodName: initializer.methodName.name,
      databaseProvider: providerExpr,
      database: databaseType,
      parameters: _parameters,
      parameterDeclarations: rawParameters,
      statement: parts,
      fixedResultType: rowTypeArg is DynamicType ? null : rowTypeArg,
    );
  }

  void _parseArguments(FormalParameterList parameters) {
    var positionalParameters = 0;
    for (final parameter in parameters.parameterElements) {
      if (parameter != null && parameter.name != 'ref') {
        final queryParameter = QueryParameterDefinition(
            parameter, parameter.isPositional ? positionalParameters++ : -1);
        _parameters.add(queryParameter);
        _parametersToQuery[parameter] = queryParameter;
      }
    }
  }

  void addStatement(Expression statement) {
    void addRawString(String value) {
      parts.add(StringPart(lexeme: value));
    }

    void addInterpolation(Expression expression) {
      QueryParameterDefinition? param;
      int? index;

      if (expression is SimpleIdentifier) {
        if (_parametersToQuery[expression.staticElement]
            case final parameter?) {
          param = parameter;
          if (parameter.sqlIndex case final existingIndex?) {
            index = existingIndex;
          } else {
            index = parameter.sqlIndex = _variableIndex++;
          }
        }
      }

      parts.add(DartExpression(expression, param, index ?? _variableIndex++));
    }

    if (statement is SimpleStringLiteral) {
      addRawString(statement.value);
    } else if (statement is AdjacentStrings) {
      for (final entry in statement.strings) {
        addStatement(entry);
      }
    } else if (statement is StringInterpolation) {
      for (final entry in statement.elements) {
        switch (entry) {
          case InterpolationExpression(:final expression):
            addInterpolation(expression);
          case InterpolationString(:final value):
            addRawString(value);
        }
      }
    }
  }
}

final class QueryParameterDefinition {
  final ParameterElement dart;
  final int dartIndex;
  int? sqlIndex;
  FoundVariable? boundVariable;

  QueryParameterDefinition(this.dart, this.dartIndex);

  String get name => dart.name;

  AnnotatedDartCode get typeCode {
    if (boundVariable case final bound?) {
      return AnnotatedDartCode.build((b) => b.addDriftType(bound));
    } else {
      return AnnotatedDartCode.type(dart.type);
    }
  }
}

sealed class StatementPart {}

final class StringPart extends StatementPart {
  final String lexeme;

  StringPart({required this.lexeme});
}

final class DartExpression extends StatementPart {
  final Expression expression;

  /// If this expression is a direct reference of a query parameter, this
  /// holds that parameter.
  final QueryParameterDefinition? parameter;
  FoundVariable? queryVariable;
  final int variableIndex;

  DartExpression(this.expression, this.parameter, this.variableIndex);
}

final class ResolvedQueryProvider {
  final QueryProviderDefinition definition;
  final SqlQuery? query;
  final Map<FoundVariable, DartExpression> variableBinding;
  final DriftOptions? databaseOptions;
  final List<DriftAnalysisError> errors;

  ResolvedQueryProvider(
    this.definition,
    this.databaseOptions,
    this.query,
    this.errors,
    this.variableBinding,
  );

  static Future<ResolvedQueryProvider> analyze(
    QueryProviderDefinition definition,
    BuildStep buildStep,
  ) async {
    final errors = <DriftAnalysisError>[];
    final variableBinding = <FoundVariable, DartExpression>{};
    SqlQuery? query;
    DriftOptions? options;

    void error(String message) {
      errors
          .add(DriftAnalysisError.forDartElement(definition.element, message));
    }

    final resolvedDatabase =
        await _ResolvedDriftDatabase.resolve(buildStep, definition.database);
    if (resolvedDatabase == null) {
      error(
          'Drift did not generate code for the referenced database ${definition.database}.');
    } else {
      final driver = DriftAnalysisDriver(
          DriftBuildBackend(buildStep), DriftOptions.fromJson({}));
      final elements = <DriftElement>[];
      for (final entry in resolvedDatabase.schemaEntities) {
        final file = driver.cache.stateForUri(entry.libraryUri);
        await driver.discoverIfNecessary(file);

        final resolved = await driver.resolveElement(file, entry);
        if (resolved != null) {
          elements.add(resolved);
        }
      }

      final knownTypes = await driver.knownTypes;
      final typeMapping = await driver.typeMapping;
      final engine = typeMapping.newEngineWithTables(elements);
      final sql = definition.buildSql();
      final context = engine.analyze(sql);
      final analyzer = QueryAnalyzer(
          context, driver.cache.stateForUri(buildStep.inputId.uri), driver,
          knownTypes: knownTypes,
          typeMapping: typeMapping,
          references: elements);

      try {
        query = await analyzer.analyze(DefinedSqlQuery(
          DriftElementId(_driftRiverpod, definition.name),
          DriftDeclaration(_driftRiverpod, 0, definition.name),
          references: const [],
          existingDartType: switch (definition.fixedResultType) {
            null => null,
            final rowType => RequestedQueryResultType(rowType, null),
          },
          sql: sql,
          sqlOffset: 0,
        ));

        for (final variable in query.variables) {
          final expression = definition.statement
              .whereType<DartExpression>()
              .singleWhere((e) => e.variableIndex == variable.originalIndex);
          variableBinding[variable] = expression;
          expression.queryVariable = variable;
          expression.parameter?.boundVariable = variable;
        }
      } catch (e) {
        error('Could not analyze statement: $e');
      }

      for (final lint in analyzer.lints) {
        errors.add(DriftAnalysisError.fromSqlError(lint));
      }
    }

    return ResolvedQueryProvider(
        definition, options, query, errors, variableBinding);
  }
}

final class _ResolvedDriftDatabase {
  final DriftElementId databaseId;
  final List<DriftElementId> schemaEntities;

  _ResolvedDriftDatabase(
      {required this.databaseId, required this.schemaEntities});

  static Future<_ResolvedDriftDatabase?> resolve(
      AssetReader reader, DriftElementId id) async {
    final databaseId =
        AssetId.resolve(id.libraryUri).addExtension('.drift_databases.json');

    if (!await reader.canRead(databaseId)) {
      return null;
    }

    final decoded = json.decode(await reader.readAsString(databaseId));
    final resolved = decoded['resolved_databases'] as List;
    for (final possibleDatabase in resolved) {
      final db = DriftElementId.fromJson(possibleDatabase['id']);
      if (db == id) {
        return _ResolvedDriftDatabase(
          databaseId: id,
          schemaEntities: [
            for (final entry in possibleDatabase['schema_elements'])
              DriftElementId.fromJson(entry),
          ],
        );
      }
    }

    return null;
  }
}

final class QueryProviderWriter {
  final Writer writer;
  final Scope databaseScope;
  final Scope providerScope;
  final ResolvedQueryProvider query;

  QueryProviderWriter(
      this.writer, this.databaseScope, this.providerScope, this.query);

  bool get isProviderFamily => query.definition.parameters.isNotEmpty;

  /// Generates code for [query] as an extension member in [databaseScope].
  void _writeInnerQuery() {
    // Write the inner query method as a local function
    QueryWriter(databaseScope).write(query.query!);
  }

  void _writeArgs(TextEmitter emitter, {bool isForParameters = false}) {
    emitter.write('(');
    var hadNamed = false;
    for (final parameter in query.definition.parameters) {
      final element = parameter.dart;
      if (element.isPositional) {
        emitter
          ..writeDart(parameter.typeCode)
          ..write(' ')
          ..write(element.name)
          ..write(',');
      } else {
        if (!hadNamed) {
          hadNamed = true;
          emitter.write('{');
        }

        if (isForParameters) {
          emitter.write('required ');
        }

        emitter
          ..writeDart(parameter.typeCode)
          ..write(' ')
          ..write(element.name)
          ..write(',');
      }
    }

    if (hadNamed) {
      emitter.write('}');
    }
    emitter.write(')');
  }

  void _turnArgsIntoRecord(TextEmitter emitter) {
    emitter.write('(');
    var hadNamed = false;
    for (final parameter in query.definition.parameters) {
      final element = parameter.dart;
      if (element.isPositional) {
        emitter
          ..write(element.name)
          ..write(',');
      } else {
        if (!hadNamed) {
          hadNamed = true;
          emitter.write('{');
        }

        emitter
          ..write(element.name)
          ..write(',');
      }
    }

    if (hadNamed) {
      emitter.write('}');
    }
    emitter.write(')');
  }

  void _writeObtainSelectable(TextEmitter emitter) {
    emitter
      ..write('ref.watch(')
      ..writeDart(AnnotatedDartCode.ast(query.definition.databaseProvider))
      ..write(').')
      ..write(query.definition.name)
      ..writeln('(');

    for (final variable in query.query!.variables) {
      final dartExpr = query.definition.statement
          .whereType<DartExpression>()
          .singleWhere((e) => e.queryVariable == variable);

      if (dartExpr.parameter case final parameter?) {
        final element = parameter.dart;
        if (element.isNamed) {
          emitter.write('args.${element.name}');
        } else {
          emitter.write('args.\$${parameter.dartIndex + 1}');
        }
      } else {
        emitter.writeDart(AnnotatedDartCode.ast(dartExpr.expression));
      }
      emitter.write(',');
    }
    emitter.write(')');
  }

  void _writeResultType(TextEmitter emitter) {
    if (query.definition.isSingleRow) {
      emitter.writeDart(AnnotatedDartCode.build((b) => b
        ..addQueryResultRowType(query.query!)
        ..addText('?')));
    } else {
      emitter
        ..writeDart(AnnotatedDartCode.importedSymbol(
            AnnotatedDartCode.dartCore, 'List'))
        ..write('<')
        ..writeDart(AnnotatedDartCode.build(
            (b) => b.addQueryResultRowType(query.query!)))
        ..write('>');
    }
  }

  void write() {
    _writeInnerQuery();

    final emitter = providerScope.leaf();

    if (isProviderFamily) {
      // Write a class for the family:
      final familyClass = writer.leaf();
      final baseFamilyClass = query.definition.isSingleRow
          ? 'SelectableSingleProviderFamily'
          : 'SelectableProviderFamily';

      final familyClassName =
          '_\$QueryProviderFamily\$${query.definition.name}';
      familyClass
        ..writeln('')
        ..writeln('// ignore: subtype_of_sealed_class')
        ..write('final class $familyClassName extends ')
        ..writeDriftRiverpod(baseFamilyClass)
        ..write('<')
        ..writeDart(AnnotatedDartCode.build(
            (b) => b.addQueryResultRowType(query.query!)))
        ..write(',');
      _writeArgs(familyClass);
      familyClass
        ..writeln('> {')
        ..write(familyClassName)
        ..write(r'({required super.$database}): super($name: ')
        ..write("r'${query.definition.name}',")
        ..write('\$create: (ref, args) => ');
      _writeObtainSelectable(familyClass);
      familyClass.writeln(');');

      // We represent args to the family as a record, which is awkward to use.
      // Provider call() method that creates the record.
      familyClass
        ..writeDriftRiverpod('SelectableProvider')
        ..write('<');
      _writeResultType(familyClass);
      familyClass.write('> call');
      _writeArgs(familyClass, isForParameters: true);
      familyClass.write(' => create(');
      _turnArgsIntoRecord(familyClass);
      familyClass.writeln(');');

      familyClass.writeln('}'); // End family class

      // Then, write an extension to create the family:
      // Signature: SelectableProviderFamily<Row, (int, String)> query(Object args)
      emitter
        ..write(familyClassName)
        ..write(' ')
        ..write(query.definition.methodName)
        ..write('(')
        ..writeDart(AnnotatedDartCode.importedSymbol(
            AnnotatedDartCode.dartCore, 'Object'))
        ..write(' _)')
        ..write(' => ')
        ..write(familyClassName)
        ..write('(\$database: ')
        ..writeDart(AnnotatedDartCode.ast(query.definition.databaseProvider))
        ..writeln(');');
    } else {
      // Signature: SelectableProvider<Row> query(String sql)

      emitter.writeDriftRiverpod('SelectableProvider');
      emitter.write('<');
      _writeResultType(emitter);
      emitter
        ..write('> ')
        ..write(query.definition.methodName)
        ..write('(')
        ..writeDart(AnnotatedDartCode.importedSymbol(
            AnnotatedDartCode.dartCore, 'String'))
        ..write(' _) { return ')
        ..writeDriftRiverpod(query.definition.isSingleRow
            ? 'queryProviderImplSingleOrNull'
            : 'queryProviderImpl')
        ..write('((ref) => ');
      _writeObtainSelectable(emitter);
      emitter.writeln(');}');
    }
  }
}

final Uri _driftRiverpod =
    Uri.parse('package:drift_riverpod/drift_riverpod.dart');

extension WriteDriftRiverpodRef on TextEmitter {
  void writeDriftRiverpod(String symbol) {
    writeUriRef(_driftRiverpod, symbol);
  }
}
