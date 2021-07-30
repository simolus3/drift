//@dart=2.9
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/navigation/navigation.dart';
import 'package:moor_generator/moor_generator.dart';
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
      moorRequest.parsedMoor.parsedFile.acceptWithoutArg(visitor);
    }
  }
}

class _NavigationVisitor extends RecursiveVisitor<void, void> {
  final MoorRequestAtPosition request;
  final NavigationCollector collector;

  _NavigationVisitor(this.request, this.collector);

  void _reportForSpan(SourceSpan span, ElementKind kind, Location target) {
    final offset = span.start.offset;
    final length = span.end.offset - offset;

    // Some clients only want the navigation target for a single region, others
    // want the whole file. For the former, only report regions is there is an
    // intersection
    if (!request.hasSpan || intersect(span, request.span)) {
      collector.addRegion(offset, length, kind, target);
    }
  }

  @override
  void visitMoorImportStatement(ImportStatement e, void arg) {
    if (request.isMoorAndParsed) {
      final moor = request.parsedMoor;
      final resolved = moor.resolvedImports[e];

      if (resolved != null) {
        final span = e.importString.span;
        _reportForSpan(
            span, ElementKind.FILE, Location(resolved.uri.path, 0, 0, 1, 1));
      }
    }

    visitChildren(e, arg);
  }

  @override
  void visitReference(Reference e, void arg) {
    if (request.isMoorAndAnalyzed) {
      final resolved = e.resolved;

      if (resolved is Column) {
        final locations = _locationOfColumn(resolved);
        for (final declaration in locations) {
          _reportForSpan(e.span, ElementKind.FIELD, declaration);
        }
      }
    }

    visitChildren(e, arg);
  }

  Iterable<Location> _locationOfColumn(Column column) sync* {
    final declaration = column.meta<MoorColumn>()?.declaration;
    if (declaration != null) {
      // the column was declared in a table and we happen to know where the
      // declaration is - point to that declaration.
      final location = locationOfDeclaration(declaration);
      yield location;
    } else if (column is ExpressionColumn) {
      // expression references don't have an explicit declaration, but they
      // reference an expression that we can target
      final expr = (declaration as ExpressionColumn).expression;
      yield locationOfNode(request.file, expr);
    } else if (column is CompoundSelectColumn) {
      // a compound select column consists of multiple column declarations -
      // let's use all of them
      yield* column.columns.where((c) => c != null).expand(_locationOfColumn);
    } else if (column is DelegatedColumn) {
      if (column.innerColumn != null) {
        yield* _locationOfColumn(column.innerColumn);
      }
    }
  }

  @override
  void visitTableReference(TableReference e, void arg) {
    final resolved = e.resolved;

    if (resolved is Table && resolved != null) {
      final declaration = resolved.meta<MoorTable>()?.declaration;
      if (declaration != null) {
        _reportForSpan(
            e.span, ElementKind.CLASS, locationOfDeclaration(declaration));
      }
    }

    visitChildren(e, arg);
  }
}
