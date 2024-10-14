import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:collection/collection.dart';
import 'package:drift_dev/src/analysis/resolver/shared/data_class.dart';
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
            if (column.column.sqlType.builtin !=
                    constraint.otherColumn.sqlType.builtin ||
                column.column.typeConverter?.dartType !=
                    constraint.otherColumn.typeConverter?.dartType) {
              print(
                  "The Manager API can only generate filters and orderings for relations where the types are exactly the same.");
              reportError(DriftAnalysisError.forDartElement(column.element,
                  "This column references a column whose type doesn't match this one. The generated managers will ignore this relation",
                  level: DriftAnalysisErrorLevel.warning));
            }
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
      nameOfRowClass:
          dataClassInfo.enforcedName ?? dataClassNameForClassName(element.name),
      interfacesForRowClass: dataClassInfo.interfaces,
      nameOfCompanionClass: dataClassInfo.companionName,
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

    final columnsWithPrimaryKeyConstraint = columns
        .where((c) => c.constraints.any((e) => e is PrimaryKeyColumn))
        .length;
    if (primaryKey != null && columnsWithPrimaryKeyConstraint > 0) {
      reportError(DriftAnalysisError.forDartElement(
        element,
        "Tables can't override primaryKey and use autoIncrement()",
      ));
    }

    if (columnsWithPrimaryKeyConstraint > 1) {
      reportError(DriftAnalysisError.forDartElement(
        element,
        'More than one column uses autoIncrement(). This would require '
        'multiple primary keys, which is not supported.',
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
        // ignore: deprecated_member_use
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
    // ignore: deprecated_member_use
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
    // ignore: deprecated_member_use
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
    // Returns true if the given field is a column defined as a getter
    bool isGetterColumn(FieldElement e) {
      return isColumn(e.type) && e.getter != null && !e.getter!.isSynthetic;
    }

    // Returns true if the given field is a column defined as a late final variable declaration
    Future<bool> isLateFinalColumn(FieldElement e) async {
      final isLateFinalField = e.isLate && e.isFinal && e.getter != null;
      if (!isLateFinalField) return false;

      if (isColumn(e.type)) {
        return true;
      } else {
        if (isColumnBuilder(e.type)) {
          // When defining a column with a declaration it's possible that the user
          // forgot to add an extra pair of parentheses at the end.
          // In that case, field would be a `ColumnBuilder` instead of a `Column`.
          // We should warn the user about this.
          // To print a detailed error message we willresolve the element to get the entire field declaration.
          final declaration = (await resolver.driver.backend
              .loadElementDeclaration(e.declaration) as VariableDeclaration);
          reportError(DriftAnalysisError.inDartAst(
            declaration.declaredElement!,
            declaration.endToken,
            '\nIt seems that you forgot to initialize the `${e.getter?.name}` column on the `${element.name}` table.\n'
            'Solution: Add an extra pair of parentheses at the end of the column: `$declaration()`.',
          ));
        }
        return false;
      }
    }

    final Set<String> columnNames = {};
    for (final element in element.allSupertypes
        .map((t) => t.element)
        .followedBy([element]).expand((e) => e.fields)) {
      if (isGetterColumn(element) || await isLateFinalColumn(element)) {
        columnNames.add(element.name);
      }
    }

    final fields = columnNames.map((name) {
      final getter = element.getGetter(name) ??
          element.lookUpInheritedConcreteGetter(name, element.library);
      // ignore: deprecated_member_use
      return getter!.variable;
    }).toList();
    final all = {for (final entry in fields) entry.getter ?? entry: entry.name};

    final results = <PendingColumnInformation>[];
    for (final field in fields) {
      final ColumnDeclaration node;
      final PendingColumnInformation? column;
      if (field.getter!.isSynthetic) {
        node = ColumnDeclaration(
            await resolver.driver.backend
                    .loadElementDeclaration(field.declaration)
                as VariableDeclaration,
            null);
        column = await _parseColumn(node, field.declaration, all);
      } else {
        node = ColumnDeclaration(
            null,
            await resolver.driver.backend.loadElementDeclaration(field.getter!)
                as MethodDeclaration);

        column = await _parseColumn(node, field.getter!, all);
      }

      if (column != null) {
        results.add(column);
      }
    }

    return results.whereType();
  }

  Future<PendingColumnInformation?> _parseColumn(ColumnDeclaration declaration,
      Element element, Map<Element, String> allColumns) async {
    return ColumnParser(this, allColumns).parse(declaration, element);
  }

  Future<List<String>> _readCustomConstraints(Set<DriftElement> references,
      List<DriftColumn> localColumns, ClassElement element) async {
    final customConstraints =
        // ignore: deprecated_member_use
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

/// Wraps the declaration of a column in a Dart table class as either a
/// [VariableDeclaration] or a [MethodDeclaration].
///
/// This allows us to abstract over the different ways in which a column can be
/// declared in Drift.
///
/// e.g. VariableDeclaration:
/// ```dart
/// late final count = integer()();
/// ```
///
/// e.g. MethodDeclaration:
/// ```dart
/// IntColumn get count => integer()();
/// ```
///
///
class ColumnDeclaration {
  final VariableDeclaration? variable;
  final MethodDeclaration? method;

  ColumnDeclaration(this.variable, this.method)
      : assert(variable != null || method != null);

  Expression? get expression {
    if (method != null) {
      final body = method!.body;
      if (body is! ExpressionFunctionBody) {
        return null;
      }
      return body.expression;
    } else {
      return variable?.initializer;
    }
  }

  String get lexemeName {
    if (method != null) {
      return method!.name.lexeme;
    } else {
      return variable!.name.lexeme;
    }
  }

  Comment? get documentationComment {
    if (method != null) {
      return method!.documentationComment;
    } else {
      return variable!.documentationComment;
    }
  }
}
