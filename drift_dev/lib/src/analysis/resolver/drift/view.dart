import 'package:recase/recase.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/utils/node_to_text.dart';

import '../../driver/state.dart';
import '../../results/results.dart';
import '../intermediate_state.dart';
import '../shared/column_name.dart';
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
        foreignConverter: true,
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
        existingRowClass = await resolveExistingRowClass(columns, desiredNames);
        final newName = existingRowClass?.targetClass?.toString();
        if (newName != null) {
          rowClassName = newName;
        }
      } else {
        rowClassName = dataClassName;
      }
    }

    final createStmtForDatabase = CreateViewStatement(
      ifNotExists: stmt.ifNotExists,
      viewName: stmt.viewName,
      columns: stmt.columns,
      query: stmt.query,
      // Remove drift-specific syntax
      driftTableName: null,
    ).toSql();

    return DriftView(
      discovered.ownId,
      DriftDeclaration.driftFile(stmt, file.ownUri),
      columns: columns,
      source: SqlViewSource('$createStmtForDatabase;'),
      customParentClass: null,
      entityInfoName: entityInfoName,
      existingRowClass: existingRowClass,
      nameOfRowClass: rowClassName,
      references: references,
    );
  }
}
