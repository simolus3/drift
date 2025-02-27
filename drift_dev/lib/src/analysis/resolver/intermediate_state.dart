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

  @override
  String? get dartElementName => null;

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

  @override
  String? get dartElementName => dartElement.name;

  DiscoveredDartElement(super.ownId, this.dartElement);
}

class DiscoveredDartTable extends DiscoveredDartElement<ClassElement> {
  @override
  DriftElementKind get kind => DriftElementKind.table;

  /// The element ids of [DiscoveredDartIndex] entries that have been added to
  /// this table with a `@TableIndex` annotation on the table class.
  final List<DriftElementId> attachedIndices;

  DiscoveredDartTable(
    super.ownId,
    super.dartElement,
    this.attachedIndices,
  );
}

class DiscoveredDartView extends DiscoveredDartElement<ClassElement> {
  /// The [DriftView] annotation on this class, if there is any.
  DartObject? viewAnnotation;

  @override
  DriftElementKind get kind => DriftElementKind.view;

  DiscoveredDartView(super.ownId, super.dartElement, this.viewAnnotation);
}

class DiscoveredDartIndex extends DiscoveredDartElement<ClassElement> {
  final DriftElementId onTable;

  ElementAnnotation annotation;

  @override
  DriftElementKind get kind => DriftElementKind.dbIndex;

  @override
  String? get dartElementName => null;

  DiscoveredDartIndex(
      super.ownId, super.dartElement, this.onTable, this.annotation);
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
