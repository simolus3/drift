part of '../steps.dart';

/// Analyzes the compiled queries found in a Dart file.
class AnalyzeDartStep extends AnalyzingStep {
  AnalyzeDartStep(Task task, FoundFile file) : super(task, file);

  void analyze() {
    final parseResult = file.currentResult as ParsedDartFile;

    for (final accessor in parseResult.dbAccessors) {
      final transitiveImports = task.crawlImports(accessor.imports!).toList();

      final unsortedEntities = _availableEntities(transitiveImports).toSet();

      final tableDartClasses = {
        for (final entry in unsortedEntities)
          if (entry.declaration is DartTableDeclaration)
            (entry.declaration as DartTableDeclaration).element: entry
      };

      final viewDartClasses = {
        for (final entry in unsortedEntities)
          if (entry.declaration is DartViewDeclaration)
            (entry.declaration as DartViewDeclaration).element: entry
      };

      for (final declaredHere in accessor.declaredTables) {
        // See issue #447: The table added to an accessor might already be
        // included through a transitive moor file. In that case, we just ignore
        // it to avoid duplicates.
        final declaration = declaredHere.declaration;
        if (declaration is DartTableDeclaration &&
            tableDartClasses.containsKey(declaration.element)) {
          continue;
        }

        // Not a Dart table that we already included - add it now
        unsortedEntities.add(declaredHere);
        if (declaration is DartTableDeclaration) {
          tableDartClasses[declaration.element] = declaredHere;
        }
      }

      if (accessor is Database) {
        _resolveDartColumnReferences(tableDartClasses);
      }

      for (final declaredHere in accessor.declaredViews) {
        // See issue #447: The view added to an accessor might already be
        // included through a transitive moor file. In that case, we just ignore
        // it to avoid duplicates.
        final declaration = declaredHere.declaration;
        if (declaration is DartViewDeclaration &&
            viewDartClasses.containsKey(declaration.element)) {
          continue;
        }

        // Not a Dart view that we already included - add it now
        unsortedEntities.add(declaredHere);
        if (declaration is DartViewDeclaration) {
          viewDartClasses[declaration.element] = declaredHere;
        }
      }

      List<DriftSchemaEntity>? availableEntities;

      try {
        availableEntities = sortEntitiesTopologically(unsortedEntities);
      } on CircularReferenceException catch (e) {
        // Just keep them unsorted so that we can generate some code
        availableEntities = unsortedEntities.toList();
        final msg = StringBuffer(
            'Found a circular reference in your database. This can cause '
            'exceptions at runtime when opening the database. This is the '
            'cycle that we found: ');

        msg.write(e.affected.map((t) => t.displayName).join(' -> '));
        // the last table in e.affected references the first one. Let's make
        // that clear in the visualization.
        msg.write(' -> ${e.affected.first.displayName}');

        reportError(ErrorInDartCode(
          severity: Severity.warning,
          affectedElement: accessor.fromClass,
          message: msg.toString(),
        ));
      } on Exception catch (e) {
        // unknown error while sorting
        reportError(ErrorInDartCode(
          severity: Severity.warning,
          affectedElement: accessor.fromClass,
          message: 'Unknown error while sorting database entities: $e',
        ));
      }

      // Just to have something in case the above breaks.
      availableEntities ??= const [];

      final availableQueries = transitiveImports
          .map((f) => f.currentResult)
          .whereType<ParsedDriftFile>()
          .expand((f) => f.resolvedQueries ?? const <Never>[]);

      final availableTables =
          availableEntities.whereType<DriftTable>().toList();
      final availableViews = availableEntities.whereType<MoorView>().toList();
      final parser = SqlAnalyzer(
          this, availableTables, availableViews, accessor.declaredQueries);
      parser.parse();

      accessor
        ..entities = availableEntities
        ..queries = availableQueries.followedBy(parser.foundQueries).toList();

      // Support custom result class names.
      CustomResultClassTransformer(accessor).transform(errors);
    }
  }

  /// Resolves a `.reference` action declared on a Dart-defined column.
  void _resolveDartColumnReferences(
      Map<ClassElement, DriftSchemaEntity> dartTables) {
    dartTables.forEach((dartClass, moorEntity) {
      if (moorEntity is! DriftTable) return;

      for (final column in moorEntity.columns) {
        for (var i = 0; i < column.features.length; i++) {
          final feature = column.features[i];

          if (feature is UnresolvedDartForeignKeyReference) {
            final table = dartTables[feature.otherTable];

            if (table is! DriftTable) {
              reportError(ErrorInDartCode(
                message: 'This class has not been added as a table',
                affectedElement: feature.surroundingElementForErrors,
                affectedNode: feature.otherTableName,
              ));
              continue;
            }

            // This table now references the other, so we need to track that.
            moorEntity.references.add(table);
            final referencedColumn = table.columns.firstWhereOrNull(
                (c) => c.dartGetterName == feature.otherColumnName);

            if (referencedColumn == null) {
              reportError(
                ErrorInDartCode(
                  message:
                      'The table `${table.sqlName}` does not declare a column '
                      'named `${feature.otherColumnName}`',
                  affectedElement: feature.surroundingElementForErrors,
                  affectedNode: feature.columnNameNode,
                ),
              );
              continue;
            }

            column.features[i] = ResolvedDartForeignKeyReference(
                table, referencedColumn, feature.onUpdate, feature.onDelete);
          }
        }
      }
    });
  }
}
