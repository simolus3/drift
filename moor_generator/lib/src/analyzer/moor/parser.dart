import 'package:moor_generator/src/analyzer/errors.dart';
import 'package:moor_generator/src/analyzer/moor/create_table_reader.dart';
import 'package:moor_generator/src/analyzer/results.dart';
import 'package:moor_generator/src/analyzer/session.dart';
import 'package:sqlparser/sqlparser.dart';

class MoorParser {
  final MoorTask task;

  MoorParser(this.task);

  Future<ParsedMoorFile> parseAndAnalyze() {
    final result =
        SqlEngine(useMoorExtensions: true).parseMoorFile(task.content);
    final parsedFile = result.rootNode as MoorFile;

    final createdReaders = <CreateTableReader>[];

    for (var parsedStmt in parsedFile.statements) {
      if (parsedStmt is ImportStatement) {
        final importStmt = parsedStmt;
        task.inlineDartResolver.importStatements.add(importStmt.importedFile);
      } else if (parsedStmt is CreateTableStatement) {
        createdReaders.add(CreateTableReader(parsedStmt));
      } else {
        task.reportError(ErrorInMoorFile(
            span: parsedStmt.span,
            message: 'At the moment, only CREATE TABLE statements are supported'
                'in .moor files'));
      }
    }

    for (var error in result.errors) {
      task.reportError(ErrorInMoorFile(
        span: error.token.span,
        message: error.message,
      ));
    }

    final createdTables =
        createdReaders.map((r) => r.extractTable(task.mapper)).toList();

    return Future.value(ParsedMoorFile(result, declaredTables: createdTables));
  }
}
