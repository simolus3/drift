import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/navigation/navigation.dart';
import 'package:moor_generator/src/backends/plugin/services/requests.dart';
import 'package:sqlparser/sqlparser.dart';

class MoorNavigationContributor implements NavigationContributor {
  const MoorNavigationContributor();

  @override
  void computeNavigation(
      NavigationRequest request, NavigationCollector collector) {
    final moorRequest = request as MoorRequestAtPosition;

    final visitor = _NavigationVisitor(moorRequest, collector);
    if (moorRequest.file.isParsed) {
      moorRequest.parsedMoor.parsedFile.accept(visitor);
    }
  }
}

class _NavigationVisitor extends RecursiveVisitor<void> {
  final MoorRequestAtPosition request;
  final NavigationCollector collector;

  _NavigationVisitor(this.request, this.collector);

  @override
  void visitMoorImportStatement(ImportStatement e) {
    if (request.isMoorAndParsed) {
      final moor = request.parsedMoor;
      final resolved = moor.resolvedImports[e];

      if (resolved != null) {
        final span = e.importString.span;
        final offset = span.start.offset;
        final length = span.end.offset - offset;

        collector.addRegion(
          offset,
          length,
          ElementKind.FILE,
          Location(resolved.uri.path, 0, 0, 1, 1),
        );
      }
    }

    super.visitChildren(e);
  }
}
