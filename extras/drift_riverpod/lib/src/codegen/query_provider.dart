import 'dart:convert';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';

import 'package:drift_dev/src/backends/build/backend.dart';
import 'package:drift_dev/src/analysis/driver/driver.dart';
import 'package:drift_dev/src/analysis/options.dart';
import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:drift_dev/src/analysis/driver/error.dart';
import 'package:drift_dev/src/analysis/resolver/queries/query_analyzer.dart';

import 'utils.dart';

final class QueryProviderDefinition implements DriftQueryDeclaration {
  final TopLevelVariableElement element;
  final String methodName;
  final Expression databaseProvider;
  final DriftElementId database;
  final List<QueryParameterDefinition> parameters;
  final List<StatementPart> statement;

  QueryProviderDefinition({
    required this.element,
    required this.methodName,
    required this.databaseProvider,
    required this.database,
    required this.parameters,
    required this.statement,
  });

  @override
  String get name => element.name;

  static Future<(QueryProviderDefinition?, List<DriftAnalysisError>)> parse(
      Element element, AstNode declaration) async {
    final parser = _QueryProviderParser(
        await KnownElements.read(element), element, declaration);
    return (parser.parseInner(), parser.errors);
  }

  String buildSql() {
    final buffer = StringBuffer();
    for (final part in statement) {
      switch (part) {
        case StringPart():
          buffer.write(part.lexeme);
        case ParameterReference():
          throw UnimplementedError();
        case ConstantReference():
          throw UnimplementedError();
      }
    }

    return buffer.toString();
  }
}

final class _QueryProviderParser {
  final KnownElements knownElements;
  final Element element;
  final AstNode declaration;

  late final typeSystem = element.library!.typeSystem;
  final errors = <DriftAnalysisError>[];
  final parts = <StatementPart>[];

  _QueryProviderParser(this.knownElements, this.element, this.declaration);

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
    Expression? sqlStatement;
    if (argument is FunctionExpression) {
      // TODO: Parse things like (String id) => 'SELECT * FROM users WHERE id = $id';
    } else {
      sqlStatement = argument;
    }

    if (sqlStatement == null) {
      return null;
    }
    addStatement(sqlStatement);

    return QueryProviderDefinition(
      element: element as TopLevelVariableElement,
      methodName: initializer.methodName.name,
      databaseProvider: providerExpr,
      database: databaseType,
      parameters: [],
      statement: parts,
    );
  }

  void addStatement(Expression statement) {
    void addRawString(String value) {
      parts.add(StringPart(lexeme: value));
    }

    void addInterpolation(Expression expression) {
      throw 'todo: parameter';
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

  QueryParameterDefinition(this.dart);

  String get name => dart.name;
}

sealed class StatementPart {}

final class StringPart extends StatementPart {
  final String lexeme;

  StringPart({required this.lexeme});
}

final class ParameterReference extends StatementPart {
  final QueryParameterDefinition parameter;

  ParameterReference(this.parameter);
}

final class ConstantReference extends StatementPart {
  final Expression expression;

  ConstantReference(this.expression);
}

final class ResolvedQueryProvider {
  final QueryProviderDefinition definition;
  final SqlQuery? query;
  final DriftOptions? databaseOptions;
  final List<DriftAnalysisError> errors;

  ResolvedQueryProvider(
      this.definition, this.databaseOptions, this.query, this.errors);

  static Future<ResolvedQueryProvider> analyze(
    QueryProviderDefinition definition,
    BuildStep buildStep,
  ) async {
    final errors = <DriftAnalysisError>[];
    SqlQuery? query;
    DriftOptions? options;

    void error(String message) {
      errors
          .add(DriftAnalysisError.forDartElement(definition.element, message));
    }

    final resolvedDatabase =
        await _ResolvedDriftDatabase.resolve(buildStep, definition.database);
    if (resolvedDatabase == null) {
      error('Drift did not generate code for the referenced database.');
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
        query = await analyzer.analyze(definition);
      } catch (e) {
        error('Could not analyze statement: $e');
      }
    }

    return ResolvedQueryProvider(definition, options, query, errors);
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
