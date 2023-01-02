import 'package:drift_dev/src/analysis/results/dart.dart';

import 'package:drift_dev/src/analysis/results/column.dart';
import 'package:sqlparser/sqlparser.dart';

import 'element.dart';
import 'result_sets.dart';
import 'table.dart';

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

  @override
  String get dbGetterName => DriftSchemaElement.dbFieldName(id.name);

  /// Obtains all tables transitively referenced by the declaration of this
  /// view.
  ///
  /// This includes all tables in [references]. If this view references other
  /// views, their [transitiveTableReferences] will be included as well.
  Set<DriftTable> get transitiveTableReferences {
    return {
      for (final reference in references)
        if (reference is DriftTable)
          reference
        else if (reference is DriftView)
          ...reference.transitiveTableReferences,
    };
  }
}

abstract class DriftViewSource {}

class SqlViewSource extends DriftViewSource {
  /// The `CREATE VIEW` statement like it appears in the database, with drift-
  /// specific syntax stripped out.
  ///
  /// In particular, the [sqlCreateViewStmt] will not have a
  /// [CreateViewStatement.driftTableName] set.
  final String sqlCreateViewStmt;

  /// The parsed `CREATE VIEW` statement from [createView].
  ///
  /// This node is not serialized and only set in the late-state, local file
  /// analysis.
  CreateViewStatement? parsedStatement;

  SqlViewSource(this.sqlCreateViewStmt);
}

/// A table added to a view via a getter.
class TableReferenceInDartView {
  /// The table referenced by the getter.
  final DriftTable table;

  /// Name of the getter adding the table.
  final String name;

  TableReferenceInDartView(this.table, this.name);
}

class DartViewSource extends DriftViewSource {
  final AnnotatedDartCode dartQuerySource;
  final TableReferenceInDartView? primaryFrom;
  final List<TableReferenceInDartView> staticReferences;

  DartViewSource(this.dartQuerySource, this.primaryFrom, this.staticReferences);
}
