@internal
library;

import 'package:drift3_preview/drift.dart';
import 'package:meta/meta.dart';

///  Enum of the possible boolean operators
enum BooleanOperator {
  /// Combine the existing filters to the new filter with an AND
  and,

  /// Combine the existing filters to the new filter with an OR
  or,
}

/// A simple function for generating aliases for referenced columns
///
/// This function is used internally by generated code and should not be used directly.
// ignore: non_constant_identifier_names
String $_aliasNameGenerator(
  GeneratedTable currentTable,
  TableColumn currentColumn,
  GeneratedTable referencedTable,
  TableColumn referencedColumn,
) {
  return '${currentTable.aliasOrName}__${currentColumn.name}__${referencedTable.aliasOrName}__${referencedColumn.name}';
}
