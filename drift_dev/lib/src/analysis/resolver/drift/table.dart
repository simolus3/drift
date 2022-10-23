import 'package:collection/collection.dart';
import 'package:recase/recase.dart';
import 'package:sqlparser/sqlparser.dart';

import '../../driver/error.dart';
import '../../results/results.dart';
import '../intermediate_state.dart';
import '../resolver.dart';
import '../shared/dart_types.dart';
import '../shared/data_class.dart';
import 'find_dart_class.dart';

class DriftTableResolver extends LocalElementResolver<DiscoveredDriftTable> {
  DriftTableResolver(super.file, super.discovered, super.resolver, super.state);

  @override
  Future<DriftTable> resolve() async {
    Table table;
    final references = <DriftElement>{};
    final stmt = discovered.sqlNode;

    try {
      final reader = SchemaFromCreateTable(
        driftExtensions: true,
        driftUseTextForDateTime:
            resolver.driver.options.storeDateTimeValuesAsText,
      );
      table = reader.read(stmt);
    } catch (e, s) {
      resolver.driver.backend.log
          .warning('Error reading table from internal statement', e, s);
      reportError(DriftAnalysisError.inDriftFile(
        stmt.tableNameToken ?? stmt,
        'The structure of this table could not be extracted, possibly due to a '
        'bug in drift_dev.',
      ));
      rethrow;
    }

    final columns = <DriftColumn>[];
    final tableConstraints = <DriftTableConstraint>[];

    for (final column in table.resultColumns) {
      String? overriddenDartName;
      final type = resolver.driver.typeMapping.sqlTypeToDrift(column.type);
      final constraints = <DriftColumnConstraint>[];

      // columns from virtual tables don't necessarily have a definition, so we
      // can't read the constraints.
      final sqlConstraints =
          column.hasDefinition ? column.constraints : const <Never>[];
      for (final constraint in sqlConstraints) {
        if (constraint is DriftDartName) {
          overriddenDartName = constraint.dartName;
        } else if (constraint is ForeignKeyColumnConstraint) {
          // Note: Warnings about whether the referenced column exists or not
          // are reported later, we just need to know dependencies before the
          // lint step of the analysis.
          final referenced = await resolveSqlReferenceOrReportError<DriftTable>(
            constraint.clause.foreignTable.tableName,
            (msg) => DriftAnalysisError.inDriftFile(
              constraint.clause.foreignTable.tableNameToken ?? constraint,
              msg,
            ),
          );

          if (referenced != null) {
            references.add(referenced);

            // Try to resolve this column to track the exact dependency. Don't
            // report a warning if this fails, a separate lint step does that.
            final columnName =
                constraint.clause.columnNames.firstOrNull?.columnName;
            if (columnName != null) {
              final targetColumn = referenced.columns
                  .firstWhereOrNull((c) => c.hasEqualSqlName(columnName));

              if (targetColumn != null) {
                constraints.add(ForeignKeyReference(
                  targetColumn,
                  constraint.clause.onUpdate,
                  constraint.clause.onDelete,
                ));
              }
            }
          }
        }
      }

      columns.add(DriftColumn(
        sqlType: type,
        nullable: column.type.nullable != false,
        nameInSql: column.name,
        nameInDart: overriddenDartName ?? ReCase(column.name).camelCase,
        constraints: constraints,
        declaration: DriftDeclaration.driftFile(
          column.definition?.nameToken ?? stmt,
          state.ownId.libraryUri,
        ),
      ));
    }

    VirtualTableData? virtualTableData;

    if (stmt is CreateTableStatement) {
      for (final constraint in stmt.tableConstraints) {
        if (constraint is ForeignKeyTableConstraint) {
          final otherTable = await resolveSqlReferenceOrReportError<DriftTable>(
            constraint.clause.foreignTable.tableName,
            (msg) => DriftAnalysisError.inDriftFile(
              constraint.clause.foreignTable.tableNameToken ?? constraint,
              msg,
            ),
          );

          if (otherTable != null) {
            references.add(otherTable);
            final localColumns = [
              for (final column in constraint.columns)
                columns.firstWhere((e) => e.nameInSql == column.columnName)
            ];

            final foreignColumns = [
              for (final column in constraint.clause.columnNames)
                otherTable.columns
                    .firstWhere((e) => e.nameInSql == column.columnName)
            ];

            tableConstraints.add(ForeignKeyTable(
              localColumns: localColumns,
              otherTable: otherTable,
              otherColumns: foreignColumns,
              onUpdate: constraint.clause.onUpdate,
              onDelete: constraint.clause.onDelete,
            ));
          }
        }
      }
    } else if (stmt is CreateVirtualTableStatement) {
      virtualTableData = VirtualTableData(
        stmt.moduleName,
        stmt.argumentContent,
      );
    }

    String? dartTableName, dataClassName;
    ExistingRowClass? existingRowClass;

    final driftTableInfo = stmt.driftTableName;
    if (driftTableInfo != null) {
      final overriddenNames = driftTableInfo.overriddenDataClassName;

      if (driftTableInfo.useExistingDartClass) {
        final imports = file.discovery!.importDependencies.toList();
        final clazz = await findDartClass(imports, overriddenNames);
        if (clazz == null) {
          reportError(DriftAnalysisError.inDriftFile(
            stmt.tableNameToken!,
            'Existing Dart class $overriddenNames was not found, are '
            'you missing an import?',
          ));
        } else {
          existingRowClass =
              validateExistingClass(columns, clazz, '', false, this);
          dataClassName = existingRowClass?.targetClass.toString();
        }
      } else if (overriddenNames.contains('/')) {
        // Feature to also specify the generated table class. This is extremely
        // rarely used if there's a conflicting class from drift. See #932
        final names = overriddenNames.split('/');
        dataClassName = names[0];
        dartTableName = names[1];
      } else {
        dataClassName = overriddenNames;
      }
    }

    dartTableName ??= ReCase(state.ownId.name).pascalCase;
    dataClassName ??= dataClassNameForClassName(dartTableName);

    return DriftTable(
      discovered.ownId,
      DriftDeclaration(
        state.ownId.libraryUri,
        stmt.firstPosition,
        stmt.createdName,
      ),
      columns: columns,
      references: references.toList(),
      nameOfRowClass: dataClassName,
      baseDartName: dartTableName,
      existingRowClass: existingRowClass,
      withoutRowId: table.withoutRowId,
      strict: table.isStrict,
      tableConstraints: tableConstraints,
      virtualTableData: virtualTableData,
    );
  }
}
