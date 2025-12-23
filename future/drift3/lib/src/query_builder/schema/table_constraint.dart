import '../compiler.dart';

/// A table constraint modifies multiple columns in a table.
abstract base class TableConstraint implements SqlComponent {
  const TableConstraint._();
}
