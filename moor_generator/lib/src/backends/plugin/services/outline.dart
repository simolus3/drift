import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/outline/outline.dart';
import 'package:moor_generator/src/backends/plugin/services/requests.dart';
import 'package:sqlparser/sqlparser.dart';

const _defaultFlags = 0;

class MoorOutlineContributor implements OutlineContributor {
  const MoorOutlineContributor();

  @override
  void computeOutline(OutlineRequest request, OutlineCollector collector) {
    final moorRequest = request as MoorRequest;
    final file = moorRequest.path;

    final libraryElement = Element(ElementKind.FILE, file, _defaultFlags);
    collector.startElement(
        libraryElement, 0, moorRequest.resolvedTask.content.length);

    final visitor = _OutlineVisitor(collector);
    moorRequest.resolvedTask.lastResult.parsedFile.accept(visitor);

    collector.endElement();
  }
}

class _OutlineVisitor extends RecursiveVisitor<void> {
  final OutlineCollector collector;

  _OutlineVisitor(this.collector);

  Element _startElement(ElementKind kind, String name, AstNode e) {
    final element = Element(kind, name, _defaultFlags);

    final offset = e.firstPosition;
    final length = e.lastPosition - offset;
    collector.startElement(element, offset, length);

    return element;
  }

  @override
  void visitCreateTableStatement(CreateTableStatement e) {
    _startElement(ElementKind.CLASS, e.tableName, e);
    super.visitChildren(e);
    collector.endElement();
  }

  @override
  void visitColumnDefinition(ColumnDefinition e) {
    _startElement(ElementKind.FIELD, e.columnName, e);
    super.visitChildren(e);
    collector.endElement();
  }
}
