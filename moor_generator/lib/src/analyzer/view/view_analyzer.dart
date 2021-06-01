//@dart=2.9
import 'package:moor_generator/moor_generator.dart';
import 'package:moor_generator/src/analyzer/runner/steps.dart';
import 'package:moor_generator/src/analyzer/sql_queries/query_analyzer.dart';
import 'package:moor_generator/src/model/table.dart';
import 'package:moor_generator/src/model/view.dart';
import 'package:recase/recase.dart';
import 'package:sqlparser/sqlparser.dart';

class ViewAnalyzer extends BaseAnalyzer {
  final List<MoorView> viewsToAnalyze;

  ViewAnalyzer(Step step, List<MoorTable> tables, this.viewsToAnalyze)
      : // We're about to analyze views and add them to the engine, but don't
        // add the unfinished views right away
        super(tables, const [], step);

  /// Resolves all the views in topological order.
  void resolve() {
    // Going through the topologically sorted list and analyzing each view.
    for (final view in viewsToAnalyze) {
      final ctx =
          engine.analyzeNode(view.declaration.node, view.file.parseResult.sql);
      lintContext(ctx, view.name);

      final parserView = view.parserView =
          const SchemaFromCreateTable(moorExtensions: true)
              .readView(ctx, view.declaration.creatingStatement);

      final columns = [
        for (final column in parserView.resolvedColumns)
          MoorColumn(
            type: mapper.resolvedToMoor(column.type),
            name: ColumnName.explicitly(column.name),
            nullable: column.type.nullable,
            dartGetterName: ReCase(column.name).camelCase,
          )
      ];
      view.columns = columns;

      engine.registerView(mapper.extractView(view));

      view.references = findReferences(view.declaration.node).toList();
    }
  }
}
