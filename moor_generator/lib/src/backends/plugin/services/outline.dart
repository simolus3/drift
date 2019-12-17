import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/outline/outline.dart';
import 'package:moor_generator/src/backends/plugin/services/requests.dart';
import 'package:moor_generator/src/backends/plugin/utils/ast_to_location.dart';
import 'package:sqlparser/sqlparser.dart';

const _defaultFlags = 0;

class MoorOutlineContributor implements OutlineContributor {
  const MoorOutlineContributor();

  @override
  void computeOutline(OutlineRequest request, OutlineCollector collector) {
    final moorRequest = request as MoorRequest;

    if (moorRequest.isMoorAndParsed) {
      final visitor = _OutlineVisitor(moorRequest, collector);

      moorRequest.parsedMoor.parsedFile.accept(visitor);
    }
  }
}

class _OutlineVisitor extends RecursiveVisitor<void> {
  final MoorRequest request;
  final OutlineCollector collector;

  _OutlineVisitor(this.request, this.collector);

  Element _startElement(ElementKind kind, String name, AstNode e) {
    final element = Element(kind, name, _defaultFlags,
        location: locationOfNode(request.file, e));

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
    // we use parameters instead of returnType because VS Code doesn't show
    // the return type but we'd really like it to be shown
    _startElement(ElementKind.FIELD, e.columnName, e).parameters = e.typeName;

    super.visitChildren(e);
    collector.endElement();
  }

  @override
  void visitMoorFile(MoorFile e) {
    _startElement(ElementKind.LIBRARY, request.file.shortName, e);
    super.visitChildren(e);
    collector.endElement();
  }

  @override
  void visitMoorDeclaredStatement(DeclaredStatement e) {
    if (!e.isRegularQuery) {
      super.visitChildren(e);
      return;
    }

    final name = e.identifier.name;
    final element = _startElement(ElementKind.TOP_LEVEL_VARIABLE, name, e);

    // enrich information with variable types if the query has been analyzed.
    final resolved = request.parsedMoor.resolvedQueries
        .firstWhere((q) => q.name == name, orElse: () => null);

    if (resolved != null) {
      final parameterBuilder = StringBuffer('(');
      final vars = resolved.elements.map((e) => e.parameterType).join(', ');
      parameterBuilder..write(vars)..write(')');

      element.parameters = parameterBuilder.toString();
    }

    super.visitChildren(e);
    collector.endElement();
  }
}
