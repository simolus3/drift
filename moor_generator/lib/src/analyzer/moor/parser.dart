import 'package:moor_generator/src/analyzer/errors.dart';
import 'package:moor_generator/src/analyzer/moor/create_table_reader.dart';
import 'package:moor_generator/src/analyzer/results.dart';
import 'package:moor_generator/src/analyzer/session.dart';
import 'package:sqlparser/sqlparser.dart';

class MoorParser {
  final MoorTask task;

  MoorParser(this.task);

  Future<ParsedMoorFile> parseAndAnalyze() {
    final results =
        SqlEngine(useMoorExtensions: true).parseMultiple(task.content);

    final createdReaders = <CreateTableReader>[];

    for (var parsedStmt in results) {
      if (parsedStmt.rootNode is ImportStatement) {
        final importStmt = (parsedStmt.rootNode) as ImportStatement;
        task.inlineDartResolver.importStatements.add(importStmt.importedFile);
      } else if (parsedStmt.rootNode is CreateTableStatement) {
        createdReaders.add(CreateTableReader(parsedStmt));
      } else {
        task.reportError(ErrorInMoorFile(
            span: parsedStmt.rootNode.span,
            message: 'At the moment, only CREATE TABLE statements are supported'
                'in .moor files'));
      }
    }

    // all results have the same list of errors
    final sqlErrors = results.isEmpty ? <ParsingError>[] : results.first.errors;

    for (var error in sqlErrors) {
      task.reportError(ErrorInMoorFile(
        span: error.token.span,
        message: error.message,
      ));
    }

    final createdTables =
        createdReaders.map((r) => r.extractTable(task.mapper)).toList();
    final parsedFile = ParsedMoorFile(createdTables);

    return Future.value(parsedFile);
  }
}
