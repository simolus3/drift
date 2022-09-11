import 'package:drift_dev/src/analysis/results/dart.dart';

import 'package:drift_dev/src/analysis/results/column.dart';

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

  DriftView(
    super.id,
    super.declaration, {
    required this.columns,
    required this.source,
    required this.customParentClass,
    required this.entityInfoName,
    required this.existingRowClass,
  });
}

abstract class DriftViewSource {}
