import 'package:drift_dev/src/analysis/results/dart.dart';

import 'package:drift_dev/src/analysis/results/column.dart';

import 'element.dart';
import 'result_sets.dart';

class DriftView extends DriftElementWithResultSet {
  @override
  final List<DriftColumn> columns;

  final DriftViewSource source;

  @override
  final AnnotatedDartCode? customParentClass;

  @override
  String entityInfoName;

  @override
  ExistingRowClass? existingRowClass;

  @override
  final String nameOfRowClass;

  @override
  List<DriftElement> references;

  DriftView(
    super.id,
    super.declaration, {
    required this.columns,
    required this.source,
    required this.customParentClass,
    required this.entityInfoName,
    required this.existingRowClass,
    required this.nameOfRowClass,
    required this.references,
  });
}

abstract class DriftViewSource {}

class SqlViewSource extends DriftViewSource {
  /// The `CREATE VIEW` statement as it appears in the `.drift` file.
  final String createView;

  SqlViewSource(this.createView);
}
