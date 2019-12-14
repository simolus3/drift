import 'package:moor_generator/moor_generator.dart';
import 'package:moor_generator/src/analyzer/errors.dart';
import 'package:moor_generator/src/analyzer/runner/steps.dart';
import 'package:moor_generator/src/analyzer/moor/create_table_reader.dart';
import 'package:moor_generator/src/analyzer/runner/results.dart';
import 'package:moor_generator/src/model/sql_query.dart';
import 'package:sqlparser/sqlparser.dart';

class MoorParser {
  final ParseMoorStep step;

  MoorParser(this.step);

  Future<ParsedMoorFile> parseAndAnalyze() {
    final engine = step.task.session.spawnEngine();
    final result = engine.parseMoorFile(step.content);
    final parsedFile = result.rootNode as MoorFile;

    final createdReaders = <CreateTableReader>[];
    final queryDeclarations = <DeclaredMoorQuery>[];
    final importStatements = <ImportStatement>[];

    for (final parsedStmt in parsedFile.statements) {
      if (parsedStmt is ImportStatement) {
        final importStmt = parsedStmt;
        step.inlineDartResolver.importStatements.add(importStmt.importedFile);
        importStatements.add(importStmt);
      } else if (parsedStmt is TableInducingStatement) {
        createdReaders.add(CreateTableReader(parsedStmt, step));
      } else if (parsedStmt is DeclaredStatement) {
        queryDeclarations.add(DeclaredMoorQuery.fromStatement(parsedStmt));
      }
    }

    for (final error in result.errors) {
      step.reportError(ErrorInMoorFile(
        severity: Severity.error,
        span: error.token.span,
        message: error.message,
      ));
    }

    final createdTables = <MoorTable>[];
    final tableDeclarations = <TableInducingStatement, MoorTable>{};
    for (final reader in createdReaders) {
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
    );
    for (final decl in queryDeclarations) {
      decl.file = analyzedFile;
    }

    return Future.value(analyzedFile);
  }
}
