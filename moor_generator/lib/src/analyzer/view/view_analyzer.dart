//@dart=2.9
import 'package:moor_generator/moor_generator.dart';
import 'package:moor_generator/src/analyzer/errors.dart';
import 'package:moor_generator/src/analyzer/moor/find_dart_class.dart';
import 'package:moor_generator/src/analyzer/runner/steps.dart';
import 'package:moor_generator/src/analyzer/sql_queries/query_analyzer.dart';
import 'package:moor_generator/src/model/table.dart';
import 'package:moor_generator/src/model/view.dart';
import 'package:moor_generator/src/utils/type_converter_hint.dart';
import 'package:recase/recase.dart';
import 'package:sqlparser/sqlparser.dart';

import '../custom_row_class.dart';

class ViewAnalyzer extends BaseAnalyzer {
  final List<MoorView> viewsToAnalyze;
  final List<ImportStatement> imports;

  ViewAnalyzer(
      Step step, List<MoorTable> tables, this.viewsToAnalyze, this.imports)
      : // We're about to analyze views and add them to the engine, but don't
        // add the unfinished views right away
        super(tables, const [], step);

  /// Resolves all the views in topological order.
  Future<void> resolve() async {
    // Going through the topologically sorted list and analyzing each view.
    for (final view in viewsToAnalyze) {
      final ctx =
          engine.analyzeNode(view.declaration.node, view.file.parseResult.sql);
      lintContext(ctx, view.name);
      final declaration = view.declaration.creatingStatement;

      final parserView = view.parserView =
          const SchemaFromCreateTable(moorExtensions: true)
              .readView(ctx, declaration);

      final columns = <MoorColumn>[];
      for (final column in parserView.resolvedColumns) {
        final type = column.type;
        UsedTypeConverter converter;
        if (type != null && type.hint is TypeConverterHint) {
          converter = (type.hint as TypeConverterHint).converter;
        }

        final moorColumn = MoorColumn(
          type: mapper.resolvedToMoor(type),
          name: ColumnName.explicitly(column.name),
          nullable: type?.nullable == true,
          dartGetterName: ReCase(column.name).camelCase,
          typeConverter: converter,
        );
        columns.add(moorColumn);
      }

      view.columns = columns;

      final desiredNames = declaration.moorTableName;
      if (desiredNames != null) {
        final dataClassName = desiredNames.overriddenDataClassName;
        if (desiredNames.useExistingDartClass) {
          final clazz = await findDartClass(step, imports, dataClassName);
          if (clazz == null) {
            step.reportError(ErrorInMoorFile(
              span: declaration.viewNameToken.span,
              message: 'Existing Dart class $dataClassName was not found, are '
                  'you missing an import?',
            ));
          } else {
            final rowClass = view.existingRowClass =
                validateExistingClass(columns, clazz, '', step.errors);
            final newName = rowClass?.targetClass?.name;
            if (newName != null) {
              view.dartTypeName = rowClass?.targetClass?.name;
            }
          }
        } else {
          view.dartTypeName = dataClassName;
        }
      }

      engine.registerView(mapper.extractView(view));
      view.references = findReferences(view.declaration.node).toList();
    }
  }
}
