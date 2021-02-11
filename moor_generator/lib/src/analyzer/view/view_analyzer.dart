import 'package:moor_generator/src/analyzer/runner/steps.dart';
import 'package:moor_generator/src/analyzer/sql_queries/query_analyzer.dart';
import 'package:moor_generator/src/model/table.dart';
import 'package:moor_generator/src/model/view.dart';
import 'package:sqlparser/sqlparser.dart';

class ViewAnalyzer extends BaseAnalyzer {
  final List<MoorView> viewsToAnalyze;

  ViewAnalyzer(Step step, List<MoorTable> tables, this.viewsToAnalyze)
      : // We're about to analyze views and add them to the engine, but don't
        // add the unfinished views right away
        super(tables, const [], step);

  List<MoorView> _viewsOrder;
  Set<MoorView> _resolvedViews;

  /// Resolves all the views in topological order.
  void resolve() {
    _viewsOrder = [];
    _resolvedViews = {};
    // Topologically sorting all the views.
    for (final view in viewsToAnalyze) {
      if (!_resolvedViews.contains(view)) {
        _topologicalSort(view);
      }
    }

    // Going through the topologically sorted list and analyzing each view.
    for (final view in _viewsOrder) {
      // Registering every table dependency.
      for (final referencedEntity in view.references) {
        if (referencedEntity is MoorTable) {
          engine.registerTable(mapper.extractStructure(referencedEntity));
        }
      }
      final ctx =
          engine.analyzeNode(view.declaration.node, view.file.parseResult.sql);
      lintContext(ctx, view.name);

      view.parserView = const SchemaFromCreateTable(moorExtensions: true)
          .readView(ctx, view.declaration.creatingStatement);
      engine.registerView(mapper.extractView(view));
    }
  }

  void _topologicalSort(MoorView view) {
    _resolvedViews.add(view);
    for (final referencedEntity in view.references) {
      if (referencedEntity is MoorView) {
        if (!_resolvedViews.contains(referencedEntity)) {
          _topologicalSort(referencedEntity);
        }
      }
    }
    _viewsOrder.add(view);
  }
}
