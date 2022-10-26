import 'package:recase/recase.dart';

import '../../driver/error.dart';
import '../../driver/state.dart';
import '../../results/results.dart';
import '../intermediate_state.dart';
import '../shared/column_name.dart';
import '../shared/dart_types.dart';
import '../shared/data_class.dart';
import 'element_resolver.dart';
import 'sqlparser/mapping.dart';

class DriftViewResolver extends DriftElementResolver<DiscoveredDriftView> {
  DriftViewResolver(super.file, super.discovered, super.resolver, super.state);

  @override
  Future<DriftView> resolve() async {
    final stmt = discovered.sqlNode;
    final references = await resolveSqlReferences(stmt);
    final engine = newEngineWithTables(references);

    final source = (file.discovery as DiscoveredDriftFile).originalSource;
    final context = engine.analyzeNode(stmt, source);
    reportLints(context, references);

    final parserView = engine.schemaReader.readView(context, stmt);

    final columns = <DriftColumn>[];
    final columnDartNames = <String>{};
    for (final column in parserView.resolvedColumns) {
      final type = column.type;
      AppliedTypeConverter? converter;
      if (type != null && type.hint is TypeConverterHint) {
        converter = (type.hint as TypeConverterHint).converter;
      }

      final driftColumn = DriftColumn(
        sqlType: resolver.driver.typeMapping.sqlTypeToDrift(type),
        nameInSql: column.name,
        nameInDart:
            dartNameForSqlColumn(column.name, existingNames: columnDartNames),
        declaration: DriftDeclaration.driftFile(stmt, file.ownUri),
        nullable: type?.nullable == true,
        typeConverter: converter,
      );

      columns.add(driftColumn);
      columnDartNames.add(driftColumn.nameInDart);
    }

    var entityInfoName = ReCase(stmt.viewName).pascalCase;
    var rowClassName = dataClassNameForClassName(entityInfoName);
    ExistingRowClass? existingRowClass;

    final desiredNames = stmt.driftTableName;
    if (desiredNames != null) {
      final dataClassName = desiredNames.overriddenDataClassName;
      if (desiredNames.useExistingDartClass) {
        final clazz = await findDartClass(dataClassName);
        if (clazz == null) {
          reportError(DriftAnalysisError.inDriftFile(
            desiredNames,
            'Existing Dart class $dataClassName was not found, are '
            'you missing an import?',
          ));
        } else {
          existingRowClass =
              validateExistingClass(columns, clazz, '', false, this);
          final newName = existingRowClass?.targetClass.toString();
          if (newName != null) {
            rowClassName = newName;
          }
        }
      } else {
        rowClassName = dataClassName;
      }
    }

    return DriftView(
      discovered.ownId,
      DriftDeclaration.driftFile(stmt, file.ownUri),
      columns: columns,
      source: SqlViewSource(
          source.substring(stmt.firstPosition, stmt.lastPosition)),
      customParentClass: null,
      entityInfoName: entityInfoName,
      existingRowClass: existingRowClass,
      nameOfRowClass: rowClassName,
      references: references,
    );
  }
}
