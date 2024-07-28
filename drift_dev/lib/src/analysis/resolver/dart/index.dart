import 'package:analyzer/dart/constant/value.dart';
import 'package:collection/collection.dart';
import 'package:sqlparser/sqlparser.dart';

import '../../driver/error.dart';
import '../../results/results.dart';
import '../intermediate_state.dart';
import '../resolver.dart';

class DartIndexResolver extends LocalElementResolver<DiscoveredDartIndex> {
  DartIndexResolver(super.file, super.discovered, super.resolver, super.state);

  @override
  Future<DriftIndex> resolve() async {
    // Revive the annotation by parsing values from the computed constant
    // value.
    final computed = discovered.annotation.computeConstantValue();
    final sql = computed?.getField('createIndexStatement')?.toStringValue();

    final tableResult = await resolver.resolveReferencedElement(
        discovered.ownId, discovered.onTable);
    final table = handleReferenceResult<DriftTable>(
      tableResult,
      (msg) => DriftAnalysisError.forDartElement(discovered.dartElement, msg),
    );

    if (sql != null) {
      return _fromSql(table, sql);
    }

    final unique = computed?.getField('unique')?.toBoolValue() ?? false;

    final columns = <DriftColumn>[];

    final referencedColumns = computed?.getField('columns')?.toSetValue();
    for (final column in referencedColumns ?? const <DartObject>{}) {
      final columnName = column.toSymbolValue();
      final tableColumn =
          table?.columns.firstWhereOrNull((c) => c.nameInDart == columnName);

      if (tableColumn != null) {
        columns.add(tableColumn);
      } else {
        reportError(DriftAnalysisError.forDartElement(
          discovered.dartElement,
          'Column `$columnName`, referenced in index `${discovered.ownId.name}`, was not found in the table.',
        ));
      }
    }

    return DriftIndex(
      discovered.ownId,
      DriftDeclaration.dartElement(discovered.dartElement),
      table: table,
      indexedColumns: columns,
      unique: unique,
      createStmt: null,
    );
  }

  Future<DriftIndex> _fromSql(
      DriftTable? table, String createIndexStatement) async {
    final engineForParsing = resolver.driver.newSqlEngine();
    final result = engineForParsing.parse(createIndexStatement);
    for (final error in result.errors) {
      reportError(DriftAnalysisError.forDartElement(
          discovered.dartElement, error.message));
    }

    final root = result.rootNode;
    bool unique = false;

    if (root is CreateIndexStatement) {
      final references = await resolveTableReferences(root);
      final engine = await newEngineWithTables(references);
      final context = engine.analyzeNode(root, createIndexStatement);

      unique = root.unique;
      for (final error in context.errors) {
        if (error.message case final message?) {
          reportError(DriftAnalysisError.forDartElement(
              discovered.dartElement, '${error.source?.span?.text}: $message'));
        }
      }

      // The @DriftIndex annotation is attached to tables, so make sure that the
      // index actually references the table.
      if (root.on.resolved case Table onTable) {
        if (table != null && onTable.name != table.schemaName) {
          reportError(DriftAnalysisError.forDartElement(
              discovered.dartElement,
              'This index was applied to `${table.baseDartName}` in Dart, '
              'but references `${onTable.name}` in SQL.'));
        }
      }
    } else {
      reportError(DriftAnalysisError.forDartElement(discovered.dartElement,
          'Statement in TableIndex.sql must be a `CREATE INDEX` statement.'));
    }

    return DriftIndex(
      discovered.ownId,
      DriftDeclaration.dartElement(discovered.dartElement),
      table: table,
      indexedColumns: const [],
      unique: unique,
      createStmt: createIndexStatement,
    );
  }
}
