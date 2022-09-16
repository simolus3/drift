import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:sqlparser/sqlparser.dart';

import '../driver/state.dart';

class DiscoveredDriftElement<AST extends AstNode> extends DiscoveredElement {
  final AST sqlNode;

  DiscoveredDriftElement(super.ownId, this.sqlNode);
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
  DiscoveredDartTable(super.ownId, super.dartElement);
}

class DiscoveredBaseAccessor extends DiscoveredDartElement<ClassElement> {
  final bool isDatabase;
  final DartObject annotation;

  bool get isAccessor => !isDatabase;

  DiscoveredBaseAccessor(
      super.ownId, super.dartElement, this.annotation, this.isDatabase);
}
