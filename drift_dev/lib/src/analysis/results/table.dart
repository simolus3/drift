import 'element.dart';

import 'column.dart';

class DriftTable extends DriftElementWithResultSet {
  @override
  final List<DriftColumn> columns;

  @override
  final List<DriftElement> references;

  DriftTable(
    super.id,
    super.declaration, {
    required this.columns,
    this.references = const [],
  });
}
