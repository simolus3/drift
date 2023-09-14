import 'package:analyzer/dart/constant/value.dart';
import 'package:collection/collection.dart';

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
    final unique = computed?.getField('unique')?.toBoolValue() ?? false;

    final tableResult = await resolver.resolveReferencedElement(
        discovered.ownId, discovered.onTable);
    final table = handleReferenceResult<DriftTable>(
      tableResult,
      (msg) => DriftAnalysisError.forDartElement(discovered.dartElement, msg),
    );
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
}
