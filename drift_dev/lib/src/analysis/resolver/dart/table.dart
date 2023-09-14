import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:collection/collection.dart';
import 'package:sqlparser/sqlparser.dart' as sql;

import '../../driver/error.dart';
import '../../results/results.dart';
import '../intermediate_state.dart';
import '../resolver.dart';
import 'column.dart';
import 'helper.dart';

class DartTableResolver extends LocalElementResolver<DiscoveredDartTable> {
  DartTableResolver(super.file, super.discovered, super.resolver, super.state);

  @override
  Future<DriftElement> resolve() async {
    final element = discovered.dartElement;

    final pendingColumns = (await _parseColumns(element)).toList();
    final columns = [for (final column in pendingColumns) column.column];
    final primaryKey = await _readPrimaryKey(element, columns);
    final uniqueKeys = await _readUniqueKeys(element, columns);

    final dataClassInfo =
        await DataClassInformation.resolve(this, columns, element);

    final references = <DriftElement>{};

    // Resolve local foreign key references in pending columns
    for (final column in pendingColumns) {
      if (column.referencesColumnInSameTable != null) {
        final ref =
            column.column.constraints.whereType<ForeignKeyReference>().first;
        final referencedColumn = columns.firstWhere(
            (e) => e.nameInDart == column.referencesColumnInSameTable);

        ref.otherColumn = referencedColumn;
      } else {
        for (final constraint in column.column.constraints) {
          if (constraint is ForeignKeyReference) {
            references.add(constraint.otherColumn.owner);
          }
        }
      }
    }

    final tableConstraints =
        await _readCustomConstraints(references, columns, element);

    final table = DriftTable(
      discovered.ownId,
      DriftDeclaration.dartElement(element),
      columns: columns,
      references: references.toList(),
      nameOfRowClass: dataClassInfo.enforcedName,
      existingRowClass: dataClassInfo.existingClass,
      customParentClass: dataClassInfo.extending,
      baseDartName: element.name,
      tableConstraints: [
        if (primaryKey != null) PrimaryKeyColumns(primaryKey),
        for (final uniqueKey in uniqueKeys ?? const <Set<DriftColumn>>[])
          UniqueColumns(uniqueKey),
      ],
      overrideTableConstraints: tableConstraints,
      withoutRowId: await _overrideWithoutRowId(element) ?? false,
      attachedIndices: [
        for (final id in discovered.attachedIndices) id.name,
      ],
    );

    if (primaryKey != null &&
        columns.any((c) => c.constraints.any((e) => e is PrimaryKeyColumn))) {
      reportError(DriftAnalysisError.forDartElement(
        element,
        "Tables can't override primaryKey and use autoIncrement()",
      ));
    }

    if (primaryKey != null &&
        primaryKey.length == 1 &&
        primaryKey.first.constraints.contains(const UniqueColumn())) {
      reportError(DriftAnalysisError.forDartElement(
        element,
        'Primary key column cannot have UNIQUE constraint',
      ));
    }

    if (uniqueKeys != null &&
        uniqueKeys.any((key) =>
            uniqueKeys.length == 1 &&
            key.first.constraints.contains(const UniqueColumn()))) {
      reportError(DriftAnalysisError.forDartElement(
        element,
        'Column provided in a single-column uniqueKey set already has a '
        'column-level UNIQUE constraint',
      ));
    }

    if (uniqueKeys != null &&
        primaryKey != null &&
        uniqueKeys
            .any((unique) => const SetEquality().equals(unique, primaryKey))) {
      reportError(DriftAnalysisError.forDartElement(
        element,
        'The uniqueKeys override contains the primary key, which is '
        'already unique by default.',
      ));
    }

    return table;
  }

  Future<Set<DriftColumn>?> _readPrimaryKey(
      ClassElement element, List<DriftColumn> columns) async {
    final primaryKeyGetter =
        element.lookUpGetter('primaryKey', element.library);

    if (primaryKeyGetter == null || primaryKeyGetter.isFromDefaultTable) {
      // resolved primaryKey is from the Table dsl superclass. That means there
      // is no primary key
      return null;
    }

    final ast = await resolver.driver.backend
        .loadElementDeclaration(primaryKeyGetter) as MethodDeclaration;
    final body = ast.body;
    if (body is! ExpressionFunctionBody) {
      reportError(DriftAnalysisError.forDartElement(primaryKeyGetter,
          'This must return a set literal using the => syntax!'));
      return null;
    }
    final expression = body.expression;
    final parsedPrimaryKey = <DriftColumn>{};

    if (expression is SetOrMapLiteral) {
      for (final entry in expression.elements) {
        if (entry is Identifier) {
          final column = columns
              .singleWhereOrNull((column) => column.nameInDart == entry.name);
          if (column == null) {
            reportError(
              DriftAnalysisError.inDartAst(
                  primaryKeyGetter, entry, 'Column not found in this table'),
            );
          } else {
            parsedPrimaryKey.add(column);
          }
        } else {
          print('Unexpected entry in expression.elements: $entry');
        }
      }
    } else {
      reportError(DriftAnalysisError.forDartElement(
          primaryKeyGetter, 'This must return a set literal!'));
    }

    return parsedPrimaryKey;
  }

  Future<List<Set<DriftColumn>>?> _readUniqueKeys(
      ClassElement element, List<DriftColumn> columns) async {
    final uniqueKeyGetter = element.lookUpGetter('uniqueKeys', element.library);

    if (uniqueKeyGetter == null || uniqueKeyGetter.isFromDefaultTable) {
      // resolved uniqueKeys is from the Table dsl superclass. That means there
      // is no unique key list
      return null;
    }

    final ast = await resolver.driver.backend
        .loadElementDeclaration(uniqueKeyGetter) as MethodDeclaration;
    final body = ast.body;
    if (body is! ExpressionFunctionBody) {
      reportError(DriftAnalysisError.forDartElement(uniqueKeyGetter,
          'This must return a list of set literal using the => syntax!'));
      return null;
    }
    final expression = body.expression;
    final parsedUniqueKeys = <Set<DriftColumn>>[];

    if (expression is ListLiteral) {
      for (final keySet in expression.elements) {
        if (keySet is SetOrMapLiteral) {
          final uniqueKey = <DriftColumn>{};
          for (final entry in keySet.elements) {
            if (entry is Identifier) {
              final column = columns.singleWhereOrNull(
                  (column) => column.nameInDart == entry.name);
              if (column == null) {
                reportError(
                  DriftAnalysisError.inDartAst(
                    uniqueKeyGetter,
                    entry,
                    'Column not found in this table',
                  ),
                );
              } else {
                uniqueKey.add(column);
              }
            } else {
              print('Unexpected entry in expression.elements: $entry');
            }
          }
          parsedUniqueKeys.add(uniqueKey);
        } else {
          reportError(DriftAnalysisError.forDartElement(
              uniqueKeyGetter, 'This must return a set list literal!'));
        }
      }
    } else {
      reportError(DriftAnalysisError.forDartElement(
          uniqueKeyGetter, 'This must return a set list literal!'));
    }

    return parsedUniqueKeys;
  }

  Future<bool?> _overrideWithoutRowId(ClassElement element) async {
    final getter = element.lookUpGetter('withoutRowId', element.library);

    // Was the getter overridden at all?
    if (getter == null || getter.isFromDefaultTable) return null;

    final ast = await resolver.driver.backend.loadElementDeclaration(getter)
        as MethodDeclaration;
    final expr = returnExpressionOfMethod(ast);

    if (expr == null) return null;

    if (expr is BooleanLiteral) {
      return expr.value;
    } else {
      reportError(DriftAnalysisError.forDartElement(
        getter,
        'This must directly return a boolean literal.',
      ));
    }

    return null;
  }

  Future<Iterable<PendingColumnInformation>> _parseColumns(
      ClassElement element) async {
    final columnNames = element.allSupertypes
        .map((t) => t.element)
        .followedBy([element])
        .expand((e) => e.fields)
        .where((field) =>
            isColumn(field.type) &&
            field.getter != null &&
            !field.getter!.isSynthetic)
        .map((field) => field.name)
        .toSet();

    final fields = columnNames.map((name) {
      final getter = element.getGetter(name) ??
          element.lookUpInheritedConcreteGetter(name, element.library);
      return getter!.variable;
    });
    final results = <PendingColumnInformation>[];
    for (final field in fields) {
      final node = await resolver.driver.backend
          .loadElementDeclaration(field.getter!) as MethodDeclaration;
      final column = await _parseColumn(node, field.getter!);

      if (column != null) {
        results.add(column);
      }
    }

    return results.whereType();
  }

  Future<PendingColumnInformation?> _parseColumn(
      MethodDeclaration declaration, Element element) async {
    return ColumnParser(this).parse(declaration, element);
  }

  Future<List<String>> _readCustomConstraints(Set<DriftElement> references,
      List<DriftColumn> localColumns, ClassElement element) async {
    final customConstraints =
        element.lookUpGetter('customConstraints', element.library);

    if (customConstraints == null || customConstraints.isFromDefaultTable) {
      // Does not define custom constraints
      return const [];
    }

    final ast = await resolver.driver.backend
        .loadElementDeclaration(customConstraints) as MethodDeclaration;
    final body = ast.body;
    if (body is! ExpressionFunctionBody) {
      reportError(DriftAnalysisError.forDartElement(customConstraints,
          'This must return a list literal with the => syntax'));
      return const [];
    }
    final expression = body.expression;
    final foundConstraints = <String>[];
    final foundConstraintSources = <SyntacticEntity>[];

    if (expression is ListLiteral) {
      for (final entry in expression.elements) {
        if (entry is StringLiteral) {
          final value = entry.stringValue;
          if (value != null) {
            foundConstraints.add(value);
            foundConstraintSources.add(entry);
          }
        } else {
          reportError(DriftAnalysisError.inDartAst(
              element, entry, 'This must be a string literal.'));
        }
      }
    } else {
      reportError(DriftAnalysisError.forDartElement(
          customConstraints, 'This must return a list literal!'));
    }

    // Try to parse these constraints and emit warnings
    final engine = resolver.driver.newSqlEngine();
    for (var i = 0; i < foundConstraintSources.length; i++) {
      final parsed = engine.parseTableConstraint(foundConstraints[i]).rootNode;

      if (parsed is sql.InvalidStatement) {
        reportError(DriftAnalysisError.inDartAst(
            customConstraints,
            foundConstraintSources[i],
            'Could not parse this table constraint'));
      } else if (parsed is sql.ForeignKeyTableConstraint) {
        final source = foundConstraintSources[i];

        // Check that the columns exist locally
        final missingLocals = parsed.columns.where(
            (e) => localColumns.every((l) => !l.hasEqualSqlName(e.columnName)));
        if (missingLocals.isNotEmpty) {
          reportError(DriftAnalysisError.inDartAst(
            element,
            source,
            'Columns ${missingLocals.join(', ')} don\'t exist locally.',
          ));
        }

        // Also see if we can resolve the referenced table.
        final clause = parsed.clause;
        final table = await resolveSqlReferenceOrReportError<DriftTable>(
            clause.foreignTable.tableName,
            (msg) => DriftAnalysisError.inDartAst(element, source, msg));

        if (table != null) {
          references.add(table);
          final missingColumns = clause.columnNames
              .map((e) => e.columnName)
              .where((e) => !table.columnBySqlName.containsKey(e));

          if (missingColumns.isNotEmpty) {
            reportError(DriftAnalysisError.inDartAst(
              element,
              source,
              'Columns ${missingColumns.join(', ')} not found in table `${table.schemaName}`.',
            ));
          }
        }
      }
    }

    return foundConstraints;
  }
}
