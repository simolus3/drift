import 'package:drift/drift.dart' show SqlDialect;
import 'package:recase/recase.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/sqlparser.dart' as sql;

import '../../../writer/queries/sql_writer.dart';
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
    final allReferences = await resolveSqlReferences(stmt);
    final references = allReferences.referencedElements;
    final engine = newEngineWithTables(references);

    final source = (file.discovery as DiscoveredDriftFile).originalSource;
    final resolveTypes = allReferences.dartTypes.isEmpty
        ? null
        : await createTypeResolver(
            allReferences,
            await resolver.driver.loadKnownTypes(),
          );

    final context = engine.analyzeNode(
      stmt,
      source,
      stmtOptions: AnalyzeStatementOptions(resolveTypeFromText: resolveTypes),
    );
    reportLints(context, references);

    final parserView = engine.schemaReader.readView(context, stmt);

    final columns = <DriftColumn>[];
    final columnDartNames = <String>{};

    for (final column in parserView.resolvedColumns) {
      final type = column.type;
      final driftType = resolver.driver.typeMapping.sqlTypeToDrift(type);
      final nullable = type?.nullable ?? true;

      AppliedTypeConverter? converter;
      var ownsConverter = false;

      // If this column has a `MAPPED BY` constraint, we can apply the converter
      // through that.
      final source = column.source;
      if (source is ExpressionColumn) {
        final mappedBy = source.mappedBy;
        if (mappedBy != null) {
          converter =
              await typeConverterFromMappedBy(driftType, nullable, mappedBy);
          ownsConverter = true;
        }
      }

      if (type?.hint<TypeConverterHint>() case final TypeConverterHint h) {
        converter ??= h.converter;
        ownsConverter = converter.owningColumn == null;
      }

      final driftColumn = DriftColumn(
        sqlType: driftType,
        nameInSql: column.name,
        nameInDart:
            dartNameForSqlColumn(column.name, existingNames: columnDartNames),
        declaration: DriftDeclaration.driftFile(stmt, file.ownUri),
        nullable: nullable,
        typeConverter: converter,
        foreignConverter: true,
      );

      columns.add(driftColumn);
      columnDartNames.add(driftColumn.nameInDart);

      if (ownsConverter) {
        converter?.owningColumn = driftColumn;
      }
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
    ).toSqlWithoutDriftSpecificSyntax(
        resolver.driver.options, SqlDialect.sqlite);

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
