import 'package:analyzer/dart/element/element.dart';
import 'package:sqlparser/sqlparser.dart';

import '../driver/state.dart';

class DiscoveredDriftTable extends DiscoveredElement {
  final TableInducingStatement createTable;

  DiscoveredDriftTable(super.ownId, this.createTable);
}

class DiscoveredDriftView extends DiscoveredElement {
  final CreateViewStatement createView;

  DiscoveredDriftView(super.ownId, this.createView);
}

class DiscoveredDriftIndex extends DiscoveredElement {
  final CreateIndexStatement createIndex;

  DiscoveredDriftIndex(super.ownId, this.createIndex);
}

class DiscoveredDriftTrigger extends DiscoveredElement {
  final CreateTriggerStatement createTrigger;

  DiscoveredDriftTrigger(super.ownId, this.createTrigger);
}

abstract class DiscoveredDartElement<DE extends Element>
    extends DiscoveredElement {
  final DE dartElement;

  DiscoveredDartElement(super.ownId, this.dartElement);
}

class DiscoveredDartTable extends DiscoveredDartElement<ClassElement> {
  DiscoveredDartTable(super.ownId, super.dartElement);
}
