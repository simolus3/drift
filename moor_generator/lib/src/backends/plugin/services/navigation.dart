import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/navigation/navigation.dart';
import 'package:moor_generator/src/analyzer/sql_queries/meta/declarations.dart';
import 'package:moor_generator/src/backends/plugin/services/requests.dart';
import 'package:moor_generator/src/backends/plugin/utils/ast_to_location.dart';
import 'package:moor_generator/src/backends/plugin/utils/span_utils.dart';
import 'package:source_span/source_span.dart';
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

  void _reportForSpan(SourceSpan span, ElementKind kind, Location target) {
    final offset = span.start.offset;
    final length = span.end.offset - offset;

    // The client only wants the navigation target for a single region, but
    // we always scan the whole file. Only report if there is an intersection
    if (intersect(span, request.span)) {
      collector.addRegion(offset, length, kind, target);
    }
  }

  @override
  void visitMoorImportStatement(ImportStatement e) {
    if (request.isMoorAndParsed) {
      final moor = request.parsedMoor;
      final resolved = moor.resolvedImports[e];

      if (resolved != null) {
        final span = e.importString.span;
        _reportForSpan(
            span, ElementKind.FILE, Location(resolved.uri.path, 0, 0, 1, 1));
      }
    }

    visitChildren(e);
  }

  @override
  void visitReference(Reference e) {
    if (request.isMoorAndAnalyzed) {
      final resolved = e.resolved;

      if (resolved is Column) {
        // if we know the declaration because the file was analyzed - use that
        final declaration = resolved.meta<ColumnDeclaration>();
        if (declaration != null) {
          final location = locationOfDeclaration(declaration);
          _reportForSpan(e.span, ElementKind.FIELD, location);
        } else if (declaration is ExpressionColumn) {
          // expression references don't have an explicit declaration, but they
          // reference an expression that we can target
          final expr = (declaration as ExpressionColumn).expression;
          final target = locationOfNode(request.file, expr);
          _reportForSpan(e.span, ElementKind.LOCAL_VARIABLE, target);
        }
      }
    }

    visitChildren(e);
  }

  @override
  void visitQueryable(Queryable e) {
    if (e is TableReference) {
      final resolved = e.resolved;

      if (resolved is Table) {
        final declaration = resolved.meta<TableDeclaration>();
        _reportForSpan(
            e.span, ElementKind.CLASS, locationOfDeclaration(declaration));
      }
    }

    visitChildren(e);
  }
}
