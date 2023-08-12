import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:drift/drift.dart' show DriftView;
import 'package:sqlparser/sqlparser.dart';

import '../driver/state.dart';
import '../results/element.dart';

class DiscoveredDriftElement<AST extends AstNode> extends DiscoveredElement {
  final AST sqlNode;

  @override
  final DriftElementKind kind;

  DiscoveredDriftElement(super.ownId, this.kind, this.sqlNode);
}

typedef DiscoveredDriftTable = DiscoveredDriftElement<TableInducingStatement>;
typedef DiscoveredDriftView = DiscoveredDriftElement<CreateViewStatement>;
typedef DiscoveredDriftIndex = DiscoveredDriftElement<CreateIndexStatement>;
typedef DiscoveredDriftTrigger = DiscoveredDriftElement<CreateTriggerStatement>;
typedef DiscoveredDriftStatement = DiscoveredDriftElement<DeclaredStatement>;

abstract class DiscoveredDartElement<DE extends Element>
    extends DiscoveredElement {
  final DE dartElement;

  DiscoveredDartElement(super.ownId, this.dartElement);
}

class DiscoveredDartTable extends DiscoveredDartElement<ClassElement> {
  @override
  DriftElementKind get kind => DriftElementKind.table;

  DiscoveredDartTable(super.ownId, super.dartElement);
}

class DiscoveredDartView extends DiscoveredDartElement<ClassElement> {
  /// The [DriftView] annotation on this class, if there is any.
  DartObject? viewAnnotation;

  @override
  DriftElementKind get kind => DriftElementKind.view;

  DiscoveredDartView(super.ownId, super.dartElement, this.viewAnnotation);
}

class DiscoveredBaseAccessor extends DiscoveredDartElement<ClassElement> {
  final bool isDatabase;
  final DartObject annotation;

  @override
  DriftElementKind get kind => isAccessor
      ? DriftElementKind.databaseAccessor
      : DriftElementKind.database;

  bool get isAccessor => !isDatabase;

  DiscoveredBaseAccessor(
      super.ownId, super.dartElement, this.annotation, this.isDatabase);
}
