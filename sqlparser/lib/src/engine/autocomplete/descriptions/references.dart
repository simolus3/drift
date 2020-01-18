part of '../engine.dart';

/// Autocomplete hint to signal that a table name is expected.
class TableNameDescription extends HintDescription {
  const TableNameDescription();

  @override
  Iterable<Suggestion> suggest(CalculationRequest request) {
    final tableNames = request.engine.knownTables.map((t) => t.escapedName);

    return tableNames.map((t) {
      return Suggestion(t, 1);
    });
  }
}
