import 'package:analyzer/dart/constant/value.dart';
import 'package:collection/collection.dart';
import 'package:source_span/source_span.dart';
import 'package:sqlparser/sqlparser.dart';

import '../../driver/error.dart';
import '../../results/results.dart';
import '../intermediate_state.dart';
import '../resolver.dart';

final class DartIndexResolver
    extends TwoStageElementResolver<DiscoveredDartIndex> {
  DartIndexResolver(super.file, super.discovered, super.resolver, super.state);

  @override
  Future<PendingDriftElement> buildPending() async {
    // Revive the annotation by parsing values from the computed constant
    // value.
    final computed = discovered.annotation.computeConstantValue();
    final sql = computed?.getField('createIndexStatement')?.toStringValue();

    final table = handleReferenceResult(
      await resolver.resolveReferencedElement(discovered.onTable),
      (msg) => DriftAnalysisError.forDartElement(discovered.dartElement, msg),
      enforceKind: DriftElementKind.table,
    );

    if (sql != null) {
      return _fromSql(table, sql);
    }

    final unique = computed?.getField('unique')?.toBoolValue() ?? false;

    final columns = <DriftIndexedColumn>[];
    return PendingDriftElement(
      element: DriftIndex(
        resolver.ownElementReference,
        DriftDeclaration.dartElement(discovered.dartElement),
        table: table?.reference,
        indexedColumns: columns,
        unique: unique,
        createStmt: null,
      ),
      resolve: (dependencies) {
        final resolvedTable =
            dependencies.resolveNullable(table) as DriftTable?;
        final referencedColumns = computed?.getField('columns')?.toSetValue();
        for (final column in referencedColumns ?? const <DartObject>{}) {
          // Column can either be a Symbol or an IndexedColumn instance.
          String? columnName;
          OrderingMode? orderBy;
          if (column.toSymbolValue() case final symbol?) {
            columnName = symbol;
          } else {
            columnName = column.getField('columnName')?.toSymbolValue();
            if (column.getField('orderBy')?.getField('_name')?.toStringValue()
                case final orderByName?) {
              orderBy = switch (orderByName) {
                'asc' => OrderingMode.ascending,
                'desc' => OrderingMode.descending,
                _ => null,
              };
            }
          }

          if (columnName == null) {
            reportError(
              DriftAnalysisError.forDartElement(
                discovered.dartElement,
                'Unknown entry in columns array, should be a symbols or an IndexedColumn instance.',
              ),
            );
          }

          final tableColumn = resolvedTable?.columns.firstWhereOrNull(
            (c) => c.nameInDart == columnName,
          );

          if (tableColumn != null) {
            columns.add(
              DriftIndexedColumn(column: tableColumn, orderBy: orderBy),
            );
          } else {
            reportError(
              DriftAnalysisError.forDartElement(
                discovered.dartElement,
                'Column `$columnName`, referenced in index `${discovered.ownId.name}`, was not found in the table.',
              ),
            );
          }
        }
      },
    );
  }

  Future<PendingDriftElement> _fromSql(
    DependencyToken? table,
    String createIndexStatement,
  ) async {
    final engineForParsing = resolver.driver.newSqlEngine();
    // TODO: Use Dart AST offsets
    final span = SourceFile.fromString(createIndexStatement).span(0);
    final result = engineForParsing.parseSpan(ParserEntrypoint.statement, span);
    for (final error in result.errors) {
      reportError(
        DriftAnalysisError.forDartElement(
          discovered.dartElement,
          error.message,
        ),
      );
    }

    final root = result.rootNode;
    final references = await resolveTableReferences(root);
    final prepareEngine = await newEngineWithTables(references);

    final index = DriftIndex(
      resolver.ownElementReference,
      DriftDeclaration.dartElement(discovered.dartElement),
      table: table?.reference,
      indexedColumns: const [],
      unique: false,
      createStmt: createIndexStatement,
    );
    return PendingDriftElement(
      element: index,
      resolve: (dependencies) {
        if (root is CreateIndexStatement) {
          final engine = prepareEngine(dependencies);
          final context = engine.analyzeNode(root, span);
          final resolvedTable =
              dependencies.resolveNullable(table) as DriftTable?;

          index.unique = root.unique;
          for (final error in context.errors) {
            if (error.message case final message?) {
              reportError(
                DriftAnalysisError.forDartElement(
                  discovered.dartElement,
                  '${error.source?.span?.text}: $message',
                ),
              );
            }
          }

          // The @DriftIndex annotation is attached to tables, so make sure that the
          // index actually references the table.
          if (root.on.resolved case Table onTable) {
            if (resolvedTable != null &&
                onTable.name != resolvedTable.schemaName) {
              reportError(
                DriftAnalysisError.forDartElement(
                  discovered.dartElement,
                  'This index was applied to `${resolvedTable.baseDartName}` in Dart, '
                  'but references `${onTable.name}` in SQL.',
                ),
              );
            }
          }
        } else {
          reportError(
            DriftAnalysisError.forDartElement(
              discovered.dartElement,
              'Statement in TableIndex.sql must be a `CREATE INDEX` statement.',
            ),
          );
        }
      },
    );
  }
}
