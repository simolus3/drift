import 'package:moor_generator/src/analyzer/errors.dart';
import 'package:moor_generator/src/analyzer/runner/steps.dart';
import 'package:moor_generator/src/analyzer/moor/create_table_reader.dart';
import 'package:moor_generator/src/analyzer/runner/results.dart';
import 'package:moor_generator/src/model/specified_table.dart';
import 'package:moor_generator/src/model/sql_query.dart';
import 'package:sqlparser/sqlparser.dart';

class MoorParser {
  final ParseMoorStep step;

  MoorParser(this.step);

  Future<ParsedMoorFile> parseAndAnalyze() {
    final result =
        SqlEngine(useMoorExtensions: true).parseMoorFile(step.content);
    final parsedFile = result.rootNode as MoorFile;

    final createdReaders = <CreateTableReader>[];
    final queryDeclarations = <DeclaredMoorQuery>[];
    final importStatements = <ImportStatement>[];
    final otherComponents = <PartOfMoorFile>[];

    for (var parsedStmt in parsedFile.statements) {
      if (parsedStmt is ImportStatement) {
        final importStmt = parsedStmt;
        step.inlineDartResolver.importStatements.add(importStmt.importedFile);
        importStatements.add(importStmt);
      } else if (parsedStmt is CreateTableStatement) {
        createdReaders.add(CreateTableReader(parsedStmt, step));
      } else if (parsedStmt is DeclaredStatement) {
        queryDeclarations.add(DeclaredMoorQuery.fromStatement(parsedStmt));
      } else if (parsedStmt is CreateTriggerStatement) {
        otherComponents.add(parsedStmt);
      }
    }

    for (var error in result.errors) {
      step.reportError(ErrorInMoorFile(
        severity: Severity.error,
        span: error.token.span,
        message: error.message,
      ));
    }

    final createdTables = <SpecifiedTable>[];
    final tableDeclarations = <CreateTableStatement, SpecifiedTable>{};
    for (var reader in createdReaders) {
      final table = reader.extractTable(step.mapper);
      createdTables.add(table);
      tableDeclarations[reader.stmt] = table;
    }

    final analyzedFile = ParsedMoorFile(
      result,
      declaredTables: createdTables,
      queries: queryDeclarations,
      imports: importStatements,
      tableDeclarations: tableDeclarations,
      otherComponents: otherComponents,
    );
    for (var decl in queryDeclarations) {
      decl.file = analyzedFile;
    }

    return Future.value(analyzedFile);
  }
}
