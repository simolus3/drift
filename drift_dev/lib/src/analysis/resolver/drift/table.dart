import 'package:collection/collection.dart';
import 'package:drift/drift.dart' show DriftSqlType;
import 'package:drift_dev/src/analysis/driver/driver.dart';
import 'package:recase/recase.dart';
import 'package:sqlparser/sqlparser.dart' hide PrimaryKeyColumn, UniqueColumn;
import 'package:sqlparser/sqlparser.dart' as sql;
import 'package:sqlparser/utils/node_to_text.dart';

import '../../../utils/string_escaper.dart';
import '../../driver/error.dart';
import '../../driver/state.dart';
import '../../results/results.dart';
import '../intermediate_state.dart';
import '../shared/dart_types.dart';
import '../shared/data_class.dart';
import 'element_resolver.dart';
import 'sqlparser/drift_lints.dart';

class DriftTableResolver extends DriftElementResolver<DiscoveredDriftTable> {
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
    } on CantReadSchemaException catch (e) {
      reportError(DriftAnalysisError.inDriftFile(stmt.tableNameToken ?? stmt,
          'Drift was unable to analyze this table: ${e.message}'));
      throw const CouldNotResolveElementException();
    }

    final columns = <DriftColumn>[];
    final tableConstraints = <DriftTableConstraint>[];

    for (final column in table.resultColumns) {
      String? overriddenDartName;
      var type = resolver.driver.typeMapping.sqlTypeToDrift(column.type);
      final nullable = column.type.nullable != false;
      final constraints = <DriftColumnConstraint>[];
      AppliedTypeConverter? converter;
      AnnotatedDartCode? defaultArgument;
      String? overriddenJsonName;

      final definition = column.definition;
      if (definition != null) {
        final typeName = definition.typeName;

        final enumIndexMatch = typeName != null
            ? FoundReferencesInSql.enumRegex.firstMatch(typeName)
            : null;

        if (definition.typeNames case [InlineDartToken token]) {
          // An inline Dart token used as a type name indicates a custom type.
          final custom = await resolveCustomColumnType(token);
          if (custom != null) {
            type = ColumnType.custom(custom);
          }
        } else if (enumIndexMatch != null) {
          final dartTypeName = enumIndexMatch.group(2)!;
          final dartType = await findDartTypeOrReportError(dartTypeName,
              column.definition?.typeNames?.toSingleEntity ?? stmt);

          if (dartType != null) {
            converter = readEnumConverter(
              (msg) => reportError(DriftAnalysisError.inDriftFile(
                  column.definition ?? stmt, msg)),
              dartType,
              type.builtin == DriftSqlType.int
                  ? EnumType.intEnum
                  : EnumType.textEnum,
              await resolver.driver.loadKnownTypes(),
            );
          }
        }
      }

      // columns from virtual tables don't necessarily have a definition, so we
      // can't read the constraints.
      final sqlConstraints =
          column.hasDefinition ? column.constraints : const <Never>[];
      final customConstraintsForDrift = StringBuffer();

      for (final constraint in sqlConstraints) {
        var writeIntoTable = true;

        if (constraint is DriftDartName) {
          overriddenDartName = constraint.dartName;
          writeIntoTable = false;
        } else if (constraint is MappedBy) {
          writeIntoTable = false;
          if (converter != null) {
            reportError(DriftAnalysisError.inDriftFile(
                constraint,
                'Multiple type converters applied to this column, ignoring '
                'this one.'));
            continue;
          }

          converter =
              await typeConverterFromMappedBy(type, nullable, constraint);
        } else if (constraint is sql.JsonKey) {
          writeIntoTable = false;
          overriddenJsonName = constraint.jsonKey;
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
        } else if (constraint is GeneratedAs) {
          constraints.add(ColumnGeneratedAs.fromParser(constraint));
        } else if (constraint is Default) {
          defaultArgument = AnnotatedDartCode.build((b) => b
            ..addText('const ')
            ..addSymbol('CustomExpression', AnnotatedDartCode.drift)
            ..addText('(')
            ..addText(asDartLiteral(constraint.expression.toSql()))
            ..addText(')'));
        } else if (constraint is sql.PrimaryKeyColumn) {
          constraints.add(PrimaryKeyColumn(constraint.autoIncrement));
        } else if (constraint is sql.UniqueColumn) {
          constraints.add(UniqueColumn());
        }

        if (writeIntoTable) {
          if (customConstraintsForDrift.isNotEmpty) {
            customConstraintsForDrift.write(' ');
          }
          customConstraintsForDrift.write(constraint.toSql());
        }
      }

      columns.add(DriftColumn(
        sqlType: type,
        nullable: nullable,
        nameInSql: column.name,
        nameInDart: overriddenDartName ?? ReCase(column.name).camelCase,
        overriddenJsonName: overriddenJsonName,
        constraints: constraints,
        typeConverter: converter,
        defaultArgument: defaultArgument,
        documentationComment: column.definition?.documentationComment,
        customConstraints: customConstraintsForDrift.toString(),
        declaration: DriftDeclaration.driftFile(
          column.definition?.nameToken ?? stmt,
          state.ownId.libraryUri,
        ),
      ));
    }

    VirtualTableData? virtualTableData;
    final sqlTableConstraints = <String>[];

    if (stmt is CreateTableStatement) {
      for (final constraint in stmt.tableConstraints) {
        sqlTableConstraints.add(constraint.toSql());

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
        } else if (constraint is KeyClause) {
          final keyColumns = <DriftColumn>{};

          for (final keyColumn in constraint.columns) {
            final expression = keyColumn.expression;
            if (expression is Reference) {
              keyColumns.add(columns
                  .firstWhere((e) => e.nameInSql == expression.columnName));
            }
          }

          if (constraint.isPrimaryKey) {
            tableConstraints.add(PrimaryKeyColumns(keyColumns));
          } else {
            tableConstraints.add(UniqueColumns(keyColumns));
          }
        }
      }
    } else if (stmt is CreateVirtualTableStatement) {
      RecognizedVirtualTableModule? recognized;
      if (table is Fts5Table) {
        final errorLocation = stmt.arguments
                .firstWhereOrNull((e) => e.text.contains('content')) ??
            stmt.span;

        final contentTable = table.contentTable != null
            ? await resolveSqlReferenceOrReportError<DriftTable>(
                table.contentTable!,
                (msg) => DriftAnalysisError(errorLocation,
                    'Could not find referenced content table: $msg'))
            : null;
        DriftColumn? contentRowId;

        if (contentTable != null) {
          references.add(contentTable);
          final parserContentTable =
              resolver.driver.typeMapping.asSqlParserTable(contentTable);
          final rowId = parserContentTable.findColumn(table.contentRowId!);

          if (rowId == null) {
            var location = stmt.arguments
                .firstWhereOrNull((e) => e.text.contains('content_rowid'));
            reportError(DriftAnalysisError(
                location ?? errorLocation,
                'Invalid content rowid, `${table.contentRowId}` not found '
                'in `${contentTable.schemaName}`'));
          } else if (rowId is! RowId) {
            // The referenced rowid of this table is an actual column
            contentRowId = contentTable.columns
                .firstWhereOrNull((c) => c.nameInSql == rowId.name);
          }

          // Also, check that all columns referenced in the fts5 table exist in
          // the content table.
          for (final column in columns) {
            var location = stmt.arguments
                .firstWhereOrNull((e) => e.text == column.nameInSql);

            if (parserContentTable.findColumn(column.nameInSql) == null) {
              reportError(DriftAnalysisError(location ?? errorLocation,
                  'The content table has no column `${column.nameInSql}`.'));
            }
          }
        }

        recognized = DriftFts5Table(contentTable, contentRowId);
      }

      virtualTableData =
          VirtualTableData(stmt.moduleName, stmt.argumentContent, recognized);
    }

    String? dartTableName, dataClassName;
    ExistingRowClass? existingRowClass;

    final driftTableInfo = stmt.driftTableName;
    if (driftTableInfo != null) {
      final overriddenNames = driftTableInfo.overriddenDataClassName;

      if (driftTableInfo.useExistingDartClass) {
        existingRowClass =
            await resolveExistingRowClass(columns, driftTableInfo);
        final nameFromExisting = existingRowClass?.targetClass?.toString();
        if (nameFromExisting != null) {
          dataClassName = nameFromExisting;
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

    final driftTable = DriftTable(
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
      fixedEntityInfoName: dartTableName,
      existingRowClass: existingRowClass,
      withoutRowId: table.withoutRowId,
      strict: table.isStrict,
      tableConstraints: tableConstraints,
      virtualTableData: virtualTableData,
      writeDefaultConstraints: false,
      overrideTableConstraints: sqlTableConstraints,
    );

    // Run drift-specific lints on the `CREATE TABLE` statement, which requires
    // having the resolved table structure first.
    final engineForAnalysis = resolver.driver.typeMapping
        .newEngineWithTables([driftTable, ...driftTable.references]);
    final source = (file.discovery as DiscoveredDriftFile).originalSource;
    final context = engineForAnalysis.analyzeNode(stmt, source);
    final linter = DriftSqlLinter(context, references: references)
      ..collectLints();
    linter.sqlParserErrors.forEach(reportLint);

    return driftTable;
  }
}

extension on ColumnDefinition {
  String? get documentationComment {
    var lastBefore = first?.previous;

    final tokens = <CommentToken>[];

    while (lastBefore is CommentToken) {
      tokens.add(lastBefore);
      lastBefore = lastBefore.previous;
    }

    if (tokens.isEmpty) return null;

    return tokens.map((t) => '///${t.content}').join('\n');
  }
}
