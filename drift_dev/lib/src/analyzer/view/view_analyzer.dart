import 'package:drift_dev/moor_generator.dart';
import 'package:drift_dev/src/analyzer/errors.dart';
import 'package:drift_dev/src/analyzer/moor/find_dart_class.dart';
import 'package:drift_dev/src/analyzer/runner/steps.dart';
import 'package:drift_dev/src/analyzer/sql_queries/query_analyzer.dart';
import 'package:drift_dev/src/utils/type_converter_hint.dart';
import 'package:sqlparser/sqlparser.dart';

import '../dart_types.dart';

class ViewAnalyzer extends BaseAnalyzer {
  final List<ImportStatement> imports;

  ViewAnalyzer(Step step, List<MoorTable> tables, this.imports)
      : super(tables, const [], step);

  /// Resolves all the views in topological order.
  Future<void> resolve(Iterable<MoorView> viewsToAnalyze) async {
    // Going through the topologically sorted list and analyzing each view.
    for (final view in viewsToAnalyze) {
      if (view.declaration is! MoorViewDeclaration) continue;
      final viewDeclaration = view.declaration as MoorViewDeclaration;

      final ctx =
          engine.analyzeNode(viewDeclaration.node, view.file!.parseResult.sql);
      lintContext(ctx, view.name);
      final declaration = viewDeclaration.creatingStatement;

      final parserView = view.parserView =
          const SchemaFromCreateTable(driftExtensions: true)
              .readView(ctx, declaration);

      final columns = <MoorColumn>[];
      final columnDartNames = <String>{};
      for (final column in parserView.resolvedColumns) {
        final type = column.type;
        UsedTypeConverter? converter;
        if (type != null && type.hint is TypeConverterHint) {
          converter = (type.hint as TypeConverterHint).converter;
        }

        final moorColumn = MoorColumn(
          type: mapper.resolvedToMoor(type),
          name: ColumnName.explicitly(column.name),
          nullable: type?.nullable == true,
          dartGetterName:
              dartNameForSqlColumn(column.name, existingNames: columnDartNames),
          typeConverter: converter,
        );
        columns.add(moorColumn);
        columnDartNames.add(moorColumn.dartGetterName);
      }

      view.columns = columns;

      final desiredNames = declaration.driftTableName;
      if (desiredNames != null) {
        final dataClassName = desiredNames.overriddenDataClassName;
        if (desiredNames.useExistingDartClass) {
          final clazz = await findDartClass(step, imports, dataClassName);
          if (clazz == null) {
            step.reportError(ErrorInMoorFile(
              span: declaration.viewNameToken!.span,
              message: 'Existing Dart class $dataClassName was not found, are '
                  'you missing an import?',
            ));
          } else {
            final rowClass = view.existingRowClass =
                validateExistingClass(columns, clazz, '', false, step);
            final newName = rowClass?.targetClass.name;
            if (newName != null) {
              view.dartTypeName = rowClass!.targetClass.name;
            }
          }
        } else {
          view.dartTypeName = dataClassName;
        }
      }

      engine.registerView(mapper.extractView(view));

      if (view.isDeclaredInDriftFile) {
        view.references = findReferences(viewDeclaration.node).toList();
      }
    }
  }
}
