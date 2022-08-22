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
