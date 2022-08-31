import 'element.dart';

import 'column.dart';

class DriftTable extends DriftElementWithResultSet {
  @override
  final List<DriftColumn> columns;

  DriftTable(
    super.id,
    super.declaration, {
    required this.columns,
  });
}
